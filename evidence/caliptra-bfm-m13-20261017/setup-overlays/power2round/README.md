# Current-main power2round setup gate

The pinned-only M13 row compiled and exited zero but reported that `python`
was unavailable and did not create `coeff_input.hex`, `coeff_high.hex`, or
`coeff_low.hex`. Its later pass marker therefore does not qualify as a
functional result.

This one-row setup overlay prepends a protected Python 3.14.4 + NumPy 2.5.4
environment to `PATH`. It does not patch RTL or testbench source. The new
environment was copied from the previously used A2 Python environment into
`/home/dsell/toolchains/python-3.14.4-numpy-2.5.4-a2-m13-20261017/`; the old
run directory remains untouched. The copied environment is 83 MiB. SHA-256:

- `bin/python`: `52e0a13e60a981d8c4b6478be2ba5176f69da07948a056bf49cf6f077e30cb41`
- `bin/python3.14`: `52e0a13e60a981d8c4b6478be2ba5176f69da07948a056bf49cf6f077e30cb41`
- `numpy/__init__.py`: `09295a80660f17925ae23765ce8cbd7ff7ceae968d5f2f89349f1cb74c0b9e11`

The gate is `power2round_tb`, pinned RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`,
Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, and Icarus main
`9b5fad2afb4104caa816b257d5bccc40f01b8c66`. It requests one CPU and 3 GiB,
with a 600-second timeout for compile and simulation. The result qualifies as
PASS only if the generator creates all three nonempty vector files, simulation
exits zero, exactly one testcase pass marker appears, and no failure marker is
reported.

Job 2264 stopped before compilation because the first script revision resolved
the Adams Bridge filelist under the Caliptra root. This was a runner-path error,
not a test result; the Slurm output is preserved in
[`attempt-2264-script-error/slurm-2264.out`](attempt-2264-script-error/slurm-2264.out).
The corrected script resolves the filelist under the Adams Bridge root.

Job 2265 passed the gate: the vector generator created all three nonempty files,
simulation exited zero, reported 2,048 completed cases, and emitted one pass
marker with no failure marker. Compile/simulation wall times were 0.01/0.06 s;
peak RSS was 14,488/30,308 KiB. The archive includes the exact script, source
and tool provenance, generated vectors, logs, and resource reports:
[`power2round-overlay-2265.tgz`](power2round-overlay-2265.tgz). Its SHA-256 is
`9f84a664bc8fdeb6b303984b3bfcc4bfa898175cb0945aca624d2bfc5968e0a0`.
