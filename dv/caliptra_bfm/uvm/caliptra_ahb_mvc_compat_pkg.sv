// SPDX-License-Identifier: Apache-2.0
// Clean-room lower-bound types for the AHB fields consumed by Caliptra UVMF.
// Exclude these fallback packages when compiling with licensed MVC/QVIP.
`ifndef CALIPTRA_BFM_EXTERNAL_MVC
package mvc_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  class mvc_sequence_item_base extends uvm_sequence_item;
    `uvm_object_utils(mvc_sequence_item_base)

    function new(string name = "mvc_sequence_item_base");
      super.new(name);
    endfunction
  endclass

  class mvc_sequencer extends uvm_sequencer #(mvc_sequence_item_base);
    `uvm_component_utils(mvc_sequencer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass
endpackage
`endif

`ifndef CALIPTRA_BFM_EXTERNAL_AHB_QVIP
package mgc_ahb_v2_0_pkg;
  import uvm_pkg::*;
  import mvc_pkg::*;
  `include "uvm_macros.svh"

  // HSIZE encodes the transfer size as log2(bytes), as used by the
  // generated SoC-IFC predictor and the native Caliptra AHB adapter.
  typedef enum bit [2:0] {
    AHB_BITS_8    = 3'd0,
    AHB_BITS_16   = 3'd1,
    AHB_BITS_32   = 3'd2,
    AHB_BITS_64   = 3'd3,
    AHB_BITS_128  = 3'd4,
    AHB_BITS_256  = 3'd5,
    AHB_BITS_512  = 3'd6,
    AHB_BITS_1024 = 3'd7
  } ahb_transfer_size_e;

  typedef enum bit {
    AHB_READ  = 1'b0,
    AHB_WRITE = 1'b1
  } ahb_rnw_e;
  localparam bit [1:0] AHB_OKAY = 2'b00;
  localparam bit [1:0] AHB_ERROR = 2'b01;

  // Icarus needs copy/compare casts to target a non-parameterized base class.
  virtual class ahb_master_burst_transfer_base extends mvc_sequence_item_base;
    function new(string name = "ahb_master_burst_transfer_base");
      super.new(name);
    endfunction

    virtual function string profile_key(); return ""; endfunction
    virtual function bit transfer_rnw(); return 0; endfunction
    virtual function longint unsigned transfer_address(); return 0; endfunction
    virtual function bit [2:0] transfer_size(); return 0; endfunction
    virtual function int transfer_data_count(); return 0; endfunction
    virtual function longint unsigned transfer_data(int index); return 0; endfunction
    virtual function int transfer_response_count(); return 0; endfunction
    virtual function bit [1:0] transfer_response(int index); return 0; endfunction
  endclass

  class ahb_master_burst_transfer #(
    parameter int NUM_MASTERS = 1,
    parameter int MASTER_BITS = 1,
    parameter int NUM_SLAVES = 1,
    parameter int ADDRESS_WIDTH = 32,
    parameter int WDATA_WIDTH = 64,
    parameter int RDATA_WIDTH = 64
  ) extends ahb_master_burst_transfer_base;
    localparam int DATA_WIDTH = WDATA_WIDTH > RDATA_WIDTH ? WDATA_WIDTH : RDATA_WIDTH;

    bit RnW;
    bit [ADDRESS_WIDTH-1:0] address;
    bit [2:0] size;
    bit [DATA_WIDTH-1:0] data[$];
    bit [1:0] resp[$];

    `uvm_object_param_utils(ahb_master_burst_transfer #(NUM_MASTERS, MASTER_BITS,
                                                        NUM_SLAVES, ADDRESS_WIDTH,
                                                        WDATA_WIDTH, RDATA_WIDTH))

    function new(string name = "ahb_master_burst_transfer");
      super.new(name);
    endfunction

    virtual function string profile_key();
      return $sformatf("%0d/%0d/%0d/%0d/%0d/%0d", NUM_MASTERS, MASTER_BITS,
                       NUM_SLAVES, ADDRESS_WIDTH, WDATA_WIDTH, RDATA_WIDTH);
    endfunction

    virtual function bit transfer_rnw(); return RnW; endfunction
    virtual function longint unsigned transfer_address(); return address; endfunction
    virtual function bit [2:0] transfer_size(); return size; endfunction
    virtual function int transfer_data_count(); return data.size(); endfunction
    virtual function longint unsigned transfer_data(int index); return data[index]; endfunction
    virtual function int transfer_response_count(); return resp.size(); endfunction
    virtual function bit [1:0] transfer_response(int index); return resp[index]; endfunction

    function void do_copy(uvm_object rhs);
      ahb_master_burst_transfer_base source;
      if (!$cast(source, rhs) || source.profile_key() != profile_key()) begin
        `uvm_error("AHB_COPY", "Cannot copy an incompatible AHB MVC transfer")
        return;
      end
      super.do_copy(rhs);
      RnW = source.transfer_rnw();
      address = ADDRESS_WIDTH'(source.transfer_address());
      size = source.transfer_size();
      data.delete();
      for (int i = 0; i < source.transfer_data_count(); i++)
        data.push_back(DATA_WIDTH'(source.transfer_data(i)));
      resp.delete();
      for (int i = 0; i < source.transfer_response_count(); i++)
        resp.push_back(source.transfer_response(i));
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      ahb_master_burst_transfer_base other;
      if (!$cast(other, rhs) || !super.do_compare(rhs, comparer) ||
          other.profile_key() != profile_key()) return 0;
      if (RnW != other.transfer_rnw() || address != other.transfer_address() ||
          size != other.transfer_size() || data.size() != other.transfer_data_count() ||
          resp.size() != other.transfer_response_count())
        return 0;
      foreach (data[i])
        if (data[i] != other.transfer_data(i)) return 0;
      foreach (resp[i])
        if (resp[i] != other.transfer_response(i)) return 0;
      return 1;
    endfunction

    function string convert2string();
      if (data.size() == 0 || resp.size() == 0)
        return $sformatf("%s address=%h size=%0d beats=%0d",
                         RnW ? "WRITE" : "READ", address, size, data.size());
      return $sformatf("%s address=%h size=%0d beats=%0d data0=%h resp0=%h",
                       RnW ? "WRITE" : "READ", address, size, data.size(),
                       data[0], resp[0]);
    endfunction
  endclass
endpackage
`endif
