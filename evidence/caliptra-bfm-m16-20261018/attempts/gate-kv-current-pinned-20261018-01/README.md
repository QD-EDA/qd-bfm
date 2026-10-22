# KeyVault pinned runtime attempt 1

Slurm job 2793 stopped before overlay generation or Icarus compilation because the staged repository snapshot omitted `scripts/run_with_memory_pressure_guard.py`, which `run.py` invokes through its memory guard. This is a source-staging failure, not a test result.

Pinned firmware commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. Pinned Icarus source: `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`. The failed-run archive is `raw/job-2793-staging-failure.tar.gz` (SHA-256 `5528823b4c2c00417ea2632b48e057246d6b71096ceaa1b070e2e8bc41c7c394`). The completed run tree was removed after capture.
