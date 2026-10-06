// SPDX-License-Identifier: Apache-2.0
// Bounded byte-addressable AHB-Lite memory target for a single selected window.
module ahb_lite_caliptra_memory_subordinate #(
  parameter integer ADDR_WIDTH = 32,
  parameter integer DATA_WIDTH = 64,
  parameter integer MEMORY_BYTES = 65536,
  parameter [ADDR_WIDTH-1:0] BASE_ADDR = {ADDR_WIDTH{1'b0}}
) (
  input  wire                  HCLK,
  input  wire                  HRESETn,
  input  wire [ADDR_WIDTH-1:0] HADDR,
  input  wire [DATA_WIDTH-1:0] HWDATA,
  input  wire                  HSEL,
  input  wire                  HWRITE,
  input  wire [1:0]            HTRANS,
  input  wire [2:0]            HSIZE,
  input  wire                  HREADY,
  input  wire [7:0]            wait_cycles,
  input  wire                  inject_error,
  output reg                   HREADYOUT,
  output reg                   HRESP,
  output reg  [DATA_WIDTH-1:0] HRDATA
);
  localparam integer DATA_BYTES = DATA_WIDTH / 8;

  reg [7:0] mem [0:MEMORY_BYTES-1];
  reg pending;
  reg pending_write;
  reg pending_valid;
  reg pending_error;
  reg error_second_cycle;
  reg burst_context;
  reg [2:0] pending_size;
  reg [ADDR_WIDTH:0] pending_offset;
  reg [7:0] wait_remaining;
  integer init_index;
  integer read_lane;
  integer read_word_start;
  integer write_lane;
  integer write_transfer_bytes;
  integer write_lane_start;
  integer write_word_start;
  reg [ADDR_WIDTH:0] accepted_offset;

  initial begin
    if ((DATA_WIDTH < 8) || ((DATA_WIDTH % 8) != 0) ||
        ((DATA_BYTES & (DATA_BYTES - 1)) != 0))
      $fatal(1, "DATA_WIDTH must be a power-of-two byte width");
    if ((MEMORY_BYTES < DATA_BYTES) || ((MEMORY_BYTES % DATA_BYTES) != 0))
      $fatal(1, "MEMORY_BYTES must be a positive multiple of the data width");
    if ((BASE_ADDR % DATA_BYTES) != 0)
      $fatal(1, "BASE_ADDR must be data-word aligned");
    for (init_index = 0; init_index < MEMORY_BYTES; init_index = init_index + 1)
      mem[init_index] = 8'h00;
  end

  always @* begin
    HREADYOUT = 1'b1;
    HRESP = 1'b0;
    HRDATA = '0;

    if (pending) begin
      if (pending_error) begin
        HRESP = 1'b1;
        HREADYOUT = error_second_cycle;
      end else if (wait_remaining != 0) begin
        HREADYOUT = 1'b0;
      end

      if (!pending_write && pending_valid && !pending_error) begin
        read_word_start = (pending_offset / DATA_BYTES) * DATA_BYTES;
        for (read_lane = 0; read_lane < DATA_BYTES; read_lane = read_lane + 1)
          HRDATA[read_lane*8 +: 8] = mem[read_word_start + read_lane];
      end
    end
  end

  always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      pending <= 1'b0;
      pending_write <= 1'b0;
      pending_valid <= 1'b0;
      pending_error <= 1'b0;
      error_second_cycle <= 1'b0;
      burst_context <= 1'b0;
      pending_size <= '0;
      pending_offset <= '0;
      wait_remaining <= '0;
    end else begin
      if (pending && pending_error && !error_second_cycle)
        error_second_cycle <= 1'b1;
      else if (pending && !pending_error && (wait_remaining != 0))
        wait_remaining <= wait_remaining - 1'b1;

      if (pending && HREADY && HREADYOUT) begin
        if (pending_write && pending_valid && !pending_error) begin
          write_transfer_bytes = 1 << pending_size;
          write_lane_start = pending_offset % DATA_BYTES;
          write_word_start = (pending_offset / DATA_BYTES) * DATA_BYTES;
          for (write_lane = 0; write_lane < DATA_BYTES; write_lane = write_lane + 1) begin
            if ((write_lane >= write_lane_start) &&
                (write_lane < (write_lane_start + write_transfer_bytes)))
              mem[write_word_start + write_lane] <= HWDATA[write_lane*8 +: 8];
          end
        end
        pending <= 1'b0;
        pending_error <= 1'b0;
        error_second_cycle <= 1'b0;
        wait_remaining <= '0;
      end

      // AHB-Lite permits the old data phase to complete while a new address
      // phase is accepted on the same edge; the new request owns the slot.
      if (HREADY && HREADYOUT && HSEL && HTRANS[1]) begin
        accepted_offset = {1'b0, HADDR} - {1'b0, BASE_ADDR};
        write_transfer_bytes = 1 << HSIZE;
        pending <= 1'b1;
        pending_write <= HWRITE;
        pending_size <= HSIZE;
        pending_offset <= accepted_offset;
        pending_valid <= (HADDR >= BASE_ADDR) &&
                         (accepted_offset + write_transfer_bytes <= MEMORY_BYTES) &&
                         (HSIZE <= $clog2(DATA_BYTES)) &&
                         ((HADDR % write_transfer_bytes) == 0);
        pending_error <= (inject_error !== 1'b0) ||
                         (^HADDR === 1'bx) || (^HWRITE === 1'bx) ||
                         (^HTRANS === 1'bx) || (^HSIZE === 1'bx) ||
                         (^wait_cycles === 1'bx) ||
                         ((HTRANS == 2'b11) && !burst_context) ||
                         (HADDR < BASE_ADDR) ||
                         (accepted_offset + write_transfer_bytes > MEMORY_BYTES) ||
                         (HSIZE > $clog2(DATA_BYTES)) ||
                         ((HADDR % write_transfer_bytes) != 0);
        error_second_cycle <= 1'b0;
        wait_remaining <= wait_cycles;
      end

      if (HREADY && HREADYOUT) begin
        if (HSEL && (HTRANS == 2'b10))
          burst_context <= 1'b1;
        else if (!HSEL || (HTRANS == 2'b00))
          burst_context <= 1'b0;
      end
    end
  end
endmodule
