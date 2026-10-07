#!/usr/bin/env python3
"""Run one command with per-process-group and system-available memory limits."""

import argparse
import ctypes
import errno
from functools import lru_cache
import math
import os
import re
import signal
import subprocess
import sys
import time
from pathlib import Path


GIB = 1024**3
DEFAULT_MAX_PROCESS_BYTES = 6 * GIB
DEFAULT_MIN_AVAILABLE_BYTES = 6 * GIB
PROC_PIDTASKINFO = 4
MAX_GROUP_PROCESSES = 65_536


def memory_available_bytes() -> int:
    if sys.platform != "darwin":
        raise RuntimeError("memory guard currently requires macOS")
    output = subprocess.check_output(["vm_stat"], text=True, stderr=subprocess.STDOUT)
    page_size = re.search(r"page size of ([\d,]+) bytes", output)
    free = re.search(r"^Pages free:\s*([\d,]+)", output, re.MULTILINE)
    inactive = re.search(r"^Pages inactive:\s*([\d,]+)", output, re.MULTILINE)
    if not page_size or not free or not inactive:
        raise RuntimeError(f"cannot parse vm_stat output: {output!r}")
    # vm_stat's speculative pages are already included in its free-page count.
    pages = int(free[1].replace(",", "")) + int(inactive[1].replace(",", ""))
    return pages * int(page_size[1].replace(",", ""))


@lru_cache(maxsize=1)
def libproc() -> ctypes.CDLL:
    library = ctypes.CDLL("/usr/lib/libproc.dylib", use_errno=True)
    library.proc_listpgrppids.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_int]
    library.proc_listpgrppids.restype = ctypes.c_int
    library.proc_pidinfo.argtypes = [
        ctypes.c_int,
        ctypes.c_int,
        ctypes.c_uint64,
        ctypes.c_void_p,
        ctypes.c_int,
    ]
    library.proc_pidinfo.restype = ctypes.c_int
    return library


def process_group_resident_bytes(group_id: int) -> int | None:
    if sys.platform != "darwin":
        raise RuntimeError("process-group memory guard currently requires macOS")
    api = libproc()
    capacity = 256
    while True:
        pids = (ctypes.c_int * capacity)()
        ctypes.set_errno(0)
        count = api.proc_listpgrppids(group_id, pids, ctypes.sizeof(pids))
        if count < 0:
            code = ctypes.get_errno()
            raise OSError(code, os.strerror(code), "proc_listpgrppids")
        if count < capacity:
            break
        if capacity >= MAX_GROUP_PROCESSES:
            raise RuntimeError(f"process group {group_id} exceeds the guard's PID limit")
        capacity = min(capacity * 2, MAX_GROUP_PROCESSES)
    if count == 0:
        return None  # The group may exit between proc.poll() and this sample.

    # ponytail: summed RSS overcounts shared pages; use per-process footprints if this trips early.
    total = 0
    info = ctypes.create_string_buffer(256)
    for pid in pids[:count]:
        ctypes.set_errno(0)
        size = api.proc_pidinfo(pid, PROC_PIDTASKINFO, 0, info, len(info))
        if size == 0:
            code = ctypes.get_errno()
            if code == errno.ESRCH:  # Process exited between the group and task queries.
                continue
            raise OSError(code, os.strerror(code), f"proc_pidinfo({pid})")
        if size < 16:
            raise RuntimeError(f"short PROC_PIDTASKINFO record for pid {pid}: {size} bytes")
        # proc_taskinfo starts with virtual_size and resident_size uint64 fields.
        total += int.from_bytes(info.raw[8:16], byteorder=sys.byteorder)
    return total


def gibibytes(value: int) -> str:
    return f"{value / GIB:.2f} GiB"


