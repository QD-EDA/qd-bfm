#include <inttypes.h>
#include <stdio.h>
#include <stdint.h>
#include "vpi_user.h"

static vpiHandle clk, valid, pc, insn, ready, rst, fatal;
static vpiHandle stdout_data, mailbox_write, reset_pending, reset_delay;
static vpiHandle reset_start, reset_assert, reset_deassert;
static vpiHandle arvalid, arready, araddr, rvalid, rready;
static vpiHandle awvalid, awready, awaddr, wvalid, wready, bvalid, bready;
static uint64_t cycles, retired, ar_count, r_count, aw_count, w_count, b_count;
static uint32_t last_pc, last_insn;
static char last_araddr[80], last_awaddr[80];
static int reset_trace_bound, reset_seen, previous_reset_n, previous_reset_request;

static int get_int(vpiHandle h) {
    s_vpi_value v;
    v.format = vpiIntVal;
    vpi_get_value(h, &v);
    return v.value.integer;
}

static void get_bin(vpiHandle h, char *out, size_t size) {
    s_vpi_value v;
    v.format = vpiBinStrVal;
    vpi_get_value(h, &v);
    snprintf(out, size, "%s", v.value.str ? v.value.str : "x");
}

static PLI_INT32 on_clock(p_cb_data cb) {
    (void)cb;
    if (reset_trace_bound) {
        int reset_n = get_int(rst);
        int reset_request = get_int(mailbox_write) && ((get_int(stdout_data) & 0xff) == 0xee);
        if (reset_seen && reset_n != previous_reset_n)
            vpi_printf("CALIPTRA_RESET_EDGE state=%s cycle=%" PRIu64
                       " pending=%d wait=%d start=%d\n",
                       reset_n ? "deassert" : "assert", cycles,
                       get_int(reset_pending), get_int(reset_delay), get_int(reset_start));
        if (reset_request && !previous_reset_request)
            vpi_printf("CALIPTRA_RESET_REQUEST cycle=%" PRIu64
                       " code=ee pending=%d wait=%d start=%d\n",
                       cycles, get_int(reset_pending), get_int(reset_delay), get_int(reset_start));
        previous_reset_n = reset_n;
        previous_reset_request = reset_request;
        reset_seen = 1;
    }
    if (get_int(clk) != 1) return 0;
    cycles++;
    if (get_int(valid)) {
        retired++;
        last_pc = (uint32_t)get_int(pc);
        last_insn = (uint32_t)get_int(insn);
    }
    if (get_int(arvalid) && get_int(arready)) { ar_count++; get_bin(araddr, last_araddr, sizeof(last_araddr));
        vpi_printf("CALIPTRA_AXI AR count=%" PRIu64 " addr=%s cycle=%" PRIu64 " pc=%08" PRIx32 "\n", ar_count, last_araddr, cycles, last_pc); }
    if (get_int(rvalid) && get_int(rready)) { r_count++; vpi_printf("CALIPTRA_AXI R count=%" PRIu64 " cycle=%" PRIu64 " pc=%08" PRIx32 "\n", r_count, cycles, last_pc); }
    if (get_int(awvalid) && get_int(awready)) { aw_count++; get_bin(awaddr, last_awaddr, sizeof(last_awaddr));
        vpi_printf("CALIPTRA_AXI AW count=%" PRIu64 " addr=%s cycle=%" PRIu64 " pc=%08" PRIx32 "\n", aw_count, last_awaddr, cycles, last_pc); }
    if (get_int(wvalid) && get_int(wready)) { w_count++; vpi_printf("CALIPTRA_AXI W count=%" PRIu64 " cycle=%" PRIu64 " pc=%08" PRIx32 "\n", w_count, cycles, last_pc); }
    if (get_int(bvalid) && get_int(bready)) { b_count++; vpi_printf("CALIPTRA_AXI B count=%" PRIu64 " cycle=%" PRIu64 " pc=%08" PRIx32 "\n", b_count, cycles, last_pc); }
    if (cycles % 100 == 0) {
        vpi_printf("CALIPTRA_TRACE cycle=%" PRIu64 " retired=%" PRIu64
                   " pc=%08" PRIx32 " insn=%08" PRIx32
                   " ready_mb=%d reset_n=%d fatal=%d axi_ar=%" PRIu64
                   " axi_aw=%" PRIu64 " axi_w=%" PRIu64 " axi_b=%" PRIu64 " axi_r=%" PRIu64 "\n",
                   cycles, retired, last_pc, last_insn, get_int(ready), get_int(rst), get_int(fatal), ar_count, aw_count, w_count, b_count, r_count);
        if (reset_trace_bound && (get_int(reset_pending) || get_int(reset_assert) || get_int(reset_deassert)))
            vpi_printf("CALIPTRA_RESET_SERVICE cycle=%" PRIu64
                       " pending=%d wait=%d start=%d assert=%d deassert=%d\n",
                       cycles, get_int(reset_pending), get_int(reset_delay), get_int(reset_start),
                       get_int(reset_assert), get_int(reset_deassert));
        vpi_flush();
    }
    return 0;
}

