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
        // Sample ARREADY in the same edge region as the subordinate assertion.
        `define AR_EQ__ <=
        `define WAIT_ARREADY @(posedge clk)
        `define SAMPLE_ARREADY axi_if_arready_cb.arready
        clocking axi_if_arready_cb @(posedge clk);
            input #1step arvalid, arready, araddr, rst_n;
        endclocking
        int unsigned m11_ar_trace_cycle = 0;
        int unsigned m11_ar_trace_count = 0;
        bit m11_ar_trace_active = 0;
        always @(posedge clk) begin
            m11_ar_trace_cycle++;
            if (axi_if_arready_cb.araddr == 32'h30020000)
                m11_ar_trace_active = 1;
            if (m11_ar_trace_active) begin
                m11_ar_trace_count++;
                if (m11_ar_trace_count <= 12 ||
                    !axi_if_arready_cb.arvalid || axi_if_arready_cb.arready ||
                    (m11_ar_trace_count % 1000000) == 0) begin
                    $display("M11_MBOX_AR_SAMPLE cycle=%0d time=%0t rst_n=%b addr=%08x valid=%b ready=%b",
                             m11_ar_trace_cycle, $time, axi_if_arready_cb.rst_n,
                             axi_if_arready_cb.araddr, axi_if_arready_cb.arvalid,
                             axi_if_arready_cb.arready);
                    $strobe("M11_MBOX_AR_POST cycle=%0d time=%0t rst_n=%b addr=%08x valid=%b ready=%b",
                            m11_ar_trace_cycle, $time, rst_n, araddr, arvalid, arready);
                end
                if (!axi_if_arready_cb.arvalid || axi_if_arready_cb.arready)
                    m11_ar_trace_active = 0;
            end
        end
        // SVA samples before the edge; keep AW drives out of its sampling region.
        `define AW_EQ__ <=
        `define TIME_ALGN #100ps
        // Wait on the clock itself; Verilator's clocking-block event spun at the first write.
        `define WAIT_AWREADY @(posedge clk)
        `define SAMPLE_AWREADY axi_if_awready_cb.awready
        clocking axi_if_awready_cb @(posedge clk);
            input #1step awready;
        endclocking
        // Keep W valid/data stable through the assertion sample at the clock edge.
        `define W_EQ__ <=
        `define WAIT_WREADY @(posedge clk)
        `define SAMPLE_WREADY axi_if_wready_cb.wready
        clocking axi_if_wready_cb @(posedge clk);
            input #1step wready;
        endclocking
        // Keep BREADY asserted until BVALID is seen in the assertion sample region.
        `define B_EQ__ <=
        `define WAIT_BVALID @(posedge clk)
        `define SAMPLE_BVALID axi_if_bvalid_cb.bvalid
        clocking axi_if_bvalid_cb @(posedge clk);
            input #1step bvalid;
        endclocking
    `else
        `define EQ__ <=
        `define AR_EQ__ <=
        `define AW_EQ__ <=
        `define W_EQ__ <=
        `define TIME_ALGN
        `define WAIT_ARREADY @(posedge clk)
        `define SAMPLE_ARREADY arready
        `define WAIT_AWREADY @(posedge clk)
        `define SAMPLE_AWREADY awready
        `define WAIT_WREADY @(posedge clk)
        `define SAMPLE_WREADY wready
        `define B_EQ__ <=
        `define WAIT_BVALID @(posedge clk)
        `define SAMPLE_BVALID bvalid
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
        task get_read_beat(output logic [DW-1:0] data,
                        output logic [UW-1:0] user,
                        output axi_resp_e     resp);
            `TIME_ALGN
            rready `EQ__ 1;
            do
                @(posedge clk);
            while (!rvalid);
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
            while(!rst_n) @(posedge clk);
            do begin
                `TIME_ALGN
                araddr  `AR_EQ__ addr;
                arburst `AR_EQ__ burst;
                arsize  `AR_EQ__ size;
                arlen   `AR_EQ__ len;
                aruser  `AR_EQ__ user;
                arid    `AR_EQ__ id;
                arlock  `AR_EQ__ lock;
                arvalid `AR_EQ__ 1;
                `WAIT_ARREADY;
                if (addr == AW'(32'h30020000)) begin
                    $display("M11_MBOX_AR_TASK time=%0t addr=%08x sampled_valid=%b sampled_ready=%b live_valid=%b live_ready=%b",
                             $time, addr, axi_if_arready_cb.arvalid,
                             `SAMPLE_ARREADY, arvalid, arready);
                end
            end while(!`SAMPLE_ARREADY);
            `TIME_ALGN
            araddr  `AR_EQ__ '0;
            arburst `AR_EQ__ AXI_BURST_FIXED;
            arsize  `AR_EQ__ '0;
            arlen   `AR_EQ__ '0;
            aruser  `AR_EQ__ '0;
            arid    `AR_EQ__ '0;
            arlock  `AR_EQ__ '0;
            arvalid `AR_EQ__ '0;
            data = new[len+1];
            resp = new[len+1];
            for (int beat=0; beat <= len; beat++) begin
                get_read_beat(beat_data, beat_user, beat_resp);
                data[beat]      = beat_data;
                resp_user[beat] = beat_user;
                resp[beat]      = beat_resp;
            end
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
        endtask

        task send_write_beat(input logic last,
                            input logic [DW-1:0] data,
                            input logic [UW-1:0] user,
                            input logic [DW/8-1:0] strb);
            `TIME_ALGN
            wvalid `W_EQ__ 1;
            wlast  `W_EQ__ last;
            wdata  `W_EQ__ data;
            wstrb  `W_EQ__ strb;
            wuser  `W_EQ__ user;
            do
                `WAIT_WREADY;
            while (!`SAMPLE_WREADY);
            `TIME_ALGN
            wvalid `W_EQ__ '0;
            wlast  `W_EQ__ '0;
            wdata  `W_EQ__ '0;
            wstrb  `W_EQ__ '0;
            wuser  `W_EQ__ '0;
            wait(!wvalid);
        endtask

        // TODO handle ID
        task get_write_resp(output axi_resp_e     resp,
                            output logic [UW-1:0] user);
            `TIME_ALGN
            bready `B_EQ__ 1;
            do
                `WAIT_BVALID;
            while(!`SAMPLE_BVALID);
            resp `EQ__ axi_resp_e'(bresp);
            user `EQ__ buser;
            `TIME_ALGN
            bready `B_EQ__ 0;
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
                awaddr  `AW_EQ__ addr;
                awburst `AW_EQ__ burst;
                awsize  `AW_EQ__ size;
                awlen   `AW_EQ__ len;
                awuser  `AW_EQ__ user;
                awid    `AW_EQ__ id;
                awlock  `AW_EQ__ lock;
                awvalid `AW_EQ__ 1;
                `WAIT_AWREADY;
            end while(!`SAMPLE_AWREADY);
            `TIME_ALGN
            awaddr  `AW_EQ__ '0;
            awburst `AW_EQ__ AXI_BURST_FIXED;
            awsize  `AW_EQ__ '0;
            awlen   `AW_EQ__ '0;
            awuser  `AW_EQ__ '0;
            awid    `AW_EQ__ '0;
            awlock  `AW_EQ__ '0;
            awvalid `AW_EQ__ '0;
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

    `undef WAIT_AWREADY
    `undef SAMPLE_AWREADY
    `undef WAIT_ARREADY
    `undef SAMPLE_ARREADY
    `undef WAIT_WREADY
    `undef SAMPLE_WREADY
    `undef WAIT_BVALID
    `undef SAMPLE_BVALID
    `undef AW_EQ__
    `undef AR_EQ__
    `undef W_EQ__
    `undef B_EQ__
    `undef EQ__
    `undef TIME_ALGN

    // synopsys translate_on

endinterface
