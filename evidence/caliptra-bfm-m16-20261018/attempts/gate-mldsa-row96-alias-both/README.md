# Gate 2745 — row 96 predictor and scoreboard type overlays

Submitted a fresh one-row gate after job 2741 showed the predictor alias cleared but the scoreboard's expected-analysis cast still failed. The testbench-only overlay now rewrites the predictor declaration and all six scoreboard declarations (three queues, three scalar locals) to the accepted QD-BFM transfer type. No RTL, firmware, or pass criteria changed.

The local runner unit suite passed (48 tests), and a direct transform check against the archived job-2741 scoreboard source rewrote all six real declarations. Job 2745 was **BLOCKED before compile** because the predictor has two generated parameterized transfer declarations, not one: its outgoing-transaction typedef and the local cast target. The runner incorrectly required exactly one and rejected the overlay. This was an overlay-source-shape guard failure, not a test result. The archived log and result are in `raw/job-2745/remote-evidence.tar.gz`; the completed remote run tree was removed after saving evidence.

See `submission-2745.txt`, `source-state.txt`, `run.sbatch`, and `raw/staged-source.tar.gz` for reproducibility details.
