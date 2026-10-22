#!/usr/bin/env python3
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent


def rows(path, delimiter=","):
    with path.open(newline="") as stream:
        return list(csv.DictReader(stream, delimiter=delimiter))


def normalize(value):
    value = (value or "").strip()
    if value.startswith("TIMEOUT"):
        return "TIMEOUT"
    if value.startswith("FAIL"):
        return "FAIL"
    return value if value in {"PASS", "BLOCKED", "UNVERIFIED"} else ""


matrix = rows(ROOT / "docs/conformance/caliptra_bfm_dv_test_matrix_2026-10-10.csv")
stock = [row for row in matrix if row["test_kind"] == "stock-firmware-test-suite"]
assert len(matrix) == 271 and len(stock) == 162
prior = {
    row["test_id"]: {"outcome": normalize(row["status"]), "mcycle": "NA", "wall": "NA", "evidence": "matrix status"}
    for row in matrix
}
timeouts = {}

sample = ROOT / "evidence/caliptra-bfm-top-firmware-sample-c339-20261011"
for row in rows(sample / "selection.tsv", "\t"):
    test_id = row["test_id"]
    timeouts[test_id] = row["timeout_s"]
    result_path = sample / "runs" / row["testname"] / "result.json"
    if result_path.exists():
        result = json.loads(result_path.read_text())
        sample_status = sample / "runs" / row["testname"] / "sample-outcome.txt"
        status_text = sample_status.read_text().strip().split("=", 1)[-1] if sample_status.exists() else ""
        finish = result.get("sim_scan", {}).get("finish") or result.get("finish") or [None, "NA"]
        prior[test_id] = {
            "outcome": normalize(result.get("outcome") or status_text),
            "mcycle": str(finish[1] or "NA"),
            "wall": str(result.get("sim_elapsed_s", "NA")),
            "evidence": str(result_path.relative_to(ROOT)),
        }

wave = ROOT / "evidence/caliptra-bfm-top-firmware-wave1-c339-20261012"
for row in rows(wave / "selection.tsv", "\t"):
    timeouts[row["test_id"]] = row["timeout_s"]
for row in rows(wave / "results.tsv", "\t"):
    value = normalize(row.get("terminal_outcome"))
    if value:
        prior[row["test_id"]] = {
            "outcome": value, "mcycle": "NA", "wall": "NA",
            "evidence": str((wave / row["evidence"]).as_posix()),
        }

m7 = ROOT / "evidence/caliptra-bfm-m7-rebaseline-20261014"
selection = {row["m7_index"]: row for row in rows(m7 / "top-level-selection.tsv", "\t")}
for row in rows(m7 / "top-level-results.tsv", "\t"):
    source = selection.get(row["task_id"])
    if not source:
        continue
    value = normalize(row.get("new_outcome")) or normalize(row.get("c339_outcome"))
    if value:
        prior[source["test_id"]] = {
            "outcome": value,
            "mcycle": str(row.get("new_mcycle") or row.get("c339_mcycle") or "NA"),
            "wall": str(row.get("new_elapsed_s") or row.get("c339_elapsed_s") or "NA"),
            "evidence": str((m7 / row["evidence"]).as_posix()),
        }
    timeouts[source["test_id"]] = row.get("timeout_s") or source["timeout_s"]

m8 = ROOT / "evidence/caliptra-bfm-verilator-m8-20261015"
for row in rows(m8 / "timeout-cohort.tsv", "\t"):
    value = normalize(row.get("latest_c339_outcome")) or normalize(row.get("initial_outcome"))
    if value:
        prior[row["test_id"]] = {
            "outcome": value,
            "mcycle": str(row.get("latest_c339_mcycle") or "NA"),
            "wall": str(row.get("latest_c339_elapsed_s") or row.get("initial_timeout_s") or "NA"),
            "evidence": str((m8 / "timeout-cohort.tsv").relative_to(ROOT)),
        }
    timeouts[row["test_id"]] = row["initial_timeout_s"]

run_rows = []
for index, row in enumerate(stock):
    case_yaml = Path(row["source_file"]).relative_to("src/integration/test_suites")
    selected_timeout = timeouts.get(row["test_id"])
    run_rows.append({
        "array_index": str(index),
        "test_id": row["test_id"],
        "testname": row["testname"],
        "case_dir": case_yaml.parent.name,
        "case_yaml": case_yaml.as_posix(),
        "timeout_s": selected_timeout or "21600",
        "timeout_basis": "existing pinned selection" if selected_timeout else "21600s maximum from wave-1 policy",
        "c339_outcome": prior[row["test_id"]]["outcome"],
        "c339_mcycle": prior[row["test_id"]]["mcycle"],
        "c339_wall_s": prior[row["test_id"]]["wall"],
    })
assert len({row["test_id"] for row in run_rows}) == 162

with (OUT / "run-selection.tsv").open("w", newline="") as stream:
    writer = csv.DictWriter(stream, list(run_rows[0]), delimiter="\t", lineterminator="\n")
    writer.writeheader(); writer.writerows(run_rows)

ledger = []
for row in matrix:
    result = prior[row["test_id"]]
    run_result_path = OUT / "runs" / row["test_id"] / "result.json"
    run_result = json.loads(run_result_path.read_text()) if run_result_path.exists() else None
    finish = (run_result or {}).get("sim_scan", {}).get("finish") or [None, "NA"]
    ledger.append({
        "test_id": row["test_id"],
        "source_repo": row["source_repo"],
        "area": row["area"],
        "test_kind": row["test_kind"],
        "testname": row["testname"],
        "source_file": row["source_file"],
        "verilator_result": (run_result.get("outcome", "HARNESS_RESULT_MISSING") if run_result else "PENDING") if row["test_kind"] == "stock-firmware-test-suite" else "NOT_RUN_NON_FIRMWARE",
        "final_mcycle": str(finish[1] or "NA"),
        "verilator_wall_s": str((run_result or {}).get("elapsed_s") or (run_result or {}).get("sim_elapsed_s", "NA")),
        "prior_icarus_result": result["outcome"],
        "prior_icarus_mcycle": result["mcycle"],
        "prior_icarus_wall_s": result["wall"],
        "prior_icarus_evidence": result["evidence"],
    })
assert len(ledger) == 271
with (OUT / "results.tsv").open("w", newline="") as stream:
    writer = csv.DictWriter(stream, list(ledger[0]), delimiter="\t", lineterminator="\n")
    writer.writeheader(); writer.writerows(ledger)
print(f"matrix={len(ledger)} stock_firmware={len(run_rows)} non_firmware={len(ledger) - len(run_rows)}")
