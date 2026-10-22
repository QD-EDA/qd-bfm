# M17 DOE/ECC timeout attempt 18: staging failure

Array job 2902 did not reach either test. Both rows attempted to unpack the same source tarball concurrently into one shared directory; the Slurm output reports `tar: ... Cannot open: File exists`. There are no per-row result records and this is not test evidence. The exact run directory was archived then removed; rows 13 and 51 were resubmitted from a fresh directory with the source snapshot extracted once before submission.

Source snapshot SHA-256: `c0d2f4bcce3a059e856a9da15977b34a7d7fef62f753386680ecad57ffdea6fe`. Infrastructure logs archive: `raw/infrastructure-job-2902.tar.gz`; SHA-256: `7f6039b72d178e05d0918d00280abb489bff925443777575637c72dd575c98b3`.
