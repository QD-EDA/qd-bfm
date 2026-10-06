# Caliptra release overlays in the QD-BFM checkpoint

The scripts under caliptra/ create disposable, hash-guarded compatibility copies for the pinned Caliptra v2.1.2 integration sources. They do not modify the Caliptra checkout. Each overlay records the expected source hash and refuses changed input.

The focused runners live under dv/caliptra_bfm and accept CALIPTRA_RTL, IVERILOG_BIN, and VVP_BIN overrides. Their test output summaries are mirrored under evidence/caliptra-bfm-*; large raw logs and generated binaries are intentionally excluded from this branch to keep the source checkpoint small.
