#!/usr/bin/env python3
import csv
import subprocess
import sys
import tarfile
from pathlib import Path


root = Path(sys.argv[1])
archive = Path(sys.argv[2])
with (root / "run-selection.tsv").open() as stream:
    selection = {row["test_id"]: row for row in csv.DictReader(stream, delimiter="\t")}

completed = []
for result_dir in sorted((root / "results").iterdir()):
    if not (result_dir / "task-complete.txt").is_file():
        continue
    checksums = result_dir / "FILE-SHA256SUMS"
    if not checksums.is_file():
        raise SystemExit(f"missing checksum manifest: {checksums}")
    subprocess.run(["sha256sum", "-c", checksums.name], cwd=result_dir, check=True)
    completed.append(result_dir)

with tarfile.open(archive, "w:gz") as tar:
    for rel in (Path("run-selection.tsv"), Path("run-array.sbatch"), Path("model.sha256"), Path("axi_if.overlay.sha256"), Path("verilator.version")):
        if (root / rel).is_file():
            tar.add(root / rel, arcname=rel.as_posix())
    for result_dir in completed:
        test_id = result_dir.name
        if test_id not in selection:
            raise SystemExit(f"result id not in selection: {test_id}")
        index = selection[test_id]["array_index"]
        for rel in (
            Path("results") / test_id,
            Path("resources") / f"{test_id}-1835-{index}.resource",
            Path("logs") / f"a2-m10b-ar-run09-1835_{index}.out",
        ):
            path = root / rel
            if not path.exists():
                continue
            def keep_without_work(tar_info):
                if ".work" in Path(tar_info.name).parts:
                    return None
                return tar_info
            tar.add(path, arcname=rel.as_posix(), filter=keep_without_work)

print(f"completed_rows={len(completed)}")
print("test_ids=" + ",".join(path.name for path in completed))
print(f"archive={archive}")
