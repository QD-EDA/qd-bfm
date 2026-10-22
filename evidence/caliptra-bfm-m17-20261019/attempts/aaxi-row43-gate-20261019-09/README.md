# M17 row 43 one-row gate

Slurm job 2884 ran one task with 1 CPU, 4 GiB, a 20-minute allocation cap, and a 600-second per-row timeout on DAN-DESKTOP. Pinned Icarus source: `9b5fad2afb4104caa816b257d5bccc40f01b8c66`; binary SHA-256: `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`. Caliptra firmware pin: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.

Result: **BLOCKED** after 0.415 seconds. Icarus stopped before simulation at `axi4_caliptra_record_if.sv:5: syntax error`; there is no runtime result. Intern independently reported the same location and terminal `I give up.`; the archived compile log confirms both.

Source snapshot SHA-256: `417ca8b53ec686899f48d44e607bc298c171c215f1cf3823d3e9e8454456a1e5`. Raw job archive SHA-256: `95aa595d111dcb5ea852c256a35c3b04508f576a770969d6e022867ed048c1f9`.
