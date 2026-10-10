# AXI manager outstanding-depth matrix — 2026-10-09

The guarded `run_outstanding_depth_matrix.sh` passed with
`MAX_OUTSTANDING` set to 1, 2, and 4 from a clean QD-BFM checkout at
`33bde55914bdc90be671336cea452629ee2fe0f8`. It used clean published Icarus
`main` `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`; the run checked that commit
was an ancestor of `origin/main`, and a live remote check returned the same
`main` SHA. Source and simulator hashes, version, Slurm script, output, and
resource measurement are retained here.

Each depth launches five concurrent read tasks, checks that the manager does
not exceed its configured number of outstanding requests before a response,
then drains the queued requests. At depths 2 and 4, the target returns distinct
IDs out of order and the test checks response data and USER routing.

Slurm job 84 requested 1 GiB and 1 CPU. All three compile/simulation cases ran
serially in 0.28 seconds with 17,572 KiB maximum RSS; exit status was zero.

This covers read concurrency at representative depths with the 32-bit data,
8-bit ID configuration. Concurrent write coverage at each depth and the full
width/ID/outstanding cross-product remain open.
