# KeyVault pinned runtime attempt 2

Slurm job 2794 reached Icarus but failed before elaborating the generated testbench: the runner's external stubs redeclared `QUESTA_MVC` and `qvip_utils_pkg`, which the staged QD-BFM compatibility packages already define. The run did not start simulation. The runner now retains only the unrelated `rw_txn_pkg` stub.

Pinned firmware commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. Pinned Icarus binary SHA-256: `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`. Source archive SHA-256: `e59aa644fe0571f4a99db9f17cff9035778d4e3ce2bb5980ef742ddeb071e616`. Failed-run archive: `raw/job-2794-runner-failure.tar.gz`, SHA-256 `a44c82ea90bd13c958fe7f68ad1d607127e4d8903a51ca580be8ce43d6befc69`. The remote run tree was removed after evidence capture.
