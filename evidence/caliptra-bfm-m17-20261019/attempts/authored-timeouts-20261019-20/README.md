# DOE and ECC timeout probes

- Job 2906 on DAN-DESKTOP ran rows 13 and 51, each with 1 CPU, 4 GiB, and a 600 s per-row timeout.
- Source snapshot SHA-256: `635e8219ba26c4e0e37b3cd76ef151ed8cc7b4f144f46d1189d141af0b76d867`.
- Toolchain: Icarus `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`.
- Row 13 `doe_cbc_nist_test`: compile exit 0, VVP timed out at 600 s (exit 124); last log line is a printed `pubkeyy` value after `*** ENCRYPTION ***`. No test pass/fail marker.
- Row 51 `ecc_normal_test`: compile exit 0, VVP timed out at 600 s (exit 124); last log line is `*** TC 0 starting ECC signing flow`. Earlier keygen success is not whole-test pass evidence. No test pass/fail marker.
- Raw archive `raw/job-2906.tar.gz`; SHA-256 `586703da04d2993d52e0d45340c72efc574294d4cea18e4957345f9c73396923`.

The intern's stopping points were checked against each archived `sim.log`; neither task reached a terminal test marker. Both are recorded as `TIMEOUT`.
