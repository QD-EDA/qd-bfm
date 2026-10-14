# AHB UVM reset-abort and recovery — 2026-10-09

## Scope

This runs the active clean-room AHB MVC/UVM compatibility path against its
bounded synthetic SRAM subordinate with `+AHB_RESET_ABORT_ONLY`. The sequence
starts a four-beat write and asserts reset during the first incomplete beat.
The test requires the command bridge to set `response_aborted`, return one
`AHB_ERROR` for the first uncompleted beat, retain the request's four data
beats, and publish no completed monitor, predictor, scoreboard, or coverage
item for the aborted transfer. It then runs follow-up traffic and requires all
four records on each compatibility stream.

This is an active UVM agent/manager integration check, not the pinned generated
Caliptra UVMF environment or a Caliptra RTL test.

## Result

The guarded run passed on clean published Icarus `main`
`4b3f3424c440aca6af92153b6860a7253b925234`, using Accellera UVM 2020.3.1.
The expected manager `$error` says the burst was reset-aborted; the UVM report
had 0 warnings, 0 errors, and 0 fatals. Follow-up traffic completed with
normal termination at 430 ns. The pin coverage report counted 10 transfer
addresses and 10 completions, 20 wait cycles, and zero completed ERROR
transfers.

The exact command was:

```sh
env \
  IVERILOG_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/iverilog \
  VVP_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/vvp \
  sh dv/caliptra_bfm/uvm/tests/run_ahb_lite_uvm_agent.sh \
  +AHB_RESET_ABORT_ONLY
```

The memory guard observed 9.35 GiB at preflight, 7.90 GiB minimum available,
and 0.36 GiB maximum process-group RSS. Its process-group cap was 3.73 GiB with
a 5.59 GiB system reserve.

## Fingerprints

Icarus source commit: `4b3f3424c440aca6af92153b6860a7253b925234`.

| Input | SHA-256 |
| --- | --- |
| `iverilog` | `00a0686a9f0d6962d3e9cd4790464321a608d77efe4db8e50fa02ec7f3f69385` |
| `vvp` | `f7b6f7cbb87d60f96914ad1213beab2a359e15cc3a2bcf176190cecb28fdc19a` |
| Test runner | `b56ca65b021314382e92b1bcc119ac4008a95ccc089b240ac8718997b1829000` |
| Testbench | `414e172aa96c3ad0fa63bd3150c3b45af42d04fac7d7617ebdb396edb070bc72` |
| AHB UVM master proxy | `15f49765daf31b37ca1f23ea56c38f74452cdcfd8dc5df02172e87ee9b5f10c4` |
| AHB command interface | `a21924976f372c86845ad05bc5b2ac2f346a6610eda563b85a51e6ad7a2484f1` |
| AHB UVM package | `82729c2af1f1ea9f3c97b9ea42e93d57b75134ded36a1bb027be8bdf5dbbb311` |
| AHB manager | `520933e2b42ba6f2e5e58e1c5be3f48088e50823045c9cdba2c4700e30d57061` |
| AHB memory subordinate | `205f58f39852e3a588947b2fecb0228060f36396eb67484be9df8f9ef2b68240` |
| UVM filelist | `afa63b20041ebef82ff585b449c06cfd208ddc95e8ba2bfd18396fc6ddd931c4` |

## Re-run against the `iverilog-uvm` fork's main (2026-10-09)

The same regression was rerun from a clean source archive of the latest
locally available `origin/main` reference for `dsellerbrock/iverilog-uvm`,
`197f9baece79e66d25524906fb7b54c9faa8f4e2` (2026-10-07), with UVM submodule
`78c06547a2a0a29b3dc9dcafae62b75b2ff61544`. The standalone AHB regression
passed under IEEE 2017 and 2023. The active UVM abort path also passed with the
same response-aborted, no-publication, post-reset traffic, and zero-UVM-error
checks above.

The branch was archived without changing the Icarus checkout. The build used
Bison 3.8.2 and the installed Homebrew libffi/Z3 include and library paths.
The `iverilog` SHA-256 was
`2588169190d99543c79d8a8c58ff3e75f7e0a9679fa871e895e5c3f15af29ba5`; `vvp`
SHA-256 was
`edbc97b6a9fec8d1425c16d0b1a6b32ad4cbdb0ad609dbfbca155cbc30eb5c6d`.

GitHub could not be resolved during this check, so `git ls-remote` could not
confirm whether a newer remote `main` exists. `197f9ba...` is the newest
published fork `origin/main` commit available in the local clone, not a claim
that the remote head was freshly verified.
