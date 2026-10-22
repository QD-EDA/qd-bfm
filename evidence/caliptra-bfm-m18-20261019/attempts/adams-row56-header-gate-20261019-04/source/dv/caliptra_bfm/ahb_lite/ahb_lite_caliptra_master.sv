// SPDX-License-Identifier: Apache-2.0
// Serialized directed AHB-Lite manager for Caliptra's 64-bit internal bus.
// HWDATA/HRDATA are raw bus lanes; the caller performs byte-lane formatting.
module ahb_lite_caliptra_master #(
  parameter integer ADDR_WIDTH = 32,
  parameter integer DATA_WIDTH = 64,
  parameter integer MAX_WAIT_CYCLES = 1024,
  parameter integer MAX_BURST_BEATS = 256
) (
  input  wire                      HCLK,
  input  wire                      HRESETn,
  input  wire                      HREADY,
  input  wire                      HRESP,
  input  wire [DATA_WIDTH-1:0]     HRDATA,
  // Convenience select for a directly connected single subordinate. Ignore
  // this pin when the master is connected through a multi-target decoder.
  output wire                      HSEL,
  output reg  [ADDR_WIDTH-1:0]     HADDR,
  output reg  [DATA_WIDTH-1:0]     HWDATA,
  output reg                       HWRITE,
  output reg  [2:0]                HSIZE,
  output reg  [1:0]                HTRANS,
  output reg                       busy,
  output reg                       poisoned
);
  localparam integer DATA_BYTES = DATA_WIDTH / 8;

  assign HSEL = HRESETn && HTRANS[1];

  initial begin
    if (ADDR_WIDTH < 1) $fatal(1, "ADDR_WIDTH must be positive");
    if ((DATA_WIDTH < 8) || ((DATA_WIDTH % 8) != 0) ||
        ((DATA_BYTES & (DATA_BYTES - 1)) != 0))
      $fatal(1, "DATA_WIDTH must be a power-of-two byte width");
    if (MAX_WAIT_CYCLES < 1) $fatal(1, "MAX_WAIT_CYCLES must be positive");
    if (MAX_BURST_BEATS < 1) $fatal(1, "MAX_BURST_BEATS must be positive");
    HADDR = '0;
    HWDATA = '0;
    HWRITE = 1'b0;
    HSIZE = '0;
    HTRANS = 2'b00;
    busy = 1'b0;
    poisoned = 1'b0;
  end

  // Call only while HRESETn is low and the active task has returned. A timeout
  // can leave a transfer in flight, so releasing poison without target reset
  // is not safe.
  task automatic reset_master;
    begin
      if (HRESETn !== 1'b0) begin
        $error("reset_master requires HRESETn low");
      end else if (busy) begin
        $error("wait for the active task to abort before reset_master");
      end else begin
        HADDR = '0;
        HWDATA = '0;
        HWRITE = 1'b0;
        HSIZE = '0;
        HTRANS = 2'b00;
        busy = 1'b0;
        poisoned = 1'b0;
      end
    end
  endtask

  task automatic transfer_one(
    input  [ADDR_WIDTH-1:0] address,
    input                   is_write,
    input  [2:0]            size,
    input  [DATA_WIDTH-1:0] write_data,
    output reg              request_ok,
    output reg              success,
    output reg              response_error,
    output reg [DATA_WIDTH-1:0] read_data
  );
    integer wait_count;
    integer bytes_per_transfer;
    reg address_accepted;
    reg data_accepted;
    reg reset_seen;
    reg wait_fault;
    reg error_first_cycle;
    begin : transfer_body
      request_ok = 1'b0;
      success = 1'b0;
      response_error = 1'b0;
      read_data = '0;

      if (busy || poisoned || (HRESETn !== 1'b1)) begin
        $error("AHB manager is busy, poisoned, or held in reset");
        disable transfer_body;
      end

      if ((^address === 1'bx) || (^size === 1'bx) ||
          ((is_write !== 1'b0) && (is_write !== 1'b1)) ||
          (is_write && (^write_data === 1'bx))) begin
        $error("AHB request contains unknown address, control, or write data");
        disable transfer_body;
      end
      if (size > $clog2(DATA_BYTES)) begin
        $error("AHB transfer size exceeds bus width");
        disable transfer_body;
      end
      bytes_per_transfer = 1 << size;
      if ((address % bytes_per_transfer) != 0) begin
        $error("AHB transfer address is not naturally aligned");
        disable transfer_body;
      end

      request_ok = 1'b1;
      busy = 1'b1;
      reset_seen = 1'b0;
      wait_fault = 1'b0;
      error_first_cycle = 1'b0;

      // Address phase. NONSEQ is a legal single transfer; transfers are
      // intentionally serialized, with an IDLE address phase during data.
      @(negedge HCLK or negedge HRESETn);
      if (HRESETn !== 1'b1) begin
        reset_seen = 1'b1;
      end
      if (reset_seen) begin
        HADDR = '0;
        HWDATA = '0;
        HWRITE = 1'b0;
        HSIZE = '0;
        HTRANS = 2'b00;
        poisoned = 1'b1;
        busy = 1'b0;
        $error("AHB manager reset before address phase");
        disable transfer_body;
      end
      HADDR = address;
      HWRITE = is_write;
      HSIZE = size;
      HTRANS = 2'b10;
      address_accepted = 1'b0;
      wait_count = 0;
      while (!address_accepted && (wait_count <= MAX_WAIT_CYCLES) &&
             !reset_seen && !wait_fault) begin
        @(posedge HCLK or negedge HRESETn);
        if (HRESETn !== 1'b1) reset_seen = 1'b1;
        else if (HRESP !== 1'b0) wait_fault = 1'b1;
        else if (HREADY === 1'b1) address_accepted = 1'b1;
        else if (HREADY === 1'b0) wait_count = wait_count + 1;
        else wait_fault = 1'b1;
      end
      if (reset_seen) begin
        HADDR = '0;
        HWDATA = '0;
        HWRITE = 1'b0;
        HSIZE = '0;
        HTRANS = 2'b00;
        poisoned = 1'b1;
        busy = 1'b0;
        $error("AHB manager reset during address wait");
        disable transfer_body;
      end
      if (wait_fault) begin
        poisoned = 1'b1;
        busy = 1'b0;
        $error("AHB manager observed unknown HREADY during address wait");
        disable transfer_body;
      end
      if (!address_accepted) begin
        poisoned = 1'b1;
        busy = 1'b0;
        $error("AHB manager timed out waiting for address acceptance");
        disable transfer_body;
      end

      // Data phase. Hold write data until HREADY; response is sampled on the
      // completing edge, including the second cycle of an AHB-Lite ERROR.
      @(negedge HCLK or negedge HRESETn);
      if (HRESETn !== 1'b1) begin
        HADDR = '0;
        HWDATA = '0;
        HWRITE = 1'b0;
        HSIZE = '0;
        HTRANS = 2'b00;
        poisoned = 1'b1;
        busy = 1'b0;
        $error("AHB manager reset before data phase");
        disable transfer_body;
      end
      HTRANS = 2'b00;
      HWRITE = 1'b0;
      HWDATA = is_write ? write_data : '0;
      data_accepted = 1'b0;
      wait_count = 0;
      while (!data_accepted && (wait_count <= MAX_WAIT_CYCLES) &&
             !reset_seen && !wait_fault) begin
        @(posedge HCLK or negedge HRESETn);
        if (HRESETn !== 1'b1) begin
          reset_seen = 1'b1;
        end else if (HREADY === 1'b1) begin
          if ((HRESP !== 1'b0) && (HRESP !== 1'b1)) begin
            wait_fault = 1'b1;
          end else if (error_first_cycle && (HRESP !== 1'b1)) begin
            wait_fault = 1'b1;
          end else if (!error_first_cycle && (HRESP === 1'b1)) begin
            wait_fault = 1'b1;
          end else begin
            data_accepted = 1'b1;
            response_error = HRESP;
            success = (HRESP === 1'b0);
            if (success) begin
              if (!is_write && (^HRDATA === 1'bx)) begin
                wait_fault = 1'b1;
                data_accepted = 1'b0;
                success = 1'b0;
                read_data = '0;
              end else begin
                read_data = HRDATA;
              end
            end
          end
        end else if (HREADY === 1'b0) begin
          if ((HRESP !== 1'b0) && (HRESP !== 1'b1))
            wait_fault = 1'b1;
          else if (HRESP === 1'b1) begin
            if (error_first_cycle) wait_fault = 1'b1;
            else error_first_cycle = 1'b1;
          end else if (error_first_cycle) begin
            wait_fault = 1'b1;
          end
          wait_count = wait_count + 1;
        end else begin
          wait_fault = 1'b1;
        end
      end
      if (reset_seen) begin
        HADDR = '0;
        HWDATA = '0;
        HWRITE = 1'b0;
        HSIZE = '0;
        HTRANS = 2'b00;
        poisoned = 1'b1;
        busy = 1'b0;
        $error("AHB manager reset during data wait");
        disable transfer_body;
      end
      if (wait_fault) begin
        poisoned = 1'b1;
        busy = 1'b0;
        $error("AHB manager observed unknown HREADY/HRESP at response");
        disable transfer_body;
      end
      if (!data_accepted) begin
        poisoned = 1'b1;
        busy = 1'b0;
        $error("AHB manager timed out waiting for data completion");
        disable transfer_body;
      end

      @(negedge HCLK or negedge HRESETn);
      HWDATA = '0;
      HTRANS = 2'b00;
      HWRITE = 1'b0;
      if (HRESETn !== 1'b1) poisoned = 1'b1;
      busy = 1'b0;
    end
  endtask

  task automatic write_one(
    input  [ADDR_WIDTH-1:0] address,
    input  [2:0]            size,
    input  [DATA_WIDTH-1:0] write_data,
    output reg              request_ok,
    output reg              success,
    output reg              response_error
  );
    reg [DATA_WIDTH-1:0] unused_read_data;
    begin
      transfer_one(address, 1'b1, size, write_data, request_ok, success,
                   response_error, unused_read_data);
    end
  endtask

  task automatic read_one(
    input  [ADDR_WIDTH-1:0] address,
    input  [2:0]            size,
    output reg              request_ok,
    output reg              success,
    output reg              response_error,
    output reg [DATA_WIDTH-1:0] read_data
  );
    reg [DATA_WIDTH-1:0] unused_write_data;
    begin
      transfer_one(address, 1'b0, size, unused_write_data, request_ok,
                   success, response_error, read_data);
    end
  endtask

  // Drives one incrementing AHB-Lite burst. The Caliptra pin profile omits
  // HBURST, so HTRANS marks the first NONSEQ address followed by SEQ beats.
  // HWDATA for the current data phase remains stable while its next address
  // phase is held through wait states.
  task automatic transfer_incr_burst(
    input  [ADDR_WIDTH-1:0] address,
    input                   is_write,
    input  [2:0]            size,
    input  integer          beat_count,
    input  [MAX_BURST_BEATS*DATA_WIDTH-1:0] write_data,
    output reg              request_ok,
    output reg              success,
    output reg              response_error,
    output reg [MAX_BURST_BEATS*DATA_WIDTH-1:0] read_data,
    output reg [MAX_BURST_BEATS-1:0] beat_error,
    output integer          completed_beats
  );
    integer beat;
    integer wait_count;
    integer bytes_per_transfer;
    reg [ADDR_WIDTH:0] beat_address;
    reg address_accepted;
    reg response_completed;
    reg error_first_cycle;
    reg reset_seen;
    reg wait_fault;
    reg timed_out;
    reg continue_burst;
    begin : burst_body
      request_ok = 1'b0;
      success = 1'b0;
      response_error = 1'b0;
      read_data = '0;
      beat_error = '0;
      completed_beats = 0;
      reset_seen = 1'b0;
      wait_fault = 1'b0;
      timed_out = 1'b0;
      continue_burst = 1'b1;

      if (busy || poisoned || (HRESETn !== 1'b1)) begin
        $error("AHB manager is busy, poisoned, or held in reset");
        disable burst_body;
      end
      if ((^address === 1'bx) || (^size === 1'bx) ||
          ((^beat_count) === 1'bx) ||
          ((is_write !== 1'b0) && (is_write !== 1'b1)) ||
          (beat_count < 1) || (beat_count > MAX_BURST_BEATS)) begin
        $error("AHB burst has unknown controls or a beat count outside 1..%0d",
               MAX_BURST_BEATS);
        disable burst_body;
      end
      if (size > $clog2(DATA_BYTES)) begin
        $error("AHB burst transfer size exceeds bus width");
        disable burst_body;
      end
      bytes_per_transfer = 1 << size;
      if ((address % bytes_per_transfer) != 0) begin
        $error("AHB burst start address is not naturally aligned");
        disable burst_body;
      end
      for (beat = 0; beat < beat_count; beat = beat + 1) begin
        beat_address = {1'b0, address} + (beat * bytes_per_transfer);
        if (beat_address[ADDR_WIDTH]) begin
          $error("AHB incrementing burst address overflows the bus width");
          disable burst_body;
        end
        if (is_write &&
            (^write_data[beat*DATA_WIDTH +: DATA_WIDTH] === 1'bx)) begin
          $error("AHB burst write data contains unknown bits");
          disable burst_body;
        end
      end

      request_ok = 1'b1;
      busy = 1'b1;

      // Launch NONSEQ and wait until the first address phase is accepted.
      @(negedge HCLK or negedge HRESETn);
      if (HRESETn !== 1'b1) begin
        reset_seen = 1'b1;
      end else begin
        HADDR = address;
        HWRITE = is_write;
        HSIZE = size;
        HTRANS = 2'b10;
      end
      address_accepted = 1'b0;
      wait_count = 0;
      while (!address_accepted && !reset_seen && !wait_fault &&
             (wait_count <= MAX_WAIT_CYCLES)) begin
        @(posedge HCLK or negedge HRESETn);
        if (HRESETn !== 1'b1) begin
          reset_seen = 1'b1;
        end else if ((HREADY !== 1'b0) && (HREADY !== 1'b1)) begin
          wait_fault = 1'b1;
        end else if ((HRESP !== 1'b0) && (HRESP !== 1'b1)) begin
          wait_fault = 1'b1;
        end else if (HREADY === 1'b1) begin
          if (HRESP !== 1'b0) wait_fault = 1'b1;
          else address_accepted = 1'b1;
        end else begin
          wait_count = wait_count + 1;
        end
      end
      if (!address_accepted && !reset_seen && !wait_fault)
        timed_out = 1'b1;

      for (beat = 0; beat < beat_count && continue_burst &&
           !reset_seen && !wait_fault && !timed_out; beat = beat + 1) begin
        // This data phase overlaps the next address phase. A final IDLE phase
        // terminates the undefined-length INCR burst after its last beat.
        @(negedge HCLK or negedge HRESETn);
        if (HRESETn !== 1'b1) begin
          reset_seen = 1'b1;
        end else begin
          HWDATA = is_write ? write_data[beat*DATA_WIDTH +: DATA_WIDTH] : '0;
          if (beat + 1 < beat_count) begin
            beat_address = {1'b0, address} +
                           ((beat + 1) * bytes_per_transfer);
            HADDR = beat_address[ADDR_WIDTH-1:0];
            HWRITE = is_write;
            HSIZE = size;
            HTRANS = 2'b11;
          end else begin
            HADDR = '0;
            HWRITE = 1'b0;
            HSIZE = '0;
            HTRANS = 2'b00;
          end
        end

        response_completed = 1'b0;
        error_first_cycle = 1'b0;
        wait_count = 0;
        while (!response_completed && !reset_seen && !wait_fault &&
               (wait_count <= MAX_WAIT_CYCLES)) begin
          @(posedge HCLK or negedge HRESETn);
          if (HRESETn !== 1'b1) begin
            reset_seen = 1'b1;
          end else if ((HREADY !== 1'b0) && (HREADY !== 1'b1)) begin
            wait_fault = 1'b1;
          end else if ((HRESP !== 1'b0) && (HRESP !== 1'b1)) begin
            wait_fault = 1'b1;
          end else if (HREADY === 1'b1) begin
            if (error_first_cycle && (HRESP !== 1'b1)) begin
              wait_fault = 1'b1;
            end else if (!error_first_cycle && (HRESP === 1'b1)) begin
              wait_fault = 1'b1;
            end else begin
              response_completed = 1'b1;
              completed_beats = completed_beats + 1;
              beat_error[beat] = HRESP;
              if (HRESP === 1'b1) begin
                response_error = 1'b1;
                continue_burst = 1'b0;
              end else if (!is_write) begin
                if (^HRDATA === 1'bx) begin
                  wait_fault = 1'b1;
                end else begin
                  read_data[beat*DATA_WIDTH +: DATA_WIDTH] = HRDATA;
                end
              end
            end
          end else begin
            if (HRESP === 1'b1) begin
              if (error_first_cycle) begin
                wait_fault = 1'b1;
              end else begin
                error_first_cycle = 1'b1;
                // AHB ERROR ends the current burst. The next address has not
                // been accepted while HREADY is low, so withdraw it now.
                @(negedge HCLK or negedge HRESETn);
                if (HRESETn !== 1'b1) begin
                  reset_seen = 1'b1;
                end else begin
                  HADDR = '0;
                  HWRITE = 1'b0;
                  HSIZE = '0;
                  HTRANS = 2'b00;
                end
              end
            end else if (error_first_cycle) begin
              wait_fault = 1'b1;
            end
            wait_count = wait_count + 1;
          end
        end
        if (!response_completed && !reset_seen && !wait_fault)
          timed_out = 1'b1;
      end

      if (reset_seen || wait_fault || timed_out) begin
        HADDR = '0;
        HWDATA = '0;
        HWRITE = 1'b0;
        HSIZE = '0;
        HTRANS = 2'b00;
        poisoned = 1'b1;
        busy = 1'b0;
        if (reset_seen)
          $error("AHB manager reset during incrementing burst");
        else if (timed_out)
          $error("AHB manager timed out during incrementing burst");
        else
          $error("AHB manager observed malformed HREADY/HRESP/HRDATA during burst");
        disable burst_body;
      end

      success = (completed_beats == beat_count) && !response_error;
      @(negedge HCLK or negedge HRESETn);
      HADDR = '0;
      HWDATA = '0;
      HWRITE = 1'b0;
      HSIZE = '0;
      HTRANS = 2'b00;
      if (HRESETn !== 1'b1) poisoned = 1'b1;
      busy = 1'b0;
    end
  endtask

  task automatic write_burst(
    input  [ADDR_WIDTH-1:0] address,
    input  [2:0]            size,
    input  integer          beat_count,
    input  [MAX_BURST_BEATS*DATA_WIDTH-1:0] write_data,
    output reg              request_ok,
    output reg              success,
    output reg              response_error,
    output integer          completed_beats,
    output reg [MAX_BURST_BEATS-1:0] beat_error
  );
    reg [MAX_BURST_BEATS*DATA_WIDTH-1:0] unused_read_data;
    begin
      transfer_incr_burst(address, 1'b1, size, beat_count, write_data,
                          request_ok, success, response_error, unused_read_data,
                          beat_error, completed_beats);
    end
  endtask

  task automatic read_burst(
    input  [ADDR_WIDTH-1:0] address,
    input  [2:0]            size,
    input  integer          beat_count,
    output reg              request_ok,
    output reg              success,
    output reg              response_error,
    output integer          completed_beats,
    output reg [MAX_BURST_BEATS-1:0] beat_error,
    output reg [MAX_BURST_BEATS*DATA_WIDTH-1:0] read_data
  );
    reg [MAX_BURST_BEATS*DATA_WIDTH-1:0] unused_write_data;
    begin
      transfer_incr_burst(address, 1'b0, size, beat_count, unused_write_data,
                          request_ok, success, response_error, read_data,
                          beat_error, completed_beats);
    end
  endtask
endmodule
