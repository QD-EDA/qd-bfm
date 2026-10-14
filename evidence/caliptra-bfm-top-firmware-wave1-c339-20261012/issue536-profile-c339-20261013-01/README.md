# c339 VVP runtime profile

A 60-second `perf` sample of the live `cptra_ss_test_rom` VVP process from array 799 task 2. The sample is a runtime profile, not a testcase verdict. The heartbeat log around the sample shows active progress; the task had no terminal result at capture time.

## Reproduction

- Host: DAN-DESKTOP, WSL2 Linux `6.18.33.1-microsoft-standard-WSL2`, x86_64, Intel Core Ultra 9 285K.
- Perf: 7.0.14.
- Runtime: Icarus 13.0 (devel), source c339 `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`.
- VVP SHA-256: `ac6cd60d97ccf128118166f10855ca75d9271a561b440d30eb010404705be60f`.
- Test: `cptra_ss_test_rom`, job 799 task 2, active VVP PID 1647759 at capture.
- Capture: 2026-10-13 03:38–03:39 MDT; 59.963 seconds, 2,892 samples, zero lost samples. The profile report identifies the sampled event as `task-clock:uppp`.
- Command: `perf record -F 49 -g --call-graph fp -p 1647759 -o perf.data -- sleep 60`.

## Highest self-overhead symbols

The percentages below are the `perf report --stdio --no-children --sort=symbol` self-overhead values, verified against the saved raw report:

| Share | Symbol |
|---:|---|
| 8.92% | `of_PROP_INDEX_CHECK(vthread_s*, vvp_code_s*)` |
| 8.85% | `vpip_vec4_to_int64_saturated(vvp_vector4_t const&, bool, long&)` |
| 8.78% | `of_LOAD_VEC4(vthread_s*, vvp_code_s*)` |
| 3.60% | `malloc` |
| 3.22% | `vthread_run(vthread_s*)` |
| 2.87% | `vvp_vector4_t::copy_from_big_(vvp_vector4_t const&)` |
| 2.52% | `__dynamic_cast` |
| 2.28% | `vthread_schedule_list(vthread_s*)` |
| 2.21% | `resolve_context_scope(__vpiScope*)` |
| 2.04% | `cfree` |
| 1.90% | `vvp_vector4_t::mul(vvp_vector4_t const&)` |
| 1.87% | `vvp_vector4_t::set_bit(unsigned int, vvp_bit4_t)` |
| 1.80% | `vvp_vector4_t::eeq(vvp_vector4_t const&) const` |
| 1.66% | `schedule_assign_vector(...)` |
| 1.49% | `schedule_simulate()` |

The top samples are spread across procedural property/index checking, vector conversion/loading and memory allocation. This single sample does not establish a workload-wide ranking or a straightforward optimization; it profiles one live test on one c339 build.

## Files

- `perf.data`: raw 0.224 MB sample.
- `perf-report.txt`: full symbol report.
- `metadata.txt`: host, tool version, binary hash, and perf header.
- `SHA256SUMS`: integrity hashes for the saved artifacts.

Trailing display whitespace was stripped from the saved text report. `perf report --header-only` emitted `Invalid HEADER_EVENT_DESC` because the data header lacks an event descriptor. The ordinary symbol report still parsed the sample and reported zero lost samples; the event shown there is `task-clock:uppp`.
