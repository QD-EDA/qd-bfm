// SPDX-License-Identifier: Apache-2.0
// Icarus top joins the generated static and UVM tops into one elaborated root.
`timescale 1ns/1ps
module caliptra_soc_ifc_generated_env_top;
  import caliptra_soc_ifc_generated_env_probe_pkg::*;
  hdl_top generated_hdl_top();
  caliptra_soc_ifc_generated_env_hvl generated_hvl_top();

`ifdef CALIPTRA_BFM_OPEN_MBOX_TARGET
  integer mbox_probe_index;
  integer mbox_probe_sram_write_count = 0;
  integer mbox_probe_ecc_write_count = 0;
  soc_ifc_pkg::cptra_mbox_sram_data_t mbox_probe_word;

  always @(posedge generated_hdl_top.clk) begin
    if (generated_hdl_top.soc_ifc_ctrl_agent_bus.cptra_rst_b !== 1'b1)
      generated_env_mailbox_data_available = 0;
    else if (generated_hdl_top.soc_ifc_status_agent_bus.mailbox_data_avail === 1'b1)
      generated_env_mailbox_data_available = 1;
  end

  always @(posedge generated_hdl_top.clk) begin
    if (generated_hdl_top.soc_ifc_ctrl_agent_bus.cptra_rst_b === 1'b1 &&
        generated_hdl_top.caliptra_open_mbox_sram.req.cs === 1'b1 &&
        generated_hdl_top.caliptra_open_mbox_sram.req.we === 1'b1) begin
      if (generated_hdl_top.caliptra_open_mbox_sram.req.addr != mbox_probe_sram_write_count)
        $fatal(1, "Mailbox SRAM writes were out of order at word %0d",
               mbox_probe_sram_write_count);
      if (mbox_probe_sram_write_count == 0) begin
        if (generated_hdl_top.mbox_sram_agent_drv_bfm.inject_ecc_error !==
            generated_env_probe_ecc_mode)
          $fatal(1, "Mailbox ECC configuration did not reach the target on the first write");
        if (generated_env_probe_ecc_mode != 2'b00)
          mbox_probe_ecc_write_count = mbox_probe_ecc_write_count + 1;
      end else if (generated_hdl_top.mbox_sram_agent_drv_bfm.inject_ecc_error !== 2'b00) begin
        $fatal(1, "One-shot mailbox ECC injection remained enabled after the first write");
      end
      mbox_probe_sram_write_count = mbox_probe_sram_write_count + 1;
    end
  end

  initial begin
    wait (generated_env_probe_done === 1'b1);
    #1ns;
    if (generated_hdl_top.caliptra_open_mbox_access_error !== 1'b0)
      $fatal(1, "Open mailbox SRAM target reported an access error");
    for (mbox_probe_index = 0; mbox_probe_index < MBOX_PROBE_WORDS;
         mbox_probe_index = mbox_probe_index + 1) begin
      generated_hdl_top.caliptra_open_mbox_sram.peek_word(mbox_probe_index, mbox_probe_word);
      if (mbox_probe_word.data !== generated_env_mbox_expected_word(mbox_probe_index))
        $fatal(1, "Mailbox SRAM word %0d mismatch: got %h expected %h",
               mbox_probe_index, mbox_probe_word.data,
               generated_env_mbox_expected_word(mbox_probe_index));
    end
    if (mbox_probe_sram_write_count != MBOX_PROBE_WORDS ||
        mbox_probe_ecc_write_count != (generated_env_probe_ecc_mode != 2'b00))
      $fatal(1, "Mailbox SRAM observed %0d writes and %0d ECC-injected writes",
             mbox_probe_sram_write_count, mbox_probe_ecc_write_count);
    generated_env_mbox_memory_check_done = 1'b1;
    $display("PASS: open mailbox SRAM contains all four expected input words (ECC mode %b)",
             generated_env_probe_ecc_mode);
  end
`endif

  initial begin
    if ($test$plusargs("TRACE_CPTRA_KEY")) begin
      $monitor("CPTRA_KEY_TRACE t=%0t pgood=%b rst_b=%b key_in=%h security=%b drv_security=%b dut_security=%b clear=%b key_reg=%h",
               $time,
               generated_hdl_top.soc_ifc_ctrl_agent_bus.cptra_pwrgood,
               generated_hdl_top.soc_ifc_ctrl_agent_bus.cptra_rst_b,
               generated_hdl_top.soc_ifc_ctrl_agent_bus.cptra_obf_key,
               generated_hdl_top.soc_ifc_ctrl_agent_bus.security_state,
               generated_hdl_top.soc_ifc_ctrl_agent_drv_bfm.security_state_o,
               generated_hdl_top.dut.security_state,
               generated_hdl_top.cptra_ctrl_agent_bus.clear_obf_secrets,
               generated_hdl_top.cptra_status_agent_bus.cptra_obf_key_reg);
    end
  end

  integer progress_fd;
  integer progress_count;
  string progress_path;
  initial begin
    if (!$value$plusargs("SOC_IFC_PROGRESS_LOG=%s", progress_path))
      progress_path =
        "evidence/caliptra-bfm-soc-ifc-generated-env-runtime-20261005/generated-env-runtime-heartbeat.log";
    progress_fd = $fopen(progress_path, "w");
    if (progress_fd == 0)
      $fatal(1, "cannot open generated SoC-IFC heartbeat log");
    progress_count = 0;
    forever begin
      #100ns;
      progress_count = progress_count + 1;
      if ((progress_count % 10) == 0) begin
        $fdisplay(progress_fd,
                  "SOC_IFC_ENV_PROGRESS t=%0t clk=%b dummy=%b pgood=%b rst_b=%b mbox_req=%h mbox_resp=%h",
                  $time,
                  generated_hdl_top.clk,
                  generated_hdl_top.dummy,
                  generated_hdl_top.soc_ifc_ctrl_agent_bus.cptra_pwrgood,
                  generated_hdl_top.soc_ifc_ctrl_agent_bus.cptra_rst_b,
                  generated_hdl_top.mbox_sram_agent_bus.mbox_sram_req,
                  generated_hdl_top.mbox_sram_agent_bus.mbox_sram_resp);
        $fflush(progress_fd);
      end
    end
  end
endmodule

module caliptra_soc_ifc_generated_env_hvl;
  import uvm_pkg::*;
  import caliptra_soc_ifc_generated_env_probe_pkg::*;

  initial begin
    run_test();
  end
endmodule
