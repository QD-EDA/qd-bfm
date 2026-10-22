#!/usr/bin/env python3
import hashlib
import sys
from pathlib import Path


SOURCE_SHA256 = "5a048411bf1dcae2cda6406a6d32afba0dc9f9ef447c301875f7b6c7e1939343"

rtl, output = map(Path, sys.argv[1:])
source = rtl / "src/integration/tb/caliptra_top_tb_services.sv"
source_bytes = source.read_bytes()
if hashlib.sha256(source_bytes).hexdigest() != SOURCE_SHA256:
    raise SystemExit(f"pinned Caliptra services source hash mismatch: {source}")
text = source_bytes.decode()

declaration_before = "    localparam DCCM_PRELOADER_ADDR_WIDTH = $clog2(DCCM_PRELOADER_DEPTH);"
declaration_after = declaration_before + """
`ifdef VERILATOR
    logic [7:0] m12_dccm_preloader [0:DCCM_BYTE_SIZE-1];
    string m12_dccm_image;
`endif"""
if text.count(declaration_before) != 1:
    raise SystemExit("expected one pinned DCCM preloader declaration anchor")
text = text.replace(declaration_before, declaration_after, 1)

load_before = (
    '        if (!hex_file_is_empty) $readmemh("dccm.hex",     '
    "dummy_dccm_preloader.ram,0,`RV_DCCM_EADR - `RV_DCCM_SADR);"
)
load_after = """        if (!hex_file_is_empty) begin
`ifdef VERILATOR
            if ($value$plusargs("M12_DCCM_IMAGE=%s", m12_dccm_image)) begin
                $readmemh(m12_dccm_image, m12_dccm_preloader, 0, DCCM_BYTE_SIZE-1);
                for (int i = 0; i < DCCM_BYTE_SIZE; i++) begin
                    dummy_dccm_preloader.ram[i / DCCM_PRELOADER_BYTE_WIDTH][i % DCCM_PRELOADER_BYTE_WIDTH] = m12_dccm_preloader[i];
                end
            end else
`endif
            $readmemh("dccm.hex",     dummy_dccm_preloader.ram,0,`RV_DCCM_EADR - `RV_DCCM_SADR);
        end"""
if text.count(load_before) != 1:
    raise SystemExit("expected one pinned DCCM $readmemh load statement")
text = text.replace(load_before, load_after, 1)

if text.count("m12_dccm_preloader [0:DCCM_BYTE_SIZE-1]") != 1:
    raise SystemExit("DCCM byte scratch self-check failed")
if text.count("$value$plusargs(\"M12_DCCM_IMAGE=%s\", m12_dccm_image)") != 1:
    raise SystemExit("DCCM overlay plusarg self-check failed")
if text.count("$readmemh(m12_dccm_image, m12_dccm_preloader, 0, DCCM_BYTE_SIZE-1);") != 1:
    raise SystemExit("1D DCCM image load self-check failed")

output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(text)
print(f"services_source_sha256={SOURCE_SHA256}")
print(f"services_overlay_sha256={hashlib.sha256(output.read_bytes()).hexdigest()}")
print("change=Verilator can load normalized byte image into 1D scratch then copy into the existing 64-bit-word preloader")
