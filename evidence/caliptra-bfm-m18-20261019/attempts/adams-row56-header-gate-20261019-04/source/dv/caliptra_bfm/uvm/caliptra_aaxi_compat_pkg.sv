// SPDX-License-Identifier: Apache-2.0
// Clean-room lower-bound aaxi_master_tr surface observed in Caliptra consumers.
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
package aaxi_uvm_pkg;
  import uvm_pkg::*;
  import aaxi_pkg::*;
  `include "uvm_macros.svh"

  typedef enum int unsigned {AAXI_READ = 0, AAXI_WRITE = 1} aaxi_kind_e;

  class aaxi_master_tr extends uvm_sequence_item;
    int unsigned kind = AAXI_READ;
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
    bit transport_success = 1'b1;
    bit protocol_error;
    bit [3:0] protocol_status;
    bit [31:0] beatQ[$];
    bit [3:0] strbQ[$];
    bit [31:0] beat_userQ[$];
    bit [1:0] respQ[$];
    bit lastQ[$];

    `uvm_object_utils(aaxi_master_tr)

    function new(string name = "aaxi_master_tr");
      super.new(name);
    endfunction

    function bit is_read();
      return kind == AAXI_READ;
    endfunction

    function bit is_write();
      return kind == AAXI_WRITE;
    endfunction

    function void copy_from(aaxi_master_tr source);
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
      transport_success = source.transport_success;
      protocol_error = source.protocol_error;
      protocol_status = source.protocol_status;
      beatQ = source.beatQ;
      strbQ = source.strbQ;
      beat_userQ = source.beat_userQ;
      respQ = source.respQ;
      lastQ = source.lastQ;
    endfunction

    function void do_copy(uvm_object rhs);
      aaxi_master_tr source;
      if (!$cast(source, rhs)) return;
      super.do_copy(rhs);
      copy_from(source);
    endfunction

    function aaxi_master_tr copy();
      aaxi_master_tr result;
      result = aaxi_master_tr::type_id::create("copy");
      result.copy_from(this);
      return result;
    endfunction

    function bit same_fields(input aaxi_master_tr other, inout string diff,
                             input bit compare_response_id);
      diff = "";
      if (kind != other.kind) diff = "kind";
      else if (addr != other.addr) diff = "addr";
      else if (id != other.id) diff = "id";
      else if (len != other.len) diff = "len";
      else if (size != other.size) diff = "size";
      else if (burst != other.burst) diff = "burst";
      else if (lock != other.lock) diff = "lock";
      else if (awuser != other.awuser) diff = "awuser";
      else if (aruser != other.aruser) diff = "aruser";
      // Read responses are compared through beatQ; the scalar remains request-phase data.
      else if (kind == AAXI_WRITE && data != other.data) diff = "data";
      else if (resp != other.resp) diff = "resp";
      else if (compare_response_id && response_id != other.response_id) diff = "response_id";
      else if (buser != other.buser) diff = "buser";
      else if (transport_success != other.transport_success) diff = "transport_success";
      else if (protocol_error != other.protocol_error) diff = "protocol_error";
      else if (protocol_status != other.protocol_status) diff = "protocol_status";
      else if (beatQ.size() != other.beatQ.size()) diff = "beatQ.size";
      else if (strbQ.size() != other.strbQ.size()) diff = "strbQ.size";
      else if (beat_userQ.size() != other.beat_userQ.size()) diff = "beat_userQ.size";
      else if (respQ.size() != other.respQ.size()) diff = "respQ.size";
      else if (lastQ.size() != other.lastQ.size()) diff = "lastQ.size";
      if (diff != "") return 0;
      foreach (beatQ[i])
        if (beatQ[i] != other.beatQ[i]) begin diff = $sformatf("beatQ[%0d]", i); return 0; end
      foreach (strbQ[i])
        if (strbQ[i] != other.strbQ[i]) begin diff = $sformatf("strbQ[%0d]", i); return 0; end
      foreach (beat_userQ[i])
        if (beat_userQ[i] != other.beat_userQ[i]) begin diff = $sformatf("beat_userQ[%0d]", i); return 0; end
      foreach (respQ[i])
        if (respQ[i] != other.respQ[i]) begin diff = $sformatf("respQ[%0d]", i); return 0; end
      foreach (lastQ[i])
        if (lastQ[i] != other.lastQ[i]) begin diff = $sformatf("lastQ[%0d]", i); return 0; end
      return 1;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      aaxi_master_tr other;
      string diff;
      if (!$cast(other, rhs) || !super.do_compare(rhs, comparer)) return 0;
      return same_fields(other, diff, 1'b1);
    endfunction

    function bit compare(aaxi_master_tr expected, inout string diff,
                         int unsigned compare_kind);
      if (kind != compare_kind) begin
        diff = "kind";
        return 0;
      end
      // Generated prediction is published from the request phase. The
      // completed bus monitor learns the response ID later, so that field is
      // intentionally excluded from prediction-vs-completion comparison.
      if (!same_fields(expected, diff, 1'b0)) begin
        `uvm_info("AAXI_COMPARE",
                  $sformatf("Mismatch in %s: actual {%s}, expected {%s}",
                            diff, convert2string(), expected.convert2string()),
                  UVM_LOW)
        return 0;
      end
      return 1;
    endfunction

    function string sprint(int verbosity, string scope);
      return $sformatf("%s %s", scope, convert2string());
    endfunction

    function void do_print(uvm_printer printer);
      super.do_print(printer);
      printer.print_string("kind", kind == AAXI_WRITE ? "AAXI_WRITE" : "AAXI_READ");
      printer.print_field_int("addr", addr, 48, UVM_HEX);
      printer.print_field_int("id", id, 8, UVM_HEX);
      printer.print_field_int("len", len, 8, UVM_DEC);
      printer.print_field_int("size", size, 3, UVM_DEC);
      printer.print_field_int("burst", burst, 2, UVM_HEX);
      printer.print_field_int("resp", resp, 2, UVM_HEX);
      printer.print_field_int("transport_success", transport_success, 1, UVM_BIN);
      printer.print_string("beat_count", $sformatf("%0d", beatQ.size()));
    endfunction

    function string convert2string();
      if (beatQ.size() == 0)
        return $sformatf("%s id=%02h addr=%012h beats=0 resp=%0h",
                         kind == AAXI_WRITE ? "AAXI_WRITE" : "AAXI_READ", id, addr, resp);
      return $sformatf("%s id=%02h addr=%012h beats=%0d data=%08h resp=%0h",
                       kind == AAXI_WRITE ? "AAXI_WRITE" : "AAXI_READ",
                       id, addr, beatQ.size(), beatQ[0], resp);
    endfunction
  endclass

  class aaxi_uvm_mem_adapter extends uvm_reg_adapter;
    `uvm_object_utils(aaxi_uvm_mem_adapter)

    function new(string name = "aaxi_uvm_mem_adapter");
      super.new(name);
      supports_byte_enable = 1;
      provides_responses = 0;
    endfunction

    function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
      aaxi_master_tr transfer;
      if (rw.kind != UVM_READ && rw.kind != UVM_WRITE) begin
        `uvm_fatal("AAXI_RAL_KIND", "Fallback AXI register adapter supports READ/WRITE only")
        return null;
      end
      if (rw.n_bits != 32) begin
        `uvm_fatal("AAXI_RAL_WIDTH", $sformatf("Fallback AXI register adapter requires 32-bit operations, got %0d", rw.n_bits))
        return null;
      end
      if (rw.addr > 48'hffff_ffff_ffff) begin
        `uvm_fatal("AAXI_RAL_ADDR", $sformatf("Register address 0x%0h exceeds the 48-bit AXI address width", rw.addr))
        return null;
      end

      transfer = new("aaxi_reg_transfer");
      transfer.kind = (rw.kind == UVM_WRITE) ? AAXI_WRITE : AAXI_READ;
      transfer.addr = rw.addr;
      transfer.id = 0;
      transfer.len = 0;
      transfer.size = 2;
      transfer.burst = 2'b01;
      transfer.lock = 0;
      transfer.awuser = '1;
      transfer.aruser = '1;
      transfer.beatQ.delete();
      transfer.strbQ.delete();
      transfer.beat_userQ.delete();
      transfer.respQ.delete();
      transfer.lastQ.delete();
      if (rw.kind == UVM_WRITE) begin
        transfer.beatQ.push_back(rw.data[31:0]);
        transfer.strbQ.push_back(rw.byte_en[3:0]);
        transfer.beat_userQ.push_back('0);
        transfer.lastQ.push_back(1'b1);
      end
      return transfer;
    endfunction

    function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
      aaxi_master_tr transfer;
      bit [1:0] response_code;
      if (!$cast(transfer, bus_item)) begin
        `uvm_fatal("AAXI_RAL_BUS_ITEM", "Fallback AXI register adapter received a non-AAXI item")
        return;
      end
      rw.kind = transfer.is_write() ? UVM_WRITE : UVM_READ;
      rw.addr = transfer.addr;
      rw.n_bits = 32;
      rw.data = (transfer.beatQ.size() == 0) ? '0 : transfer.beatQ[0];
      rw.byte_en = '0;
      if (transfer.is_write()) begin
        if (transfer.strbQ.size() != 0) rw.byte_en[3:0] = transfer.strbQ[0];
        response_code = transfer.resp;
      end else begin
        rw.byte_en[3:0] = 4'hf;
        response_code = transfer.respQ.size() == 0 ? transfer.resp : transfer.respQ[0];
      end
      rw.status = (transfer.transport_success && !transfer.protocol_error &&
                   (response_code == 2'b00 || response_code == 2'b01)) ?
                  UVM_IS_OK : UVM_NOT_OK;
    endfunction
  endclass

  class aaxi_uvm_reg_predictor #(type BUSTYPE = aaxi_master_tr)
    extends uvm_reg_predictor #(BUSTYPE);
    uvm_analysis_export #(BUSTYPE) bus_item_write_export;
    uvm_analysis_export #(BUSTYPE) bus_item_read_export;

    `uvm_component_param_utils(aaxi_uvm_reg_predictor #(BUSTYPE))

    function new(string name, uvm_component parent);
      super.new(name, parent);
      bus_item_write_export = new("bus_item_write_export", this);
      bus_item_read_export = new("bus_item_read_export", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      bus_item_write_export.connect(this.bus_in);
      bus_item_read_export.connect(this.bus_in);
    endfunction
  endclass

  class aaxi_uvm_sequencer extends uvm_sequencer #(aaxi_master_tr);
    `uvm_component_utils(aaxi_uvm_sequencer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  // The generated HDL top stores its interface handle in this container.
  class aaxi_uvm_container;
    virtual aaxi_intf ports;
  endclass

  // Caliptra's generated SoC-IFC environment assigns these fields directly
  // during connect_phase. Keep only the fields observed in that consumer.
  class aaxi_cfg_info extends uvm_object;
    int unsigned data_bus_bytes = 4;
    bit uvm_resp = 1;
    int unsigned total_outstanding_depth = 1;
    int unsigned id_outstanding_depth = 1;
    bit opt_awuser_enable = 1;
    bit opt_wuser_enable = 1;
    bit opt_buser_enable = 1;
    bit opt_aruser_enable = 1;
    bit opt_ruser_enable = 1;
    bit passive_mode;
    bit [63:0] base_address[1];
    bit [63:0] limit_address[1];

    `uvm_object_utils(aaxi_cfg_info)

    function new(string name = "aaxi_cfg_info");
      super.new(name);
      base_address[0] = '0;
      limit_address[0] = '1;
    endfunction
  endclass
endpackage
`endif
