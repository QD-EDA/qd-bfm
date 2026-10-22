# MLDSA AHB MVC one-row gate: row 96

Pinned Icarus 13.0 (`9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`) compiled the generated MLDSA environment with the QD-BFM AHB overlay. The initial missing Questa MVC header was gone; compile advanced to `test_top.svh:32` and stopped because the open `qvip_utils_pkg` namespace lacked `qvip_memory_message_handler`.

Source inspection found exactly one reference in this generated environment: an optional handle declaration. It is not constructed or otherwise used. This attempt is therefore recorded as **BLOCKED** on a missing optional UVMF utility type, not as a simulator defect or a firmware result. The next gate adds only that unused type declaration.

The row, source pins, overlay filelist and support-source hashes are in `row-96/result.json` and `row-96/overlays/mldsa-ahb-open-mvc.json`; raw compile output and resource records are preserved alongside them.