static PLI_INT32 finish(p_cb_data cb) {
    (void)cb;
    vpi_printf("CALIPTRA_TRACE_END cycles=%" PRIu64 " retired=%" PRIu64
               " pc=%08" PRIx32 " insn=%08" PRIx32 " axi_ar=%" PRIu64
               " axi_aw=%" PRIu64 " axi_w=%" PRIu64 " axi_b=%" PRIu64 " axi_r=%" PRIu64 "\n",
               cycles, retired, last_pc, last_insn, ar_count, aw_count, w_count, b_count, r_count);
    return 0;
}

static vpiHandle bind(const char *name) {
    return vpi_handle_by_name((PLI_BYTE8 *)name, NULL);
}

static PLI_INT32 start(p_cb_data cb) {
    (void)cb;
    clk = bind("caliptra_top_tb.core_clk");
    valid = bind("caliptra_top_tb.caliptra_top_dut.trace_rv_i_valid_ip");
    pc = bind("caliptra_top_tb.caliptra_top_dut.trace_rv_i_address_ip");
    insn = bind("caliptra_top_tb.caliptra_top_dut.trace_rv_i_insn_ip");
    ready = bind("caliptra_top_tb.ready_for_mb_processing");
    rst = bind("caliptra_top_tb.cptra_rst_b");
    fatal = bind("caliptra_top_tb.cptra_error_fatal");
    stdout_data = bind("caliptra_top_tb.tb_services_i.WriteData");
    mailbox_write = bind("caliptra_top_tb.tb_services_i.mailbox_write");
    reset_pending = bind("caliptra_top_tb.tb_services_i.prandom_warm_rst");
    reset_delay = bind("caliptra_top_tb.tb_services_i.wait_time_to_rst");
    reset_start = bind("caliptra_top_tb.tb_services_i.rst_cyclecnt");
    reset_assert = bind("caliptra_top_tb.tb_services_i.assert_rst_flag");
    reset_deassert = bind("caliptra_top_tb.tb_services_i.deassert_rst_flag");
    arvalid = bind("caliptra_top_tb.m_axi_if.arvalid");
    arready = bind("caliptra_top_tb.m_axi_if.arready");
    araddr = bind("caliptra_top_tb.m_axi_if.araddr");
    rvalid = bind("caliptra_top_tb.m_axi_if.rvalid");
    rready = bind("caliptra_top_tb.m_axi_if.rready");
    awvalid = bind("caliptra_top_tb.m_axi_if.awvalid");
    awready = bind("caliptra_top_tb.m_axi_if.awready");
    awaddr = bind("caliptra_top_tb.m_axi_if.awaddr");
    wvalid = bind("caliptra_top_tb.m_axi_if.wvalid");
    wready = bind("caliptra_top_tb.m_axi_if.wready");
    bvalid = bind("caliptra_top_tb.m_axi_if.bvalid");
    bready = bind("caliptra_top_tb.m_axi_if.bready");
    if (!clk || !valid || !pc || !insn || !ready || !rst || !fatal || !arvalid || !arready || !araddr ||
        !rvalid || !rready || !awvalid || !awready || !awaddr || !wvalid || !wready || !bvalid || !bready) {
        vpi_printf("CALIPTRA_TRACE_BIND_FAIL clk=%p valid=%p pc=%p ready=%p arvalid=%p arready=%p araddr=%p awvalid=%p awready=%p awaddr=%p\n",
                   (void *)clk, (void *)valid, (void *)pc, (void *)ready, (void *)arvalid, (void *)arready,
                   (void *)araddr, (void *)awvalid, (void *)awready, (void *)awaddr);
        vpi_flush();
        return 0;
    }
    reset_trace_bound = stdout_data && mailbox_write && reset_pending && reset_delay && reset_start && reset_assert && reset_deassert;
    if (reset_trace_bound) {
        previous_reset_n = get_int(rst);
        reset_seen = 1;
        vpi_printf("CALIPTRA_RESET_TRACE_BOUND\n");
    } else {
        vpi_printf("CALIPTRA_RESET_TRACE_BIND_FAIL data=%p write=%p pending=%p delay=%p start=%p assert=%p deassert=%p\n",
                   (void *)stdout_data, (void *)mailbox_write, (void *)reset_pending, (void *)reset_delay,
                   (void *)reset_start, (void *)reset_assert, (void *)reset_deassert);
    }
    vpi_printf("CALIPTRA_TRACE_BOUND\n");
    vpi_flush();
    s_vpi_value value;
    value.format = vpiIntVal;
    s_cb_data cb_clk = {0}; cb_clk.reason = cbValueChange; cb_clk.cb_rtn = on_clock; cb_clk.obj = clk; cb_clk.value = &value;
    vpi_register_cb(&cb_clk);
    s_cb_data cb_end = {0}; cb_end.reason = cbEndOfSimulation; cb_end.cb_rtn = finish; vpi_register_cb(&cb_end);
    return 0;
}

static void register_trace(void) { s_cb_data cb = {0}; cb.reason = cbStartOfSimulation; cb.cb_rtn = start; vpi_register_cb(&cb); }
void (*vlog_startup_routines[])(void) = { register_trace, 0 };
