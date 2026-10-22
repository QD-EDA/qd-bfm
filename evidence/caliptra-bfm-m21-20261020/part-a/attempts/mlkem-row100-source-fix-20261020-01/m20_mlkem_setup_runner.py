#!/usr/bin/env python3
"""Provide the pinned ML-KEM testbench's missing local setup inputs per run."""

import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

MLKEM_ROWS = {83, 84, 85, 88, 94, 95, 98, 100}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def stage_runtime(repo: Path, runtime: Path, binary: Path, env: dict[str, str]) -> dict:
    vectors = repo / "dv/caliptra_bfm/native_vectors"
    script = vectors / "random_test_ml_kem.py"
    mlkem = runtime / "ml-kem"
    mlkem.mkdir(parents=True, exist_ok=True)
    shutil.copy2(script, mlkem / script.name)
    shutil.copy2(binary, mlkem / "native_mlkem")
    tv = mlkem / "tv"
    tv.mkdir(parents=True, exist_ok=True)

    shim = runtime / ".bin"
    shim.mkdir(parents=True, exist_ok=True)
    python = Path(sys.executable).resolve()
    for name in ("python", "python3.9"):
        link = shim / name
        if link.exists() or link.is_symlink():
            if not link.is_symlink() or link.resolve() != python:
                raise RuntimeError(f"refusing to replace existing interpreter path: {link}")
        else:
            link.symlink_to(python)
    env["PATH"] = str(shim) + os.pathsep + env.get("PATH", "")
    return {
        "runtime_model": str(mlkem / "native_mlkem"),
        "runtime_model_sha256": sha256(mlkem / "native_mlkem"),
        "runtime_script": str(mlkem / script.name),
        "runtime_script_sha256": sha256(mlkem / script.name),
        "tv_directory": str(tv),
        "python_shim_directory": str(shim),
        "python_executable": str(python),
    }


def prepare(row_id: int, repo: Path, caliptra: Path, runtime: Path, output: Path,
            env: dict[str, str]) -> dict:
    vectors = repo / "dv/caliptra_bfm/native_vectors"
    source = vectors / "native_mlkem.c"
    checker = vectors / "check_native_mlkem.py"
    adams = caliptra / "submodules/adams-bridge"
    model_dir = output / "native-models"
    model_dir.mkdir(parents=True, exist_ok=True)
    binary = model_dir / "native_mlkem"
    compiler = shutil.which("cc", path=env.get("PATH"))
    if not compiler:
        raise RuntimeError("ML-KEM setup requires cc")

    build = subprocess.run(
        [compiler, "-Wall", "-Wextra", "-Werror", "-O2", str(source), "-lcrypto", "-o", str(binary)],
        cwd=output, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
    )
    (model_dir / "build.log").write_text(build.stdout)
    if build.returncode:
        raise RuntimeError(f"native ML-KEM helper build failed; see {model_dir / 'build.log'}")

    check = subprocess.run(
        [sys.executable, str(checker), str(adams), str(binary)],
        cwd=output, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
    )
    (model_dir / "kat-check.log").write_text(check.stdout)
    if check.returncode:
        raise RuntimeError(f"native ML-KEM helper KAT check failed; see {model_dir / 'kat-check.log'}")

    staged = stage_runtime(repo, runtime, binary, env)
    openssl = shutil.which("openssl", path=env.get("PATH"))
    openssl_version = subprocess.run(
        [openssl, "version"], check=True, capture_output=True, text=True
    ).stdout.strip() if openssl else "unavailable"
    manifest = {
        "row_id": row_id,
        "caliptra_source_pin": "49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e",
        "adams_bridge_source_pin": "b77e3d899e828d626cfc2a0d26a6b5704cc121e0",
        "native_model_source": str(source), "native_model_source_sha256": sha256(source),
        "native_model_binary": str(binary), "native_model_binary_sha256": sha256(binary),
        "kat_checker": str(checker), "kat_checker_sha256": sha256(checker),
        "compiler": compiler,
        "compiler_version": subprocess.run([compiler, "--version"], check=True, capture_output=True, text=True).stdout.splitlines()[0],
        "openssl_version": openssl_version,
        "kat_check": str(model_dir / "kat-check.log"),
        "kat_check_scope": "pinned Adams Bridge keygen and encapsulation KATs, a decapsulation round-trip, and malformed-input rejection",
        "staged": staged,
        "scope": "run-local testbench setup only; RTL, firmware, vectors, assertions, and pass criteria are unchanged",
    }
    path = output / "overlays/m20-mlkem-setup.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest


def self_check() -> None:
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        runtime = root / "runtime"
        vectors = repo / "dv/caliptra_bfm/native_vectors"
        vectors.mkdir(parents=True)
        script = vectors / "random_test_ml_kem.py"
        script.write_text("pass\n")
        binary = root / "native_mlkem"
        binary.write_text("model\n")
        env = {"PATH": "/usr/bin"}
        staged = stage_runtime(repo, runtime, binary, env)
        assert (runtime / "ml-kem/tv").is_dir()
        assert (runtime / "ml-kem/native_mlkem").read_text() == "model\n"
        assert (runtime / "ml-kem/random_test_ml_kem.py").read_text() == "pass\n"
        assert (runtime / ".bin/python3.9").resolve() == Path(sys.executable).resolve()
        assert env["PATH"].startswith(str(runtime / ".bin") + os.pathsep)
        assert staged["runtime_model_sha256"] == sha256(runtime / "ml-kem/native_mlkem")


def main() -> int:
    if sys.argv[1:] == ["--self-check"]:
        self_check()
        print("ML-KEM setup overlay self-check passed")
        return 0

    runner = Path(os.environ["M20_BASE_RUNNER"]).resolve()
    repo = Path(os.environ["M20_REPO_ROOT"]).resolve()
    caliptra = Path(os.environ["CALIPTRA_ROOT"]).resolve()
    args = sys.argv[1:]
    row_index = args.index("--row-id")
    row_id = int(args[row_index + 1])
    if row_id not in MLKEM_ROWS:
        raise RuntimeError(f"row {row_id} is outside the M20 ML-KEM setup group")

    namespace = {"__name__": "m20_base_runner", "__file__": str(runner), "__package__": None}
    exec(compile(runner.read_bytes(), str(runner), "exec"), namespace)
    original_run_logged = namespace["run_logged"]
    installed = False

    def overlay_run_logged(command, cwd, env, log, timeout):
        nonlocal installed
        if command and Path(command[0]).name == "vvp" and not installed:
            manifest = prepare(row_id, repo, caliptra, cwd, log.parent, env)
            installed = True
            print("M20 ML-KEM setup installed: " + json.dumps(manifest, sort_keys=True))
        return original_run_logged(command, cwd, env, log, timeout)

    namespace["run_logged"] = overlay_run_logged
    sys.argv = [str(runner), *args]
    result = namespace["main"]()
    output_index = args.index("--output-dir")
    if (Path(args[output_index + 1]) / "sim.log").exists() and not installed:
        raise RuntimeError("runner completed without installing ML-KEM setup before VVP")
    return result


if __name__ == "__main__":
    raise SystemExit(main())
