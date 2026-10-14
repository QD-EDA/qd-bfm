// SPDX-License-Identifier: Apache-2.0
// Transaction-level driver for Caliptra's PCRVault client pins.
//
// pv_read is a combinational lookup request. pv_write.write_en commits one
// word on the next rising edge. The response records are combinational.
module pv_caliptra_master
  import pv_defines_pkg::*;
#(
  parameter integer READ_INDEX = 0,
  parameter integer WRITE_INDEX = 0
) (
  input wire clk,
  input wire rst_n,
  output pv_read_t [PV_NUM_READ-1:0] pv_read,
  input pv_rd_resp_t [PV_NUM_READ-1:0] pv_rd_resp,
  output pv_write_t [PV_NUM_WRITE-1:0] pv_write,
  input pv_wr_resp_t [PV_NUM_WRITE-1:0] pv_wr_resp
);
  reg read_busy;
  reg write_busy;

  initial begin
    if ((READ_INDEX < 0) || (READ_INDEX >= PV_NUM_READ))
      $fatal(1, "READ_INDEX is outside PV_NUM_READ");
    if ((WRITE_INDEX < 0) || (WRITE_INDEX >= PV_NUM_WRITE))
      $fatal(1, "WRITE_INDEX is outside PV_NUM_WRITE");
    pv_read = '0;
    pv_write = '0;
    read_busy = 1'b0;
    write_busy = 1'b0;
  end

  always @(negedge rst_n) begin
    pv_read = '0;
    pv_write = '0;
  end

  task automatic write_one(
    input [PV_ENTRY_ADDR_W-1:0] entry,
    input [PV_ENTRY_SIZE_WIDTH-1:0] offset,
    input [PV_DATA_W-1:0] data,
    output reg request_ok,
    output reg success,
    output reg response_error
  );
    begin : write_body
      request_ok = 1'b0;
      success = 1'b0;
      response_error = 1'b0;

      if (write_busy || (rst_n !== 1'b1) || (^entry === 1'bx) ||
          (^offset === 1'bx) || (^data === 1'bx) ||
          (entry >= PV_NUM_PCR) || (offset >= PV_NUM_DWORDS)) begin
        response_error = 1'b1;
        disable write_body;
      end

      write_busy = 1'b1;
      request_ok = 1'b1;
      @(negedge clk or negedge rst_n);
      if (rst_n !== 1'b1) begin
        response_error = 1'b1;
        request_ok = 1'b0;
        write_busy = 1'b0;
        disable write_body;
      end

      pv_write[WRITE_INDEX].write_en = 1'b1;
      pv_write[WRITE_INDEX].write_entry = entry;
      pv_write[WRITE_INDEX].write_offset = offset;
      pv_write[WRITE_INDEX].write_data = data;

      @(posedge clk or negedge rst_n);
      if (rst_n !== 1'b1) begin
        response_error = 1'b1;
        request_ok = 1'b0;
        write_busy = 1'b0;
        disable write_body;
      end else if (pv_wr_resp[WRITE_INDEX].error !== 1'b0) begin
        response_error = 1'b1;
      end else begin
        success = 1'b1;
      end

      @(negedge clk or negedge rst_n);
      pv_write[WRITE_INDEX] = '0;
      write_busy = 1'b0;
    end
  endtask

  task automatic read_one(
    input [PV_ENTRY_ADDR_W-1:0] entry,
    input [PV_ENTRY_SIZE_WIDTH-1:0] offset,
    output reg request_ok,
    output reg success,
    output reg response_error,
    output reg last,
    output reg [PV_DATA_W-1:0] data
  );
    begin : read_body
      request_ok = 1'b0;
      success = 1'b0;
      response_error = 1'b0;
      last = 1'b0;
      data = '0;

      if (read_busy || (rst_n !== 1'b1) || (^entry === 1'bx) ||
          (^offset === 1'bx) || (entry >= PV_NUM_PCR) ||
          (offset >= PV_NUM_DWORDS)) begin
        response_error = 1'b1;
        disable read_body;
      end

      read_busy = 1'b1;
      request_ok = 1'b1;
      @(negedge clk or negedge rst_n);
      if (rst_n !== 1'b1) begin
        response_error = 1'b1;
        request_ok = 1'b0;
        read_busy = 1'b0;
        disable read_body;
      end

      pv_read[READ_INDEX].read_entry = entry;
      pv_read[READ_INDEX].read_offset = offset;
      @(posedge clk or negedge rst_n);
      if (rst_n !== 1'b1) begin
        response_error = 1'b1;
        request_ok = 1'b0;
        read_busy = 1'b0;
        disable read_body;
      end else if ((^pv_rd_resp[READ_INDEX] === 1'bx) ||
                   (pv_rd_resp[READ_INDEX].error !== 1'b0)) begin
        response_error = 1'b1;
      end else begin
        data = pv_rd_resp[READ_INDEX].read_data;
        last = pv_rd_resp[READ_INDEX].last;
        success = 1'b1;
      end

      @(negedge clk or negedge rst_n);
      pv_read[READ_INDEX] = '0;
      read_busy = 1'b0;
    end
  endtask
endmodule
