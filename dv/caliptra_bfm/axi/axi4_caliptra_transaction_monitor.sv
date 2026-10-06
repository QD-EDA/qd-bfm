// SPDX-License-Identifier: Apache-2.0
// Bounded completed-transaction records for the Caliptra AXI profile.
// Beat zero occupies the least-significant packed output slice.
module axi4_caliptra_transaction_monitor #(
  parameter integer ADDR_WIDTH = 48,
  parameter integer DATA_WIDTH = 32,
  parameter integer ID_WIDTH = 8,
  parameter integer USER_WIDTH = 32,
  parameter integer MAX_BEATS = 256,
  parameter integer MAX_OUTSTANDING = 8
) (
  input wire ACLK,
  input wire ARESETn,
  input wire [ID_WIDTH-1:0] AWID,
  input wire [ADDR_WIDTH-1:0] AWADDR,
  input wire [7:0] AWLEN,
  input wire [2:0] AWSIZE,
  input wire [1:0] AWBURST,
  input wire AWLOCK,
  input wire [USER_WIDTH-1:0] AWUSER,
  input wire AWVALID,
  input wire AWREADY,
  input wire [DATA_WIDTH-1:0] WDATA,
  input wire [DATA_WIDTH/8-1:0] WSTRB,
  input wire [USER_WIDTH-1:0] WUSER,
  input wire WLAST,
  input wire WVALID,
  input wire WREADY,
  input wire [ID_WIDTH-1:0] BID,
  input wire [1:0] BRESP,
  input wire [USER_WIDTH-1:0] BUSER,
  input wire BVALID,
  input wire BREADY,
  input wire [ID_WIDTH-1:0] ARID,
  input wire [ADDR_WIDTH-1:0] ARADDR,
  input wire [7:0] ARLEN,
  input wire [2:0] ARSIZE,
  input wire [1:0] ARBURST,
  input wire ARLOCK,
  input wire [USER_WIDTH-1:0] ARUSER,
  input wire ARVALID,
  input wire ARREADY,
  input wire [ID_WIDTH-1:0] RID,
  input wire [DATA_WIDTH-1:0] RDATA,
  input wire [1:0] RRESP,
  input wire [USER_WIDTH-1:0] RUSER,
  input wire RLAST,
  input wire RVALID,
  input wire RREADY,
  output reg [63:0] cycle_count,
  output reg write_complete,
  output reg write_request_complete,
  output reg write_request_error,
  output reg [3:0] write_request_status,
  output reg [ID_WIDTH-1:0] write_request_id,
  output reg [ADDR_WIDTH-1:0] write_request_addr,
  output reg [7:0] write_request_len,
  output reg [2:0] write_request_size,
  output reg [1:0] write_request_burst,
  output reg write_request_lock,
  output reg [USER_WIDTH-1:0] write_request_awuser,
  output reg [8:0] write_request_beat_count,
  output reg [MAX_BEATS*DATA_WIDTH-1:0] write_request_data,
  output reg [MAX_BEATS*(DATA_WIDTH/8)-1:0] write_request_strb,
  output reg [MAX_BEATS*USER_WIDTH-1:0] write_request_wuser,
  output reg [MAX_BEATS-1:0] write_request_last_mask,
  output reg write_error,
  output reg [3:0] write_error_code,
  output reg [3:0] write_status,
  output reg [63:0] write_cycle,
  output reg [ID_WIDTH-1:0] write_id,
  output reg [ADDR_WIDTH-1:0] write_addr,
  output reg [7:0] write_len,
  output reg [2:0] write_size,
  output reg [1:0] write_burst,
  output reg write_lock,
  output reg [USER_WIDTH-1:0] write_awuser,
  output reg [8:0] write_beat_count,
  output reg [MAX_BEATS*DATA_WIDTH-1:0] write_data,
  output reg [MAX_BEATS*(DATA_WIDTH/8)-1:0] write_strb,
  output reg [MAX_BEATS*USER_WIDTH-1:0] write_wuser,
  output reg [MAX_BEATS-1:0] write_last_mask,
  output reg [ID_WIDTH-1:0] write_response_id,
  output reg [1:0] write_response,
  output reg [USER_WIDTH-1:0] write_buser,
  output reg read_complete,
  output reg read_error,
  output reg [3:0] read_error_code,
  output reg [3:0] read_status,
  output reg [63:0] read_cycle,
  output reg [ID_WIDTH-1:0] read_id,
  output reg [ADDR_WIDTH-1:0] read_addr,
  output reg [7:0] read_len,
  output reg [2:0] read_size,
  output reg [1:0] read_burst,
  output reg read_lock,
  output reg [USER_WIDTH-1:0] read_aruser,
  output reg [8:0] read_beat_count,
  output reg [MAX_BEATS*DATA_WIDTH-1:0] read_data,
  output reg [MAX_BEATS*2-1:0] read_resp,
  output reg [MAX_BEATS*USER_WIDTH-1:0] read_ruser,
  output reg [MAX_BEATS-1:0] read_last_mask
);
  localparam integer STRB_WIDTH = DATA_WIDTH / 8;

  localparam [3:0] STATUS_OK = 4'd0;
  localparam [3:0] STATUS_SHAPE = 4'd1;
  localparam [3:0] STATUS_CAPACITY = 4'd2;
  localparam [3:0] STATUS_ID = 4'd3;
  localparam [3:0] STATUS_OVERLAP = 4'd4;
  localparam [3:0] STATUS_ORPHAN = 4'd5;

  reg [MAX_OUTSTANDING-1:0] write_open;
  reg [MAX_OUTSTANDING-1:0] write_data_done;
  reg [MAX_OUTSTANDING-1:0] write_response_seen;
  reg [3:0] write_work_status [0:MAX_OUTSTANDING-1];
  integer write_work_count [0:MAX_OUTSTANDING-1];
  reg [ID_WIDTH-1:0] write_work_id [0:MAX_OUTSTANDING-1];
  reg [ADDR_WIDTH-1:0] write_work_addr [0:MAX_OUTSTANDING-1];
  reg [7:0] write_work_len [0:MAX_OUTSTANDING-1];
  reg [2:0] write_work_size [0:MAX_OUTSTANDING-1];
  reg [1:0] write_work_burst [0:MAX_OUTSTANDING-1];
  reg write_work_lock [0:MAX_OUTSTANDING-1];
  reg [USER_WIDTH-1:0] write_work_awuser [0:MAX_OUTSTANDING-1];
  reg [63:0] write_work_sequence [0:MAX_OUTSTANDING-1];
  reg [DATA_WIDTH-1:0] write_data_work [0:MAX_OUTSTANDING-1][0:MAX_BEATS-1];
  reg [STRB_WIDTH-1:0] write_strb_work [0:MAX_OUTSTANDING-1][0:MAX_BEATS-1];
  reg [USER_WIDTH-1:0] write_wuser_work [0:MAX_OUTSTANDING-1][0:MAX_BEATS-1];
  reg write_last_work [0:MAX_OUTSTANDING-1][0:MAX_BEATS-1];
  reg [63:0] write_sequence_next;
  integer write_w_order [0:MAX_OUTSTANDING-1];
  integer write_w_head;
  integer write_w_tail;
  integer write_w_count;

  // One bounded W-before-AW frame is retained before its address arrives.
  reg pre_write_active;
  reg pre_write_done;
  reg [3:0] pre_write_status;
  integer pre_write_count;
  reg [DATA_WIDTH-1:0] pre_write_data [0:MAX_BEATS-1];
  reg [STRB_WIDTH-1:0] pre_write_strb [0:MAX_BEATS-1];
  reg [USER_WIDTH-1:0] pre_write_user [0:MAX_BEATS-1];
  reg pre_write_last [0:MAX_BEATS-1];

  reg [MAX_OUTSTANDING-1:0] read_open;
  reg [3:0] read_work_status [0:MAX_OUTSTANDING-1];
  integer read_work_count [0:MAX_OUTSTANDING-1];
  reg [ID_WIDTH-1:0] read_work_id [0:MAX_OUTSTANDING-1];
  reg [ADDR_WIDTH-1:0] read_work_addr [0:MAX_OUTSTANDING-1];
  reg [7:0] read_work_len [0:MAX_OUTSTANDING-1];
  reg [2:0] read_work_size [0:MAX_OUTSTANDING-1];
  reg [1:0] read_work_burst [0:MAX_OUTSTANDING-1];
  reg read_work_lock [0:MAX_OUTSTANDING-1];
  reg [USER_WIDTH-1:0] read_work_aruser [0:MAX_OUTSTANDING-1];
  reg [63:0] read_work_sequence [0:MAX_OUTSTANDING-1];
  reg [DATA_WIDTH-1:0] read_data_work [0:MAX_OUTSTANDING-1][0:MAX_BEATS-1];
  reg [1:0] read_resp_work [0:MAX_OUTSTANDING-1][0:MAX_BEATS-1];
  reg [USER_WIDTH-1:0] read_ruser_work [0:MAX_OUTSTANDING-1][0:MAX_BEATS-1];
  reg read_last_work [0:MAX_OUTSTANDING-1][0:MAX_BEATS-1];
  reg [63:0] read_sequence_next;

  reg write_b_used;
  integer write_match_slot;
  integer write_oldest_slot;
  integer write_free_slot;
  integer write_data_slot;
  integer read_match_slot;
  integer read_oldest_slot;
  integer read_free_slot;
  integer i;
  integer j;

  task automatic flag_write_error(input integer slot, input [3:0] code);
    begin
      write_error <= 1'b1;
      write_error_code <= code;
      if (slot >= 0) begin
        if (write_work_status[slot] == STATUS_OK)
          write_work_status[slot] = code;
      end
    end
  endtask

  task automatic find_write_response_slot(
    input [ID_WIDTH-1:0] response_id,
    output integer slot
  );
    integer s;
    integer match_slot;
    integer oldest_slot;
    begin
      match_slot = -1;
      oldest_slot = -1;
      for (s = 0; s < MAX_OUTSTANDING; s = s + 1) begin
        if (write_open[s] && !write_response_seen[s]) begin
          if (oldest_slot < 0)
            oldest_slot = s;
          else if (write_work_sequence[s] < write_work_sequence[oldest_slot])
            oldest_slot = s;
          if (write_work_id[s] == response_id) begin
            if (match_slot < 0)
              match_slot = s;
            else if (write_work_sequence[s] < write_work_sequence[match_slot])
              match_slot = s;
          end
        end
      end
      slot = match_slot >= 0 ? match_slot : oldest_slot;
    end
  endtask

  task automatic flag_read_error(input integer slot, input [3:0] code);
    begin
      read_error <= 1'b1;
      read_error_code <= code;
      if (slot >= 0) begin
        if (read_work_status[slot] == STATUS_OK)
          read_work_status[slot] = code;
      end
    end
  endtask

  task automatic publish_write_request(input integer slot);
    integer j;
    reg [MAX_BEATS*DATA_WIDTH-1:0] data_snapshot;
    reg [MAX_BEATS*STRB_WIDTH-1:0] strb_snapshot;
    reg [MAX_BEATS*USER_WIDTH-1:0] user_snapshot;
    reg [MAX_BEATS-1:0] last_snapshot;
    reg [3:0] final_status;
    begin
      final_status = write_work_status[slot];
      if ((write_work_len[slot] + 1) > MAX_BEATS && final_status == STATUS_OK)
        final_status = STATUS_CAPACITY;
      else if (write_work_count[slot] != (write_work_len[slot] + 1) &&
               final_status == STATUS_OK)
        final_status = STATUS_SHAPE;
      data_snapshot = 0;
      strb_snapshot = 0;
      user_snapshot = 0;
      last_snapshot = 0;
      for (j = 0; j < MAX_BEATS; j = j + 1) begin
        if (j < write_work_count[slot]) begin
          data_snapshot[j*DATA_WIDTH +: DATA_WIDTH] = write_data_work[slot][j];
          strb_snapshot[j*STRB_WIDTH +: STRB_WIDTH] = write_strb_work[slot][j];
          user_snapshot[j*USER_WIDTH +: USER_WIDTH] = write_wuser_work[slot][j];
          last_snapshot[j] = write_last_work[slot][j];
        end
      end
      write_request_complete <= 1'b1;
      write_request_error <= (final_status != STATUS_OK);
      write_request_status <= final_status;
      write_request_id <= write_work_id[slot];
      write_request_addr <= write_work_addr[slot];
      write_request_len <= write_work_len[slot];
      write_request_size <= write_work_size[slot];
      write_request_burst <= write_work_burst[slot];
      write_request_lock <= write_work_lock[slot];
      write_request_awuser <= write_work_awuser[slot];
      write_request_beat_count <= write_work_count[slot];
      write_request_data <= data_snapshot;
      write_request_strb <= strb_snapshot;
      write_request_wuser <= user_snapshot;
      write_request_last_mask <= last_snapshot;
    end
  endtask

  task automatic finish_write(
    input integer slot,
    input [ID_WIDTH-1:0] response_id,
    input [1:0] response_code,
    input [USER_WIDTH-1:0] response_user
  );
    integer j;
    reg [MAX_BEATS*DATA_WIDTH-1:0] data_snapshot;
    reg [MAX_BEATS*STRB_WIDTH-1:0] strb_snapshot;
    reg [MAX_BEATS*USER_WIDTH-1:0] user_snapshot;
    reg [MAX_BEATS-1:0] last_snapshot;
    reg [3:0] final_status;
    begin
      final_status = write_work_status[slot];
      if (!write_data_done[slot] && final_status == STATUS_OK)
        final_status = STATUS_SHAPE;
      if (response_id != write_work_id[slot] && final_status == STATUS_OK)
        final_status = STATUS_ID;
      data_snapshot = 0;
      strb_snapshot = 0;
      user_snapshot = 0;
      last_snapshot = 0;
      for (j = 0; j < MAX_BEATS; j = j + 1) begin
        if (j < write_work_count[slot]) begin
          data_snapshot[j*DATA_WIDTH +: DATA_WIDTH] = write_data_work[slot][j];
          strb_snapshot[j*STRB_WIDTH +: STRB_WIDTH] = write_strb_work[slot][j];
          user_snapshot[j*USER_WIDTH +: USER_WIDTH] = write_wuser_work[slot][j];
          last_snapshot[j] = write_last_work[slot][j];
        end
      end
      write_complete <= 1'b1;
      write_error <= (final_status != STATUS_OK);
      if (final_status != STATUS_OK)
        write_error_code <= final_status;
      write_status <= final_status;
      write_cycle <= cycle_count;
      write_id <= write_work_id[slot];
      write_addr <= write_work_addr[slot];
      write_len <= write_work_len[slot];
      write_size <= write_work_size[slot];
      write_burst <= write_work_burst[slot];
      write_lock <= write_work_lock[slot];
      write_awuser <= write_work_awuser[slot];
      write_beat_count <= write_work_count[slot];
      write_data <= data_snapshot;
      write_strb <= strb_snapshot;
      write_wuser <= user_snapshot;
      write_last_mask <= last_snapshot;
      write_response_id <= response_id;
      write_response <= response_code;
      write_buser <= response_user;
      write_response_seen[slot] = 1'b1;
      if (write_data_done[slot])
        write_open[slot] = 1'b0;
    end
  endtask

  task automatic finish_read(input integer slot);
    integer j;
    reg [MAX_BEATS*DATA_WIDTH-1:0] data_snapshot;
    reg [MAX_BEATS*2-1:0] resp_snapshot;
    reg [MAX_BEATS*USER_WIDTH-1:0] user_snapshot;
    reg [MAX_BEATS-1:0] last_snapshot;
    reg [3:0] final_status;
    begin
      final_status = read_work_status[slot];
      if (read_work_count[slot] != (read_work_len[slot] + 1) && final_status == STATUS_OK)
        final_status = STATUS_SHAPE;
      data_snapshot = 0;
      resp_snapshot = 0;
      user_snapshot = 0;
      last_snapshot = 0;
      for (j = 0; j < MAX_BEATS; j = j + 1) begin
        if (j < read_work_count[slot]) begin
          data_snapshot[j*DATA_WIDTH +: DATA_WIDTH] = read_data_work[slot][j];
          resp_snapshot[j*2 +: 2] = read_resp_work[slot][j];
          user_snapshot[j*USER_WIDTH +: USER_WIDTH] = read_ruser_work[slot][j];
          last_snapshot[j] = read_last_work[slot][j];
        end
      end
      read_complete <= 1'b1;
      read_error <= (final_status != STATUS_OK);
      if (final_status != STATUS_OK)
        read_error_code <= final_status;
      read_status <= final_status;
      read_cycle <= cycle_count;
      read_id <= read_work_id[slot];
      read_addr <= read_work_addr[slot];
      read_len <= read_work_len[slot];
      read_size <= read_work_size[slot];
      read_burst <= read_work_burst[slot];
      read_lock <= read_work_lock[slot];
      read_aruser <= read_work_aruser[slot];
      read_beat_count <= read_work_count[slot];
      read_data <= data_snapshot;
      read_resp <= resp_snapshot;
      read_ruser <= user_snapshot;
      read_last_mask <= last_snapshot;
      read_open[slot] = 1'b0;
      read_work_status[slot] = STATUS_OK;
      read_work_count[slot] = 0;
    end
  endtask

  initial begin
    if (MAX_BEATS < 1 || MAX_BEATS > 256)
      $error("MAX_BEATS must be in the range 1..256");
    if (MAX_OUTSTANDING < 1 || MAX_OUTSTANDING > 256)
      $error("MAX_OUTSTANDING must be in the range 1..256");
    if ((DATA_WIDTH % 8) != 0)
      $error("DATA_WIDTH must be a whole number of bytes");
  end

  always @(posedge ACLK) begin
    if (!ARESETn) begin
      cycle_count <= 0;
      write_complete <= 0;
      write_request_complete <= 0;
      write_request_error <= 0;
      write_request_status <= 0;
      write_request_id <= 0;
      write_request_addr <= 0;
      write_request_len <= 0;
      write_request_size <= 0;
      write_request_burst <= 0;
      write_request_lock <= 0;
      write_request_awuser <= 0;
      write_request_beat_count <= 0;
      write_request_data <= 0;
      write_request_strb <= 0;
      write_request_wuser <= 0;
      write_request_last_mask <= 0;
      write_error <= 0;
      write_error_code <= 0;
      write_status <= 0;
      write_cycle <= 0;
      write_id <= 0;
      write_addr <= 0;
      write_len <= 0;
      write_size <= 0;
      write_burst <= 0;
      write_lock <= 0;
      write_awuser <= 0;
      write_beat_count <= 0;
      write_data <= 0;
      write_strb <= 0;
      write_wuser <= 0;
      write_last_mask <= 0;
      write_response_id <= 0;
      write_response <= 0;
      write_buser <= 0;
      read_complete <= 0;
      read_error <= 0;
      read_error_code <= 0;
      read_status <= 0;
      read_cycle <= 0;
      read_id <= 0;
      read_addr <= 0;
      read_len <= 0;
      read_size <= 0;
      read_burst <= 0;
      read_lock <= 0;
      read_aruser <= 0;
      read_beat_count <= 0;
      read_data <= 0;
      read_resp <= 0;
      read_ruser <= 0;
      read_last_mask <= 0;
      write_open = 0;
      write_data_done = 0;
      write_response_seen = 0;
      write_sequence_next = 0;
      write_w_head = 0;
      write_w_tail = 0;
      write_w_count = 0;
      pre_write_active = 0;
      pre_write_done = 0;
      pre_write_status = STATUS_OK;
      pre_write_count = 0;
      read_open = 0;
      read_sequence_next = 0;
      write_b_used = 0;
      for (i = 0; i < MAX_OUTSTANDING; i = i + 1) begin
        write_work_status[i] = STATUS_OK;
        write_work_count[i] = 0;
        write_work_id[i] = 0;
        write_work_addr[i] = 0;
        write_work_len[i] = 0;
        write_work_size[i] = 0;
        write_work_burst[i] = 0;
        write_work_lock[i] = 0;
        write_work_awuser[i] = 0;
        write_work_sequence[i] = 0;
        write_w_order[i] = 0;
        read_work_status[i] = STATUS_OK;
        read_work_count[i] = 0;
        read_work_id[i] = 0;
        read_work_addr[i] = 0;
        read_work_len[i] = 0;
        read_work_size[i] = 0;
        read_work_burst[i] = 0;
        read_work_lock[i] = 0;
        read_work_aruser[i] = 0;
        read_work_sequence[i] = 0;
        for (j = 0; j < MAX_BEATS; j = j + 1) begin
          write_data_work[i][j] = 0;
          write_strb_work[i][j] = 0;
          write_wuser_work[i][j] = 0;
          write_last_work[i][j] = 0;
          read_data_work[i][j] = 0;
          read_resp_work[i][j] = 0;
          read_ruser_work[i][j] = 0;
          read_last_work[i][j] = 0;
        end
      end
      for (i = 0; i < MAX_BEATS; i = i + 1) begin
        pre_write_data[i] = 0;
        pre_write_strb[i] = 0;
        pre_write_user[i] = 0;
        pre_write_last[i] = 0;
      end
    end else begin
      cycle_count <= cycle_count + 1'b1;
      write_complete <= 0;
      write_request_complete <= 0;
      write_request_error <= 0;
      write_request_status <= 0;
      write_error <= 0;
      read_complete <= 0;
      read_error <= 0;
      write_b_used = 0;

      // A W beat belongs to the oldest AW context that has not seen WLAST.
      // Drain an already queued context before allocating this cycle's AW.
      write_data_slot = -1;
      if (WVALID && WREADY && write_w_count > 0) begin
        write_data_slot = write_w_order[write_w_head];
        if (write_data_done[write_data_slot]) begin
          flag_write_error(write_data_slot, STATUS_OVERLAP);
        end else begin
          if (write_work_count[write_data_slot] < MAX_BEATS) begin
            if (WLAST !==
                (write_work_count[write_data_slot] == write_work_len[write_data_slot]))
              flag_write_error(write_data_slot, STATUS_SHAPE);
            if (write_work_count[write_data_slot] >=
                (write_work_len[write_data_slot] + 1))
              flag_write_error(write_data_slot, STATUS_SHAPE);
            write_data_work[write_data_slot][write_work_count[write_data_slot]] = WDATA;
            write_strb_work[write_data_slot][write_work_count[write_data_slot]] = WSTRB;
            write_wuser_work[write_data_slot][write_work_count[write_data_slot]] = WUSER;
            write_last_work[write_data_slot][write_work_count[write_data_slot]] = WLAST;
            write_work_count[write_data_slot] = write_work_count[write_data_slot] + 1;
          end else begin
            flag_write_error(write_data_slot, STATUS_CAPACITY);
          end
          if (WLAST) begin
            write_data_done[write_data_slot] = 1'b1;
            publish_write_request(write_data_slot);
            write_w_head = (write_w_head + 1) % MAX_OUTSTANDING;
            write_w_count = write_w_count - 1;
            if (write_response_seen[write_data_slot])
              write_open[write_data_slot] = 1'b0;
          end
        end
      end

      // Retire an older response before AW allocation so its slot can be
      // reused on this edge. If no old context exists, defer B until after AW/W.
      if (BVALID && BREADY) begin
        find_write_response_slot(BID, write_match_slot);
        if (write_match_slot >= 0 &&
            !(write_work_id[write_match_slot] != BID &&
              AWVALID && AWREADY && AWID == BID)) begin
          finish_write(write_match_slot, BID, BRESP, BUSER);
          write_b_used = 1;
        end
      end

      if (AWVALID && AWREADY) begin
        write_free_slot = -1;
        for (i = 0; i < MAX_OUTSTANDING; i = i + 1) begin
          if (!write_open[i] && write_free_slot < 0)
            write_free_slot = i;
        end
        if (write_free_slot < 0) begin
          flag_write_error(-1, STATUS_CAPACITY);
        end else begin
          write_open[write_free_slot] = 1'b1;
          write_data_done[write_free_slot] = 1'b0;
          write_response_seen[write_free_slot] = 1'b0;
          write_work_status[write_free_slot] = STATUS_OK;
          write_work_count[write_free_slot] = 0;
          write_work_id[write_free_slot] = AWID;
          write_work_addr[write_free_slot] = AWADDR;
          write_work_len[write_free_slot] = AWLEN;
          write_work_size[write_free_slot] = AWSIZE;
          write_work_burst[write_free_slot] = AWBURST;
          write_work_lock[write_free_slot] = AWLOCK;
          write_work_awuser[write_free_slot] = AWUSER;
          write_work_sequence[write_free_slot] = write_sequence_next;
          write_sequence_next = write_sequence_next + 1'b1;
          if (pre_write_active) begin
            write_work_status[write_free_slot] = pre_write_status;
            write_work_count[write_free_slot] = pre_write_count;
            for (i = 0; i < MAX_BEATS; i = i + 1) begin
              if (i < pre_write_count) begin
                write_data_work[write_free_slot][i] = pre_write_data[i];
                write_strb_work[write_free_slot][i] = pre_write_strb[i];
                write_wuser_work[write_free_slot][i] = pre_write_user[i];
                write_last_work[write_free_slot][i] = pre_write_last[i];
                if (pre_write_last[i] !== (i == AWLEN))
                  flag_write_error(write_free_slot, STATUS_SHAPE);
              end
            end
            if (pre_write_done && pre_write_count != (AWLEN + 1))
              flag_write_error(write_free_slot, STATUS_SHAPE);
            write_data_done[write_free_slot] = pre_write_done;
            if (write_data_done[write_free_slot])
              publish_write_request(write_free_slot);
            pre_write_active = 1'b0;
            pre_write_done = 1'b0;
            pre_write_status = STATUS_OK;
            pre_write_count = 0;
            if (!write_data_done[write_free_slot]) begin
              write_w_order[write_w_tail] = write_free_slot;
              write_w_tail = (write_w_tail + 1) % MAX_OUTSTANDING;
              write_w_count = write_w_count + 1;
            end
          end else begin
            write_w_order[write_w_tail] = write_free_slot;
            write_w_tail = (write_w_tail + 1) % MAX_OUTSTANDING;
            write_w_count = write_w_count + 1;
          end
          if ((AWLEN + 1) > MAX_BEATS)
            flag_write_error(write_free_slot, STATUS_CAPACITY);
        end
      end

      if (WVALID && WREADY && write_data_slot < 0) begin
        if (write_w_count > 0) begin
          write_data_slot = write_w_order[write_w_head];
          if (write_work_count[write_data_slot] < MAX_BEATS) begin
            if (WLAST !==
                (write_work_count[write_data_slot] == write_work_len[write_data_slot]))
              flag_write_error(write_data_slot, STATUS_SHAPE);
            if (write_work_count[write_data_slot] >=
                (write_work_len[write_data_slot] + 1))
              flag_write_error(write_data_slot, STATUS_SHAPE);
            write_data_work[write_data_slot][write_work_count[write_data_slot]] = WDATA;
            write_strb_work[write_data_slot][write_work_count[write_data_slot]] = WSTRB;
            write_wuser_work[write_data_slot][write_work_count[write_data_slot]] = WUSER;
            write_last_work[write_data_slot][write_work_count[write_data_slot]] = WLAST;
            write_work_count[write_data_slot] = write_work_count[write_data_slot] + 1;
          end else begin
            flag_write_error(write_data_slot, STATUS_CAPACITY);
          end
          if (WLAST) begin
            write_data_done[write_data_slot] = 1'b1;
            publish_write_request(write_data_slot);
            write_w_head = (write_w_head + 1) % MAX_OUTSTANDING;
            write_w_count = write_w_count - 1;
            if (write_response_seen[write_data_slot])
              write_open[write_data_slot] = 1'b0;
          end
        end else if (!pre_write_active) begin
          pre_write_active = 1'b1;
          pre_write_done = 1'b0;
          pre_write_status = STATUS_OK;
          pre_write_count = 0;
          if (pre_write_count < MAX_BEATS) begin
            pre_write_data[pre_write_count] = WDATA;
            pre_write_strb[pre_write_count] = WSTRB;
            pre_write_user[pre_write_count] = WUSER;
            pre_write_last[pre_write_count] = WLAST;
            pre_write_count = pre_write_count + 1;
          end
          if (WLAST)
            pre_write_done = 1'b1;
        end else if (!pre_write_done) begin
          if (pre_write_count < MAX_BEATS) begin
            pre_write_data[pre_write_count] = WDATA;
            pre_write_strb[pre_write_count] = WSTRB;
            pre_write_user[pre_write_count] = WUSER;
            pre_write_last[pre_write_count] = WLAST;
            pre_write_count = pre_write_count + 1;
          end else begin
            pre_write_status = STATUS_CAPACITY;
          end
          if (WLAST)
            pre_write_done = 1'b1;
        end else begin
          flag_write_error(-1, STATUS_OVERLAP);
        end
      end

      if (BVALID && BREADY && !write_b_used) begin
        find_write_response_slot(BID, write_match_slot);
        if (write_match_slot >= 0) begin
          finish_write(write_match_slot, BID, BRESP, BUSER);
        end else begin
          flag_write_error(-1, STATUS_ORPHAN);
        end
      end

      // Responses may interleave by ID and complete in a different order from
      // their address handshakes. Same-ID responses retain AXI ordering.
      if (RVALID && RREADY) begin
        read_match_slot = -1;
        read_oldest_slot = -1;
        for (i = 0; i < MAX_OUTSTANDING; i = i + 1) begin
          if (read_open[i]) begin
            if (read_oldest_slot < 0)
              read_oldest_slot = i;
            else if (read_work_sequence[i] < read_work_sequence[read_oldest_slot])
              read_oldest_slot = i;
            if (read_work_id[i] == RID) begin
              if (read_match_slot < 0)
                read_match_slot = i;
              else if (read_work_sequence[i] < read_work_sequence[read_match_slot])
                read_match_slot = i;
            end
          end
        end

        if (read_match_slot < 0) begin
          if (read_oldest_slot >= 0) begin
            read_match_slot = read_oldest_slot;
            flag_read_error(read_match_slot, STATUS_ID);
          end else begin
            flag_read_error(-1, STATUS_ORPHAN);
          end
        end

        if (read_match_slot >= 0) begin
          if (RID != read_work_id[read_match_slot])
            flag_read_error(read_match_slot, STATUS_ID);
          if (read_work_count[read_match_slot] < MAX_BEATS) begin
            if (RLAST !==
                (read_work_count[read_match_slot] == read_work_len[read_match_slot]))
              flag_read_error(read_match_slot, STATUS_SHAPE);
            read_data_work[read_match_slot][read_work_count[read_match_slot]] = RDATA;
            read_resp_work[read_match_slot][read_work_count[read_match_slot]] = RRESP;
            read_ruser_work[read_match_slot][read_work_count[read_match_slot]] = RUSER;
            read_last_work[read_match_slot][read_work_count[read_match_slot]] = RLAST;
            read_work_count[read_match_slot] = read_work_count[read_match_slot] + 1;
          end else begin
            flag_read_error(read_match_slot, STATUS_CAPACITY);
          end
          if (RLAST)
            finish_read(read_match_slot);
        end
      end

      if (ARVALID && ARREADY) begin
        read_free_slot = -1;
        for (i = 0; i < MAX_OUTSTANDING; i = i + 1) begin
          if (!read_open[i] && read_free_slot < 0)
            read_free_slot = i;
        end
        if (read_free_slot < 0) begin
          flag_read_error(-1, STATUS_CAPACITY);
        end else begin
          read_open[read_free_slot] = 1'b1;
          read_work_status[read_free_slot] = STATUS_OK;
          read_work_count[read_free_slot] = 0;
          read_work_id[read_free_slot] = ARID;
          read_work_addr[read_free_slot] = ARADDR;
          read_work_len[read_free_slot] = ARLEN;
          read_work_size[read_free_slot] = ARSIZE;
          read_work_burst[read_free_slot] = ARBURST;
          read_work_lock[read_free_slot] = ARLOCK;
          read_work_aruser[read_free_slot] = ARUSER;
          read_work_sequence[read_free_slot] = read_sequence_next;
          read_sequence_next = read_sequence_next + 1'b1;
          if ((ARLEN + 1) > MAX_BEATS)
            flag_read_error(read_free_slot, STATUS_CAPACITY);
        end
      end
    end
  end
endmodule
