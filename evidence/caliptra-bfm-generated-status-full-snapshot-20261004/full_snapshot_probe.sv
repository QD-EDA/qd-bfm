// SPDX-License-Identifier: Apache-2.0
package status_full_snapshot_probe_pkg;
  import uvm_pkg::*;
  import uvmf_base_pkg::*;
  import cptra_status_pkg::*;
  `include "uvm_macros.svh"

  class status_coverage_probe extends cptra_status_transaction_coverage;
    `uvm_component_utils(status_coverage_probe)

    int unsigned sample_count;

    function new(string name = "status_coverage_probe", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void write(cptra_status_transaction item);
      sample_count++;
      super.write(item);
    endfunction
  endclass

  class status_full_snapshot_probe_test extends uvm_test;
    `uvm_component_utils(status_full_snapshot_probe_test)

    cptra_status_configuration cfg;
    cptra_status_agent status_agent;
    status_coverage_probe status_coverage;
    uvm_analysis_imp #(cptra_status_transaction, status_full_snapshot_probe_test) observed_export;
    int unsigned observations;
    bit first_snapshot_ok;
    bit second_snapshot_ok;
    bit third_snapshot_ok;

    function new(string name = "status_full_snapshot_probe_test", uvm_component parent = null);
      super.new(name, parent);
      observed_export = new("observed_export", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      cfg = cptra_status_configuration::type_id::create("cfg");
      cfg.initialize(PASSIVE, "uvm_test_top.status_agent", "cptra_status_agent_BFM");
      status_agent = cptra_status_agent::type_id::create("status_agent", this);
      status_coverage = status_coverage_probe::type_id::create("status_coverage", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      status_agent.monitored_ap.connect(observed_export);
      status_agent.monitored_ap.connect(status_coverage.analysis_export);
    endfunction

    function bit matches_snapshot(cptra_status_transaction item, int unsigned snapshot);
      bit expected_noncore_asserted;
      bit expected_uc_asserted;
      bit expected_fw_update_window;
      bit expected_soc_error;
      bit expected_soc_notif;
      bit expected_sha_error;
      bit expected_sha_notif;
      bit expected_dma_error;
      bit expected_dma_notif;
      bit expected_timer;
      bit [31:0] expected_nmi_vector;
      bit expected_nmi;
      bit expected_iccm_locked;
      bit matched;

      if (snapshot == 0) begin
        expected_noncore_asserted = 1'b0;
        expected_uc_asserted = 1'b1;
        expected_fw_update_window = 1'b0;
        expected_soc_error = 1'b0;
        expected_soc_notif = 1'b0;
        expected_sha_error = 1'b0;
        expected_sha_notif = 1'b0;
        expected_dma_error = 1'b0;
        expected_dma_notif = 1'b0;
        expected_timer = 1'b0;
        expected_nmi_vector = 32'b0;
        expected_nmi = 1'b0;
        expected_iccm_locked = 1'b0;
      end else if (snapshot == 1) begin
        expected_noncore_asserted = 1'b1;
        expected_uc_asserted = 1'b0;
        expected_fw_update_window = 1'b1;
        expected_soc_error = 1'b1;
        expected_soc_notif = 1'b0;
        expected_sha_error = 1'b1;
        expected_sha_notif = 1'b0;
        expected_dma_error = 1'b0;
        expected_dma_notif = 1'b1;
        expected_timer = 1'b1;
        expected_nmi_vector = 32'hA5C39E71;
        expected_nmi = 1'b1;
        expected_iccm_locked = 1'b1;
      end else begin
        expected_noncore_asserted = 1'b0;
        expected_uc_asserted = 1'b1;
        expected_fw_update_window = 1'b0;
        expected_soc_error = 1'b0;
        expected_soc_notif = 1'b1;
        expected_sha_error = 1'b0;
        expected_sha_notif = 1'b1;
        expected_dma_error = 1'b1;
        expected_dma_notif = 1'b0;
        expected_timer = 1'b0;
        expected_nmi_vector = 32'h5A3C618E;
        expected_nmi = 1'b0;
        expected_iccm_locked = 1'b0;
      end

      matched = item.noncore_rst_asserted === expected_noncore_asserted
        && item.uc_rst_asserted === expected_uc_asserted
        && item.fw_update_rst_window === expected_fw_update_window
        && item.soc_ifc_err_intr_pending === expected_soc_error
        && item.soc_ifc_notif_intr_pending === expected_soc_notif
        && item.sha_err_intr_pending === expected_sha_error
        && item.sha_notif_intr_pending === expected_sha_notif
        && item.dma_err_intr_pending === expected_dma_error
        && item.dma_notif_intr_pending === expected_dma_notif
        && item.timer_intr_pending === expected_timer
        && item.nmi_vector === expected_nmi_vector
        && item.nmi_intr_pending === expected_nmi
        && item.iccm_locked === expected_iccm_locked;

      for (int unsigned i = 0; i < 8; i++) begin
        if (snapshot == 0) begin
          matched &= item.cptra_obf_key_reg[i] === 32'b0;
          matched &= item.obf_field_entropy[i] === 32'b0;
          matched &= item.obf_hek_seed[i] === 32'b0;
        end else if (snapshot == 1) begin
          matched &= item.cptra_obf_key_reg[i] === (32'hC001_0000 | i);
          matched &= item.obf_field_entropy[i] === (32'hFE00_1000 | i);
          matched &= item.obf_hek_seed[i] === (32'h0E1E_0000 | i);
        end else begin
          matched &= item.cptra_obf_key_reg[i] === (32'hC002_0000 | i);
          matched &= item.obf_field_entropy[i] === (32'hFE00_2000 | i);
          matched &= item.obf_hek_seed[i] === (32'h0E2E_0000 | i);
        end
      end
      for (int unsigned i = 0; i < 16; i++) begin
        if (snapshot == 0)
          matched &= item.obf_uds_seed[i] === 32'b0;
        else if (snapshot == 1)
          matched &= item.obf_uds_seed[i] === (32'h0D50_0000 | i);
        else
          matched &= item.obf_uds_seed[i] === (32'h0D60_0000 | i);
      end
      return matched;
    endfunction

    function void write(cptra_status_transaction item);
      observations++;
      if (observations == 1) begin
        first_snapshot_ok = matches_snapshot(item, 0);
        if (!first_snapshot_ok)
          `uvm_error("STATUS_SNAPSHOT", "startup generated status record did not preserve all 17 sampled fields")
      end else if (observations == 2) begin
        second_snapshot_ok = matches_snapshot(item, 1);
        if (!second_snapshot_ok)
          `uvm_error("STATUS_SNAPSHOT", "first driven status record did not preserve all 17 sampled fields")
      end else if (observations == 3) begin
        third_snapshot_ok = matches_snapshot(item, 2);
        if (!third_snapshot_ok)
          `uvm_error("STATUS_SNAPSHOT", "second driven status record did not preserve all 17 sampled fields")
      end else begin
        `uvm_error("STATUS_SNAPSHOT", $sformatf("unexpected extra status record %0d", observations))
      end
    endfunction

    virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      fork
        begin
          wait (observations == 3);
          if (!first_snapshot_ok || !second_snapshot_ok || !third_snapshot_ok)
            `uvm_fatal("STATUS_SNAPSHOT", "full-field snapshot validation failed")
          if (status_coverage.sample_count != 3)
            `uvm_fatal("STATUS_SNAPSHOT", $sformatf("generated coverage subscriber received %0d of 3 snapshots", status_coverage.sample_count))
          `uvm_info("STATUS_SNAPSHOT",
            "PASS: generated passive monitor preserved all status fields and the generated coverage subscriber received all three snapshots",
            UVM_NONE)
        end
        begin
          #200;
          `uvm_fatal("STATUS_SNAPSHOT", "timed out waiting for startup and two event snapshots")
        end
      join_any
      disable fork;
      phase.drop_objection(this);
    endtask
  endclass
endpackage

module tb_generated_status_full_snapshot;
  import uvm_pkg::*;
  import uvmf_base_pkg::*;
  import status_full_snapshot_probe_pkg::*;

  bit clk;
  bit dummy;
  bit cptra_noncore_rst_b_drive = 1'b1;
  bit cptra_uc_rst_b_drive = 1'b0;
  bit fw_update_rst_window_drive;
  bit [7:0][31:0] cptra_obf_key_reg_drive;
  bit [7:0][31:0] obf_field_entropy_drive;
  bit [15:0][31:0] obf_uds_seed_drive;
  bit [7:0][31:0] obf_hek_seed_drive;
  bit soc_ifc_error_intr_drive;
  bit soc_ifc_notif_intr_drive;
  bit sha_error_intr_drive;
  bit sha_notif_intr_drive;
  bit dma_error_intr_drive;
  bit dma_notif_intr_drive;
  bit timer_intr_drive;
  bit [31:0] nmi_vector_drive;
  bit nmi_intr_drive;
  bit iccm_lock_drive;

  tri cptra_noncore_rst_b, cptra_uc_rst_b, fw_update_rst_window;
  tri [7:0][31:0] cptra_obf_key_reg, obf_field_entropy;
  tri [15:0][31:0] obf_uds_seed;
  tri [7:0][31:0] obf_hek_seed;
  tri soc_ifc_error_intr, soc_ifc_notif_intr, sha_error_intr, sha_notif_intr;
  tri dma_error_intr, dma_notif_intr, timer_intr;
  tri [31:0] nmi_vector;
  tri nmi_intr, iccm_lock;

  assign cptra_noncore_rst_b = cptra_noncore_rst_b_drive;
  assign cptra_uc_rst_b = cptra_uc_rst_b_drive;
  assign fw_update_rst_window = fw_update_rst_window_drive;
  assign cptra_obf_key_reg = cptra_obf_key_reg_drive;
  assign obf_field_entropy = obf_field_entropy_drive;
  assign obf_uds_seed = obf_uds_seed_drive;
  assign obf_hek_seed = obf_hek_seed_drive;
  assign soc_ifc_error_intr = soc_ifc_error_intr_drive;
  assign soc_ifc_notif_intr = soc_ifc_notif_intr_drive;
  assign sha_error_intr = sha_error_intr_drive;
  assign sha_notif_intr = sha_notif_intr_drive;
  assign dma_error_intr = dma_error_intr_drive;
  assign dma_notif_intr = dma_notif_intr_drive;
  assign timer_intr = timer_intr_drive;
  assign nmi_vector = nmi_vector_drive;
  assign nmi_intr = nmi_intr_drive;
  assign iccm_lock = iccm_lock_drive;

  cptra_status_if bus(clk, dummy, cptra_noncore_rst_b, cptra_uc_rst_b,
    fw_update_rst_window, cptra_obf_key_reg, obf_field_entropy, obf_uds_seed,
    obf_hek_seed, soc_ifc_error_intr, soc_ifc_notif_intr, sha_error_intr,
    sha_notif_intr, dma_error_intr, dma_notif_intr, timer_intr, nmi_vector,
    nmi_intr, iccm_lock);
  cptra_status_driver_bfm driver_bfm(bus);
  cptra_status_monitor_bfm monitor_bfm(bus);

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    driver_bfm.initiator_responder = RESPONDER;
    uvm_config_db #(virtual cptra_status_driver_bfm)::set(
      null, UVMF_VIRTUAL_INTERFACES, "cptra_status_agent_BFM", driver_bfm);
    uvm_config_db #(virtual cptra_status_monitor_bfm)::set(
      null, UVMF_VIRTUAL_INTERFACES, "cptra_status_agent_BFM", monitor_bfm);
    run_test("status_full_snapshot_probe_test");
  end

  initial begin
    #30;
    cptra_noncore_rst_b_drive = 1'b0;
    cptra_uc_rst_b_drive = 1'b1;
    fw_update_rst_window_drive = 1'b1;
    soc_ifc_error_intr_drive = 1'b1;
    soc_ifc_notif_intr_drive = 1'b0;
    sha_error_intr_drive = 1'b1;
    sha_notif_intr_drive = 1'b0;
    dma_error_intr_drive = 1'b0;
    dma_notif_intr_drive = 1'b1;
    timer_intr_drive = 1'b1;
    nmi_vector_drive = 32'hA5C39E71;
    nmi_intr_drive = 1'b1;
    iccm_lock_drive = 1'b1;
    for (int unsigned i = 0; i < 8; i++) begin
      cptra_obf_key_reg_drive[i] = 32'hC001_0000 | i;
      obf_field_entropy_drive[i] = 32'hFE00_1000 | i;
      obf_hek_seed_drive[i] = 32'h0E1E_0000 | i;
    end
    for (int unsigned i = 0; i < 16; i++)
      obf_uds_seed_drive[i] = 32'h0D50_0000 | i;

    #20;
    cptra_noncore_rst_b_drive = 1'b1;
    cptra_uc_rst_b_drive = 1'b0;
    fw_update_rst_window_drive = 1'b0;
    soc_ifc_error_intr_drive = 1'b0;
    soc_ifc_notif_intr_drive = 1'b1;
    sha_error_intr_drive = 1'b0;
    sha_notif_intr_drive = 1'b1;
    dma_error_intr_drive = 1'b1;
    dma_notif_intr_drive = 1'b0;
    timer_intr_drive = 1'b0;
    nmi_vector_drive = 32'h5A3C618E;
    nmi_intr_drive = 1'b0;
    iccm_lock_drive = 1'b0;
    for (int unsigned i = 0; i < 8; i++) begin
      cptra_obf_key_reg_drive[i] = 32'hC002_0000 | i;
      obf_field_entropy_drive[i] = 32'hFE00_2000 | i;
      obf_hek_seed_drive[i] = 32'h0E2E_0000 | i;
    end
    for (int unsigned i = 0; i < 16; i++)
      obf_uds_seed_drive[i] = 32'h0D60_0000 | i;
  end
endmodule
