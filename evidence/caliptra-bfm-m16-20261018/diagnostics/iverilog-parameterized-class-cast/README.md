# Parameterized AHB class cast diagnostic

The minimal test uses the MLDSA predictor's class-parameter expressions and the QD-BFM's literal-width typedef. On pinned Icarus 13.0 (`9b5fad2af`) and Verilator 5.032, both casts return the same results: `alias_cast=1 generated_cast=0`. Both tools compile and run the file successfully.

This is not classified as an Icarus simulator defect: the generated specialization also fails on Verilator. The MLDSA compatibility overlay should declare the predictor item through the QD-BFM typedef that accepts the received object. No issue was sent to A3 from this diagnostic.

The reproducer source SHA256 is in `source.sha256`; job 2740 provenance and logs are in `raw/job-2740/`.
