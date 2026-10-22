# Local Icarus build attempt 1

This Mac build used the archived, clean source snapshot for `cae035642e056644274a01e98d4422ce286685b4` (snapshot SHA-256 `396d4ddd8dc3a0f9285d67e3c23c15673b30d665c0956cffb10c8b51a2ee82e8`). It stopped during compilation at `vvp_dpi.cc:15`: `fatal error: 'ffi.h' file not found`. Configure completed; no binaries or smoke result were produced.

The run used `localrun 3600` and `make -j1`. It exited after 440.52 seconds with peak RSS 1,365,458,944 bytes. The build log and localrun resource summary are in `raw/`.
