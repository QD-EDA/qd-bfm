# Top-level build attempt 1302

The Verilator 5.052 frontend passed with `--timing`: 4,322.831 MB of RTL across 813 modules produced 319.452 MB of C++ in 87.788 seconds. The C++ build then failed because `jtagdpi.c` could not find `tcp_server.h`.

Cause: passing `CFLAGS=-std=c++20` on the Make command line replaced the upstream Makefile's `CFLAGS += $(TB_DPI_INCS)`, dropping both DPI include directories. The next attempt preserves the recommended C++20 mode and passes the existing `jtagdpi` and `tcp_server` include paths explicitly. No RTL, checker, or test logic was changed.
