# AXI transaction monitor parameter matrix — 2026-10-09

The guarded `run_parameter_matrix.sh` passed all nine configurations from a
clean QD-BFM checkout at `f994681bf664b6a01df7e43fb82e2400ecdeb84e`, using
clean published Icarus `main` `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`.
A live remote check returned that exact Icarus `main` SHA. Source commits,
file hashes, simulator hashes and version, Slurm script, output, and resource
measurement are retained here.

The matrix crosses `DATA_WIDTH` 32, 64, and 128 with `ID_WIDTH` 1, 4, and 8.
For each configuration, the transaction monitor observes two completed writes
and two completed reads over manager/subordinate traffic. Checks validate the
final four-beat WRAP write and read records, including IDs, addresses, burst
fields, USER metadata, payload, strobes, responses, and last-beat masks.

Slurm job 92 requested 1 GiB and 1 CPU. The nine compile/simulation cases ran
serially in 0.28 seconds with 17,604 KiB maximum RSS; exit status was zero.

This verifies representative successful completed-transaction records across
the width/ID matrix. Error, malformed-transaction, and capacity cases are not
crossed across this matrix; full Caliptra/UVMF qualification remains open.
