M14 sigdecode_z follow-up — STAGING_ERROR, NOT A TEST RESULT

Job 2349 failed during run setup, before compile and simulation, because the testbench overlay file was staged at the run root instead of RUN/overlay/. This is an agent staging error and is not classified as a row result. The complete remote job tree was hash-verified and archived under raw/ before cleanup; the next run uses a fresh directory with the file placed in the required overlay path.

Remote run-tree bytes freed: 32227.
