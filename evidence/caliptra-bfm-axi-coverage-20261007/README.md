# Caliptra AXI passive-monitor coverage evidence

## Scope

The guarded AXI subordinate regression checks the passive monitor's
denominators and bins for address bursts and LOCK, B/R responses, accepted W
strobes and LAST beats, plus per-channel VALID and stall cycles. This is
standalone component evidence; it does not qualify the full Caliptra top or
generated UVMF environments.

## Result

`dv/caliptra_bfm/axi/tests/run_subordinate.sh` passed using the simulator built
from the merged Icarus-UVM checkout. The memory guard was configured with a
40% free-memory floor: preflight was 47% and the lowest sampled value was 46%.
The complete output is in [`verify.log`](verify.log), with machine-readable
counts in [`result.json`](result.json).

The AW and AR denominators are accepted address transactions; B is accepted
write responses; W and R are accepted data beats. In this run AW=8, AR=6, B=8,
W=10, and R=8. Burst, LOCK, response, and strobe bin totals each equal their
channel denominator. The directed writes exercise 8 full, 1 partial, and 1
zero strobe beat. VALID/stall counts are sampled clock cycles, not transfers.

## Reproduction

```sh
env CALIPTRA_BFM_MIN_FREE_PERCENT=40 \
  CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
  IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
  VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  dv/caliptra_bfm/axi/tests/run_subordinate.sh
```

The simulator binaries report Icarus Verilog 13.0 (devel), source merge
`ac4532fab037e91df2f903e67fb40f59baedccca` (which merges
`origin/main` `197f9baece79e66d25524906fb7b54c9faa8f4e2`). Their hashes and the
test source hashes are recorded in `result.json`. The simulator checkout had
other in-progress changes; this evidence uses the recorded binaries and does
not modify or clean that checkout.
