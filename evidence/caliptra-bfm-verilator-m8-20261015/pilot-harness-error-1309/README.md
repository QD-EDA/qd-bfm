# Harness setup error: job 1309

Job 1309 stopped before starting Verilator. The existing vector helper selected system OpenSSL from `/usr/bin`, then looked for `libcrypto.so` under `/usr/lib/lib`; this host's pinned OpenSSL is instead under `/home/dsell/toolchains/iverilog-c339/openssl`. The recorded exception is `missing native vector inputs: ['openssl_libcrypto']`.

The array environment now puts the pinned OpenSSL `bin` and `lib` directories first on `PATH` and `LD_LIBRARY_PATH`, with a preflight check for `openssl` and `libcrypto.so`. This was a harness/setup error, not a simulator test result. The case is being retried once in a fresh job.
