# Icarus c339 issue #539 attribution

All source references use the pinned Adams Bridge revision `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`. Issue [#539](https://github.com/dsellerbrock/iverilog-uvm/issues/539) reproduces enum loss in a packed-struct assignment pattern when the address-member expression is wider than the packed member.

| Matrix row | Packed assignment pattern in pinned RTL | Evidence |
|---|---|---|
| `pkdecode_tb` | `src/pk_decode/rtl/pkdecode.sv:161-162`, `mem_a_wr_req` and `mem_b_wr_req` write requests use `locked_dest_addr + num_mem_operands[ + 1]` | Baseline run 502 yielded 4,096 all-X comparisons. Job 510's two address casts removed the X outputs but left 1,790 mismatches in the second invocation. Source inspection showed the TB's `src_base_addr_tb` is not connected to the DUT, which always reads from API address zero. Job 539 kept the casts and used source base zero for both calls; both 2,048-word comparisons then had zero mismatch diagnostics. Job 552 added a run-local mismatch counter/pass marker and both comparisons passed with zero mismatches. See `run-02/tasks/pkdecode/`, `run-04-pkdecode-src0/`, and `run-05-pkdecode-passmarker/`. |
| `sigdecode_z_tb` | `src/sig_decode_z/rtl/sigdecode_z_top.sv:179-180` write requests and `:199-200` read requests place wider address expressions in the packed request pattern | Existing c339 run with vectors and NumPy available produced 3,584 all-X outputs; see `slurm-mldsa-width/README.md` and array 506 evidence. |
| `skencode_tb` | `src/sk_encode/rtl/skencode.sv:226` write request uses `locked_dest_addr + num_api_operands`; read expressions also appear at `:280-281` | Existing c339 run with the testbench compatibility overlay produced all-X outputs; see array 502 evidence and `slurm-mldsa-width/README.md`. |

The cast was applied only to the copied source in the job 510 run directory. Pinned source revisions and the Icarus tree were not changed.
