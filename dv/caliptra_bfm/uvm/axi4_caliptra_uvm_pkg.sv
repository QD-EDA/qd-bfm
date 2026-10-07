// SPDX-License-Identifier: Apache-2.0
`include "uvm_macros.svh"

package axi4_caliptra_uvm_pkg;
  import uvm_pkg::*;
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
  import aaxi_uvm_pkg::*;
`endif

  localparam bit [47:0] CALIPTRA_DMA_SRAM_BASE = 48'h0001_2344_0000;
  localparam bit [47:0] CALIPTRA_DMA_FIFO_BASE = 48'h0000_fa57_0000;

  typedef enum bit [2:0] {
    AXI4_CHANNEL_AW, AXI4_CHANNEL_W, AXI4_CHANNEL_B,
    AXI4_CHANNEL_AR, AXI4_CHANNEL_R
  } axi4_caliptra_channel_e;

  class axi4_caliptra_channel_transaction extends uvm_sequence_item;
    axi4_caliptra_channel_e channel;
    bit [63:0] cycle;
    bit [7:0] id;
    bit [47:0] addr;
    bit [7:0] len;
    bit [2:0] size;
    bit [1:0] burst;
    bit lock;
    bit [31:0] user;
    bit [31:0] data;
    bit [3:0] strb;
    bit last;
    bit [1:0] response;

    `uvm_object_utils(axi4_caliptra_channel_transaction)

    function new(string name = "axi4_caliptra_channel_transaction");
      super.new(name);
    endfunction

    function void do_copy(uvm_object rhs);
      axi4_caliptra_channel_transaction source;
      if (!$cast(source, rhs)) begin
        `uvm_error("AXI_CHANNEL_COPY", "Cannot copy a non-Caliptra AXI channel item")
        return;
      end
      super.do_copy(rhs);
      channel = source.channel;
      cycle = source.cycle;
      id = source.id;
      addr = source.addr;
      len = source.len;
      size = source.size;
      burst = source.burst;
      lock = source.lock;
      user = source.user;
      data = source.data;
      strb = source.strb;
      last = source.last;
      response = source.response;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      axi4_caliptra_channel_transaction other;
      if (!$cast(other, rhs)) return 0;
      return super.do_compare(rhs, comparer) && channel == other.channel &&
             cycle == other.cycle &&
             id == other.id && addr == other.addr && len == other.len &&
             size == other.size && burst == other.burst && lock == other.lock &&
             user == other.user && data == other.data && strb == other.strb &&
             last == other.last && response == other.response;
    endfunction

    function void do_print(uvm_printer printer);
      super.do_print(printer);
      printer.print_field_int("channel", channel, 3, UVM_DEC);
      printer.print_field_int("cycle", cycle, 64, UVM_DEC);
      printer.print_field_int("id", id, 8, UVM_HEX);
      printer.print_field_int("addr", addr, 48, UVM_HEX);
      printer.print_field_int("len", len, 8, UVM_DEC);
      printer.print_field_int("size", size, 3, UVM_DEC);
      printer.print_field_int("burst", burst, 2, UVM_HEX);
      printer.print_field_int("lock", lock, 1, UVM_BIN);
      printer.print_field_int("user", user, 32, UVM_HEX);
      printer.print_field_int("data", data, 32, UVM_HEX);
      printer.print_field_int("strb", strb, 4, UVM_HEX);
      printer.print_field_int("last", last, 1, UVM_BIN);
      printer.print_field_int("response", response, 2, UVM_HEX);
    endfunction

    function string convert2string();
      return $sformatf("cycle=%0d channel=%0d id=%02h addr=%012h data=%08h resp=%0h",
                       cycle, channel, id, addr, data, response);
    endfunction
  endclass

  class axi4_caliptra_transaction extends uvm_sequence_item;
    localparam int unsigned AXI_READ = 0;
    localparam int unsigned AXI_WRITE = 1;

    int unsigned kind;
    bit [47:0] addr;
    bit [7:0] id;
    bit [7:0] len;
    bit [2:0] size;
    bit [1:0] burst;
    bit lock;
    bit [31:0] awuser;
    bit [31:0] aruser;
    bit [31:0] data;
    bit [1:0] resp;
    bit [7:0] response_id;
    bit [31:0] buser;
    bit protocol_error;
    bit [3:0] protocol_status;
    bit [31:0] beatQ[$];
    bit [3:0] strbQ[$];
    bit [31:0] beat_userQ[$];
    bit [1:0] respQ[$];
    bit lastQ[$];

    `uvm_object_utils(axi4_caliptra_transaction)

    function new(string name = "axi4_caliptra_transaction");
      super.new(name);
      kind = AXI_READ;
    endfunction

    function bit is_read();
      return kind == AXI_READ;
    endfunction

    function bit is_write();
      return kind == AXI_WRITE;
    endfunction

    function void do_copy(uvm_object rhs);
      axi4_caliptra_transaction source;
      if (!$cast(source, rhs)) begin
        `uvm_error("AXI_COPY", "Cannot copy a non-Caliptra AXI transaction")
        return;
      end
      super.do_copy(rhs);
      kind = source.kind;
      addr = source.addr;
      id = source.id;
      len = source.len;
      size = source.size;
      burst = source.burst;
      lock = source.lock;
      awuser = source.awuser;
      aruser = source.aruser;
      data = source.data;
      resp = source.resp;
      response_id = source.response_id;
      buser = source.buser;
      protocol_error = source.protocol_error;
      protocol_status = source.protocol_status;
      beatQ = source.beatQ;
      strbQ = source.strbQ;
      beat_userQ = source.beat_userQ;
      respQ = source.respQ;
      lastQ = source.lastQ;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      axi4_caliptra_transaction other;
      if (!$cast(other, rhs)) return 0;
      if (!super.do_compare(rhs, comparer)) return 0;
      if (kind != other.kind || addr != other.addr || id != other.id ||
          len != other.len || size != other.size || burst != other.burst ||
          lock != other.lock || awuser != other.awuser ||
          aruser != other.aruser || data != other.data || resp != other.resp ||
          response_id != other.response_id || buser != other.buser ||
          protocol_error != other.protocol_error ||
          protocol_status != other.protocol_status ||
          beatQ.size() != other.beatQ.size() ||
          strbQ.size() != other.strbQ.size() ||
          beat_userQ.size() != other.beat_userQ.size() ||
          respQ.size() != other.respQ.size() ||
          lastQ.size() != other.lastQ.size()) return 0;
      foreach (beatQ[i])
        if (beatQ[i] != other.beatQ[i]) return 0;
      foreach (strbQ[i])
        if (strbQ[i] != other.strbQ[i]) return 0;
      foreach (beat_userQ[i])
        if (beat_userQ[i] != other.beat_userQ[i]) return 0;
      foreach (respQ[i])
        if (respQ[i] != other.respQ[i]) return 0;
      foreach (lastQ[i])
        if (lastQ[i] != other.lastQ[i]) return 0;
      return 1;
    endfunction

    function void do_print(uvm_printer printer);
      super.do_print(printer);
      printer.print_field_int("kind", kind, 32, UVM_DEC);
      printer.print_field_int("addr", addr, 48, UVM_HEX);
      printer.print_field_int("id", id, 8, UVM_HEX);
      printer.print_field_int("len", len, 8, UVM_DEC);
      printer.print_field_int("size", size, 3, UVM_DEC);
      printer.print_field_int("burst", burst, 2, UVM_HEX);
      printer.print_field_int("lock", lock, 1, UVM_BIN);
      printer.print_field_int("data", data, 32, UVM_HEX);
      printer.print_field_int("resp", resp, 2, UVM_HEX);
      printer.print_field_int("response_id", response_id, 8, UVM_HEX);
      printer.print_field_int("protocol_error", protocol_error, 1, UVM_BIN);
      printer.print_field_int("protocol_status", protocol_status, 4, UVM_HEX);
      printer.print_string("beat_count", $sformatf("%0d", beatQ.size()));
    endfunction

    function string convert2string();
      return $sformatf("%s id=%02h addr=%012h beats=%0d data=%08h resp=%0h status=%0h",
                       is_write() ? "WRITE" : "READ", id, addr,
                       beatQ.size(), data, resp, protocol_status);
    endfunction
  endclass

  class axi4_caliptra_uvm_monitor extends uvm_monitor;
    virtual axi4_caliptra_record_if vif;
    uvm_analysis_port #(axi4_caliptra_transaction) ap;
    uvm_analysis_port #(axi4_caliptra_channel_transaction) channel_ap;
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
    uvm_analysis_port #(aaxi_master_tr) aaxi_ap;
    uvm_analysis_port #(aaxi_master_tr) ms_tx_AW_W_export;
    uvm_analysis_port #(aaxi_master_tr) ms_rx_rvalid_export;
    uvm_analysis_port #(aaxi_master_tr) write_done_export;
    uvm_analysis_port #(aaxi_master_tr) read_done_export;
