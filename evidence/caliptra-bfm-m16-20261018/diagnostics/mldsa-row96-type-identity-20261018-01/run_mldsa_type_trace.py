#!/usr/bin/env python3
import os
import sys
from pathlib import Path

source_root = Path(os.environ["M16_SOURCE_ROOT"])
sys.path.insert(0, str(source_root / "dv/caliptra_bfm/uvmf_lite/tests"))
import run_m15_test as runner


TRACE = (
    '    `uvm_info("M16_TYPE_TRACE", '
    '$sformatf("incoming=%s alias_wrapper_match=%0b", _t.get_type_name(), '
    '(_t.get_object_type() == '
    'ahb_lite_caliptra_uvm_pkg::ahb_lite_caliptra_mvc_transfer::type_id::get())), '
    'UVM_NONE)\n'
)


def instrument_scoreboard(source: str) -> str:
    source = original_fix_mldsa_scoreboard(source)
    signature = "virtual function void write_expected_ahb_analysis_export(mvc_sequence_item_base _t);"
    if source.count(signature) != 1:
        raise RuntimeError("expected one MLDSA expected-analysis function")
    start = source.index(signature)
    end = source.index("endfunction", start)
    body = source[start:end]
    cast = "if (!$cast(t,_t)) begin"
    if body.count(cast) != 1:
        raise RuntimeError("expected one expected-analysis cast")
    return source[:start] + body.replace(cast, TRACE + "    " + cast, 1) + source[end:]


original_fix_mldsa_scoreboard = runner.fix_mldsa_scoreboard
runner.fix_mldsa_scoreboard = instrument_scoreboard

if __name__ == "__main__":
    runner.main()
