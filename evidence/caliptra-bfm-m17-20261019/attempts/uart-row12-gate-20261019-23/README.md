# UART row 12 single-row gate

A 600 s Icarus gate for the authored `uart_test`, using a filelist built from the pinned UART compile.yml and the Caliptra primitive filelist. The bench's existing `* TESTCASE PASSED`/`FAILED` output remains the pass criterion. Overlay scope is filelist/setup only.

Job 2929 ran on DAN-DESKTOP. Compile exit 0; VVP hit the 600 s cap (exit 124, elapsed 599.164 s). The log has no terminal test marker and ends during repeated reads from address `0x14`, each returning `0x31`. Row 12 is `TIMEOUT`. Toolchain: Icarus `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`. Raw archive `raw/job-2929.tar.gz`; SHA-256 `5c4e93d17977873243c94b0f1b5218a018befbcc2ad133080ec4383f15b700d`.

The intern timed out on the full 7 MB log, then summarized the final 120 lines; its repeated-read observation matches the archived tail and structured `result.json`. No pass/fail marker was present.
