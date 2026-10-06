#!/usr/bin/env python3
"""Run one command while enforcing a system-memory floor on macOS."""

import argparse
import math
import os
import re
import signal
import subprocess
import sys
import time
from pathlib import Path


def memory_free_percent() -> int:
    if sys.platform != "darwin":
        raise RuntimeError("memory-pressure guard currently requires macOS")
    output = subprocess.check_output(
        ["memory_pressure", "-Q"], text=True, stderr=subprocess.STDOUT
    )
    match = re.search(r"System-wide memory free percentage:\s*(\d+)%", output)
    if not match:
        raise RuntimeError(f"cannot parse memory_pressure output: {output!r}")
    return int(match.group(1))


def stop_process_group(proc: subprocess.Popen, reason: str) -> None:
    print(f"memory guard: stopping command ({reason})", file=sys.stderr)
    try:
        os.killpg(proc.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    try:
        proc.wait(timeout=3)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(proc.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        proc.wait()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--min-free-percent",
        type=int,
        default=int(os.environ.get("CALIPTRA_BFM_MIN_FREE_PERCENT", "60")),
    )
    parser.add_argument("--interval", type=float, default=0.5)
    parser.add_argument("--timeout-seconds", type=float, default=90)
    parser.add_argument("--log", type=Path)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()

    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    if not command:
        parser.error("provide a command after --")
    if not 0 <= args.min_free_percent <= 100:
        parser.error("--min-free-percent must be between 0 and 100")
    if (
        not math.isfinite(args.interval)
        or not math.isfinite(args.timeout_seconds)
        or args.interval <= 0
        or args.timeout_seconds <= 0
    ):
        parser.error("--interval and --timeout-seconds must be finite and positive")

    try:
        initial_free = memory_free_percent()
    except (OSError, subprocess.CalledProcessError, RuntimeError) as exc:
        print(f"memory guard: preflight failed; command not started: {exc}", file=sys.stderr)
        return 78
    if initial_free < args.min_free_percent:
        print(
            f"memory guard: preflight {initial_free}% is below "
            f"{args.min_free_percent}%; command not started",
            file=sys.stderr,
        )
        return 78

    print(
        f"memory guard: preflight {initial_free}% free; "
        f"floor {args.min_free_percent}%",
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
        minimum_free = initial_free
        stop_reason = None
        try:
            while proc.poll() is None:
                if time.monotonic() >= deadline:
                    stop_reason = f"timeout after {args.timeout_seconds:g}s"
                    break
                current_free = memory_free_percent()
                minimum_free = min(minimum_free, current_free)
                if current_free < args.min_free_percent:
                    stop_reason = (
                        f"free memory fell to {current_free}% "
                        f"(floor {args.min_free_percent}%)"
                    )
                    break
                time.sleep(args.interval)
        except KeyboardInterrupt:
            stop_reason = "interrupted"

        if stop_reason:
            stop_process_group(proc, stop_reason)
            print(
                f"memory guard: minimum observed free memory {minimum_free}%",
                file=sys.stderr,
            )
            return 130 if stop_reason == "interrupted" else 124
        return_code = proc.wait()
        print(
            f"memory guard: command exited {return_code}; "
            f"minimum observed free memory {minimum_free}%",
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
