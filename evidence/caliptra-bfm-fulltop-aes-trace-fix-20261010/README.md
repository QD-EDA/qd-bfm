# Full-top AES case 8 trace fix — 2026-10-10

## Result

AES/DMA case 8 passes through the Caliptra full top with the native AXI checker
and AXI VPI trace enabled. It emitted one `TESTCASE PASSED`, no failure or bad
diagnostic markers, and normal `$finish` at `minstret=1685`, `mcycle=4528`.
The trace recorded AR=2, R=16, AW=3, W=16, and B=3 handshakes.

The first traced attempt compiled and built firmware successfully, then `vvp`
terminated with signal 11 at cycle 400, before AXI traffic. Running the same
compiled top and firmware without the trace plugin passed. Inspection found
that the VPI callback registered a pointer to a stack-local `s_vpi_value`; the
callback reads signals directly and never uses `cb->value`. The active tracer
now leaves that optional value unset. The historic source under
`caliptra-bfm-open-top-smoke-20261006/` is unchanged; the full-top runner now
uses the active implementation at
`dv/caliptra_bfm/uvm/tests/sim-axi-trace-vpi.c`.

## Reproduction

```sh
sh dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.sh \
  --case smoke_test_dma_aes_gcm_short_1_dword \
  --limit-aes-cases 1 --start-aes-case 7 \
  --fast-trng --trace-axi --output <new-output-directory>
```

