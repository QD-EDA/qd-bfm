#!/usr/bin/env python3
import csv
import json
import re
import sys
from pathlib import Path


if len(sys.argv) != 4:
    raise SystemExit("usage: aggregate-results.py RUN_ROOT C339_TIMINGS.tsv PINNED_RESULTS.tsv")

root = Path(sys.argv[1])
with (root / "run-selection.tsv").open() as stream:
    selection = {row["test_id"]: row for row in csv.DictReader(stream, delimiter="\t")}
with Path(sys.argv[2]).open() as stream:
    recovered = {row["test_id"]: row for row in csv.DictReader(stream, delimiter="\t")}
with Path(sys.argv[3]).open() as stream:
    pinned = {row["test_id"]: row for row in csv.DictReader(stream, delimiter="\t")}
if selection.keys() != pinned.keys():
    raise SystemExit("pinned results do not cover the same selected test IDs")
for test_id, row in selection.items():
    if pinned[test_id]["array_index"] != row["array_index"] or pinned[test_id]["testname"] != row["testname"]:
        raise SystemExit(f"pinned row mismatch for {test_id}")

print(
    "array_index\ttest_id\ttestname\tpinned_verilator_outcome\tpinned_assertion\tpinned_sim_elapsed_s"
    "\tc339_outcome\tc339_mcycle\tc339_wall_s"
    "\toverlay_outcome\toverlay_mcycle\toverlay_sim_s\tspeedup_x"
)
records = []
for result_path in sorted((root / "results").glob("*/result.json")):
    result_dir = result_path.parent
    if not (result_dir / "task-complete.txt").is_file():
        continue

    test_id = result_dir.name
    baseline = selection[test_id]
    pinned_result = pinned[test_id]
    result = json.loads(result_path.read_text())
    baseline_timing = recovered.get(test_id, {})
    c339_wall_s = baseline_timing.get("c339_wall_s", baseline["c339_wall_s"])
    sim_log = (result_dir / "sim.log").read_text(errors="replace")
    mcycle_match = re.search(
        r"Finished\s*:\s*minstret\s*=\s*(\d+),\s*mcycle\s*=\s*(\d+)",
        sim_log,
    )
    overlay_mcycle = mcycle_match.group(2) if mcycle_match else "NA"
    sim_elapsed = result.get("sim_elapsed_s", "NA")
    speedup = "NA"
    try:
        wall = float(c339_wall_s)
        elapsed = float(sim_elapsed)
        if baseline["c339_outcome"] == "PASS" and result.get("outcome") == "PASS":
            speedup = f"{wall / elapsed:.3f}"
    except (TypeError, ValueError, ZeroDivisionError):
        pass

    records.append(
        (
                baseline["array_index"],
                test_id,
                baseline["testname"],
                pinned_result["verilator_outcome"],
                pinned_result["assertion"],
                pinned_result["sim_elapsed_s"],
                baseline["c339_outcome"],
                baseline["c339_mcycle"],
                c339_wall_s,
                str(result.get("outcome", "NA")),
                overlay_mcycle,
                str(sim_elapsed),
                speedup,
        )
    )

for record in sorted(records, key=lambda row: int(row[0])):
    print("\t".join(record))
