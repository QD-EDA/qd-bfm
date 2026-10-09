# Published Caliptra full-top AES diagnostic

Date: 2026-10-09

Command: sh dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.sh --case smoke_test_dma_aes_gcm_short_1_dword --fast-trng --first-aes-case-diagnostic

The retained full-top firmware runner passed one selected AES-DMA smoke case.
It ran with the Caliptra BFM checker enabled and exited normally:

- Case: smoke_test_dma_aes_gcm_short_1_dword
- Result: simulation exit 0, one testcase pass marker, zero fail markers
- Caliptra source: clean commit 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
- Icarus source: clean published commit 127b887dfdc09283ab0187a2e618421dee3d5dcc
- Runner modes: fast TRNG, fast boot-data preload, first AES case only, PQ vector generation skipped
- The JTAG DPI listener logged one sandbox bind denial; there were no JTAG server errors and the test did not require a client.

This is a diagnostic pass for one intentionally narrowed firmware case. It is not
stock-firmware, full regression, generated-UVMF, or full-profile qualification.
The source and binary details, command vectors, input hashes, and run summary are
preserved in results.json; the simulation log is preserved in sim.log.
