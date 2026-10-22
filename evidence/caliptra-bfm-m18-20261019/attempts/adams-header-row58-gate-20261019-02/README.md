# Adams Bridge missing-config-header row 58 gate, retry 2

This gate reruns row 58 (`sib_rand_test`) after removing the overlay helper's incorrect requirement that a listed bench import the renamed sampler package. The pinned sample_in_ball bench does not import that package; the filelist still maps it to the current ABR source. No macro values, RTL, expected outputs, or pass criteria change.

Pinned Icarus: `cae035642e056644274a01e98d4422ce286685b4`; one CPU, 4 GiB, 600-second per-row timeout. Source snapshot SHA-256: `7f56cc02876e16c24713d15bfa4a5872c03d05e3575dcae54ea62a06ef7899ed`. Job 3052 ran after correcting the no-import guard. The overlay was generated, but compile stopped at `sample_in_ball_tb.sv:25`: the bench imports legacy `sampler_pkg` while the pinned source provides `abr_sampler_pkg`. This diagnostic is retained; it is not the terminal row result. Archive SHA-256: a0c934ac68c1721f8ae668c8aab8721549f5949cff58ae99da422bbcd5953aaa.
