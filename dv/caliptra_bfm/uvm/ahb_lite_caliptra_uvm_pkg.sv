// SPDX-License-Identifier: Apache-2.0
`include "uvm_macros.svh"

package ahb_lite_caliptra_uvm_pkg;
  import uvm_pkg::*;
  import mvc_pkg::*;
  import mgc_ahb_v2_0_pkg::*;

  localparam integer AHB_MVC_MAX_BURST_BEATS = 256;
  // Adams Bridge MLDSA's generated QVIP uses 32-bit data; Caliptra defaults to 64.
`ifdef CALIPTRA_BFM_AHB_32BIT
  localparam integer AHB_MVC_DATA_WIDTH = 32;
`else
  localparam integer AHB_MVC_DATA_WIDTH = 64;
`endif
  localparam integer AHB_MVC_WORD_SIZE = $clog2(AHB_MVC_DATA_WIDTH / 8);
  localparam bit [63:0] AHB_MVC_DATA_MASK =
    {64{1'b1}} >> (64 - AHB_MVC_DATA_WIDTH);

  typedef ahb_master_burst_transfer #(1, 1, 1, 32,
                                      AHB_MVC_DATA_WIDTH,
                                      AHB_MVC_DATA_WIDTH)
    ahb_lite_caliptra_mvc_transfer;

  class ahb_lite_caliptra_transaction extends uvm_sequence_item;
    bit [31:0] address;
    bit write;
    bit [1:0] trans;
    bit [2:0] size;
    bit [63:0] data;
    bit error;
    bit protocol_error;

    `uvm_object_utils(ahb_lite_caliptra_transaction)

    function new(string name = "ahb_lite_caliptra_transaction");
      super.new(name);
    endfunction

    function void do_copy(uvm_object rhs);
      ahb_lite_caliptra_transaction source;
      if (!$cast(source, rhs)) begin
        `uvm_error("AHB_COPY", "Cannot copy a non-Caliptra AHB transaction")
        return;
      end
      super.do_copy(rhs);
      address = source.address;
      write = source.write;
      trans = source.trans;
      size = source.size;
      data = source.data;
      error = source.error;
      protocol_error = source.protocol_error;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      ahb_lite_caliptra_transaction other;
      if (!$cast(other, rhs)) return 0;
      return super.do_compare(rhs, comparer) && address == other.address &&
             write == other.write && trans == other.trans && size == other.size &&
             data == other.data && error == other.error &&
             protocol_error == other.protocol_error;
    endfunction

    function void do_print(uvm_printer printer);
      super.do_print(printer);
      printer.print_field_int("address", address, 32, UVM_HEX);
      printer.print_field_int("write", write, 1, UVM_BIN);
      printer.print_field_int("trans", trans, 2, UVM_BIN);
      printer.print_field_int("size", size, 3, UVM_DEC);
      printer.print_field_int("data", data, 64, UVM_HEX);
      printer.print_field_int("error", error, 1, UVM_BIN);
      printer.print_field_int("protocol_error", protocol_error, 1, UVM_BIN);
    endfunction

    function string convert2string();
      return $sformatf("%s addr=%08h size=%0d data=%016h error=%0b protocol_error=%0b",
                       write ? "WRITE" : "READ", address, size, data,
                       error, protocol_error);
    endfunction
  endclass

  class ahb_lite_caliptra_transfer extends uvm_sequence_item;
    bit write;
    bit [31:0] address;
    bit [2:0] size = 3;
    bit [63:0] write_data;
    bit request_ok;
    bit success;
    bit response_error;
    bit [63:0] read_data;

    `uvm_object_utils(ahb_lite_caliptra_transfer)

    function new(string name = "ahb_lite_caliptra_transfer");
      super.new(name);
    endfunction
  endclass

  class ahb_lite_caliptra_sequencer extends uvm_sequencer #(ahb_lite_caliptra_transfer);
    `uvm_component_utils(ahb_lite_caliptra_sequencer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  class ahb_lite_caliptra_driver extends uvm_driver #(ahb_lite_caliptra_transfer);
    virtual ahb_lite_caliptra_master_cmd_if cmd_vif;
    `uvm_component_utils(ahb_lite_caliptra_driver)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual ahb_lite_caliptra_master_cmd_if)::get(
            this, "", "cmd_vif", cmd_vif))
        `uvm_fatal("AHB_CMD_VIF", "Missing Caliptra AHB-Lite command interface")
    endfunction

    task run_phase(uvm_phase phase);
      ahb_lite_caliptra_transfer req;
      forever begin
        seq_item_port.get_next_item(req);
        wait (cmd_vif.HRESETn === 1'b1);
        cmd_vif.request_write = req.write;
        cmd_vif.request_address = req.address;
        cmd_vif.request_size = req.size;
        cmd_vif.request_write_data = req.write_data;
        cmd_vif.request_burst_count = 1;
        cmd_vif.request_valid = 1;
        wait (cmd_vif.response_valid === 1'b1);
        req.request_ok = cmd_vif.response_request_ok;
        req.success = cmd_vif.response_success;
        req.response_error = cmd_vif.response_error;
        req.read_data = cmd_vif.response_read_data;
        cmd_vif.request_valid = 0;
        wait (cmd_vif.response_valid === 1'b0);
        seq_item_port.item_done();
      end
    endtask
  endclass

  class ahb_lite_caliptra_mvc_driver extends uvm_driver #(mvc_sequence_item_base);
    virtual ahb_lite_caliptra_master_cmd_if cmd_vif;
    `uvm_component_utils(ahb_lite_caliptra_mvc_driver)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual ahb_lite_caliptra_master_cmd_if)::get(
            this, "", "cmd_vif", cmd_vif))
        `uvm_fatal("AHB_MVC_CMD_VIF", "Missing Caliptra AHB-Lite MVC command interface")
    endfunction

    task run_phase(uvm_phase phase);
      mvc_sequence_item_base base_req;
      ahb_lite_caliptra_mvc_transfer req;
      forever begin
        seq_item_port.get_next_item(base_req);
        if (!$cast(req, base_req)) begin
          `uvm_fatal("AHB_MVC_ITEM", $sformatf("Expected ahb_master_burst_transfer #(1,1,1,32,64,64), got %s", base_req.get_type_name()))
          seq_item_port.item_done();
          continue;
        end
        if (req.data.size() < 1 || req.data.size() > AHB_MVC_MAX_BURST_BEATS) begin
          `uvm_fatal("AHB_MVC_BEATS", $sformatf("AHB MVC item must contain 1..%0d beats, got %0d", AHB_MVC_MAX_BURST_BEATS, req.data.size()))
          seq_item_port.item_done();
          continue;
        end
        wait (cmd_vif.HRESETn === 1'b1);
        cmd_vif.request_write = (req.RnW == AHB_WRITE);
        cmd_vif.request_address = req.address;
        cmd_vif.request_size = req.size;
        cmd_vif.request_write_data = req.data[0];
        cmd_vif.request_burst_count = req.data.size();
        cmd_vif.request_burst_data = '0;
        for (int beat = 0; beat < req.data.size(); beat++)
          cmd_vif.request_burst_data[beat*64 +: 64] = req.data[beat];
        cmd_vif.request_valid = 1;
        wait (cmd_vif.response_valid === 1'b1);
        req.resp.delete();
        if (cmd_vif.response_completed_beats > req.data.size())
          `uvm_fatal("AHB_MVC_COMPLETED", "AHB manager completed more beats than requested")
        for (int beat = 0; beat < cmd_vif.response_completed_beats; beat++) begin
          req.resp.push_back(cmd_vif.response_beat_error[beat] ? AHB_ERROR : AHB_OKAY);
          if (req.RnW == AHB_READ &&
              !cmd_vif.response_beat_error[beat])
            req.data[beat] = cmd_vif.response_burst_read_data[beat*64 +: 64];
        end
        if (cmd_vif.response_completed_beats == 0 &&
            !cmd_vif.response_request_ok)
          req.resp.push_back(AHB_ERROR);
        cmd_vif.request_valid = 0;
        wait (cmd_vif.response_valid === 1'b0);
        seq_item_port.item_done();
      end
    endtask
  endclass

  class ahb_lite_caliptra_reg_adapter extends uvm_reg_adapter;
    int unsigned bus_data_width;

    `uvm_object_utils(ahb_lite_caliptra_reg_adapter)

    function new(string name = "ahb_lite_caliptra_reg_adapter");
      super.new(name);
      bus_data_width = AHB_MVC_DATA_WIDTH;
      supports_byte_enable = 0;
      provides_responses = 0;
    endfunction

    function void set_bus_data_width(input int unsigned width);
      int unsigned bus_bytes;
      bus_bytes = width / 8;
      if (width < 8 || width > 64 || (width % 8) != 0 ||
          (bus_bytes & (bus_bytes - 1)) != 0) begin
        `uvm_fatal("AHB_RAL_BUS_WIDTH", $sformatf("AHB adapter bus width must be a power-of-two byte width from 8 to 64, got %0d", width))
        return;
      end
      bus_data_width = width;
    endfunction

    function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
      ahb_lite_caliptra_mvc_transfer transfer;
      int unsigned byte_count;
      int unsigned bus_bytes;
      int unsigned lane;
      bit [63:0] bus_data;

      if (rw.kind != UVM_READ && rw.kind != UVM_WRITE) begin
        `uvm_fatal("AHB_RAL_KIND", "Caliptra AHB adapter supports scalar READ/WRITE operations only")
        return null;
      end
      if (rw.n_bits == 0 || rw.n_bits > bus_data_width || (rw.n_bits % 8) != 0) begin
        `uvm_fatal("AHB_RAL_WIDTH", $sformatf("AHB adapter requires byte-sized operations up to bus width %0d, got %0d", bus_data_width, rw.n_bits))
        return null;
      end
      byte_count = rw.n_bits / 8;
      bus_bytes = bus_data_width / 8;
      if ((byte_count & (byte_count - 1)) != 0 ||
          (rw.addr % byte_count) != 0 || ((rw.addr % bus_bytes) + byte_count) > bus_bytes) begin
        `uvm_fatal("AHB_RAL_ALIGN", $sformatf("AHB access at 0x%0h is not naturally aligned for %0d bytes", rw.addr, byte_count))
        return null;
      end

      transfer = new("ahb_reg_transfer");
      transfer.RnW = (rw.kind == UVM_WRITE) ? AHB_WRITE : AHB_READ;
      transfer.address = rw.addr;
      transfer.size = $clog2(byte_count);
      transfer.data.delete();
      transfer.resp.delete();
      bus_data = '0;
      lane = rw.addr % bus_bytes;
      for (int byte_index = 0; byte_index < byte_count; byte_index++)
        bus_data[(lane + byte_index)*8 +: 8] = rw.data[byte_index*8 +: 8];
      transfer.data.push_back(bus_data);
      return transfer;
    endfunction

    function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
      ahb_lite_caliptra_mvc_transfer transfer;
      int unsigned byte_count;
      int unsigned bus_bytes;
      int unsigned lane;

      if (!$cast(transfer, bus_item)) begin
        `uvm_fatal("AHB_RAL_BUS_ITEM", "AHB register adapter received a non-Caliptra MVC transfer")
        return;
      end
      if (transfer.size > 3) begin
        `uvm_error("AHB_RAL_RESPONSE", "AHB response has an unsupported size or address alignment")
        rw.status = UVM_NOT_OK;
        return;
      end
      byte_count = 1 << transfer.size;
      bus_bytes = bus_data_width / 8;
      if (byte_count > bus_bytes ||
          transfer.address % byte_count != 0 ||
          (transfer.address % bus_bytes) + byte_count > bus_bytes) begin
        `uvm_error("AHB_RAL_RESPONSE", "AHB response has an unsupported size or address alignment")
        rw.status = UVM_NOT_OK;
        return;
      end
      rw.kind = (transfer.RnW == AHB_WRITE) ? UVM_WRITE : UVM_READ;
      rw.addr = transfer.address;
      rw.n_bits = byte_count * 8;
      rw.data = '0;
      rw.byte_en = '0;
      lane = transfer.address % bus_bytes;
      if (transfer.data.size() != 1 || transfer.resp.size() != 1) begin
        rw.status = UVM_NOT_OK;
        return;
      end
      for (int byte_index = 0; byte_index < byte_count; byte_index++) begin
        rw.data[byte_index*8 +: 8] = transfer.data[0][(lane + byte_index)*8 +: 8];
        rw.byte_en[byte_index] = 1'b1;
      end
      rw.status = (transfer.resp[0] == AHB_OKAY) ? UVM_IS_OK : UVM_NOT_OK;
    endfunction
  endclass

  class ahb_lite_caliptra_monitor extends uvm_monitor;
    virtual ahb_lite_caliptra_record_if vif;
    uvm_analysis_port #(ahb_lite_caliptra_transaction) ap;
    uvm_analysis_port #(mvc_sequence_item_base) burst_transfer_ap;
    uvm_analysis_port #(mvc_sequence_item_base) burst_transfer_sb_ap;
    uvm_analysis_port #(mvc_sequence_item_base) burst_transfer_cov_ap;
    `uvm_component_utils(ahb_lite_caliptra_monitor)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
      burst_transfer_ap = new("burst_transfer", this);
      burst_transfer_sb_ap = new("burst_transfer_sb", this);
      burst_transfer_cov_ap = new("burst_transfer_cov", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual ahb_lite_caliptra_record_if)::get(
            this, "", "vif", vif))
        `uvm_fatal("AHB_MON_VIF", "Missing Caliptra AHB-Lite record interface")
    endfunction

    function void publish_group(ahb_lite_caliptra_mvc_transfer source);
      ahb_lite_caliptra_mvc_transfer predictor_item;
      ahb_lite_caliptra_mvc_transfer scoreboard_item;
      ahb_lite_caliptra_mvc_transfer coverage_item;
      if (source.data.size() == 0) return;
      predictor_item = new("burst_transfer");
      predictor_item.RnW = source.RnW;
      predictor_item.address = source.address;
      predictor_item.size = source.size;
      predictor_item.data = source.data;
      predictor_item.resp = source.resp;
      scoreboard_item = new("burst_transfer_sb");
      scoreboard_item.RnW = source.RnW;
      scoreboard_item.address = source.address;
      scoreboard_item.size = source.size;
      scoreboard_item.data = source.data;
      scoreboard_item.resp = source.resp;
      coverage_item = new("burst_transfer_cov");
      coverage_item.RnW = source.RnW;
      coverage_item.address = source.address;
      coverage_item.size = source.size;
      coverage_item.data = source.data;
      coverage_item.resp = source.resp;
      burst_transfer_ap.write(predictor_item);
      burst_transfer_sb_ap.write(scoreboard_item);
      burst_transfer_cov_ap.write(coverage_item);
    endfunction

    task run_phase(uvm_phase phase);
      ahb_lite_caliptra_transaction item;
      ahb_lite_caliptra_mvc_transfer group_item;
      bit flush_group;
      group_item = new("burst_transfer_pending");
      forever begin
        @(negedge vif.HCLK);
        if (vif.HRESETn !== 1'b1) begin
          group_item = new("burst_transfer_pending");
        end else if (vif.transfer_fire) begin
          item = ahb_lite_caliptra_transaction::type_id::create("transfer");
          item.address = vif.transfer_addr;
          item.write = vif.transfer_write;
          item.trans = vif.transfer_trans;
          item.size = vif.transfer_size;
          item.data = vif.transfer_data;
          item.error = vif.transfer_error;
          item.protocol_error = vif.transfer_protocol_error;
          ap.write(item);

          flush_group = 0;
          if (group_item.data.size() != 0) begin
            if (item.trans != 2'b11 ||
                group_item.RnW != (item.write ? AHB_WRITE : AHB_READ) ||
                group_item.size != item.size ||
                item.address != (group_item.address +
                                 (group_item.data.size() * (1 << group_item.size))) ||
                group_item.data.size() >= AHB_MVC_MAX_BURST_BEATS)
              flush_group = 1;
          end
          if (flush_group) begin
            publish_group(group_item);
            group_item = new("burst_transfer_pending");
          end
          if (group_item.data.size() == 0) begin
            group_item.RnW = item.write ? AHB_WRITE : AHB_READ;
            group_item.address = item.address;
            group_item.size = item.size;
          end
          group_item.data.push_back(item.data);
          group_item.resp.push_back(item.error ? AHB_ERROR : AHB_OKAY);

          // The accepted address overlaps this completed data phase. Keep the
          // group only when that phase is a possible continuation.
          if (item.error || item.protocol_error ||
              group_item.data.size() >= AHB_MVC_MAX_BURST_BEATS ||
              !vif.address_phase_fire ||
              (vif.address_phase_selected !== 1'b1) ||
              (vif.address_phase_trans !== 2'b11)) begin
            publish_group(group_item);
            group_item = new("burst_transfer_pending");
          end
        end
      end
    endtask
  endclass

  class ahb_lite_caliptra_agent extends uvm_agent;
    ahb_lite_caliptra_sequencer sequencer;
    ahb_lite_caliptra_driver driver;
    ahb_lite_caliptra_monitor monitor;
    uvm_analysis_port #(ahb_lite_caliptra_transaction) ap;
    uvm_analysis_port #(mvc_sequence_item_base) burst_transfer_ap;
    uvm_analysis_port #(mvc_sequence_item_base) burst_transfer_sb_ap;
    uvm_analysis_port #(mvc_sequence_item_base) burst_transfer_cov_ap;

    `uvm_component_utils(ahb_lite_caliptra_agent)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
      burst_transfer_ap = new("burst_transfer", this);
      burst_transfer_sb_ap = new("burst_transfer_sb", this);
      burst_transfer_cov_ap = new("burst_transfer_cov", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      monitor = ahb_lite_caliptra_monitor::type_id::create("monitor", this);
      if (is_active == UVM_ACTIVE) begin
        sequencer = ahb_lite_caliptra_sequencer::type_id::create("sequencer", this);
        driver = ahb_lite_caliptra_driver::type_id::create("driver", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      monitor.ap.connect(ap);
      monitor.burst_transfer_ap.connect(burst_transfer_ap);
      monitor.burst_transfer_sb_ap.connect(burst_transfer_sb_ap);
      monitor.burst_transfer_cov_ap.connect(burst_transfer_cov_ap);
      if (is_active == UVM_ACTIVE)
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
  endclass

  // Keyed analysis-port component used by the QVIP-named clean-room facade.
  class ahb_lite_caliptra_qvip_compat_agent extends uvm_agent;
    ahb_lite_caliptra_agent agent;
    mvc_sequencer m_sequencer;
    ahb_lite_caliptra_mvc_driver mvc_driver;
    uvm_analysis_port #(mvc_sequence_item_base) ap[string];
    bit publish_burst_transfer = 1;
    bit publish_burst_transfer_sb = 1;
    bit publish_burst_transfer_cov = 1;

    `uvm_component_utils(ahb_lite_caliptra_qvip_compat_agent)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap["burst_transfer"] = new("burst_transfer", this);
      ap["burst_transfer_sb"] = new("burst_transfer_sb", this);
      ap["burst_transfer_cov"] = new("burst_transfer_cov", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = ahb_lite_caliptra_agent::type_id::create("agent", this);
      agent.is_active = UVM_PASSIVE;
      if (is_active == UVM_ACTIVE) begin
        m_sequencer = mvc_sequencer::type_id::create("m_sequencer", this);
        mvc_driver = ahb_lite_caliptra_mvc_driver::type_id::create("mvc_driver", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (publish_burst_transfer)
        agent.burst_transfer_ap.connect(ap["burst_transfer"]);
      if (publish_burst_transfer_sb)
        agent.burst_transfer_sb_ap.connect(ap["burst_transfer_sb"]);
      if (publish_burst_transfer_cov)
        agent.burst_transfer_cov_ap.connect(ap["burst_transfer_cov"]);
      if (is_active == UVM_ACTIVE)
        mvc_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    endfunction
  endclass

  class ahb_lite_caliptra_smoke_sequence extends uvm_sequence #(mvc_sequence_item_base);
    `uvm_object_utils(ahb_lite_caliptra_smoke_sequence)

    function new(string name = "ahb_lite_caliptra_smoke_sequence");
      super.new(name);
    endfunction

    task body();
      ahb_lite_caliptra_mvc_transfer req;
      req = new("write_req");
      start_item(req);
      req.RnW = AHB_WRITE;
      req.address = 32'h20;
      req.size = AHB_MVC_WORD_SIZE;
      req.data.push_back(64'h1122_3344_5566_7788);
      finish_item(req);
      if (req.resp.size() != 1 || req.resp[0] != AHB_OKAY)
        `uvm_fatal("AHB_WRITE", "UVM-driven AHB-Lite write failed")

      req = new("read_req");
      start_item(req);
      req.RnW = AHB_READ;
      req.address = 32'h20;
      req.size = AHB_MVC_WORD_SIZE;
      req.data.push_back(0);
      finish_item(req);
      if (req.resp.size() != 1 || req.resp[0] != AHB_OKAY ||
          req.data[0] != (64'h1122_3344_5566_7788 & AHB_MVC_DATA_MASK))
        `uvm_fatal("AHB_READ", "UVM-driven AHB-Lite read did not return the stored data")

      req = new("write_burst_req");
      start_item(req);
      req.RnW = AHB_WRITE;
      req.address = 32'h80;
      req.size = AHB_MVC_WORD_SIZE;
      req.data.push_back(64'h0102_0304_0506_0708);
      req.data.push_back(64'h1112_1314_1516_1718);
      req.data.push_back(64'h2122_2324_2526_2728);
      req.data.push_back(64'h3132_3334_3536_3738);
      finish_item(req);
      if (req.resp.size() != 4 || req.resp[0] != AHB_OKAY ||
          req.resp[1] != AHB_OKAY || req.resp[2] != AHB_OKAY ||
          req.resp[3] != AHB_OKAY)
        `uvm_fatal("AHB_BURST_WRITE", "UVM-driven AHB-Lite burst write failed")

      req = new("read_burst_req");
      start_item(req);
      req.RnW = AHB_READ;
      req.address = 32'h80;
      req.size = AHB_MVC_WORD_SIZE;
      repeat (4) req.data.push_back(0);
      finish_item(req);
      if (req.resp.size() != 4 || req.resp[0] != AHB_OKAY ||
          req.resp[1] != AHB_OKAY || req.resp[2] != AHB_OKAY ||
          req.resp[3] != AHB_OKAY ||
          req.data[0] != (64'h0102_0304_0506_0708 & AHB_MVC_DATA_MASK) ||
          req.data[1] != (64'h1112_1314_1516_1718 & AHB_MVC_DATA_MASK) ||
          req.data[2] != (64'h2122_2324_2526_2728 & AHB_MVC_DATA_MASK) ||
          req.data[3] != (64'h3132_3334_3536_3738 & AHB_MVC_DATA_MASK))
        `uvm_fatal("AHB_BURST_READ", "UVM-driven AHB-Lite burst read data mismatch")
    endtask
  endclass

  class ahb_lite_caliptra_error_sequence extends uvm_sequence #(mvc_sequence_item_base);
    `uvm_object_utils(ahb_lite_caliptra_error_sequence)

    function new(string name = "ahb_lite_caliptra_error_sequence");
      super.new(name);
    endfunction

    task body();
      ahb_lite_caliptra_mvc_transfer req;
      req = new("error_req");
      start_item(req);
      req.RnW = AHB_READ;
      req.address = 32'h20;
      req.size = AHB_MVC_WORD_SIZE;
      req.data.push_back(0);
      finish_item(req);
      if (req.resp.size() != 1 || req.resp[0] != AHB_ERROR)
        `uvm_fatal("AHB_ERROR", "UVM driver did not preserve the injected AHB-Lite ERROR")

      req = new("error_burst_req");
      start_item(req);
      req.RnW = AHB_READ;
      req.address = 32'h10000;
      req.size = AHB_MVC_WORD_SIZE;
      req.data.push_back(64'hfeed_0000_0000_0000);
      req.data.push_back(64'hfeed_0000_0000_0001);
      req.data.push_back(64'hfeed_0000_0000_0002);
      req.data.push_back(64'hfeed_0000_0000_0003);
      finish_item(req);
      if (req.resp.size() != 1 || req.resp[0] != AHB_ERROR ||
          req.data[0] != (64'hfeed_0000_0000_0000 & AHB_MVC_DATA_MASK) ||
          req.data[1] != (64'hfeed_0000_0000_0001 & AHB_MVC_DATA_MASK) ||
          req.data[2] != (64'hfeed_0000_0000_0002 & AHB_MVC_DATA_MASK) ||
          req.data[3] != (64'hfeed_0000_0000_0003 & AHB_MVC_DATA_MASK))
        `uvm_fatal("AHB_BURST_ERROR", "Aborted burst fabricated read data or lost ERROR")
    endtask
  endclass

  class ahb_lite_caliptra_partial_burst_error_sequence extends uvm_sequence #(mvc_sequence_item_base);
    `uvm_object_utils(ahb_lite_caliptra_partial_burst_error_sequence)

    function new(string name = "ahb_lite_caliptra_partial_burst_error_sequence");
      super.new(name);
    endfunction

    task body();
      ahb_lite_caliptra_mvc_transfer req;
      req = new("partial_error_burst_req");
      start_item(req);
      req.RnW = AHB_WRITE;
      req.address = (AHB_MVC_DATA_WIDTH == 32) ? 32'hfffc : 32'hfff8;
      req.size = AHB_MVC_WORD_SIZE;
      req.data.push_back(64'h4142_4344_4546_4748);
      req.data.push_back(64'h5152_5354_5556_5758);
      req.data.push_back(64'h6162_6364_6566_6768);
      req.data.push_back(64'h7172_7374_7576_7778);
      finish_item(req);
      if (req.resp.size() != 2 || req.resp[0] != AHB_OKAY ||
          req.resp[1] != AHB_ERROR || req.data.size() != 4 ||
          req.data[0] != (64'h4142_4344_4546_4748 & AHB_MVC_DATA_MASK) ||
          req.data[1] != (64'h5152_5354_5556_5758 & AHB_MVC_DATA_MASK) ||
          req.data[2] != (64'h6162_6364_6566_6768 & AHB_MVC_DATA_MASK) ||
          req.data[3] != (64'h7172_7374_7576_7778 & AHB_MVC_DATA_MASK))
        `uvm_fatal("AHB_PARTIAL_BURST_ERROR", "Partial burst did not retain the successful/error responses and original write queue")
    endtask
  endclass
endpackage