`endif

    `uvm_component_utils(axi4_caliptra_uvm_monitor)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
      channel_ap = new("channel_ap", this);
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
      aaxi_ap = new("aaxi_ap", this);
      ms_tx_AW_W_export = new("ms_tx_AW_W_export", this);
      ms_rx_rvalid_export = new("ms_rx_rvalid_export", this);
      write_done_export = new("write_done_export", this);
      read_done_export = new("read_done_export", this);
`endif
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual axi4_caliptra_record_if)::get(
            this, "", "vif", vif))
        `uvm_fatal("AXI_VIF", "Missing axi4_caliptra_record_if config")
    endfunction

`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
    function aaxi_master_tr to_aaxi_item(axi4_caliptra_transaction source);
      aaxi_master_tr item;
      item = aaxi_master_tr::type_id::create("aaxi_master_tr");
      item.kind = source.is_write() ? AAXI_WRITE : AAXI_READ;
      item.addr = source.addr;
      item.id = source.id;
      item.len = source.len;
      item.size = source.size;
      item.burst = source.burst;
      item.lock = source.lock;
      item.awuser = source.awuser;
      item.aruser = source.aruser;
      item.data = source.data;
      item.resp = source.resp;
      item.response_id = source.response_id;
      item.buser = source.buser;
      item.transport_success = !source.protocol_error;
      item.protocol_error = source.protocol_error;
      item.protocol_status = source.protocol_status;
      item.beatQ = source.beatQ;
      item.strbQ = source.strbQ;
      item.beat_userQ = source.beat_userQ;
      item.respQ = source.respQ;
      item.lastQ = source.lastQ;
      return item;
    endfunction
`endif

    task run_phase(uvm_phase phase);
      forever begin
        @(negedge vif.ACLK);
        if (vif.ARESETn !== 1'b1) continue;
        if (vif.write_error)
          `uvm_error("AXI_PROTOCOL", $sformatf("AXI write protocol error code %0d",
            vif.write_error_code))
        if (vif.read_error)
          `uvm_error("AXI_PROTOCOL", $sformatf("AXI read protocol error code %0d",
            vif.read_error_code))
        if (vif.aw_fire === 1'b1) publish_channel(AXI4_CHANNEL_AW);
        if (vif.w_fire === 1'b1) publish_channel(AXI4_CHANNEL_W);
        if (vif.b_fire === 1'b1) publish_channel(AXI4_CHANNEL_B);
        if (vif.ar_fire === 1'b1) publish_channel(AXI4_CHANNEL_AR);
        if (vif.r_fire === 1'b1) publish_channel(AXI4_CHANNEL_R);
        if (vif.write_request_complete) publish_write_request();
        if (vif.write_complete) publish_write();
        if (vif.read_complete) publish_read();
      end
    endtask

    function void report_phase(uvm_phase phase);
      super.report_phase(phase);
      // ponytail: report handshake/stall totals; expose finer native bins if UVM consumers need them.
      `uvm_info("AXI_COVERAGE", $sformatf(
        "accepted AW/W/B/AR/R=%0d/%0d/%0d/%0d/%0d; stalled AW/W/B/AR/R=%0d/%0d/%0d/%0d/%0d",
        vif.aw_count, vif.w_count, vif.b_count, vif.ar_count, vif.r_count,
        vif.aw_stall_cycles, vif.w_stall_cycles, vif.b_stall_cycles,
        vif.ar_stall_cycles, vif.r_stall_cycles), UVM_LOW)
    endfunction

    function void publish_channel(axi4_caliptra_channel_e channel);
      axi4_caliptra_channel_transaction item;
      item = axi4_caliptra_channel_transaction::type_id::create("channel_item");
      item.channel = channel;
      item.cycle = vif.channel_cycle;
      case (channel)
        AXI4_CHANNEL_AW: begin
          item.id = vif.aw_record[101:94];
          item.addr = vif.aw_record[93:46];
          item.len = vif.aw_record[45:38];
          item.size = vif.aw_record[37:35];
          item.burst = vif.aw_record[34:33];
          item.lock = vif.aw_record[32];
          item.user = vif.aw_record[31:0];
        end
        AXI4_CHANNEL_W: begin
          item.data = vif.w_record[68:37];
          item.strb = vif.w_record[36:33];
          item.user = vif.w_record[32:1];
          item.last = vif.w_record[0];
        end
        AXI4_CHANNEL_B: begin
          item.id = vif.b_record[41:34];
          item.response = vif.b_record[33:32];
          item.user = vif.b_record[31:0];
        end
        AXI4_CHANNEL_AR: begin
          item.id = vif.ar_record[101:94];
          item.addr = vif.ar_record[93:46];
          item.len = vif.ar_record[45:38];
          item.size = vif.ar_record[37:35];
          item.burst = vif.ar_record[34:33];
          item.lock = vif.ar_record[32];
          item.user = vif.ar_record[31:0];
        end
        AXI4_CHANNEL_R: begin
          item.id = vif.r_record[74:67];
          item.data = vif.r_record[66:35];
          item.response = vif.r_record[34:33];
          item.user = vif.r_record[32:1];
          item.last = vif.r_record[0];
        end
        default: `uvm_error("AXI_CHANNEL_KIND", $sformatf("Unknown channel %0d", channel))
      endcase
      channel_ap.write(item);
    endfunction

    function void publish_write_request();
      axi4_caliptra_transaction item;
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
      aaxi_master_tr projected;
`endif
      item = axi4_caliptra_transaction::type_id::create("write_request_item");
      item.kind = item.AXI_WRITE;
      item.addr = vif.write_request_addr;
      item.id = vif.write_request_id;
      item.len = vif.write_request_len;
      item.size = vif.write_request_size;
      item.burst = vif.write_request_burst;
      item.lock = vif.write_request_lock;
      item.awuser = vif.write_request_awuser;
      item.protocol_error = vif.write_request_error;
      item.protocol_status = vif.write_request_status;
      for (int beat = 0; beat < vif.write_request_beat_count && beat < 256; beat++) begin
        item.beatQ.push_back(vif.write_request_data[beat*32 +: 32]);
        item.strbQ.push_back(vif.write_request_strb[beat*4 +: 4]);
        item.beat_userQ.push_back(vif.write_request_wuser[beat*32 +: 32]);
        item.lastQ.push_back(vif.write_request_last_mask[beat]);
      end
      if (item.beatQ.size() != 0) item.data = item.beatQ[0];
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
      projected = to_aaxi_item(item);
      ms_tx_AW_W_export.write(projected);
`endif
    endfunction

    function void publish_write();
      axi4_caliptra_transaction item;
      item = axi4_caliptra_transaction::type_id::create("write_item");
      item.kind = item.AXI_WRITE;
      item.addr = vif.write_addr;
      item.id = vif.write_id;
      item.len = vif.write_len;
      item.size = vif.write_size;
      item.burst = vif.write_burst;
      item.lock = vif.write_lock;
      item.awuser = vif.write_awuser;
      item.resp = vif.write_response;
      item.response_id = vif.write_response_id;
      item.buser = vif.write_buser;
      item.protocol_error = vif.write_error;
      item.protocol_status = vif.write_status;
      for (int beat = 0; beat < vif.write_beat_count && beat < 256; beat++) begin
        item.beatQ.push_back(vif.write_data[beat*32 +: 32]);
        item.strbQ.push_back(vif.write_strb[beat*4 +: 4]);
        item.beat_userQ.push_back(vif.write_wuser[beat*32 +: 32]);
        item.lastQ.push_back(vif.write_last_mask[beat]);
      end
      if (item.beatQ.size() != 0) item.data = item.beatQ[0];
      ap.write(item);
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
      begin
        aaxi_master_tr projected;
        projected = to_aaxi_item(item);
        aaxi_ap.write(projected.copy());
        write_done_export.write(projected.copy());
      end
`endif
    endfunction

    function void publish_read();
      axi4_caliptra_transaction item;
      item = axi4_caliptra_transaction::type_id::create("read_item");
      item.kind = item.AXI_READ;
      item.addr = vif.read_addr;
      item.id = vif.read_id;
      item.len = vif.read_len;
      item.size = vif.read_size;
      item.burst = vif.read_burst;
      item.lock = vif.read_lock;
      item.aruser = vif.read_aruser;
      item.response_id = vif.read_id;
      item.protocol_error = vif.read_error;
      item.protocol_status = vif.read_status;
      for (int beat = 0; beat < vif.read_beat_count && beat < 256; beat++) begin
        item.beatQ.push_back(vif.read_data[beat*32 +: 32]);
        item.respQ.push_back(vif.read_resp[beat*2 +: 2]);
        item.beat_userQ.push_back(vif.read_ruser[beat*32 +: 32]);
        item.lastQ.push_back(vif.read_last_mask[beat]);
      end
      if (item.beatQ.size() != 0) begin
        item.data = item.beatQ[0];
        item.resp = item.respQ[0];
      end
      ap.write(item);
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
      begin
        aaxi_master_tr projected;
        projected = to_aaxi_item(item);
        aaxi_ap.write(projected.copy());
        ms_rx_rvalid_export.write(projected.copy());
        read_done_export.write(projected.copy());
      end
`endif
    endfunction
  endclass

  class axi4_caliptra_uvm_transfer extends uvm_sequence_item;
    bit write;
    bit [47:0] addr;
    bit [7:0] len;
    bit [2:0] size;
    bit [1:0] burst;
    bit [7:0] id;
    bit [31:0] user;
    bit lock;
    bit [8191:0] write_data;
    bit [1023:0] write_strb;
    bit [8191:0] write_user;

    bit success;
    bit [1:0] response;
    bit [31:0] response_user;
    bit [8191:0] read_data;
    bit [8191:0] read_user;
    bit [511:0] read_response;

    `uvm_object_utils(axi4_caliptra_uvm_transfer)

    function new(string name = "axi4_caliptra_uvm_transfer");
      super.new(name);
      size = 2;
      burst = 2'b01;
    endfunction
  endclass

  class axi4_caliptra_uvm_user_extension extends uvm_object;
    bit [31:0] addr_user = '1;

    `uvm_object_utils(axi4_caliptra_uvm_user_extension)

    function new(string name = "axi4_caliptra_uvm_user_extension");
      super.new(name);
    endfunction

    function void set_addr_user(bit [31:0] value);
      addr_user = value;
    endfunction

    function bit [31:0] get_addr_user();
      return addr_user;
    endfunction
  endclass

  class axi4_caliptra_uvm_reg_adapter extends uvm_reg_adapter;
    bit [31:0] last_addr_user;
    axi4_caliptra_uvm_user_extension bus2reg_user_obj;

    `uvm_object_utils(axi4_caliptra_uvm_reg_adapter)

    function new(string name = "axi4_caliptra_uvm_reg_adapter");
      super.new(name);
      supports_byte_enable = 1;
      provides_responses = 0;
      last_addr_user = '1;
      bus2reg_user_obj = axi4_caliptra_uvm_user_extension::type_id::create("bus2reg_user_obj");
    endfunction

    function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
      axi4_caliptra_uvm_transfer transfer;
      axi4_caliptra_uvm_user_extension user_extension;
      uvm_reg_item reg_item;

      if (rw.kind != UVM_READ && rw.kind != UVM_WRITE) begin
        `uvm_fatal("AXI_RAL_KIND", "Caliptra AXI adapter supports single READ/WRITE register operations only")
        return null;
      end
      if (rw.n_bits != 32) begin
        `uvm_fatal("AXI_RAL_WIDTH", $sformatf("Caliptra AXI register adapter requires 32-bit operations, got %0d", rw.n_bits))
        return null;
      end
      if (rw.addr > 48'hffff_ffff_ffff) begin
        `uvm_fatal("AXI_RAL_ADDR", $sformatf("Register address 0x%0h exceeds the 48-bit AXI address width", rw.addr))
        return null;
      end

      transfer = axi4_caliptra_uvm_transfer::type_id::create("axi4_reg_transfer");
      transfer.write = (rw.kind == UVM_WRITE);
      transfer.addr = rw.addr;
      transfer.len = 0;
      transfer.size = 2;
      transfer.burst = 2'b01;
      transfer.id = 0;
      transfer.lock = 0;
      transfer.user = '1;
      transfer.write_data[0 +: 32] = rw.data[31:0];
      transfer.write_strb[0 +: 4] = rw.byte_en[3:0];

      reg_item = get_item();
      if (reg_item != null && reg_item.extension != null) begin
        if ($cast(user_extension, reg_item.extension))
          transfer.user = user_extension.get_addr_user();
        else
          `uvm_error("AXI_RAL_USER", "Register item extension is not axi4_caliptra_uvm_user_extension; using all-ones AxUSER")
      end
      return transfer;
    endfunction

    function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
      axi4_caliptra_uvm_transfer transfer;
      bit [1:0] response_code;

      if (!$cast(transfer, bus_item)) begin
        `uvm_fatal("AXI_RAL_BUS_ITEM", "AXI register adapter received a non-Caliptra transfer item")
        return;
      end

      rw.kind = transfer.write ? UVM_WRITE : UVM_READ;
      rw.addr = transfer.addr;
      rw.n_bits = 32;
      rw.byte_en = '0;
      if (transfer.write) begin
        rw.data = transfer.write_data[0 +: 32];
        rw.byte_en[3:0] = transfer.write_strb[0 +: 4];
        response_code = transfer.response;
      end else begin
        rw.data = transfer.read_data[0 +: 32];
        rw.byte_en[3:0] = 4'hf;
        response_code = transfer.read_response[0 +: 2];
      end
      rw.status = (transfer.success &&
                   (response_code == 2'b00 || response_code == 2'b01)) ?
                  UVM_IS_OK : UVM_NOT_OK;
      last_addr_user = transfer.user;
      bus2reg_user_obj.set_addr_user(last_addr_user);
    endfunction

    function bit [31:0] get_last_addr_user();
      return last_addr_user;
    endfunction
  endclass

`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
  class axi4_caliptra_aaxi_reg_adapter extends aaxi_uvm_mem_adapter;
    axi4_caliptra_uvm_user_extension bus2reg_user_obj;
    `uvm_object_utils(axi4_caliptra_aaxi_reg_adapter)

    function new(string name = "axi4_caliptra_aaxi_reg_adapter");
      super.new(name);
      bus2reg_user_obj = axi4_caliptra_uvm_user_extension::type_id::create("bus2reg_user_obj");
    endfunction

    function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
      uvm_sequence_item bus_item;
      aaxi_master_tr transfer;
      axi4_caliptra_uvm_user_extension user_extension;
      uvm_reg_item reg_item;
      bit [31:0] addr_user;

      bus_item = super.reg2bus(rw);
      if (!$cast(transfer, bus_item)) begin
        `uvm_fatal("AAXI_RAL_CAST", "AAXI base adapter returned a non-AAXI transaction")
        return null;
      end
      addr_user = '1;
      reg_item = get_item();
      if (reg_item != null && reg_item.extension != null) begin
        if ($cast(user_extension, reg_item.extension))
          addr_user = user_extension.get_addr_user();
        else
          `uvm_error("AAXI_RAL_USER", "Unexpected UVM register extension; using all-ones AxUSER")
      end
      transfer.awuser = addr_user;
      transfer.aruser = addr_user;
      return transfer;
    endfunction

    function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
      aaxi_master_tr transfer;
      if (!$cast(transfer, bus_item)) begin
        `uvm_fatal("AAXI_RAL_CAST", "AAXI USER adapter received a non-AAXI transaction")
        return;
      end
      super.bus2reg(bus_item, rw);
      bus2reg_user_obj.set_addr_user(transfer.is_write() ? transfer.awuser : transfer.aruser);
    endfunction
  endclass
`endif

  class axi4_caliptra_uvm_sequencer extends uvm_sequencer #(axi4_caliptra_uvm_transfer);
    `uvm_component_utils(axi4_caliptra_uvm_sequencer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  class axi4_caliptra_uvm_driver extends uvm_driver #(axi4_caliptra_uvm_transfer);
    virtual axi4_caliptra_master_cmd_if cmd_vif;
    `uvm_component_utils(axi4_caliptra_uvm_driver)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual axi4_caliptra_master_cmd_if)::get(
            this, "", "cmd_vif", cmd_vif))
        `uvm_fatal("AXI_CMD_VIF", "Missing axi4_caliptra_master_cmd_if config")
    endfunction

    task run_phase(uvm_phase phase);
      axi4_caliptra_uvm_transfer req;
      forever begin
        seq_item_port.get_next_item(req);
        wait (cmd_vif.ARESETn === 1'b1);
        cmd_vif.request_write = req.write;
        cmd_vif.request_addr = req.addr;
        cmd_vif.request_len = req.len;
        cmd_vif.request_size = req.size;
        cmd_vif.request_burst = req.burst;
        cmd_vif.request_id = req.id;
        cmd_vif.request_user = req.user;
        cmd_vif.request_lock = req.lock;
        cmd_vif.request_write_data = req.write_data;
        cmd_vif.request_write_strb = req.write_strb;
        cmd_vif.request_write_user = req.write_user;
        cmd_vif.request_valid = 1'b1;
        wait (cmd_vif.response_valid === 1'b1);
        req.success = cmd_vif.response_success;
        req.response = cmd_vif.response_code;
        req.response_user = cmd_vif.response_user;
        req.read_data = cmd_vif.response_read_data;
        req.read_user = cmd_vif.response_read_user;
        req.read_response = cmd_vif.response_read_code;
        cmd_vif.request_valid = 1'b0;
        wait (cmd_vif.response_valid === 1'b0);
        seq_item_port.item_done();
      end
    endtask
  endclass

  class axi4_caliptra_uvm_agent extends uvm_agent;
    axi4_caliptra_uvm_sequencer sequencer;
    axi4_caliptra_uvm_driver driver;
    axi4_caliptra_uvm_monitor monitor;
    uvm_analysis_port #(axi4_caliptra_transaction) ap;
    uvm_analysis_port #(axi4_caliptra_channel_transaction) channel_ap;
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
    uvm_analysis_port #(aaxi_master_tr) aaxi_ap;
    uvm_analysis_port #(aaxi_master_tr) ms_tx_AW_W_export;
    uvm_analysis_port #(aaxi_master_tr) ms_rx_rvalid_export;
    uvm_analysis_port #(aaxi_master_tr) write_done_export;
    uvm_analysis_port #(aaxi_master_tr) read_done_export;
`endif

    `uvm_component_utils(axi4_caliptra_uvm_agent)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
      channel_ap = new("channel_ap", this);
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
      aaxi_ap = new("aaxi_ap", this);
      ms_tx_AW_W_export = new("ms_tx_AW_W_export", this);
      ms_rx_rvalid_export = new("ms_rx_rvalid_export", this);
      write_done_export = new("write_done_export", this);
      read_done_export = new("read_done_export", this);
`endif
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      monitor = axi4_caliptra_uvm_monitor::type_id::create("monitor", this);
      if (is_active == UVM_ACTIVE) begin
        sequencer = axi4_caliptra_uvm_sequencer::type_id::create("sequencer", this);
        driver = axi4_caliptra_uvm_driver::type_id::create("driver", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      monitor.ap.connect(ap);
      monitor.channel_ap.connect(channel_ap);
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
      monitor.aaxi_ap.connect(aaxi_ap);
      monitor.ms_tx_AW_W_export.connect(ms_tx_AW_W_export);
      monitor.ms_rx_rvalid_export.connect(ms_rx_rvalid_export);
      monitor.write_done_export.connect(write_done_export);
      monitor.read_done_export.connect(read_done_export);
`endif
      if (is_active == UVM_ACTIVE)
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
  endclass

`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
  class axi4_caliptra_aaxi_driver extends uvm_driver #(aaxi_master_tr);
    virtual axi4_caliptra_master_cmd_if cmd_vif;
    virtual aaxi_intf ports;
    aaxi_cfg_info cfg_info;
    `uvm_component_utils(axi4_caliptra_aaxi_driver)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual axi4_caliptra_master_cmd_if)::get(
            this, "", "cmd_vif", cmd_vif))
        `uvm_fatal("AAXI_CMD_VIF", "Missing AXI compatibility command interface")
    endfunction

    task run_phase(uvm_phase phase);
      aaxi_master_tr req;
      int unsigned beat_count;
      bit [8191:0] write_data;
      bit [1023:0] write_strb;
      bit [8191:0] write_user;
      forever begin
        seq_item_port.get_next_item(req);
        beat_count = int'(req.len) + 1;
        if (req.is_write() && req.beatQ.size() != beat_count) begin
          `uvm_fatal("AAXI_WRITE_BEATS", $sformatf("AAXI write LEN requires %0d beats, got %0d", beat_count, req.beatQ.size()))
          seq_item_port.item_done();
          continue;
        end
        write_data = '0;
        write_strb = '0;
        write_user = '0;
        for (int beat = 0; beat < beat_count; beat++) begin
          if (req.is_write()) begin
            write_data[beat*32 +: 32] = req.beatQ[beat];
            write_strb[beat*4 +: 4] = (req.strbQ.size() > beat) ? req.strbQ[beat] : 4'hf;
            write_user[beat*32 +: 32] = (req.beat_userQ.size() > beat) ? req.beat_userQ[beat] : 32'b0;
          end
        end

        if (ports != null)
          wait (ports.ARESETn === 1'b1);
        wait (cmd_vif.ARESETn === 1'b1);
        cmd_vif.request_write = req.is_write();
        cmd_vif.request_addr = req.addr;
        cmd_vif.request_len = req.len;
        cmd_vif.request_size = req.size;
        cmd_vif.request_burst = req.burst;
        cmd_vif.request_id = req.id;
        cmd_vif.request_user = req.is_write() ? req.awuser : req.aruser;
        cmd_vif.request_lock = req.lock;
        cmd_vif.request_write_data = write_data;
        cmd_vif.request_write_strb = write_strb;
        cmd_vif.request_write_user = write_user;
        cmd_vif.request_valid = 1'b1;
        wait (cmd_vif.response_valid === 1'b1);
        req.transport_success = cmd_vif.response_success;
        req.response_id = cmd_vif.response_id;
        req.resp = cmd_vif.response_code;
        req.buser = cmd_vif.response_user;
        if (!req.is_write()) begin
          req.beatQ.delete();
          req.respQ.delete();
          req.beat_userQ.delete();
          req.lastQ.delete();
          for (int beat = 0; beat < beat_count; beat++) begin
            req.beatQ.push_back(cmd_vif.response_read_data[beat*32 +: 32]);
            req.respQ.push_back(cmd_vif.response_read_code[beat*2 +: 2]);
            req.beat_userQ.push_back(cmd_vif.response_read_user[beat*32 +: 32]);
            req.lastQ.push_back(beat == req.len);
          end
          if (req.beatQ.size() != 0) req.data = req.beatQ[0];
          if (req.respQ.size() != 0) req.resp = req.respQ[0];
        end
        cmd_vif.request_valid = 1'b0;
        wait (cmd_vif.response_valid === 1'b0);
        seq_item_port.item_done();
      end
    endtask
  endclass

  class axi4_caliptra_aaxi_uvm_agent extends uvm_agent;
    axi4_caliptra_uvm_monitor monitor;
    aaxi_uvm_sequencer sequencer;
    axi4_caliptra_aaxi_driver driver;
    uvm_analysis_port #(axi4_caliptra_transaction) ap;
    uvm_analysis_port #(axi4_caliptra_channel_transaction) channel_ap;
    uvm_analysis_port #(aaxi_master_tr) aaxi_ap;
    uvm_analysis_port #(aaxi_master_tr) ms_tx_AW_W_export;
    uvm_analysis_port #(aaxi_master_tr) ms_rx_rvalid_export;
    uvm_analysis_port #(aaxi_master_tr) write_done_export;
    uvm_analysis_port #(aaxi_master_tr) read_done_export;

    `uvm_component_utils(axi4_caliptra_aaxi_uvm_agent)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
      channel_ap = new("channel_ap", this);
      aaxi_ap = new("aaxi_ap", this);
      ms_tx_AW_W_export = new("ms_tx_AW_W_export", this);
      ms_rx_rvalid_export = new("ms_rx_rvalid_export", this);
      write_done_export = new("write_done_export", this);
      read_done_export = new("read_done_export", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      monitor = axi4_caliptra_uvm_monitor::type_id::create("monitor", this);
      if (is_active == UVM_ACTIVE) begin
        sequencer = aaxi_uvm_sequencer::type_id::create("sequencer", this);
        driver = axi4_caliptra_aaxi_driver::type_id::create("driver", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      monitor.ap.connect(ap);
      monitor.channel_ap.connect(channel_ap);
      monitor.aaxi_ap.connect(aaxi_ap);
      monitor.ms_tx_AW_W_export.connect(ms_tx_AW_W_export);
      monitor.ms_rx_rvalid_export.connect(ms_rx_rvalid_export);
      monitor.write_done_export.connect(write_done_export);
      monitor.read_done_export.connect(read_done_export);
      if (is_active == UVM_ACTIVE)
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
  endclass
`endif

  class axi4_caliptra_uvm_smoke_sequence extends uvm_sequence #(axi4_caliptra_uvm_transfer);
    `uvm_object_utils(axi4_caliptra_uvm_smoke_sequence)

    function new(string name = "axi4_caliptra_uvm_smoke_sequence");
      super.new(name);
    endfunction

    task body();
      axi4_caliptra_uvm_transfer req;

      req = axi4_caliptra_uvm_transfer::type_id::create("write_req");
      start_item(req);
      req.write = 1;
      req.addr = CALIPTRA_DMA_SRAM_BASE + 48'h20;
      req.len = 1;
      req.size = 2;
      req.burst = 2'b01;
      req.id = 8'h31;
      req.user = 32'h1122_3344;
      // Keep this burst non-exclusive; exclusive reservation behavior has its
      // own target regression and requires a matching exclusive read first.
      req.lock = 0;
      req.write_data[0 +: 32] = 32'ha5a5_5a5a;
      req.write_data[32 +: 32] = 32'h1357_9bdf;
      req.write_strb[0 +: 4] = 4'hf;
      req.write_strb[4 +: 4] = 4'hf;
      req.write_user[0 +: 32] = 32'h5566_7788;
      req.write_user[32 +: 32] = 32'h1020_3040;
      finish_item(req);
      if (!req.success || req.response != 2'b00 || req.response_user != 32'h1122_3344)
        `uvm_fatal("AXI_WRITE", "UVM-driven AXI write did not complete as expected")

      req = axi4_caliptra_uvm_transfer::type_id::create("read_req");
      start_item(req);
      req.write = 0;
      req.addr = CALIPTRA_DMA_SRAM_BASE + 48'h20;
      req.len = 1;
      req.size = 2;
      req.burst = 2'b01;
      req.id = 8'h42;
      req.user = 32'h89ab_cdef;
      req.lock = 0;
      finish_item(req);
      if (!req.success || req.read_data[0 +: 32] != 32'ha5a5_5a5a ||
          req.read_data[32 +: 32] != 32'h1357_9bdf ||
          req.read_user[0 +: 64] != {32'h89ab_cdef, 32'h89ab_cdef} ||
          req.read_response[0 +: 4] != 4'b0000)
        `uvm_fatal("AXI_READ", "UVM-driven AXI read did not return the written data")
    endtask
  endclass

  class axi4_caliptra_uvm_exclusive_sequence extends uvm_sequence #(axi4_caliptra_uvm_transfer);
    `uvm_object_utils(axi4_caliptra_uvm_exclusive_sequence)

    function new(string name = "axi4_caliptra_uvm_exclusive_sequence");
      super.new(name);
    endfunction

    task body();
      axi4_caliptra_uvm_transfer req;

      req = axi4_caliptra_uvm_transfer::type_id::create("exclusive_read_req");
      start_item(req);
      req.write = 0;
      req.addr = CALIPTRA_DMA_SRAM_BASE + 48'h60;
      req.len = 0;
      req.size = 2;
      req.burst = 2'b01;
      req.id = 8'h71;
      req.user = 32'h71a0_0001;
      req.lock = 1;
      finish_item(req);
      if (!req.success || req.read_response[0 +: 2] != 2'b01 ||
          req.read_data[0 +: 32] != 0)
        `uvm_fatal("AXI_EXCL_READ", "UVM exclusive read did not return successful EXOKAY")

      req = axi4_caliptra_uvm_transfer::type_id::create("exclusive_write_req");
      start_item(req);
      req.write = 1;
      req.addr = CALIPTRA_DMA_SRAM_BASE + 48'h60;
      req.len = 0;
      req.size = 2;
      req.burst = 2'b01;
      req.id = 8'h71;
      req.user = 32'h71a0_0001;
      req.lock = 1;
      req.write_data[0 +: 32] = 32'hc0de_6001;
      req.write_strb[0 +: 4] = 4'hf;
      finish_item(req);
      if (!req.success || req.response != 2'b01)
        `uvm_fatal("AXI_EXCL_WRITE", "Matching UVM exclusive write did not return successful EXOKAY")

      req = axi4_caliptra_uvm_transfer::type_id::create("exclusive_readback_req");
      start_item(req);
      req.write = 0;
      req.addr = CALIPTRA_DMA_SRAM_BASE + 48'h60;
      req.len = 0;
      req.size = 2;
      req.burst = 2'b01;
      req.id = 8'h72;
      req.user = 32'h72a0_0002;
      req.lock = 0;
      finish_item(req);
      if (!req.success || req.read_response[0 +: 2] != 2'b00 ||
          req.read_data[0 +: 32] != 32'hc0de_6001)
        `uvm_fatal("AXI_EXCL_READBACK", "UVM exclusive write data did not read back")

      req = axi4_caliptra_uvm_transfer::type_id::create("invalidated_exclusive_read_req");
      start_item(req);
      req.write = 0;
      req.addr = CALIPTRA_DMA_SRAM_BASE + 48'h60;
      req.len = 0;
      req.size = 2;
      req.burst = 2'b01;
      req.id = 8'h73;
      req.user = 32'h73a0_0003;
      req.lock = 1;
      finish_item(req);
      if (!req.success || req.read_response[0 +: 2] != 2'b01 ||
          req.read_data[0 +: 32] != 32'hc0de_6001)
        `uvm_fatal("AXI_EXCL_INVALIDATE_READ", "Second exclusive read did not return EXOKAY")

      req = axi4_caliptra_uvm_transfer::type_id::create("reservation_invalidating_write_req");
      start_item(req);
      req.write = 1;
      req.addr = CALIPTRA_DMA_SRAM_BASE + 48'h60;
      req.len = 0;
      req.size = 2;
      req.burst = 2'b01;
      req.id = 8'h74;
      req.user = 32'h74a0_0004;
      req.lock = 0;
      req.write_data[0 +: 32] = 32'hc0de_6002;
      req.write_strb[0 +: 4] = 4'hf;
      finish_item(req);
      if (!req.success || req.response != 2'b00)
        `uvm_fatal("AXI_EXCL_INVALIDATE_WRITE", "Intervening ordinary write failed")

      req = axi4_caliptra_uvm_transfer::type_id::create("failed_exclusive_write_req");
      start_item(req);
      req.write = 1;
      req.addr = CALIPTRA_DMA_SRAM_BASE + 48'h60;
      req.len = 0;
      req.size = 2;
      req.burst = 2'b01;
      req.id = 8'h73;
      req.user = 32'h73a0_0003;
      req.lock = 1;
      req.write_data[0 +: 32] = 32'hc0de_6003;
      req.write_strb[0 +: 4] = 4'hf;
      finish_item(req);
      if (!req.success || req.response != 2'b00)
        `uvm_fatal("AXI_EXCL_FAILED_WRITE", "Invalidated exclusive write did not return OKAY")

      req = axi4_caliptra_uvm_transfer::type_id::create("invalidated_exclusive_readback_req");
      start_item(req);
      req.write = 0;
      req.addr = CALIPTRA_DMA_SRAM_BASE + 48'h60;
      req.len = 0;
      req.size = 2;
      req.burst = 2'b01;
      req.id = 8'h75;
      req.user = 32'h75a0_0005;
      req.lock = 0;
      finish_item(req);
      if (!req.success || req.read_response[0 +: 2] != 2'b00 ||
          req.read_data[0 +: 32] != 32'hc0de_6002)
        `uvm_fatal("AXI_EXCL_FAILED_READBACK", "Failed exclusive store changed the intervening write")
    endtask
  endclass

  class axi4_caliptra_fifo_uvm_sequence extends uvm_sequence #(axi4_caliptra_uvm_transfer);
    `uvm_object_utils(axi4_caliptra_fifo_uvm_sequence)

    function new(string name = "axi4_caliptra_fifo_uvm_sequence");
      super.new(name);
    endfunction

    task body();
      axi4_caliptra_uvm_transfer req;

      req = axi4_caliptra_uvm_transfer::type_id::create("fifo_write_req");
      start_item(req);
      req.write = 1;
      req.addr = CALIPTRA_DMA_FIFO_BASE;
      req.len = 1;
      req.size = 2;
      req.burst = 2'b00;
      req.id = 8'h51;
      req.user = 32'h5a5a_0001;
      req.write_data[0 +: 32] = 32'hc001_0001;
      req.write_data[32 +: 32] = 32'hc001_0002;
      req.write_strb[0 +: 4] = 4'hf;
      req.write_strb[4 +: 4] = 4'hf;
      req.write_user[0 +: 32] = 32'h5a5a_1001;
      req.write_user[32 +: 32] = 32'h5a5a_1002;
      finish_item(req);
      if (!req.success || req.response != 2'b00 || req.response_user != 32'h5a5a_0001)
        `uvm_fatal("AXI_FIFO_WRITE", "UVM FIFO write did not complete as expected")

      req = axi4_caliptra_uvm_transfer::type_id::create("fifo_read_req");
      start_item(req);
      req.write = 0;
      req.addr = CALIPTRA_DMA_FIFO_BASE;
      req.len = 1;
      req.size = 2;
      req.burst = 2'b00;
      req.id = 8'h52;
      req.user = 32'ha5a5_0002;
      finish_item(req);
      if (!req.success || req.read_data[0 +: 32] != 32'hc001_0001 ||
          req.read_data[32 +: 32] != 32'hc001_0002 ||
          req.read_user[0 +: 64] != {32'ha5a5_0002, 32'ha5a5_0002} ||
          req.read_response[0 +: 4] != 4'b0000)
        `uvm_fatal("AXI_FIFO_READ", "UVM FIFO read did not return the queued words")
    endtask
  endclass

  class axi4_caliptra_full_range_uvm_sequence extends uvm_sequence #(axi4_caliptra_uvm_transfer);
    `uvm_object_utils(axi4_caliptra_full_range_uvm_sequence)

    function new(string name = "axi4_caliptra_full_range_uvm_sequence");
      super.new(name);
    endfunction

    task body();
      axi4_caliptra_uvm_transfer req;
      req = axi4_caliptra_uvm_transfer::type_id::create("full_range_write");
      start_item(req);
      req.write = 1;
      req.addr = CALIPTRA_DMA_SRAM_BASE + 48'h1000;
      req.len = 8'hff;
      req.size = 2;
      req.burst = 2'b01;
      req.id = 8'h60;
      req.user = 32'hcafe_0001;
      for (int beat = 0; beat < 256; beat++) begin
        req.write_data[beat*32 +: 32] = 32'hd00d_0000 ^ beat;
        req.write_strb[beat*4 +: 4] = 4'hf;
        req.write_user[beat*32 +: 32] = 32'hb055_0000 | beat;
      end
      finish_item(req);
      if (!req.success || req.response != 2'b00 || req.response_user != 32'hcafe_0001)
        `uvm_fatal("AXI_FULL_WRITE", "256-beat UVM AXI write did not complete successfully")

      req = axi4_caliptra_uvm_transfer::type_id::create("full_range_read");
      start_item(req);
      req.write = 0;
      req.addr = CALIPTRA_DMA_SRAM_BASE + 48'h1000;
      req.len = 8'hff;
      req.size = 2;
      req.burst = 2'b01;
      req.id = 8'h61;
      req.user = 32'hcaf0_0002;
      finish_item(req);
      if (!req.success)
        `uvm_fatal("AXI_FULL_READ", "256-beat UVM AXI read did not complete successfully")
      for (int beat = 0; beat < 256; beat++) begin
        if (req.read_data[beat*32 +: 32] != (32'hd00d_0000 ^ beat) ||
            req.read_user[beat*32 +: 32] != 32'hcaf0_0002 ||
            req.read_response[beat*2 +: 2] != 2'b00)
          `uvm_fatal("AXI_FULL_READ", $sformatf("Bad 256-beat read response at beat %0d", beat))
      end
    endtask
  endclass
endpackage
