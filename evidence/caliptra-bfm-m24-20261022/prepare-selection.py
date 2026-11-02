#!/usr/bin/env python3
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "selection.tsv"


def rows(path, delimiter="\t"):
    with path.open(newline="") as stream:
        return list(csv.DictReader(stream, delimiter=delimiter))


matrix = rows(ROOT / "docs/conformance/caliptra_bfm_dv_test_matrix_2026-10-10.csv", delimiter=",")
m9 = {row["test_id"]: row for row in rows(ROOT / "evidence/caliptra-bfm-verilator-m9-20261016/results.tsv")}
m9_selection = {row["test_id"]: row for row in rows(ROOT / "evidence/caliptra-bfm-verilator-m9-20261016/run-selection.tsv")}
m21 = {
    row["test_id"]: row for row in rows(ROOT / "evidence/caliptra-bfm-m21-20261020/m21-results.tsv")
    if row["scope"] == "B"
}

out = []
stock_count = 0
for index, row in enumerate(matrix):
    old = m9[row["test_id"]]
    is_stock = row["test_kind"] == "stock-firmware-test-suite"
    run = m9_selection.get(row["test_id"], {})
    if is_stock:
        assert run, f"M9 selection is missing {row['test_id']}"
        case_yaml = run["case_yaml"]
        case_dir = run["case_dir"]
        assert case_dir == Path(case_yaml).parent.name, (row["test_id"], case_dir, case_yaml)
        assert Path(row["source_file"]).as_posix().endswith(case_yaml)
        timeout_s = min(int(run["timeout_s"]), 13_800)
        stock_count += 1
        mode = "full-top"
    else:
        case_dir = "NA"
        case_yaml = "NA"
        timeout_s = 0
        mode = "waitlist"

    last_icarus = m21.get(row["test_id"])
    out.append({
        "array_index": str(index),
        "test_id": row["test_id"],
        "source_repo": row["source_repo"],
        "area": row["area"],
        "test_kind": row["test_kind"],
        "matrix_testname": row["testname"],
        "source_file": row["source_file"],
        "case_dir": case_dir,
        "case_yaml": case_yaml,
        "timeout_s": str(timeout_s),
        "m9_verilator_outcome": old["verilator_result"],
        "m9_verilator_wall_s": old["verilator_wall_s"] or "NA",
        "last_icarus_outcome": (last_icarus["m21_status"].removeprefix("B_") if last_icarus else old["prior_icarus_result"] or "UNVERIFIED"),
        "last_icarus_source": "M21-Part-B" if last_icarus else old["prior_icarus_evidence"],
        "execution_mode": mode,
    })

assert len(matrix) == 271 and len({row["test_id"] for row in matrix}) == 271
assert stock_count == 162 and len(out) - stock_count == 109
row144 = next(row for row in out if row["test_id"] == "1b067d21081b705c")
assert row144["case_dir"] == "smoke_test_sha3_interrupt"
assert row144["matrix_testname"] == "smoke_test_sha3_interrupts"

with OUT.open("w", newline="") as stream:
    writer = csv.DictWriter(stream, fieldnames=list(out[0]), delimiter="\t", lineterminator="\n")
    writer.writeheader()
    writer.writerows(out)
print(f"rows={len(out)} full_top={stock_count} waitlist={len(out)-stock_count}")
