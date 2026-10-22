// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Description:
//      Signals for a standard AXI4 compliant interface
//

interface axi_if #(parameter integer AW = 32, parameter integer DW = 32, parameter integer IW = 8, parameter integer UW = 32) (input logic clk, input logic rst_n);

    import axi_pkg::*;

    // AXI AR
    logic [AW-1:0]                 araddr;
    logic [$bits(axi_burst_e)-1:0] arburst;
    logic [2:0]                    arsize;
    logic [7:0]                    arlen;
    logic [UW-1:0]                 aruser;
    logic [IW-1:0]                 arid;
    logic                          arlock;
    logic                          arvalid;
    logic                          arready;

    // AXI R
    logic [DW-1:0]                 rdata;
    logic [$bits(axi_resp_e)-1:0]  rresp;
    logic [IW-1:0]                 rid;
    logic [UW-1:0]                 ruser;
    logic                          rlast;
    logic                          rvalid;
    logic                          rready;
    int unsigned                   m9_trace_mbox_read_count = 0;

    // AXI AW
    logic [AW-1:0]                 awaddr;
    logic [$bits(axi_burst_e)-1:0] awburst;
    logic [2:0]                    awsize;
    logic [7:0]                    awlen;
    logic [UW-1:0]                 awuser;
    logic [IW-1:0]                 awid;
    logic                          awlock;
    logic                          awvalid;
    logic                          awready;

    // AXI W
    logic [DW-1:0]                 wdata;
    logic [DW/8-1:0]               wstrb;
    logic [UW-1:0]                 wuser;
    logic                          wvalid;
    logic                          wready;
    logic                          wlast;

    // AXI B
    logic [$bits(axi_resp_e)-1:0]  bresp;
    logic [IW-1:0]                 bid;
    logic [UW-1:0]                 buser;
    logic                          bvalid;
    logic                          bready;

    // Modport for read manager
    modport r_mgr (
        // AR
        output araddr,
        output arburst,
        output arsize,
        output arlen,
        output aruser,
        output arid,
        output arlock,
        output arvalid,
        input  arready,
        // R
        input  rdata,
        input  rresp,
        input  rid,
        input  ruser,
        input  rlast,
        input  rvalid,
        output rready
    );

    // Modport for write manager
    modport w_mgr (
        // AW
        output awaddr,
        output awburst,
        output awsize,
        output awlen,
        output awuser,
        output awid,
        output awlock,
        output awvalid,
        input  awready,
        // W
        output wdata,
        output wstrb,
        output wuser,
        output wvalid,
        input  wready,
        output wlast,
        // B
        input  bresp,
        input  bid,
        input  buser,
        input  bvalid,
        output bready
    );

    // Modport for read subordinate
    modport r_sub (
        // AR
        input  araddr,
        input  arburst,
        input  arsize,
        input  arlen,
        input  aruser,
        input  arid,
        input  arlock,
        input  arvalid,
        output arready,
        // R
        output rdata,
        output rresp,
        output rid,
        output ruser,
        output rlast,
        output rvalid,
        input  rready
    );

    // Modport for write subordinate
    modport w_sub (
        // AW
        input  awaddr,
        input  awburst,
        input  awsize,
        input  awlen,
        input  awuser,
        input  awid,
        input  awlock,
        input  awvalid,
        output awready,
        // W
        input  wdata,
        input  wstrb,
        input  wuser,
        input  wvalid,
        output wready,
        input  wlast,
        // B
        output bresp,
        output bid,
        output buser,
        output bvalid,
        input  bready
    );

    // synopsys translate_off

    // Tasks
    `ifdef VERILATOR
        `define EQ__ =
        `define TIME_ALGN #100ps
    `else
        `define EQ__ <=
        `define TIME_ALGN
    `endif

    `ifndef SYNTHESIS
    `ifndef XCELIUM
        task rst_mgr();
            araddr  `EQ__ '0;
            arburst `EQ__ AXI_BURST_FIXED;
            arsize  `EQ__ '0;
            arlen   `EQ__ '0;
            aruser  `EQ__ '0;
            arid    `EQ__ '0;
            arlock  `EQ__ '0;
            arvalid `EQ__ '0;

            rready  `EQ__ '0;

            awaddr  `EQ__ '0;
            awburst `EQ__ AXI_BURST_FIXED;
            awsize  `EQ__ '0;
            awlen   `EQ__ '0;
            awuser  `EQ__ '0;
            awid    `EQ__ '0;
            awlock  `EQ__ '0;
            awvalid `EQ__ '0;

            wdata   `EQ__ '0;
            wstrb   `EQ__ '0;
            wuser   `EQ__ '0;
            wvalid  `EQ__ '0;
            wlast   `EQ__ '0;

            bready  `EQ__ '0;
        endtask

        // TODO: handle IDs?
        task get_read_beat(input logic trace_mbox_read,
                        input int unsigned trace_seq,
                        input logic [AW-1:0] trace_addr,
                        output logic [DW-1:0] data,
                        output logic [UW-1:0] user,
                        output axi_resp_e     resp);
            int unsigned trace_cycles;
            trace_cycles = 0;
            `TIME_ALGN
            rready `EQ__ 1;
            do begin
                @(posedge clk);
                if (trace_mbox_read) begin
                    trace_cycles++;
                    if (trace_cycles <= 3 || rvalid || (trace_cycles % 1000000) == 0)
                        $display("M9AXI R seq=%0d addr=%08x cycles=%0d rvalid=%0b rready=%0b rdata=%08x rresp=%0h ruser=%08x",
                                 trace_seq, trace_addr, trace_cycles, rvalid, rready, rdata, rresp, ruser);
                end
            end while (!rvalid);
            if (trace_mbox_read)
                $display("M9AXI R_ACCEPT seq=%0d addr=%08x cycles=%0d rdata=%08x rresp=%0h ruser=%08x",
                         trace_seq, trace_addr, trace_cycles, rdata, rresp, ruser);
            data   `EQ__ rdata;
            user   `EQ__ ruser;
            resp   `EQ__ axi_resp_e'(rresp);
            `TIME_ALGN
            rready `EQ__ 0;
            wait(!rready);
        endtask

        // Read: default to single beat of native data width
        task axi_read(input  logic [AW-1:0] addr,
                    input  axi_burst_e    burst = AXI_BURST_INCR,
                    input  logic [2:0]    size  = $clog2(DW/8),
                    input  logic [7:0]    len   = 0,
                    input  logic [UW-1:0] user  = UW'(0),
                    input  logic [IW-1:0] id    = IW'(0),
                    input  logic          lock  = 1'b0,
                    output logic [DW-1:0] data [],
                    output logic [UW-1:0] resp_user [],
                    output axi_resp_e     resp []);
            axi_resp_e     beat_resp;
            logic [UW-1:0] beat_user;
            logic [DW-1:0] beat_data;
            bit trace_this_read;
            int unsigned trace_ar_cycles;
            trace_this_read = 0;
            trace_ar_cycles = 0;
            if (addr == AW'(32'h30020000)) begin
                m9_trace_mbox_read_count++;
                trace_this_read = (m9_trace_mbox_read_count <= 20 ||
                                   (m9_trace_mbox_read_count % 1000) == 0);
                if (trace_this_read)
                    $display("M9AXI AR_START seq=%0d addr=%08x t=%0t",
                             m9_trace_mbox_read_count, addr, $time);
            end
            while(!rst_n) @(posedge clk);
            do begin
                `TIME_ALGN
                araddr  `EQ__ addr;
                arburst `EQ__ burst;
                arsize  `EQ__ size;
                arlen   `EQ__ len;
                aruser  `EQ__ user;
                arid    `EQ__ id;
                arlock  `EQ__ lock;
                arvalid `EQ__ 1;
                @(posedge clk);
                if (trace_this_read) begin
                    trace_ar_cycles++;
                    if (trace_ar_cycles <= 3 || arready || (trace_ar_cycles % 1000000) == 0)
                        $display("M9AXI AR_WAIT seq=%0d addr=%08x cycles=%0d arvalid=%0b arready=%0b",
                                 m9_trace_mbox_read_count, addr, trace_ar_cycles, arvalid, arready);
                end
            end while(!arready);
            if (trace_this_read)
                $display("M9AXI AR_ACCEPT seq=%0d addr=%08x cycles=%0d",
                         m9_trace_mbox_read_count, addr, trace_ar_cycles);
            `TIME_ALGN
            araddr  `EQ__ '0;
            arburst `EQ__ AXI_BURST_FIXED;
            arsize  `EQ__ '0;
            arlen   `EQ__ '0;
            aruser  `EQ__ '0;
            arid    `EQ__ '0;
            arlock  `EQ__ '0;
            arvalid `EQ__ '0;
            data = new[len+1];
            resp = new[len+1];
            for (int beat=0; beat <= len; beat++) begin
                get_read_beat(trace_this_read, m9_trace_mbox_read_count, addr,
                              beat_data, beat_user, beat_resp);
                data[beat]      = beat_data;
                resp_user[beat] = beat_user;
                resp[beat]      = beat_resp;
            end
            if (trace_this_read)
                $display("M9AXI READ_RETURN seq=%0d addr=%08x data=%08x resp=%0h user=%08x",
                         m9_trace_mbox_read_count, addr, data[0], resp[0], resp_user[0]);
        endtask

        task axi_read_single(input  logic [AW-1:0] addr,
                            input  logic [UW-1:0] user  = UW'(0),
                            input  logic [IW-1:0] id    = IW'(0),
                            input  logic          lock  = 1'b0,
                            output logic [DW-1:0] data,
                            output logic [UW-1:0] resp_user,
                            output axi_resp_e     resp);
            automatic axi_resp_e     burst_resp[];
            automatic logic [UW-1:0] burst_ruser[];
            automatic logic [DW-1:0] burst_data[];
            automatic bit trace_single;
            automatic int unsigned trace_seq;
            trace_seq = m9_trace_mbox_read_count + 1;
            trace_single = addr == AW'(32'h30020000) &&
                           (trace_seq <= 20 || (trace_seq % 1000) == 0);
            if (trace_single)
                $display("M9AXI SINGLE_BEGIN seq=%0d addr=%08x", trace_seq, addr);
            axi_read(.addr     (addr       ),
                    .user     (user       ),
                    .id       (id         ),
                    .lock     (lock       ),
                    .data     (burst_data ),
                    .resp_user(burst_ruser),
                    .resp     (burst_resp ));
            data      = burst_data[0];
            resp_user = burst_ruser[0];
            resp      = burst_resp[0];
            if (trace_single)
                $display("M9AXI SINGLE_RETURN seq=%0d addr=%08x data=%08x resp=%0h user=%08x",
                         trace_seq, addr, data, resp, resp_user);
        endtask

        task send_write_beat(input logic last,
                            input logic [DW-1:0] data,
                            input logic [UW-1:0] user,
                            input logic [DW/8-1:0] strb);
            `TIME_ALGN
            wvalid `EQ__ 1;
            wlast  `EQ__ last;
            wdata  `EQ__ data;
            wstrb  `EQ__ strb;
            wuser  `EQ__ user;
            do
                @(posedge clk);
            while (!wready);
            `TIME_ALGN
            wvalid `EQ__ '0;
            wlast  `EQ__ '0;
            wdata  `EQ__ '0;
            wstrb  `EQ__ '0;
            wuser  `EQ__ '0;
            wait(!wvalid);
        endtask

        // TODO handle ID
        task get_write_resp(output axi_resp_e     resp,
                            output logic [UW-1:0] user);
            `TIME_ALGN
            bready `EQ__ 1;
            do
                @(posedge clk);
            while(!bvalid);
            resp `EQ__ axi_resp_e'(bresp);
            user `EQ__ buser;
            `TIME_ALGN
            bready `EQ__ 0;
            wait(!bready);
        endtask

        task axi_write(input  logic [AW-1:0]   addr,
                    input  axi_burst_e      burst = AXI_BURST_INCR,
                    input  logic [2:0]      size  = $clog2(DW/8),
                    input  logic [7:0]      len   = 0,
                    input  logic [UW-1:0]   user  = UW'(0),
                    input  logic [IW-1:0]   id    = IW'(0),
                    input  logic            lock  = 1'b0,
                    input  logic [DW-1:0]   data [],
                    input  logic            use_strb = 0,
                    input  logic [DW/8-1:0] strb [],
                    input  logic            use_write_user = 0,
                    input  logic [UW-1:0]   write_user [],
                    output axi_resp_e       resp,
                    output logic [UW-1:0]   resp_user);
            while(!rst_n) @(posedge clk);
            do begin
                `TIME_ALGN
                awaddr  `EQ__ addr;
                awburst `EQ__ burst;
                awsize  `EQ__ size;
                awlen   `EQ__ len;
                awuser  `EQ__ user;
                awid    `EQ__ id;
                awlock  `EQ__ lock;
                awvalid `EQ__ 1;
                @(posedge clk);
            end while(!awready);
            `TIME_ALGN
            awaddr  `EQ__ '0;
            awburst `EQ__ AXI_BURST_FIXED;
            awsize  `EQ__ '0;
            awlen   `EQ__ '0;
            awuser  `EQ__ '0;
            awid    `EQ__ '0;
            awlock  `EQ__ '0;
            awvalid `EQ__ '0;
            fork
                for (int beat=0; beat <= len; beat++)
                    send_write_beat(beat == len, data[beat], use_write_user ? write_user[beat] : UW'(0), use_strb ? strb[beat] : {DW/8{1'b1}});
                get_write_resp(resp, resp_user);
            join
        endtask

        task axi_write_single(input  logic [AW-1:0] addr,
                            input  logic [UW-1:0] user  = UW'(0),
                            input  logic [IW-1:0] id    = IW'(0),
                            input  logic          lock  = 1'b0,
                            input  logic [DW-1:0] data,
                            input  logic [UW-1:0] write_user = UW'(0),
                            output axi_resp_e     resp,
                            output logic [UW-1:0] resp_user);
            automatic logic [DW/8-1:0] burst_strb[] = new[1]('{{DW/8{1'b1}}});
            automatic logic [UW  -1:0] burst_user[] = new[1]('{write_user});
            automatic logic [DW  -1:0] burst_data[] = new[1]('{data});
            axi_write(.addr(addr),
                    .user(user),
                    .id  (id  ),
                    .lock(lock),
                    .data(burst_data),
                    .use_strb(0),
                    .strb(burst_strb),
                    .use_write_user(0),
                    .write_user(burst_user),
                    .resp(resp),
                    .resp_user(resp_user));
        endtask
    `endif
    `endif

    `undef EQ__
    `undef TIME_ALGN

    // synopsys translate_on

endinterface
