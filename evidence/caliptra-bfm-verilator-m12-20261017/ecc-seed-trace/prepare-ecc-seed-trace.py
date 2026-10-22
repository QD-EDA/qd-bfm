#!/usr/bin/env python3
import hashlib
import sys
from pathlib import Path

rtl, filelist, overlay_root = map(Path, sys.argv[1:])
source = rtl / "src/ecc/rtl/ecc_dsa_ctrl.sv"
source_bytes = source.read_bytes()
source_sha = hashlib.sha256(source_bytes).hexdigest()
if source_sha != "bfe41f23b8002cc18e22c2f1fe8045fd0fb9c026d966154e3c6e845f9b24989b":
    raise SystemExit(f"pinned ECC controller source hash mismatch: {source_sha}")

anchor = b"`CALIPTRA_ASSERT_STABLE(ERR_ECC_SEED_NOT_STABLE, seed_reg, clk, (!reset_n || ecc_ready_reg) )"
replacement = b"""`ifdef VERILATOR
always @(posedge clk) begin
    if (kv_seed_write_en || zeroize_reg || kv_seed_data_present_reset ||
        (kv_seed_error == KV_READ_FAIL)) begin
        $display("M12_ECC_SEED_CONTROL time=%0t zeroize=%b present_reset=%b kv_read_fail=%b write_en=%b offset=%0d data=%08h ready=%b hwclr=%b seed=%096h",
                 $time, zeroize_reg, kv_seed_data_present_reset,
                 (kv_seed_error == KV_READ_FAIL), kv_seed_write_en,
                 kv_seed_write_offset, kv_seed_write_data, ecc_ready_reg,
                 hwif_in.ECC_SEED[0].SEED.hwclr, seed_reg);
    end
end
M12_ECC_SEED_STABILITY_TRACE: assert property (@(posedge clk)
    disable iff (((!reset_n || ecc_ready_reg) !== '0)) ($stable(seed_reg)))
else begin
    $display("M12_ECC_SEED_CHANGE time=%0t previous=%096h current=%096h ready=%b zeroize_hist=%05b present_reset_hist=%05b read_fail_hist=%05b hwclr_hist=%05b write_en_hist=%05b offset=%0d data=%08h next0=%08h swwe0=%b we0=%b",
             $time, $past(seed_reg), $sampled(seed_reg), $sampled(ecc_ready_reg),
             {$sampled(zeroize_reg), $past(zeroize_reg, 1), $past(zeroize_reg, 2), $past(zeroize_reg, 3), $past(zeroize_reg, 4)},
             {$sampled(kv_seed_data_present_reset), $past(kv_seed_data_present_reset, 1), $past(kv_seed_data_present_reset, 2), $past(kv_seed_data_present_reset, 3), $past(kv_seed_data_present_reset, 4)},
             {$sampled(kv_seed_error == KV_READ_FAIL), $past(kv_seed_error == KV_READ_FAIL, 1), $past(kv_seed_error == KV_READ_FAIL, 2), $past(kv_seed_error == KV_READ_FAIL, 3), $past(kv_seed_error == KV_READ_FAIL, 4)},
             {$sampled(hwif_in.ECC_SEED[0].SEED.hwclr), $past(hwif_in.ECC_SEED[0].SEED.hwclr, 1), $past(hwif_in.ECC_SEED[0].SEED.hwclr, 2), $past(hwif_in.ECC_SEED[0].SEED.hwclr, 3), $past(hwif_in.ECC_SEED[0].SEED.hwclr, 4)},
             {$sampled(kv_seed_write_en), $past(kv_seed_write_en, 1), $past(kv_seed_write_en, 2), $past(kv_seed_write_en, 3), $past(kv_seed_write_en, 4)},
             $sampled(kv_seed_write_offset), $sampled(kv_seed_write_data),
             $sampled(hwif_in.ECC_SEED[0].SEED.next),
             $sampled(hwif_in.ECC_SEED[0].SEED.swwe),
             $sampled(hwif_in.ECC_SEED[0].SEED.we));
    `CALIPTRA_ASSERT_ERROR(ERR_ECC_SEED_NOT_STABLE)
end
`else
`CALIPTRA_ASSERT_STABLE(ERR_ECC_SEED_NOT_STABLE, seed_reg, clk, (!reset_n || ecc_ready_reg) )
`endif"""
if source_bytes.count(anchor) != 1:
    raise SystemExit("expected one pinned ECC seed-stability assertion")
overlay_bytes = source_bytes.replace(anchor, replacement, 1)
if (overlay_bytes.count(anchor) != 1
        or overlay_bytes.count(b"M12_ECC_SEED_STABILITY_TRACE") != 1
        or overlay_bytes.count(b"M12_ECC_SEED_CONTROL") != 1
        or overlay_bytes.count(b"$stable(seed_reg)") != 1):
    raise SystemExit("ECC seed trace overlay self-check failed")

overlay = overlay_root / "rtl/src/ecc/rtl/ecc_dsa_ctrl.sv"
overlay.parent.mkdir(parents=True, exist_ok=True)
overlay.write_bytes(overlay_bytes)
text = filelist.read_text()
pinned = "${CALIPTRA_ROOT}/src/ecc/rtl/ecc_dsa_ctrl.sv"
if text.count(pinned) != 1:
    raise SystemExit(f"expected one pinned ECC controller filelist entry, found {text.count(pinned)}")
text = text.replace(pinned, str(overlay), 1)
if pinned in text or text.count(str(overlay)) != 1:
    raise SystemExit("ECC diagnostic filelist replacement failed")
filelist.write_text(text)
print(f"ecc_source_sha256={source_sha}")
print(f"ecc_trace_overlay_sha256={hashlib.sha256(overlay_bytes).hexdigest()}")
print(f"filelist_sha256={hashlib.sha256(filelist.read_bytes()).hexdigest()}")