The run used QD-BFM base `e9474e37da18cb09a5ef28e160fb74f1344a02f1`, active
runner SHA-256 `ea57294b045c7cae66a8aa6b93692a4c1ae8b343160624e0f137b71d855c6cb0`,
and tracer SHA-256
`cf378ed88ab6c3ec39fd38d3767d64a5598ad05a7afee63e90b5799743e09ae5`.
Caliptra RTL was clean commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
The simulator was clean, published Icarus `main` at
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602` with bundled UVM
`78c06547a2a0a29b3dc9dcafae62b75b2ff61544`.

The full-top command used 2 CPUs and requested 6 GiB. Its peak RSS was
1,859,984 KiB; the process-group guard measured 1.80 GiB maximum and 21.62 GiB
minimum available memory. The no-trace comparison used 1 CPU and requested
4 GiB; it passed at `mcycle=4528`, with 1,135,228 KiB peak RSS and a 1.08 GiB
maximum process group. Job IDs were 117 and 115 respectively. The first traced
failure was job 111; its peak RSS was 1,859,192 KiB.

Slurm had all required dependencies: Icarus and `vvp`, RISC-V GCC, Python 3.12,
C compiler, `make`, OpenSSL, `xxd`, mbedTLS, and the pinned JTAG VPI plugin. No
additional packages were needed.

This is a narrowed diagnostic: one AES vector, fast TRNG cadence, fast
`.data`/`.bss` preload, and PQ vector generation skipped. It is not stock
firmware, full-suite, generated-UVMF, or qualification evidence.

## Artifacts

- [`result.json`](result.json): full-top run result and tool/source fingerprints.
- [`trace-sanitized.log`](trace-sanitized.log): cycle/AXI trace and pass/finish markers only.
- [`resource.log`](resource.log) and [`guard-summary.log`](guard-summary.log): requested-run measurements.
- [`failed-trace-result.json`](failed-trace-result.json) and [`failed-trace-resource.log`](failed-trace-resource.log): initial signal-11 result and resource record.
- [`no-trace-summary.log`](no-trace-summary.log) and [`no-trace-resource.log`](no-trace-resource.log): successful A/B markers and resource record.
- [`source-revisions.txt`](source-revisions.txt): source and tool pins.

Raw simulation logs were left in the Slurm run directory; they are not copied
here.

## Follow-up: traced AES case 9

The next vector also passed with the active tracer and AXI checker enabled:
one testcase pass, no failure or bad diagnostic markers, and normal `$finish`
at `minstret=1721`, `mcycle=4649`. The trace recorded AR=2, R=18, AW=4,
W=18, and B=4 handshakes. This run used QD-BFM commit
`accfce9c6ef0e4742a1b6b9f4a784262d0c348c8` and the same clean, published
Icarus and Caliptra pins above.

Slurm job 121 used 2 CPUs and 6 GiB; MaxRSS was 1,859,820 KiB, the guard
measured a 1.80 GiB process-group peak, and minimum available memory was
21.43 GiB. This remains narrowed firmware diagnostic evidence.

- [`case9-result.json`](case9-result.json): structured pass and provenance.
- [`case9-trace-sanitized.log`](case9-trace-sanitized.log): trace and finish markers.
- [`case9-resource.log`](case9-resource.log) and [`case9-guard-summary.log`](case9-guard-summary.log): resource and guard records.
- [`case9-source-revisions.txt`](case9-source-revisions.txt): source pins.

## Follow-up: traced AES case 10

The next vector passed with the active tracer and AXI checker enabled: one
testcase pass, no failure or bad diagnostic markers, and normal `$finish` at
`minstret=1752`, `mcycle=4809`. The trace recorded AR=2, R=20, AW=4, W=20, and
B=4 handshakes. This run used QD-BFM commit
`25228bd1e35bae806d055ca67a4378082730f198` and the same clean, published
Icarus and Caliptra pins above.

Slurm job 123 used 2 CPUs and 6 GiB and ran for 11:00.55; MaxRSS was
1,859,704 KiB, the guard measured a 1.80 GiB process-group peak, and minimum
available memory was 21.18 GiB. This remains narrowed firmware diagnostic
evidence.

- [`case10-result.json`](case10-result.json): structured pass and provenance.
- [`case10-trace-sanitized.log`](case10-trace-sanitized.log): trace and finish markers.
- [`case10-resource.log`](case10-resource.log) and [`case10-guard-summary.log`](case10-guard-summary.log): resource and guard records.
- [`case10-source-revisions.txt`](case10-source-revisions.txt): source pins.

## Follow-up: traced AES case 11

The next vector passed with the active tracer and AXI checker enabled: one
testcase pass, no failure or bad diagnostic markers, and normal `$finish` at
`minstret=1815`, `mcycle=4947`. The trace recorded AR=2, R=22, AW=4, W=22, and
B=4 handshakes. This run used QD-BFM commit
`22fc2f91478f9087aa0802fae3908998332c3488` and the same clean, published
Icarus and Caliptra pins above.

Slurm job 127 used 2 CPUs and 6 GiB and ran for 11:47.47; MaxRSS was
1,860,352 KiB, the guard measured a 1.80 GiB process-group peak, and minimum
available memory was 21.82 GiB. This remains narrowed firmware diagnostic
evidence.

- [`case11-result.json`](case11-result.json): structured pass and provenance.
- [`case11-trace-sanitized.log`](case11-trace-sanitized.log): trace and finish markers.
- [`case11-resource.log`](case11-resource.log) and [`case11-guard-summary.log`](case11-guard-summary.log): resource and guard records.
- [`case11-source-revisions.txt`](case11-source-revisions.txt): source pins.

## Follow-up: traced AES case 12

The next vector passed with the active tracer and AXI checker enabled: one
testcase pass, no failure or bad diagnostic markers, and normal `$finish` at
`minstret=1840`, `mcycle=5099`. The trace recorded AR=2, R=24, AW=4, W=24, and
B=4 handshakes. This run used QD-BFM commit
`4737c88424010b713ed95a5b28a2b8aa136150ce` and the same clean, published
Icarus and Caliptra pins above.

Slurm job 133 used 2 CPUs and 6 GiB and ran for 12:30.13; MaxRSS was
1,860,000 KiB, the guard measured a 1.80 GiB process-group peak, and minimum
available memory was 20.25 GiB. This remains narrowed firmware diagnostic
evidence.

- [`case12-result.json`](case12-result.json): structured pass and provenance.
- [`case12-trace-sanitized.log`](case12-trace-sanitized.log): trace and finish markers.
- [`case12-resource.log`](case12-resource.log) and [`case12-guard-summary.log`](case12-guard-summary.log): resource and guard records.
- [`case12-source-revisions.txt`](case12-source-revisions.txt): source pins.
