// SPDX-License-Identifier: Apache-2.0
module ecc_generated_full_probe;
  hdl_top hdl();
  hvl_top hvl();

  integer ecc_trace_cycles;
  initial begin
    if ($test$plusargs("UVM_TESTNAME=ecc_key_sign_only_test")) begin
      ecc_trace_cycles = 0;
      forever begin
        repeat (10000) @(posedge hdl.ECC_in_agent_bus.clk);
        ecc_trace_cycles = ecc_trace_cycles + 10000;
        $display("ECC_KEY_SIGN_TRACE cycles=%0d sign=%b dsa_busy=%b pm_busy=%b hmac_busy=%b dsa_pc=%h pm_pc=%h mont=%0d error=%b",
          ecc_trace_cycles,
          hdl.dut.ecc_dsa_ctrl_i.signing_process,
          hdl.dut.ecc_dsa_ctrl_i.dsa_busy,
          hdl.dut.ecc_dsa_ctrl_i.pm_busy_o,
          hdl.dut.ecc_dsa_ctrl_i.hmac_busy,
          hdl.dut.ecc_dsa_ctrl_i.prog_cntr,
          hdl.dut.ecc_dsa_ctrl_i.ecc_arith_unit_i.ecc_pm_ctrl_i.prog_cntr,
          hdl.dut.ecc_dsa_ctrl_i.ecc_arith_unit_i.ecc_pm_ctrl_i.mont_cntr,
          hdl.dut.ecc_dsa_ctrl_i.error_flag);
        $fflush;
      end
    end
  end
endmodule
