// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
`include "uvm_macros.svh"

module tb_ahb_lite_caliptra_uvm_agent;
  import uvm_pkg::*;
  import ahb_lite_caliptra_uvm_pkg::*;
  import qvip_ahb_lite_slave_pkg::*;
  import mvc_pkg::*;
  import mgc_ahb_v2_0_pkg::*;

  reg HCLK = 0;
  reg HRESETn = 0;
  wire HSEL, HWRITE, HRESP, HREADY, HREADYOUT, inject_error;
  wire [31:0] HADDR;
  wire [63:0] HWDATA, HRDATA;
  wire [2:0] HSIZE;
  wire [1:0] HTRANS;
  wire [7:0] wait_cycles;

  ahb_lite_caliptra_master_cmd_if cmd_if(HCLK);
  ahb_lite_caliptra_record_if record_if(HCLK);
  assign cmd_if.HRESETn = HRESETn;
  assign wait_cycles = cmd_if.target_wait_cycles;
  assign inject_error = cmd_if.inject_target_error;
  assign HREADY = HREADYOUT;
  always #5 HCLK = ~HCLK;

  ahb_lite_caliptra_uvm_master_proxy master_proxy (
    .cmd_if(cmd_if), .HCLK(HCLK), .HRESETn(HRESETn), .HREADY(HREADY),
    .HRESP(HRESP), .HRDATA(HRDATA), .HSEL(HSEL), .HADDR(HADDR),
    .HWDATA(HWDATA), .HWRITE(HWRITE), .HSIZE(HSIZE), .HTRANS(HTRANS)
  );

  ahb_lite_caliptra_memory_subordinate #(
    .ADDR_WIDTH(32), .DATA_WIDTH(64), .MEMORY_BYTES(65536)
  ) memory (
    .HCLK(HCLK), .HRESETn(HRESETn), .HADDR(HADDR), .HWDATA(HWDATA),
    .HSEL(HSEL), .HWRITE(HWRITE), .HTRANS(HTRANS), .HSIZE(HSIZE),
    .HREADY(HREADY), .wait_cycles(wait_cycles), .inject_error(inject_error),
    .HREADYOUT(HREADYOUT), .HRESP(HRESP), .HRDATA(HRDATA)
  );

  ahb_lite_caliptra_pin_monitor_adapter monitor_adapter (
    .HCLK(HCLK), .HRESETn(HRESETn), .HADDR(HADDR), .HWDATA(HWDATA),
    .HSEL(HSEL), .HWRITE(HWRITE), .HTRANS(HTRANS), .HSIZE(HSIZE),
    .HREADY(HREADY), .HRESP(HRESP), .HRDATA(HRDATA), .record_if(record_if)
  );

  class ahb_lite_caliptra_subscriber extends uvm_subscriber #(ahb_lite_caliptra_transaction);
    int write_count;
    int read_count;
    int error_count;
    int burst_write_beats;
    int burst_read_beats;
    int error_burst_beats;
    int partial_burst_write_beats;
    event received;
    `uvm_component_utils(ahb_lite_caliptra_subscriber)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void write(ahb_lite_caliptra_transaction item);
      if (item.protocol_error)
        `uvm_fatal("AHB_MON_PROTOCOL", "Monitor marked a legal transfer as malformed")
      if (item.error) begin
        error_count++;
        if (item.address == 32'h10000) begin
          if (!(item.trans inside {2'b10, 2'b11}))
            `uvm_fatal("AHB_MON_ERROR", $sformatf("Unexpected burst ERROR record: %s", item.convert2string()))
          error_burst_beats++;
        end else if (item.write || !(item.address inside {32'h20, 32'h40}) ||
                     item.trans != 2'b10) begin
          `uvm_fatal("AHB_MON_ERROR", $sformatf("Unexpected ERROR record: %s", item.convert2string()))
        end
      end else if (item.address == 32'h40) begin
        if (item.size != 2 || item.data[31:0] != 32'h89ab_cdef)
          `uvm_fatal("AHB_MON_RAL", $sformatf("Bad 32-bit RAL record: %s", item.convert2string()))
        if (item.write) write_count++;
        else read_count++;
      end else if (item.address inside {32'h80, 32'h88, 32'h90, 32'h98}) begin
        if (item.size != 3 ||
            ((item.address == 32'h80) && item.trans != 2'b10) ||
            ((item.address != 32'h80) && item.trans != 2'b11))
          `uvm_fatal("AHB_MON_BURST", $sformatf("Bad burst address record: %s", item.convert2string()))
        case (item.address)
          32'h80: if (item.data != 64'h0102_0304_0506_0708) `uvm_fatal("AHB_MON_BURST_DATA", "Bad beat 0")
          32'h88: if (item.data != 64'h1112_1314_1516_1718) `uvm_fatal("AHB_MON_BURST_DATA", "Bad beat 1")
          32'h90: if (item.data != 64'h2122_2324_2526_2728) `uvm_fatal("AHB_MON_BURST_DATA", "Bad beat 2")
          32'h98: if (item.data != 64'h3132_3334_3536_3738) `uvm_fatal("AHB_MON_BURST_DATA", "Bad beat 3")
        endcase
        if (item.write) begin
          write_count++;
          burst_write_beats++;
        end else begin
          read_count++;
          burst_read_beats++;
        end
      end else if (item.address == 32'hfff8) begin
        if (!item.write || item.size != 3 || item.trans != 2'b10 ||
            item.data != 64'h4142_4344_4546_4748)
          `uvm_fatal("AHB_MON_PARTIAL_BURST", $sformatf("Bad successful beat before burst ERROR: %s", item.convert2string()))
        write_count++;
        partial_burst_write_beats++;
      end else if (item.write) begin
        write_count++;
        if (item.address != 32'h20 || item.size != 3 ||
            item.data != 64'h1122_3344_5566_7788)
          `uvm_fatal("AHB_MON_WRITE", $sformatf("Bad write record: %s", item.convert2string()))
      end else begin
        read_count++;
        if (item.address != 32'h20 || item.size != 3 ||
            item.data != 64'h1122_3344_5566_7788)
          `uvm_fatal("AHB_MON_READ", $sformatf("Bad read record: %s", item.convert2string()))
      end
      -> received;
    endfunction
  endclass

  class ahb_lite_caliptra_mvc_subscriber extends uvm_subscriber #(mvc_sequence_item_base);
    int unsigned item_count;
    int unsigned write_count;
    int unsigned read_count;
    int unsigned error_count;
    int unsigned burst_write_count;
    int unsigned burst_read_count;
    int unsigned error_burst_count;
    int unsigned partial_burst_count;
    ahb_lite_caliptra_mvc_transfer last_item;

    `uvm_component_utils(ahb_lite_caliptra_mvc_subscriber)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void write(mvc_sequence_item_base base_item);
      if (!$cast(last_item, base_item))
        `uvm_fatal("AHB_MVC_CAST", $sformatf("Keyed AHB port published %s, expected ahb_master_burst_transfer #(1,1,1,32,64,64)", base_item.get_type_name()))
      if (last_item.data.size() < 1 || last_item.data.size() > AHB_MVC_MAX_BURST_BEATS ||
          last_item.resp.size() != last_item.data.size())
        `uvm_fatal("AHB_MVC_SHAPE", $sformatf("Bad keyed AHB transfer: %s", last_item.convert2string()))
      if (!(last_item.address inside {32'h80, 32'h10000, 32'hfff8}) &&
          last_item.data.size() != 1)
        `uvm_fatal("AHB_MVC_SCALAR_SHAPE", "A scalar AHB transfer was grouped with another address")
      item_count++;
      if (last_item.address == 32'h10000) begin
        error_burst_count++;
        error_count++;
        if (last_item.RnW != AHB_READ || last_item.data.size() != 1 ||
            last_item.resp.size() != 1 || last_item.resp[0] != AHB_ERROR)
          `uvm_fatal("AHB_MVC_BURST_ERROR", "Bad aborted MVC burst response")
      end else if (last_item.address == 32'hfff8) begin
        partial_burst_count++;
        if (last_item.RnW != AHB_WRITE || last_item.size != 3 ||
            last_item.data.size() != 2 || last_item.resp.size() != 2 ||
            last_item.data[0] != 64'h4142_4344_4546_4748 ||
            last_item.data[1] != 64'h5152_5354_5556_5758 ||
            last_item.resp[0] != AHB_OKAY || last_item.resp[1] != AHB_ERROR)
          `uvm_fatal("AHB_MVC_PARTIAL_BURST", "Bad partial MVC burst data/response queue")
        write_count++;
        error_count++;
        error_burst_count++;
      end else if (last_item.address == 32'h80) begin
        if (last_item.size != 3 || last_item.data.size() != 4 ||
            last_item.resp[0] != AHB_OKAY || last_item.resp[1] != AHB_OKAY ||
            last_item.resp[2] != AHB_OKAY || last_item.resp[3] != AHB_OKAY)
          `uvm_fatal("AHB_MVC_BURST_SHAPE", "Bad four-beat MVC burst shape or response")
        if (last_item.RnW == AHB_WRITE) begin
          burst_write_count++;
          if (last_item.data[0] != 64'h0102_0304_0506_0708 ||
              last_item.data[1] != 64'h1112_1314_1516_1718 ||
              last_item.data[2] != 64'h2122_2324_2526_2728 ||
              last_item.data[3] != 64'h3132_3334_3536_3738)
            `uvm_fatal("AHB_MVC_BURST_WRITE", "Bad MVC write burst payload")
        end else begin
          burst_read_count++;
          if (last_item.data[0] != 64'h0102_0304_0506_0708 ||
              last_item.data[1] != 64'h1112_1314_1516_1718 ||
              last_item.data[2] != 64'h2122_2324_2526_2728 ||
              last_item.data[3] != 64'h3132_3334_3536_3738)
            `uvm_fatal("AHB_MVC_BURST_READ", "Bad MVC read burst payload")
        end
      end else if (last_item.address == 32'h40) begin
        if (last_item.size != 2)
          `uvm_fatal("AHB_MVC_RAL_SIZE", "32-bit register access used the wrong HSIZE")
        if (last_item.RnW == AHB_WRITE) begin
          write_count++;
          if (last_item.data[0] != 64'h0000_0000_89ab_cdef ||
              last_item.resp[0] != AHB_OKAY)
            `uvm_fatal("AHB_MVC_RAL_WRITE", "Bad 32-bit RAL write transaction")
        end else begin
          read_count++;
          if (last_item.resp[0] == AHB_ERROR) error_count++;
          else if (last_item.data[0] != 64'h0000_0000_89ab_cdef ||
                   last_item.resp[0] != AHB_OKAY)
            `uvm_fatal("AHB_MVC_RAL_READ", "Bad 32-bit RAL read transaction")
        end
      end else begin
        if (last_item.address != 32'h20 || last_item.size != 3)
          `uvm_fatal("AHB_MVC_SHAPE", "Unexpected AHB address or transfer size")
        if (last_item.RnW == AHB_WRITE) begin
          write_count++;
          if (last_item.data[0] != 64'h1122_3344_5566_7788 ||
              last_item.resp[0] != AHB_OKAY)
            `uvm_fatal("AHB_MVC_WRITE", $sformatf("Bad keyed AHB write: %s", last_item.convert2string()))
        end else begin
          read_count++;
          if (last_item.resp[0] == AHB_ERROR) error_count++;
        end
      end
    endfunction
  endclass

  class ahb_lite_caliptra_ral_smoke_reg extends uvm_reg;
    uvm_reg_field value;
    `uvm_object_utils(ahb_lite_caliptra_ral_smoke_reg)

    function new(string name = "ahb_lite_caliptra_ral_smoke_reg");
      super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
      value = uvm_reg_field::type_id::create("value");
      value.configure(this, 32, 0, "RW", 0, 0, 1, 0, 0);
    endfunction
  endclass

  class ahb_lite_caliptra_ral_burst_reg extends uvm_reg;
    uvm_reg_field value;
    `uvm_object_utils(ahb_lite_caliptra_ral_burst_reg)

    function new(string name = "ahb_lite_caliptra_ral_burst_reg");
      super.new(name, 64, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
      value = uvm_reg_field::type_id::create("value");
      value.configure(this, 64, 0, "RW", 0, 0, 1, 0, 0);
    endfunction
  endclass

  class ahb_lite_caliptra_ral_smoke_block extends uvm_reg_block;
    ahb_lite_caliptra_ral_smoke_reg csr;
    ahb_lite_caliptra_ral_burst_reg burst_csr[4];
    ahb_lite_caliptra_ral_burst_reg partial_ok_csr;
    ahb_lite_caliptra_ral_burst_reg partial_error_csr;
    `uvm_object_utils(ahb_lite_caliptra_ral_smoke_block)

    function new(string name = "ahb_lite_caliptra_ral_smoke_block");
      super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
      default_map = create_map("default_map", 0, 8, UVM_LITTLE_ENDIAN, 1);
      csr = ahb_lite_caliptra_ral_smoke_reg::type_id::create("csr");
      csr.configure(this);
      csr.build();
      default_map.add_reg(csr, 32'h40, "RW");
      foreach (burst_csr[i]) begin
        burst_csr[i] = ahb_lite_caliptra_ral_burst_reg::type_id::create(
          $sformatf("burst_csr_%0d", i));
        burst_csr[i].configure(this);
        burst_csr[i].build();
        default_map.add_reg(burst_csr[i], 32'h80 + (i * 8), "RW");
      end
      partial_ok_csr = ahb_lite_caliptra_ral_burst_reg::type_id::create("partial_ok_csr");
      partial_ok_csr.configure(this);
      partial_ok_csr.build();
      default_map.add_reg(partial_ok_csr, 32'hfff8, "RW");
      partial_error_csr = ahb_lite_caliptra_ral_burst_reg::type_id::create("partial_error_csr");
      partial_error_csr.configure(this);
      partial_error_csr.build();
      default_map.add_reg(partial_error_csr, 32'h10000, "RW");
      lock_model();
    endfunction
  endclass

  class ahb_lite_caliptra_env extends uvm_env;
    ahb_lite_caliptra_qvip_compat_agent agent;
    ahb_reg_predictor #(ahb_lite_caliptra_mvc_transfer) burst_predictor;
    ahb_lite_caliptra_subscriber subscriber;
    ahb_lite_caliptra_mvc_subscriber predictor_subscriber;
    ahb_lite_caliptra_mvc_subscriber scoreboard_subscriber;
    ahb_lite_caliptra_mvc_subscriber coverage_subscriber;
    `uvm_component_utils(ahb_lite_caliptra_env)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = ahb_lite_caliptra_qvip_compat_agent::type_id::create("agent", this);
      burst_predictor = ahb_reg_predictor #(ahb_lite_caliptra_mvc_transfer)::type_id::create(
        "burst_predictor", this);
      subscriber = ahb_lite_caliptra_subscriber::type_id::create("subscriber", this);
      predictor_subscriber = ahb_lite_caliptra_mvc_subscriber::type_id::create("predictor_subscriber", this);
      scoreboard_subscriber = ahb_lite_caliptra_mvc_subscriber::type_id::create("scoreboard_subscriber", this);
      coverage_subscriber = ahb_lite_caliptra_mvc_subscriber::type_id::create("coverage_subscriber", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.agent.ap.connect(subscriber.analysis_export);
      agent.ap["burst_transfer"].connect(predictor_subscriber.analysis_export);
      agent.ap["burst_transfer"].connect(burst_predictor.bus_item_export);
      agent.ap["burst_transfer_sb"].connect(scoreboard_subscriber.analysis_export);
      agent.ap["burst_transfer_cov"].connect(coverage_subscriber.analysis_export);
    endfunction
  endclass

  class ahb_lite_caliptra_reset_abort_sequence extends uvm_sequence #(mvc_sequence_item_base);
    `uvm_object_utils(ahb_lite_caliptra_reset_abort_sequence)

    function new(string name = "ahb_lite_caliptra_reset_abort_sequence");
      super.new(name);
    endfunction

    task body();
      ahb_lite_caliptra_mvc_transfer req;
      req = new("reset_abort_burst");
      start_item(req);
      req.RnW = AHB_WRITE;
      req.address = 32'h20;
      req.size = AHB_MVC_WORD_SIZE;
      repeat (4) req.data.push_back(64'hdead_beef_cafe_0001);
      finish_item(req);
      if (req.resp.size() != 1 || req.resp[0] != AHB_ERROR ||
          req.data.size() != 4)
        `uvm_fatal("AHB_RESET_ABORT", "Reset-aborted burst did not return one error for the first uncompleted beat")
    endtask
  endclass

  class ahb_lite_caliptra_agent_test extends uvm_test;
    ahb_lite_caliptra_env env;
    ahb_lite_caliptra_ral_smoke_block ral_model;
    ahb_lite_caliptra_reg_adapter ral_adapter;
    `uvm_component_utils(ahb_lite_caliptra_agent_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = ahb_lite_caliptra_env::type_id::create("env", this);
      ral_model = ahb_lite_caliptra_ral_smoke_block::type_id::create("ral_model");
      ral_model.build();
      ral_adapter = ahb_lite_caliptra_reg_adapter::type_id::create("ral_adapter");
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      ral_model.default_map.set_sequencer(env.agent.m_sequencer, ral_adapter);
      env.burst_predictor.map = ral_model.default_map;
      env.burst_predictor.adapter = ral_adapter;
    endfunction

    task run_phase(uvm_phase phase);
      ahb_lite_caliptra_smoke_sequence smoke_seq;
      ahb_lite_caliptra_error_sequence error_seq;
      ahb_lite_caliptra_partial_burst_error_sequence partial_burst_seq;
      uvm_status_e ral_status;
      uvm_reg_data_t ral_read_value;
      bit [63:0] expected_burst[4];
      ahb_lite_caliptra_mvc_transfer copy_source, copy_target;
      int burst_index;
      phase.raise_objection(this);

      copy_source = new("copy_source");
      copy_source.RnW = AHB_WRITE;
      copy_source.address = 32'h24;
      copy_source.size = AHB_MVC_WORD_SIZE;
      copy_source.data.push_back(64'hcafef00d & AHB_MVC_DATA_MASK);
      copy_source.resp.push_back(AHB_OKAY);
      copy_target = new("copy_target");
      copy_target.RnW = AHB_READ;
      copy_target.address = 0;
      copy_target.size = 0;
      copy_target.data.push_back(0);
      copy_target.resp.push_back(AHB_ERROR);
      copy_target.copy(copy_source);
      if (copy_target.RnW !== copy_source.RnW ||
          copy_target.address !== copy_source.address ||
          copy_target.size !== copy_source.size ||
          copy_target.data.size() != 1 ||
          copy_target.data[0] !== copy_source.data[0] ||
          copy_target.resp.size() != 1 ||
          copy_target.resp[0] !== copy_source.resp[0])
        `uvm_fatal("AHB_MVC_COPY", "MVC transfer copy did not preserve typed fields")
      if (!copy_target.compare(copy_source))
        `uvm_fatal("AHB_MVC_COMPARE", "Matching MVC transfers compare unequal")
      copy_target.data[0] ^= 1;
      if (copy_target.compare(copy_source))
        `uvm_fatal("AHB_MVC_COMPARE", "MVC transfer compare missed changed data")
      $display("PASS: AHB MVC transfer copy/compare");

      if ($test$plusargs("AHB_RESET_ABORT_ONLY")) begin
        ahb_lite_caliptra_reset_abort_sequence reset_abort_seq;
        reset_abort_seq = ahb_lite_caliptra_reset_abort_sequence::type_id::create("reset_abort_seq");
        env.agent.mvc_driver.cmd_vif.target_wait_cycles = 20;
        reset_abort_seq.start(env.agent.m_sequencer);
        if (!env.agent.mvc_driver.cmd_vif.response_aborted)
          `uvm_fatal("AHB_RESET_STATUS", "Command bridge did not identify the reset-aborted transfer")
        if (env.predictor_subscriber.item_count != 0 ||
            env.scoreboard_subscriber.item_count != 0 ||
            env.coverage_subscriber.item_count != 0)
          `uvm_fatal("AHB_RESET_MONITOR", "Reset-aborted address was published as a completed transfer")
        env.agent.mvc_driver.cmd_vif.target_wait_cycles = 2;
        smoke_seq = ahb_lite_caliptra_smoke_sequence::type_id::create("post_reset_smoke_seq");
        smoke_seq.start(env.agent.m_sequencer);
        if (env.predictor_subscriber.item_count != 4 ||
            env.scoreboard_subscriber.item_count != 4 ||
            env.coverage_subscriber.item_count != 4)
          `uvm_fatal("AHB_RESET_RECOVERY", "AHB monitor did not recover for post-reset scalar and burst traffic")
        $display("PASS: AHB reset abort returned an error and recovered for follow-up traffic");
        phase.drop_objection(this);
      end

      if (!$test$plusargs("AHB_RESET_ABORT_ONLY")) begin
        env.agent.mvc_driver.cmd_vif.target_wait_cycles = 2;
        smoke_seq = ahb_lite_caliptra_smoke_sequence::type_id::create("smoke_seq");
        smoke_seq.start(env.agent.m_sequencer);
        env.agent.mvc_driver.cmd_vif.inject_target_error = 1;
        error_seq = ahb_lite_caliptra_error_sequence::type_id::create("error_seq");
        error_seq.start(env.agent.m_sequencer);
        env.agent.mvc_driver.cmd_vif.inject_target_error = 0;
        partial_burst_seq = ahb_lite_caliptra_partial_burst_error_sequence::type_id::create("partial_burst_seq");
        partial_burst_seq.start(env.agent.m_sequencer);
        ral_model.csr.write(ral_status, 32'h89ab_cdef, UVM_FRONTDOOR,
                            ral_model.default_map);
        if (ral_status != UVM_IS_OK)
          `uvm_fatal("AHB_RAL_WRITE", "AHB RAL frontdoor write failed")
        ral_model.csr.read(ral_status, ral_read_value, UVM_FRONTDOOR,
                           ral_model.default_map);
        if (ral_status != UVM_IS_OK || ral_read_value != 32'h89ab_cdef)
          `uvm_fatal("AHB_RAL_READ", $sformatf("AHB RAL frontdoor read failed status=%s value=%08h",
                                               ral_status.name(), ral_read_value))
        env.agent.mvc_driver.cmd_vif.inject_target_error = 1;
        ral_model.csr.read(ral_status, ral_read_value, UVM_FRONTDOOR,
                           ral_model.default_map);
        env.agent.mvc_driver.cmd_vif.inject_target_error = 0;
        if (ral_status != UVM_NOT_OK)
          `uvm_fatal("AHB_RAL_ERROR", "AHB RAL frontdoor did not report injected ERROR")
        fork
          begin
            wait (env.subscriber.write_count > 0 && env.subscriber.read_count > 0 &&
                  env.subscriber.error_count > 0 &&
                  env.predictor_subscriber.item_count >= 6 &&
                  env.scoreboard_subscriber.item_count >= 6 &&
                  env.coverage_subscriber.item_count >= 6 &&
                  env.predictor_subscriber.burst_write_count > 0 &&
                  env.predictor_subscriber.burst_read_count > 0 &&
                  env.predictor_subscriber.error_burst_count > 0 &&
                  env.predictor_subscriber.partial_burst_count > 0 &&
                  env.subscriber.burst_write_beats >= 4 &&
                  env.subscriber.burst_read_beats >= 4 &&
                  env.subscriber.error_burst_beats >= 2 &&
                  env.subscriber.partial_burst_write_beats == 1);
          end
          begin
            #2000;
            `uvm_fatal("AHB_TIMEOUT", "Timed out waiting for monitored AHB-Lite records")
        end
        join_any
        disable fork;
        expected_burst[0] = 64'h0102_0304_0506_0708;
        expected_burst[1] = 64'h1112_1314_1516_1718;
        expected_burst[2] = 64'h2122_2324_2526_2728;
        expected_burst[3] = 64'h3132_3334_3536_3738;
        foreach (ral_model.burst_csr[burst_index]) begin
          if (ral_model.burst_csr[burst_index].get_mirrored_value() !==
              (expected_burst[burst_index] & AHB_MVC_DATA_MASK))
            `uvm_fatal("AHB_RAL_BURST_PREDICT",
              $sformatf("Burst beat %0d mirror mismatch: got %016h expected %016h",
                burst_index,
                ral_model.burst_csr[burst_index].get_mirrored_value(),
                expected_burst[burst_index] & AHB_MVC_DATA_MASK))
        end
        if (ral_model.partial_ok_csr.get_mirrored_value() !== 64'h4142_4344_4546_4748 ||
            ral_model.partial_error_csr.get_mirrored_value() !== 0)
          `uvm_fatal("AHB_RAL_PARTIAL_PREDICT", "Partial ERROR burst predicted a failed beat or lost its successful beat")
        if (env.agent.agent.monitor.vif.wait_cycle_count < 4)
          `uvm_fatal("AHB_WAIT", "AHB-Lite UVM smoke did not exercise configured wait cycles")
        if (env.agent.agent.monitor.vif.address_count != 17 ||
            env.agent.agent.monitor.vif.transfer_count != 17 ||
            env.agent.agent.monitor.vif.read_address_count != 9 ||
            env.agent.agent.monitor.vif.write_address_count != 8 ||
            env.agent.agent.monitor.vif.size_4byte_count != 3 ||
            env.agent.agent.monitor.vif.size_8byte_count != 14 ||
            env.agent.agent.monitor.vif.pending_wait_cycle_count == 0 ||
            env.agent.agent.monitor.vif.error_transfer_count != 4)
          `uvm_fatal("AHB_COVERAGE",
            $sformatf("Pin-monitor counts addr=%0d xfer=%0d read=%0d write=%0d size4=%0d size8=%0d waits=%0d errors=%0d",
              env.agent.agent.monitor.vif.address_count,
              env.agent.agent.monitor.vif.transfer_count,
              env.agent.agent.monitor.vif.read_address_count,
              env.agent.agent.monitor.vif.write_address_count,
              env.agent.agent.monitor.vif.size_4byte_count,
              env.agent.agent.monitor.vif.size_8byte_count,
              env.agent.agent.monitor.vif.pending_wait_cycle_count,
              env.agent.agent.monitor.vif.error_transfer_count))
        if (env.predictor_subscriber.error_count != 4 ||
            env.scoreboard_subscriber.error_count != 4 ||
            env.coverage_subscriber.error_count != 4)
          `uvm_fatal("AHB_MVC_ERROR", "Keyed AHB streams did not preserve the ERROR response")
        if (env.predictor_subscriber.burst_write_count != 1 ||
            env.predictor_subscriber.burst_read_count != 1 ||
            env.predictor_subscriber.error_burst_count != 2 ||
            env.predictor_subscriber.partial_burst_count != 1 ||
            env.scoreboard_subscriber.burst_write_count != 1 ||
            env.scoreboard_subscriber.burst_read_count != 1 ||
            env.scoreboard_subscriber.error_burst_count != 2 ||
            env.scoreboard_subscriber.partial_burst_count != 1 ||
            env.coverage_subscriber.burst_write_count != 1 ||
            env.coverage_subscriber.burst_read_count != 1 ||
            env.coverage_subscriber.error_burst_count != 2 ||
            env.coverage_subscriber.partial_burst_count != 1)
          `uvm_fatal("AHB_MVC_BURST_COUNTS", "Keyed AHB streams lost or split a burst item")
        if (env.predictor_subscriber.last_item == env.scoreboard_subscriber.last_item ||
            env.predictor_subscriber.last_item == env.coverage_subscriber.last_item ||
            env.scoreboard_subscriber.last_item == env.coverage_subscriber.last_item)
          `uvm_fatal("AHB_MVC_ALIAS", "Predictor, scoreboard, and coverage streams shared a mutable item")
        $display("PASS: keyed AHB streams preserved scalar, full/partial bursts, and ERROR responses");
        phase.drop_objection(this);
      end
    endtask
  endclass

  initial begin
    uvm_config_db#(virtual ahb_lite_caliptra_master_cmd_if)::set(
      null, "uvm_test_top.env.agent.mvc_driver", "cmd_vif", cmd_if);
    uvm_config_db#(virtual ahb_lite_caliptra_record_if)::set(
      null, "uvm_test_top.env.agent.agent.monitor", "vif", record_if);
    run_test("ahb_lite_caliptra_agent_test");
  end

  initial begin
    repeat (2) @(posedge HCLK);
    @(negedge HCLK);
    HRESETn = 1;
  end

  initial begin
    if ($test$plusargs("AHB_RESET_ABORT_ONLY")) begin
      wait (HRESETn === 1'b1);
      wait (HSEL === 1'b1 && HTRANS[1] === 1'b1);
      @(posedge HCLK);
      #1 HRESETn = 1'b0;
      repeat (2) @(negedge HCLK);
      HRESETn = 1'b1;
    end
  end
endmodule
