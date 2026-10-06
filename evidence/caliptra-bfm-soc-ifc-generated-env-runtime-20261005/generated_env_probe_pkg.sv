// SPDX-License-Identifier: Apache-2.0
// Minimal generated-environment runtime probe using the open Caliptra AAXI BFM.
package caliptra_soc_ifc_generated_env_probe_pkg;
  import uvm_pkg::*;
  import soc_ifc_tests_pkg::*;
  import soc_ifc_sequences_pkg::*;
  import soc_ifc_ctrl_pkg::*;
  import soc_ifc_status_pkg::*;
  import cptra_status_pkg::*;
  import ss_mode_status_pkg::*;
  import mbox_sram_pkg::*;
  import aaxi_uvm_pkg::*;
  `include "uvm_macros.svh"

  localparam integer MBOX_PROBE_WORDS = 4;
  bit generated_env_probe_done = 0;
  bit generated_env_mbox_memory_check_done = 0;
  bit generated_env_mailbox_data_available = 0;
  bit [1:0] generated_env_probe_ecc_mode = 0;

  function automatic logic [31:0] generated_env_mbox_word(input integer index);
    case (index)
      0: generated_env_mbox_word = 32'hb0f0_5eed;
      1: generated_env_mbox_word = 32'hb0f0_5eee;
      2: generated_env_mbox_word = 32'hb0f0_5eef;
      3: generated_env_mbox_word = 32'hb0f0_5ef0;
      default: generated_env_mbox_word = 'x;
    endcase
  endfunction

  function automatic logic [31:0] generated_env_mbox_expected_word(input integer index);
    generated_env_mbox_expected_word = generated_env_mbox_word(index);
    if (index == 0) begin
      if (generated_env_probe_ecc_mode[1])
        generated_env_mbox_expected_word ^= 32'h0000_0003;
      else if (generated_env_probe_ecc_mode[0])
        generated_env_mbox_expected_word ^= 32'h0000_0001;
    end
  endfunction

  function automatic logic [31:0] generated_env_mbox_host_response_word(input integer index);
    generated_env_mbox_host_response_word = generated_env_mbox_word(index);
    // The RTL corrects a single-bit error on read; double-bit data remains corrupt.
    if (index == 0 && generated_env_probe_ecc_mode[1])
      generated_env_mbox_host_response_word ^= 32'h0000_0003;
  endfunction

  class caliptra_soc_ifc_aaxi_observer extends uvm_component;
    uvm_analysis_imp #(aaxi_master_tr, caliptra_soc_ifc_aaxi_observer) completed_export;
    int write_count;
    int read_count;
    int data_in_write_count;
    bit axi_user_init_active;
    bit mailbox_response_active;
    bit mailbox_user_rejection_active;
    bit [31:0] axi_user_init_expected_user;
    bit [47:0] axi_user_init_expected_address [12];
    int axi_user_init_write_count;
    int mailbox_response_read_count;
    int mailbox_response_write_count;
    int mailbox_user_rejection_count;
    bit [31:0] mailbox_response_axi_user;
    event completed;

    `uvm_component_utils(caliptra_soc_ifc_aaxi_observer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      completed_export = new("completed_export", this);
    endfunction

    function void write(aaxi_master_tr item);
      if (!axi_user_init_active && item.id != 8'h5a)
        `uvm_fatal("SOC_IFC_ENV_AAXI", $sformatf("Unexpected host AXI record: %s", item.convert2string()))
      if (mailbox_user_rejection_active) begin
        if (item.is_write() || item.addr != 48'h2_0000 || item.aruser != 32'hbad0_bad0 ||
            item.resp != 2'b10)
          `uvm_fatal("SOC_IFC_ENV_AXI_USER_REJECT", $sformatf("Invalid mailbox USER read was not rejected with SLVERR: %s", item.convert2string()))
        mailbox_user_rejection_count++;
        -> completed;
        return;
      end
      if (item.resp != 2'b00 || !item.transport_success)
        `uvm_fatal("SOC_IFC_ENV_AAXI", $sformatf("Unexpected host AXI response: %s", item.convert2string()))
      if (item.is_write()) begin
        if (item.beatQ.size() != 1 || item.strbQ.size() != 1 || item.strbQ[0] != 4'hf)
          `uvm_fatal("SOC_IFC_ENV_AAXI_WRITE", "Generated environment monitor lost single-beat write data")
        if (mailbox_response_active) begin
          if (item.addr != 48'h2_001c || item.awuser != mailbox_response_axi_user ||
              item.beatQ[0] != 32'd2)
            `uvm_fatal("SOC_IFC_ENV_MBOX_RESPONSE", $sformatf("Unexpected mailbox response write: %s", item.convert2string()))
          mailbox_response_write_count++;
          write_count++;
          -> completed;
          return;
        end
        if (axi_user_init_active) begin
          if (axi_user_init_write_count >= 12 ||
              item.addr != axi_user_init_expected_address[axi_user_init_write_count] ||
              item.awuser != axi_user_init_expected_user)
            `uvm_fatal("SOC_IFC_ENV_AXI_USER_INIT", $sformatf("Generated RAL address/AWUSER mismatch at write %0d: %s", axi_user_init_write_count, item.convert2string()))
          case (axi_user_init_write_count)
            0, 1, 2, 3, 4:
              if (item.beatQ[0] != (32'hc0de_0000 | axi_user_init_write_count))
                `uvm_fatal("SOC_IFC_ENV_AXI_USER_INIT", "Mailbox valid-user RAL write data mismatch")
            5, 6, 7, 8, 9, 11:
              if (item.beatQ[0] != 32'd1)
                `uvm_fatal("SOC_IFC_ENV_AXI_USER_INIT", "AXI USER lock RAL write data mismatch")
            10:
              if (item.beatQ[0] != 32'hbeef_0001)
                `uvm_fatal("SOC_IFC_ENV_AXI_USER_INIT", "TRNG valid-user RAL write data mismatch")
          endcase
          axi_user_init_write_count++;
          write_count++;
          -> completed;
          return;
        end
        case (item.addr)
          48'h3_0048: if (item.beatQ[0] != 32'hcafe_51f0)
            `uvm_fatal("SOC_IFC_ENV_AAXI_USER", "Mailbox AXI user probe write mismatch")
`ifdef CALIPTRA_BFM_OPEN_MBOX_TARGET
          48'h2_0008: if (item.beatQ[0] != 32'hcafe_0001)
            `uvm_fatal("SOC_IFC_ENV_MBOX_CMD", "Mailbox command write mismatch")
          48'h2_000c: if (item.beatQ[0] != 32'd16)
            `uvm_fatal("SOC_IFC_ENV_MBOX_DLEN", "Mailbox length write mismatch")
          48'h2_0010: begin
            if (data_in_write_count >= MBOX_PROBE_WORDS ||
                item.beatQ[0] != generated_env_mbox_word(data_in_write_count))
              `uvm_fatal("SOC_IFC_ENV_MBOX_DATAIN", "Mailbox input word mismatch")
            data_in_write_count++;
          end
          48'h2_0018: if (item.beatQ[0] != 32'h0000_0001)
            `uvm_fatal("SOC_IFC_ENV_MBOX_EXECUTE", "Mailbox execute write mismatch")
`endif
          default: `uvm_fatal("SOC_IFC_ENV_AAXI_WRITE_ADDR", $sformatf("Unexpected write address %h", item.addr))
        endcase
        write_count++;
      end else begin
        if (axi_user_init_active)
          `uvm_fatal("SOC_IFC_ENV_AXI_USER_INIT", "Stock AXI USER initialization sequence unexpectedly issued a read")
        if (item.beatQ.size() != 1 || item.respQ.size() != 1 || item.respQ[0] != 2'b00)
          `uvm_fatal("SOC_IFC_ENV_AAXI_READ", "Generated environment monitor lost single-beat read data")
        if (mailbox_response_active) begin
          if (item.aruser != mailbox_response_axi_user)
            `uvm_fatal("SOC_IFC_ENV_MBOX_RESPONSE", "Mailbox response read used unexpected AXI USER")
          case (mailbox_response_read_count)
            0: if (item.addr != 48'h2_0008 || item.beatQ[0] != 32'hcafe_0001)
              `uvm_fatal("SOC_IFC_ENV_MBOX_RESPONSE_CMD", $sformatf("Mailbox command response mismatch: %s", item.convert2string()))
            1: if (item.addr != 48'h2_000c || item.beatQ[0] != 32'd16)
              `uvm_fatal("SOC_IFC_ENV_MBOX_RESPONSE_DLEN", $sformatf("Mailbox length response mismatch: %s", item.convert2string()))
            default: begin
              if (mailbox_response_read_count >= 2 + MBOX_PROBE_WORDS ||
                  item.addr != 48'h2_0014 ||
                  item.beatQ[0] != generated_env_mbox_host_response_word(mailbox_response_read_count - 2))
                `uvm_fatal("SOC_IFC_ENV_MBOX_RESPONSE_DATA", $sformatf("Mailbox data response %0d mismatch: %s", mailbox_response_read_count - 2, item.convert2string()))
            end
          endcase
          mailbox_response_read_count++;
          read_count++;
          -> completed;
          return;
        end
        case (item.addr)
          48'h3_0048: if (item.beatQ[0] != 32'hcafe_51f0)
            `uvm_fatal("SOC_IFC_ENV_AAXI_USER_READ", "Mailbox AXI user probe readback mismatch")
`ifdef CALIPTRA_BFM_OPEN_MBOX_TARGET
          48'h2_0000: if (item.beatQ[0] != 32'h0000_0000)
            `uvm_fatal("SOC_IFC_ENV_MBOX_LOCK", "Mailbox did not begin unlocked")
`endif
          default: `uvm_fatal("SOC_IFC_ENV_AAXI_READ_ADDR", $sformatf("Unexpected read address %h", item.addr))
        endcase
        read_count++;
      end
      -> completed;
    endfunction
  endclass

  class caliptra_soc_ifc_aaxi_rw_sequence extends uvm_sequence #(aaxi_master_tr);
    bit mailbox_response_only;
    bit mailbox_user_rejection_probe;
    bit [31:0] mailbox_response_axi_user;
`ifdef CALIPTRA_BFM_OPEN_MBOX_TARGET
    mbox_sram_configuration mbox_sram_agent_config;
`endif

    `uvm_object_utils(caliptra_soc_ifc_aaxi_rw_sequence)

    function new(string name = "caliptra_soc_ifc_aaxi_rw_sequence");
      super.new(name);
    endfunction

    task write_word(input logic [47:0] address, input logic [31:0] data, input logic [31:0] user);
      aaxi_master_tr req;
      req = aaxi_master_tr::type_id::create($sformatf("write_%h", address));
      start_item(req);
      req.kind = AAXI_WRITE;
      req.addr = address;
      req.id = 8'h5a;
      req.len = 0;
      req.size = 2;
      req.burst = 2'b01;
      req.awuser = user;
      req.beatQ.push_back(data);
      req.strbQ.push_back(4'hf);
      finish_item(req);
      if (!req.transport_success || req.resp != 2'b00)
        `uvm_fatal("SOC_IFC_ENV_AAXI_WRITE", $sformatf("AAXI write failed at %h", address))
    endtask

    task read_word(input logic [47:0] address, input logic [31:0] user, output logic [31:0] data);
      aaxi_master_tr req;
      req = aaxi_master_tr::type_id::create($sformatf("read_%h", address));
      start_item(req);
      req.kind = AAXI_READ;
      req.addr = address;
      req.id = 8'h5a;
      req.len = 0;
      req.size = 2;
      req.burst = 2'b01;
      req.aruser = user;
      finish_item(req);
      if (!req.transport_success || req.resp != 2'b00 || req.beatQ.size() != 1)
        `uvm_fatal("SOC_IFC_ENV_AAXI_READ", $sformatf("AAXI read failed at %h", address))
      data = req.beatQ[0];
    endtask

    task read_word_expect_slverr(input logic [47:0] address, input logic [31:0] user);
      aaxi_master_tr req;
      req = aaxi_master_tr::type_id::create($sformatf("read_denied_%h", address));
      start_item(req);
      req.kind = AAXI_READ;
      req.addr = address;
      req.id = 8'h5a;
      req.len = 0;
      req.size = 2;
      req.burst = 2'b01;
      req.aruser = user;
      finish_item(req);
      if (req.resp != 2'b10)
        `uvm_fatal("SOC_IFC_ENV_AXI_USER_REJECT", $sformatf("Invalid mailbox USER read did not return SLVERR: %s", req.convert2string()))
    endtask

    task body();
      logic [31:0] read_data;
      int i;
      bit [1:0] ecc_mode;

      ecc_mode = 2'b00;
`ifdef CALIPTRA_BFM_OPEN_MBOX_TARGET
      if ($test$plusargs("CALIPTRA_MBOX_ECC_SINGLE") &&
          $test$plusargs("CALIPTRA_MBOX_ECC_DOUBLE"))
        `uvm_fatal("SOC_IFC_ENV_MBOX_ECC", "Select only one mailbox ECC injection mode")
      if ($test$plusargs("CALIPTRA_MBOX_ECC_SINGLE")) ecc_mode = 2'b01;
      if ($test$plusargs("CALIPTRA_MBOX_ECC_DOUBLE")) ecc_mode = 2'b10;
      if (mbox_sram_agent_config == null)
        `uvm_fatal("SOC_IFC_ENV_MBOX_ECC", "Generated mailbox SRAM configuration handle is missing")
      generated_env_probe_ecc_mode = ecc_mode;
`endif

      if (mailbox_user_rejection_probe) begin
        read_word_expect_slverr(48'h2_0000, 32'hbad0_bad0);
      end else if (mailbox_response_only) begin
        read_word(48'h2_0008, mailbox_response_axi_user, read_data);
        if (read_data != 32'hcafe_0001)
          `uvm_fatal("SOC_IFC_ENV_MBOX_RESPONSE_CMD", "SoC AXI mailbox command readback mismatch")
        read_word(48'h2_000c, mailbox_response_axi_user, read_data);
        if (read_data != 32'd16)
          `uvm_fatal("SOC_IFC_ENV_MBOX_RESPONSE_DLEN", "SoC AXI mailbox length readback mismatch")
        for (i = 0; i < MBOX_PROBE_WORDS; i++) begin
          read_word(48'h2_0014, mailbox_response_axi_user, read_data);
          if (read_data != generated_env_mbox_host_response_word(i))
            `uvm_fatal("SOC_IFC_ENV_MBOX_RESPONSE_DATA", $sformatf("SoC AXI mailbox data read %0d mismatch: got 0x%0h", i, read_data))
        end
        write_word(48'h2_001c, 32'd2, mailbox_response_axi_user);
      end else begin
        write_word(48'h3_0048, 32'hcafe_51f0, 32'h0);
        read_word(48'h3_0048, 32'h0, read_data);
        if (read_data != 32'hcafe_51f0)
          `uvm_fatal("SOC_IFC_ENV_AAXI_USER", "Mailbox AXI user probe readback mismatch")
`ifdef CALIPTRA_BFM_OPEN_MBOX_TARGET
        if (!$test$plusargs("CALIPTRA_GENERATED_AHB_MBOX_PAYLOAD")) begin
          read_word(48'h2_0000, 32'hffff_ffff, read_data);
          if (read_data != 32'h0000_0000)
            `uvm_fatal("SOC_IFC_ENV_MBOX_LOCK", "Mailbox did not begin unlocked")
          write_word(48'h2_0008, 32'hcafe_0001, 32'hffff_ffff);
          write_word(48'h2_000c, 32'd16, 32'hffff_ffff);
          for (i = 0; i < MBOX_PROBE_WORDS; i++) begin
            if (i == 0) mbox_sram_agent_config.inject_ecc_error = ecc_mode;
            write_word(48'h2_0010, generated_env_mbox_word(i), 32'hffff_ffff);
          end
          if (ecc_mode != 2'b00 && mbox_sram_agent_config.inject_ecc_error != 2'b00)
            `uvm_fatal("SOC_IFC_ENV_MBOX_ECC", "Generated BFM did not clear one-shot ECC injection")
          write_word(48'h2_0018, 32'h0000_0001, 32'hffff_ffff);
        end
`endif
      end
    endtask
  endclass

  class caliptra_soc_ifc_powered_bench_sequence extends soc_ifc_bench_sequence_base;
    bit poweron_done;
    bit shutdown_requested;

    `uvm_object_utils(caliptra_soc_ifc_powered_bench_sequence)

    function new(string name = "caliptra_soc_ifc_powered_bench_sequence");
      super.new(name);
    endfunction

    task body();
      soc_ifc_ctrl_poweron_sequence poweron_sequence;
      soc_ifc_status_agent_responder_seq_t soc_ifc_responder;
      cptra_status_agent_responder_seq_t cptra_responder;
      ss_mode_status_agent_responder_seq_t ss_mode_responder;
      mbox_sram_agent_responder_seq_t mbox_responder;

      poweron_done = 0;
      shutdown_requested = 0;
      fork
        soc_ifc_ctrl_agent_config.wait_for_reset();
        cptra_ctrl_agent_config.wait_for_reset();
        ss_mode_ctrl_agent_config.wait_for_reset();
        soc_ifc_status_agent_config.wait_for_reset();
        cptra_status_agent_config.wait_for_reset();
        ss_mode_status_agent_config.wait_for_reset();
        mbox_sram_agent_config.wait_for_reset();
      join
      reg_model.reset();

      soc_ifc_responder = soc_ifc_status_agent_responder_seq_t::type_id::create("soc_ifc_responder");
      soc_ifc_status_agent_responder_seq = soc_ifc_responder;
      cptra_responder = cptra_status_agent_responder_seq_t::type_id::create("cptra_responder");
      ss_mode_responder = ss_mode_status_agent_responder_seq_t::type_id::create("ss_mode_responder");
      mbox_responder = mbox_sram_agent_responder_seq_t::type_id::create("mbox_responder");
      fork
        soc_ifc_responder.start(soc_ifc_status_agent_sequencer);
        cptra_responder.start(cptra_status_agent_sequencer);
        ss_mode_responder.start(ss_mode_status_agent_sequencer);
        mbox_responder.start(mbox_sram_agent_sequencer);
      join_none

      poweron_sequence = soc_ifc_ctrl_poweron_sequence::type_id::create("poweron_sequence");
      poweron_sequence.start(soc_ifc_ctrl_agent_sequencer);
      soc_ifc_ctrl_agent_config.wait_for_num_clocks(10);
      poweron_done = 1;
      wait (shutdown_requested);
      soc_ifc_responder.kill();
      cptra_responder.kill();
      ss_mode_responder.kill();
      mbox_responder.kill();
    endtask
  endclass

  class caliptra_soc_ifc_generated_env_probe_test extends test_top;
    caliptra_soc_ifc_aaxi_observer observer;

    `uvm_component_utils(caliptra_soc_ifc_generated_env_probe_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      observer = caliptra_soc_ifc_aaxi_observer::type_id::create("observer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      environment.aaxi_tb.env0.master[0].write_done_export.connect(observer.completed_export);
      environment.aaxi_tb.env0.master[0].read_done_export.connect(observer.completed_export);
    endfunction

    task run_phase(uvm_phase phase);
      caliptra_soc_ifc_powered_bench_sequence powered_sequence;
      caliptra_soc_ifc_aaxi_rw_sequence aaxi_sequence;
      soc_ifc_env_pkg::soc_ifc_env_axi_user_init_sequence_t axi_user_init_sequence;
      uvm_report_server report_server;
      uvm_status_e ahb_ral_status;
      uvm_reg_data_t ahb_ral_value;
      bit sequence_done;
      bit top_sequence_done;
      bit poweron_wait_done;
      int i;
      phase.raise_objection(this);
      report_server = uvm_report_server::get_server();
      powered_sequence = caliptra_soc_ifc_powered_bench_sequence::type_id::create("top_level_sequence");
      top_level_sequence = powered_sequence;
      observer.mailbox_response_axi_user = 32'hffff_ffff;
      top_sequence_done = 0;
      poweron_wait_done = 0;
      fork
        begin
          fork
            begin
              wait (powered_sequence.poweron_done);
            end
            begin
              #1000000ns;
              if (!powered_sequence.poweron_done)
                `uvm_fatal("SOC_IFC_ENV_SEQUENCE_TIMEOUT", "Generated SoC-IFC bench sequence did not complete")
          end
          join_any
          poweron_wait_done = 1;
        end
        begin
          powered_sequence.start(null);
          top_sequence_done = 1;
        end
      join_none
      wait (poweron_wait_done);

      sequence_done = 0;
      aaxi_sequence = caliptra_soc_ifc_aaxi_rw_sequence::type_id::create("aaxi_sequence");
`ifdef CALIPTRA_BFM_OPEN_MBOX_TARGET
      aaxi_sequence.mbox_sram_agent_config = top_level_sequence.mbox_sram_agent_config;
`endif
      fork
        begin
          aaxi_sequence.start(top_level_sequence.uvm_test_top_environment_aaxi_tb_env0_master_0_sqr);
          sequence_done = 1;
        end
        begin
`ifdef CALIPTRA_BFM_OPEN_MBOX_TARGET
          if ($test$plusargs("CALIPTRA_GENERATED_AHB_MBOX_PAYLOAD"))
            wait(sequence_done && observer.write_count == 1 && observer.read_count == 1);
          else
            wait(sequence_done && observer.write_count == 8 && observer.read_count == 2 &&
                 observer.data_in_write_count == MBOX_PROBE_WORDS);
`else
          wait(sequence_done && observer.write_count == 1 && observer.read_count == 1);
`endif
        end
        begin
          #100000ns;
          `uvm_fatal("SOC_IFC_ENV_AAXI_TIMEOUT", "Generated environment AXI probe timed out")
        end
      join_any

`ifdef CALIPTRA_BFM_OPEN_MBOX_TARGET
      if ($test$plusargs("CALIPTRA_GENERATED_AHB_MBOX_PAYLOAD")) begin
        if (observer.write_count != 1 || observer.read_count != 1)
          `uvm_fatal("SOC_IFC_ENV_AAXI_OBSERVE", "Unexpected AAXI traffic in generated AHB mailbox mode")
      end else if (observer.write_count != 8 || observer.read_count != 2 ||
                   observer.data_in_write_count != MBOX_PROBE_WORDS)
`else
      if (observer.write_count != 1 || observer.read_count != 1)
`endif
        `uvm_fatal("SOC_IFC_ENV_AAXI_OBSERVE", "Generated environment monitor did not publish both transactions")

      if ($test$plusargs("CALIPTRA_GENERATED_AXI_USER_INIT")) begin
        observer.axi_user_init_expected_user =
            top_level_sequence.reg_model.soc_ifc_reg_rm.CPTRA_MBOX_VALID_AXI_USER[0].AXI_USER.get_reset("HARD");
        for (i = 0; i < 5; i++) begin
          observer.axi_user_init_expected_address[i] =
              top_level_sequence.reg_model.soc_ifc_reg_rm.CPTRA_MBOX_VALID_AXI_USER[i].get_address(
                  top_level_sequence.reg_model.soc_ifc_AXI_map);
          observer.axi_user_init_expected_address[i + 5] =
              top_level_sequence.reg_model.soc_ifc_reg_rm.CPTRA_MBOX_AXI_USER_LOCK[i].get_address(
                  top_level_sequence.reg_model.soc_ifc_AXI_map);
        end
        observer.axi_user_init_expected_address[10] =
            top_level_sequence.reg_model.soc_ifc_reg_rm.CPTRA_TRNG_VALID_AXI_USER.get_address(
                top_level_sequence.reg_model.soc_ifc_AXI_map);
        observer.axi_user_init_expected_address[11] =
            top_level_sequence.reg_model.soc_ifc_reg_rm.CPTRA_TRNG_AXI_USER_LOCK.get_address(
                top_level_sequence.reg_model.soc_ifc_AXI_map);
        observer.axi_user_init_active = 1;
        axi_user_init_sequence = soc_ifc_env_pkg::soc_ifc_env_axi_user_init_sequence_t::type_id::create("axi_user_init_sequence");
        axi_user_init_sequence.soc_ifc_status_agent_rsp_seq =
            top_level_sequence.soc_ifc_status_agent_responder_seq;
        for (i = 0; i < 5; i++)
          axi_user_init_sequence.mbox_valid_users[i] = 32'hc0de_0000 | i;
        axi_user_init_sequence.trng_valid_user = 32'hbeef_0001;
        observer.mailbox_response_axi_user = axi_user_init_sequence.mbox_valid_users[0];
        sequence_done = 0;
        fork
          begin
            axi_user_init_sequence.start(top_level_sequence.top_configuration.vsqr);
            sequence_done = 1;
          end
          begin
            wait(sequence_done && observer.axi_user_init_write_count == 12);
          end
          begin
            #100000ns;
            `uvm_fatal("SOC_IFC_ENV_AXI_USER_INIT_TIMEOUT", "Stock generated AXI USER initialization sequence timed out")
          end
        join_any
        observer.axi_user_init_active = 0;
        if (observer.axi_user_init_write_count != 12)
          `uvm_fatal("SOC_IFC_ENV_AXI_USER_INIT_OBSERVE", "Did not observe all 12 stock generated AXI USER initialization writes")
        $display("PASS: stock generated AXI USER RAL sequence completed 12 pin-checked writes");
      end

      if ($test$plusargs("CALIPTRA_GENERATED_AXI_USER_REJECT")) begin
        if (!$test$plusargs("CALIPTRA_GENERATED_AXI_USER_INIT") ||
            !$test$plusargs("CALIPTRA_GENERATED_AHB_MBOX_PAYLOAD"))
          `uvm_fatal("SOC_IFC_ENV_AXI_USER_REJECT_CONFIG", "USER rejection probe requires stock AXI USER initialization and generated AHB mailbox payload")
        observer.mailbox_user_rejection_active = 1;
        observer.mailbox_user_rejection_count = 0;
        sequence_done = 0;
        aaxi_sequence = caliptra_soc_ifc_aaxi_rw_sequence::type_id::create("aaxi_invalid_user_probe");
        aaxi_sequence.mailbox_user_rejection_probe = 1;
        aaxi_sequence.mbox_sram_agent_config = top_level_sequence.mbox_sram_agent_config;
        fork
          begin
            aaxi_sequence.start(top_level_sequence.uvm_test_top_environment_aaxi_tb_env0_master_0_sqr);
            sequence_done = 1;
          end
          begin
            wait (sequence_done && observer.mailbox_user_rejection_count == 1);
          end
          begin
            #100000ns;
            if (!sequence_done)
              `uvm_fatal("SOC_IFC_ENV_AXI_USER_REJECT_TIMEOUT", "Invalid mailbox USER AXI read timed out")
          end
        join_any
        observer.mailbox_user_rejection_active = 0;
        if (observer.mailbox_user_rejection_count != 1)
          `uvm_fatal("SOC_IFC_ENV_AXI_USER_REJECT_OBSERVE", "Did not observe the rejected mailbox USER AXI read")
        $display("PASS: invalid mailbox AXI USER read returned SLVERR");
      end

      if ($test$plusargs("CALIPTRA_GENERATED_AHB_MBOX_PAYLOAD")) begin
        sequence_done = 0;
        fork
          begin
            top_level_sequence.reg_model.mbox_csr_rm.mbox_lock.read(
                ahb_ral_status, ahb_ral_value, UVM_FRONTDOOR,
                top_level_sequence.reg_model.soc_ifc_AHB_map);
            if (ahb_ral_status != UVM_IS_OK || ahb_ral_value != 0)
              `uvm_fatal("SOC_IFC_ENV_AHB_MBOX_LOCK", $sformatf("Mailbox claim failed: status=%0d value=0x%0h", ahb_ral_status, ahb_ral_value))
            if ($test$plusargs("CALIPTRA_GENERATED_AXI_USER_REJECT"))
              $display("PASS: denied AXI USER read left mailbox available for the following AHB claim");
            top_level_sequence.reg_model.mbox_csr_rm.mbox_cmd.write(
                ahb_ral_status, 32'hcafe_0001, UVM_FRONTDOOR,
                top_level_sequence.reg_model.soc_ifc_AHB_map);
            if (ahb_ral_status != UVM_IS_OK)
              `uvm_fatal("SOC_IFC_ENV_AHB_MBOX_CMD", "Generated AHB MBOX_CMD write failed")
            top_level_sequence.reg_model.mbox_csr_rm.mbox_dlen.write(
                ahb_ral_status, 32'd16, UVM_FRONTDOOR,
                top_level_sequence.reg_model.soc_ifc_AHB_map);
            if (ahb_ral_status != UVM_IS_OK)
              `uvm_fatal("SOC_IFC_ENV_AHB_MBOX_DLEN", "Generated AHB MBOX_DLEN write failed")
            top_level_sequence.reg_model.mbox_csr_rm.mbox_dlen.read(
                ahb_ral_status, ahb_ral_value, UVM_FRONTDOOR,
                top_level_sequence.reg_model.soc_ifc_AHB_map);
            if (ahb_ral_status != UVM_IS_OK || ahb_ral_value != 32'd16)
              `uvm_fatal("SOC_IFC_ENV_AHB_MBOX_DLEN", $sformatf("MBOX_DLEN readback failed: status=%0d value=0x%0h", ahb_ral_status, ahb_ral_value))
            for (i = 0; i < MBOX_PROBE_WORDS; i++) begin
              if (i == 0)
                top_level_sequence.mbox_sram_agent_config.inject_ecc_error = generated_env_probe_ecc_mode;
              top_level_sequence.reg_model.mbox_csr_rm.mbox_datain.write(
                  ahb_ral_status, generated_env_mbox_word(i), UVM_FRONTDOOR,
                  top_level_sequence.reg_model.soc_ifc_AHB_map);
              if (ahb_ral_status != UVM_IS_OK)
                `uvm_fatal("SOC_IFC_ENV_AHB_MBOX_DATAIN", $sformatf("Generated AHB MBOX_DATAIN write %0d failed", i))
            end
            if (generated_env_probe_ecc_mode != 2'b00 &&
                top_level_sequence.mbox_sram_agent_config.inject_ecc_error != 2'b00)
              `uvm_fatal("SOC_IFC_ENV_MBOX_ECC", "Generated BFM did not clear one-shot ECC injection")
            top_level_sequence.reg_model.mbox_csr_rm.mbox_execute.write(
                ahb_ral_status, 32'h1, UVM_FRONTDOOR,
                top_level_sequence.reg_model.soc_ifc_AHB_map);
            if (ahb_ral_status != UVM_IS_OK)
              `uvm_fatal("SOC_IFC_ENV_AHB_MBOX_EXECUTE", "Generated AHB MBOX_EXECUTE write failed")
            sequence_done = 1;
          end
          begin
            #100000ns;
            if (!sequence_done)
              `uvm_fatal("SOC_IFC_ENV_AHB_MBOX_TIMEOUT", "Generated AHB mailbox payload timed out")
          end
        join_any
        sequence_done = 0;
        fork
          begin
            wait (generated_env_mailbox_data_available === 1'b1);
            sequence_done = 1;
          end
          begin
            #100000ns;
            if (!sequence_done)
              `uvm_fatal("SOC_IFC_ENV_MBOX_AVAILABLE_TIMEOUT", "Mailbox data did not become available to the SoC AXI host")
          end
        join_any

        observer.mailbox_response_active = 1;
        observer.mailbox_response_read_count = 0;
        observer.mailbox_response_write_count = 0;
        sequence_done = 0;
        aaxi_sequence = caliptra_soc_ifc_aaxi_rw_sequence::type_id::create("aaxi_mbox_response_sequence");
        aaxi_sequence.mailbox_response_only = 1;
        aaxi_sequence.mailbox_response_axi_user = observer.mailbox_response_axi_user;
        aaxi_sequence.mbox_sram_agent_config = top_level_sequence.mbox_sram_agent_config;
        fork
          begin
            aaxi_sequence.start(top_level_sequence.uvm_test_top_environment_aaxi_tb_env0_master_0_sqr);
            sequence_done = 1;
          end
          begin
            wait (sequence_done && observer.mailbox_response_read_count == 2 + MBOX_PROBE_WORDS &&
                  observer.mailbox_response_write_count == 1);
          end
          begin
            #100000ns;
            if (!sequence_done)
              `uvm_fatal("SOC_IFC_ENV_MBOX_RESPONSE_TIMEOUT", "SoC AXI mailbox response service timed out")
          end
        join_any
        observer.mailbox_response_active = 0;
        if (observer.mailbox_response_read_count != 2 + MBOX_PROBE_WORDS ||
            observer.mailbox_response_write_count != 1)
          `uvm_fatal("SOC_IFC_ENV_MBOX_RESPONSE_OBSERVE", "Did not observe the command, length, four data, and status AXI operations")

        sequence_done = 0;
        fork
          begin
            top_level_sequence.reg_model.mbox_csr_rm.mbox_status.status.read(
                ahb_ral_status, ahb_ral_value, UVM_FRONTDOOR,
                top_level_sequence.reg_model.soc_ifc_AHB_map);
            if (ahb_ral_status != UVM_IS_OK || ahb_ral_value != 32'd2)
              `uvm_fatal("SOC_IFC_ENV_MBOX_STATUS", $sformatf("Expected CMD_COMPLETE (2), got status=%0d value=0x%0h", ahb_ral_status, ahb_ral_value))
            top_level_sequence.reg_model.mbox_csr_rm.mbox_execute.execute.write(
                ahb_ral_status, 32'd0, UVM_FRONTDOOR,
                top_level_sequence.reg_model.soc_ifc_AHB_map);
            if (ahb_ral_status != UVM_IS_OK)
              `uvm_fatal("SOC_IFC_ENV_MBOX_EXECUTE_CLEAR", "Firmware-side MBOX_EXECUTE clear failed")
            sequence_done = 1;
          end
          begin
            #100000ns;
            if (!sequence_done)
              `uvm_fatal("SOC_IFC_ENV_MBOX_STATUS_TIMEOUT", "Firmware-side status read/execute clear timed out")
          end
        join_any
        $display("PASS: generated AHB/AAXI BFMs completed a four-word mailbox request/status handshake");
      end

      if ($test$plusargs("CALIPTRA_GENERATED_AHB_RAL_DLEN_WRITE_READBACK")) begin
        sequence_done = 0;
        fork
          begin
            top_level_sequence.reg_model.mbox_csr_rm.mbox_lock.read(
                ahb_ral_status, ahb_ral_value, UVM_FRONTDOOR,
                top_level_sequence.reg_model.soc_ifc_AHB_map);
            if (ahb_ral_status != UVM_IS_OK || ahb_ral_value != 0)
              `uvm_fatal("SOC_IFC_ENV_AHB_RAL_CLAIM", $sformatf("Mailbox claim failed or mailbox was already locked: status=%0d value=0x%0h", ahb_ral_status, ahb_ral_value))
            top_level_sequence.reg_model.mbox_csr_rm.mbox_dlen.write(
                ahb_ral_status, 32'h10, UVM_FRONTDOOR,
                top_level_sequence.reg_model.soc_ifc_AHB_map);
            if (ahb_ral_status != UVM_IS_OK)
              `uvm_fatal("SOC_IFC_ENV_AHB_RAL_DLEN_WRITE", "Generated AHB MBOX_DLEN RAL write failed")
            top_level_sequence.reg_model.mbox_csr_rm.mbox_dlen.read(
                ahb_ral_status, ahb_ral_value, UVM_FRONTDOOR,
                top_level_sequence.reg_model.soc_ifc_AHB_map);
            sequence_done = 1;
          end
          begin
            #100000ns;
            if (!sequence_done)
              `uvm_fatal("SOC_IFC_ENV_AHB_RAL_DLEN_TIMEOUT", "Generated AHB MBOX_DLEN write/readback timed out")
          end
        join_any
        if (ahb_ral_status != UVM_IS_OK)
          `uvm_fatal("SOC_IFC_ENV_AHB_RAL_DLEN_STATUS", "Generated AHB MBOX_DLEN RAL readback failed")
        if (ahb_ral_value != 32'h10)
          `uvm_fatal("SOC_IFC_ENV_AHB_RAL_DLEN_VALUE", $sformatf("Expected MBOX_DLEN 0x10, got 0x%0h", ahb_ral_value))
        $display("PASS: generated AHB RAL claimed mailbox at lock value 0, then wrote/read MBOX_DLEN as 0x10");
      end else if ($test$plusargs("CALIPTRA_GENERATED_AHB_RAL_READ")) begin
        sequence_done = 0;
        fork
          begin
            top_level_sequence.reg_model.mbox_csr_rm.mbox_lock.read(
                ahb_ral_status, ahb_ral_value, UVM_FRONTDOOR,
                top_level_sequence.reg_model.soc_ifc_AHB_map);
            sequence_done = 1;
          end
          begin
            #100000ns;
            if (!sequence_done)
              `uvm_fatal("SOC_IFC_ENV_AHB_RAL_TIMEOUT", "Generated AHB RAL read timed out")
          end
        join_any
        if (ahb_ral_status != UVM_IS_OK)
          `uvm_fatal("SOC_IFC_ENV_AHB_RAL_STATUS", "Generated mailbox-lock AHB RAL read failed")
        if (ahb_ral_value != 0)
          `uvm_fatal("SOC_IFC_ENV_AHB_RAL_VALUE", $sformatf("Expected unlocked mailbox lock 0, got 0x%0h", ahb_ral_value))
        $display("PASS: generated AHB RAL frontdoor read unlocked mailbox lock as 0");
      end

      top_level_sequence.soc_ifc_ctrl_agent_config.wait_for_num_clocks(4);
      powered_sequence.shutdown_requested = 1;
      wait (top_sequence_done);
      if (report_server.get_severity_count(UVM_ERROR) != 0)
        `uvm_fatal("SOC_IFC_ENV_SCOREBOARD", "Generated environment reported UVM errors during the AAXI probe")
`ifdef CALIPTRA_BFM_OPEN_MBOX_TARGET
      generated_env_probe_done = 1;
      wait (generated_env_mbox_memory_check_done === 1'b1);
      $display("PASS: generated SoC-IFC UVM environment transferred four mailbox words through the open SRAM target");
`endif
      $display("PASS: generated SoC-IFC bench sequence and AHB/AAXI BFMs completed without UVM errors");
      phase.drop_objection(this);
    endtask
  endclass
endpackage