def stop_process_group(proc: subprocess.Popen, reason: str) -> None:
    print(f"memory guard: stopping command ({reason})", file=sys.stderr)
    try:
        os.killpg(proc.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    try:
        proc.wait(timeout=3)
    except subprocess.TimeoutExpired:
        pass
    # Ensure surviving grandchildren do not keep using memory after the leader exits.
    try:
        os.killpg(proc.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    if proc.poll() is None:
        proc.wait()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--max-process-bytes",
        type=int,
        default=os.environ.get(
            "CALIPTRA_BFM_MAX_PROCESS_BYTES", str(DEFAULT_MAX_PROCESS_BYTES)
        ),
    )
    parser.add_argument(
        "--min-available-bytes",
        type=int,
        default=os.environ.get(
            "CALIPTRA_BFM_MIN_AVAILABLE_BYTES", str(DEFAULT_MIN_AVAILABLE_BYTES)
        ),
    )
    parser.add_argument("--interval", type=float, default=0.25)
    parser.add_argument("--timeout-seconds", type=float, default=90)
    parser.add_argument("--log", type=Path)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()

    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    if not command:
        parser.error("provide a command after --")
    if args.max_process_bytes <= 0 or args.min_available_bytes <= 0:
        parser.error("memory limits must be positive byte counts")
    if (
        not math.isfinite(args.interval)
        or not math.isfinite(args.timeout_seconds)
        or args.interval <= 0
        or args.timeout_seconds <= 0
    ):
        parser.error("--interval and --timeout-seconds must be finite and positive")

    try:
        initial_available = memory_available_bytes()
        if process_group_resident_bytes(os.getpgrp()) is None:
            raise RuntimeError("cannot read process-group memory before launch")
    except (OSError, subprocess.CalledProcessError, RuntimeError) as exc:
        print(f"memory guard: preflight failed; command not started: {exc}", file=sys.stderr)
        return 78
    if initial_available < args.min_available_bytes:
        print(
            f"memory guard: preflight available {gibibytes(initial_available)} is below "
            f"reserve {gibibytes(args.min_available_bytes)}; command not started",
            file=sys.stderr,
        )
        return 78

    print(
        f"memory guard: preflight available {gibibytes(initial_available)}; "
        f"process-group cap {gibibytes(args.max_process_bytes)}; "
        f"system reserve {gibibytes(args.min_available_bytes)}",
        file=sys.stderr,
    )
    log_handle = None
    proc = None
    try:
        if args.log:
            args.log.parent.mkdir(parents=True, exist_ok=True)
            log_handle = args.log.open("w")
        proc = subprocess.Popen(
            command,
            stdout=log_handle,
            stderr=subprocess.STDOUT if log_handle else None,
            start_new_session=True,
        )
        deadline = time.monotonic() + args.timeout_seconds
        minimum_available = initial_available
        maximum_process_bytes = 0
        stop_reason = None
        try:
            while proc.poll() is None:
                if time.monotonic() >= deadline:
                    stop_reason = f"timeout after {args.timeout_seconds:g}s"
                    break
                current_available = memory_available_bytes()
                current_process_bytes = process_group_resident_bytes(proc.pid)
                if current_process_bytes is None:
                    if proc.poll() is not None:
                        break
                    raise RuntimeError(f"guarded process group {proc.pid} disappeared")
                minimum_available = min(minimum_available, current_available)
                maximum_process_bytes = max(maximum_process_bytes, current_process_bytes)
                if current_process_bytes > args.max_process_bytes:
                    stop_reason = (
                        f"process group reached {gibibytes(current_process_bytes)} "
                        f"(cap {gibibytes(args.max_process_bytes)})"
                    )
                    break
                if current_available < args.min_available_bytes:
                    stop_reason = (
                        f"available memory fell to {gibibytes(current_available)} "
                        f"(reserve {gibibytes(args.min_available_bytes)})"
                    )
                    break
                time.sleep(args.interval)
        except KeyboardInterrupt:
            stop_reason = "interrupted"

        if stop_reason:
            stop_process_group(proc, stop_reason)
            print(
                f"memory guard: minimum available {gibibytes(minimum_available)}; "
                f"maximum process group {gibibytes(maximum_process_bytes)}",
                file=sys.stderr,
            )
            return 130 if stop_reason == "interrupted" else 124
        return_code = proc.wait()
        print(
            f"memory guard: command exited {return_code}; "
            f"minimum available {gibibytes(minimum_available)}; "
            f"maximum process group {gibibytes(maximum_process_bytes)}",
            file=sys.stderr,
        )
        return return_code if return_code >= 0 else 128 - return_code
    except (OSError, subprocess.CalledProcessError, RuntimeError) as exc:
        if proc is not None and proc.poll() is None:
            try:
                stop_process_group(proc, f"memory monitor failed: {exc}")
            except OSError as stop_exc:
                print(
                    f"memory guard: failed to stop command after monitor failure: {stop_exc}",
                    file=sys.stderr,
                )
        print(f"memory guard: monitor or launch failed: {exc}", file=sys.stderr)
        return 78
    finally:
        if log_handle:
            log_handle.close()


if __name__ == "__main__":
    sys.exit(main())
