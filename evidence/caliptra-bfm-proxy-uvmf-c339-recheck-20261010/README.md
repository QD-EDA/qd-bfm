# Generated PCRVault and KeyVault compile recheck on Icarus c339

Slurm array 283 reran the existing guarded PCRVault and KeyVault generated-HDL
entry points with the current QD-BFM snapshot, clean pinned Caliptra/Adams
sources, and published Icarus
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`. Each task requested 1 CPU, 1 GiB,
and a 600-second process timeout; measured peaks were 79,660 KiB (PCRVault) and
63,832 KiB (KeyVault).

Both tests stopped during compilation with `syntax error` and `Invalid module
item` at generated BFM declarations such as:

```systemverilog
pv_read_pkg::pv_read_driver #(
  .PV_READ_REQUESTOR(PV_READ_REQUESTOR)
  )
proxy;
```

The KeyVault declaration has the same package-qualified parameterized class
shape. Neither VVP nor UVM started. These are simulator compile blockers, not
completed test failures. Earlier PCRVault and KeyVault runtime passes used
older Icarus revisions and do not qualify the current pinned toolchain.

This recheck plus the generated ECC failure establishes the same blocker in
three generated Caliptra environments (ECC, PCRVault, and KeyVault). The
standalone minimal reducer confirms the parser failure independently; it was
reported in [Icarus issue #533](https://github.com/dsellerbrock/iverilog-uvm/issues/533)
with label `from-caliptra-dv`.

Artifacts preserve each suite's runner output, summary log, source/tool
revisions, binary hashes, resource usage, and status. See [`job.sbatch`](job.sbatch),
[`PCRVault log`](pcrvault/logs/runner.log), [`KeyVault log`](keyvault/logs/runner.log),
and [array scheduler output](slurm-logs/).
