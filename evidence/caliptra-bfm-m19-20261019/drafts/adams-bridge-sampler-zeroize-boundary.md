# Draft report: sampler testbench zeroize boundary is one edge late

**Review only; not submitted.**

Four pinned Adams Bridge testbenches fail one queue-underflow check per input vector: `mldsa_rej_sampler_tb.sv`, `cbd_sampler_tb.sv`, `exp_mask_tb.sv`, and `rej_bounded_tb.sv`. Each scoreboard consumes four samples per valid output and increments a blocking `vld_coeff_ctr` in one `posedge clk_tb` process. A separate `posedge clk_tb` process checks `vld_coeff_ctr == 256` and schedules `zeroize <= 1`. When the scoreboard consumes the final four samples (252 to 256), the zeroize process sees the previous count. On the next edge it sees `data_valid_o=1`, `zeroize=0`, and an empty expected queue; only after that edge does zeroize rise.

Current-c339 PRE/POST traces reproduce that sequence. A testbench-only overlay changes the trigger to `data_valid_o && vld_coeff_ctr == 256 - <*_VLD_SAMPLES>`. It leaves all expected samples, comparisons, DUT logic, data, and pass criteria unchanged. The one-row row71 gate and rows 56/62/69/71 overlay reruns pass; pinned-only reruns remain failing.

Suggested scope: correct the end-of-vector zeroize scheduling in these sampler benches, and keep the expected-output comparisons intact. Evidence: `../attempts/queue-trace-row56-gate-20261019-02/`, `../attempts/queue-trace-array-20261019-01/`, `../attempts/queue-trace-array-20261019-02/`, `../attempts/queue-zeroize-overlay-gate-20261019-02/`, and `../attempts/queue-zeroize-overlay-array-20261019-01/`.
