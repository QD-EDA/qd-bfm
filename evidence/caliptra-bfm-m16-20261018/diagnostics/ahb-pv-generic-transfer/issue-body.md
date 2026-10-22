## Reduced reproducer

```systemverilog
package mvc_types_pkg;
  class mvc_sequence_item_base;
  endclass

  class ahb_master_burst_transfer extends mvc_sequence_item_base;
    bit RnW;
    bit [31:0] address;
    bit [2:0] size;
    bit [63:0] data[$];
    bit [1:0] resp[$];
  endclass
endpackage

package qvip_compat_pkg;
  import mvc_types_pkg::*;

  class ahb_reg_predictor #(type T = ahb_master_burst_transfer);
    virtual function void write(mvc_sequence_item_base tr);
      T transfer;
      T beat;
      if (!$cast(transfer, tr)) return;
      beat = new();
      beat.RnW = transfer.RnW;
      beat.size = transfer.size;
      for (int unsigned i = 0; i < transfer.data.size(); i++) begin
        beat.address = transfer.address + (i * (1 << transfer.size));
        beat.data.delete();
        beat.data.push_back(transfer.data[i]);
        beat.resp.delete();
        beat.resp.push_back(transfer.resp[i]);
      end
    endfunction
  endclass

  class pv_ahb_reg_predictor #(type T = int)
    extends ahb_reg_predictor #(.T(T));
    virtual function void write(mvc_sequence_item_base tr);
      T ahb_txn;
      $cast(ahb_txn, tr);
      if (ahb_txn.RnW && ahb_txn.address == 32'h1000)
        $display("PV_WRITE %h %h", ahb_txn.address, ahb_txn.data[0]);
    endfunction
  endclass
endpackage

module pv_generic_transfer_repro;
  import mvc_types_pkg::*;
  import qvip_compat_pkg::*;

  ahb_master_burst_transfer transfer;
  pv_ahb_reg_predictor #(ahb_master_burst_transfer) predictor;

  initial begin
    transfer = new();
    predictor = new();
    transfer.RnW = 1;
    transfer.address = 32'h1000;
    transfer.data.push_back(64'h1234);
    transfer.resp.push_back(2'b00);
    predictor.write(transfer);
    $finish;
  end
endmodule
```

Run with the pinned compiler:

```sh
iverilog -g2012 -s pv_generic_transfer_repro -o repro.vvp pv_generic_transfer_repro.sv
vvp -n repro.vvp
```

## Observed

Icarus 13.0 devel, source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, exits 10 during elaboration. The runtime does not start.

```text
/home/dsell/slurm-runs/caliptra-bfm/a2/m16-ahb-pv-generic-transfer-20261018-01/pv_generic_transfer_repro.sv:40: error: Variable ahb_txn does not have a field named: RnW.
/home/dsell/slurm-runs/caliptra-bfm/a2/m16-ahb-pv-generic-transfer-20261018-01/pv_generic_transfer_repro.sv:40: error: Variable ahb_txn does not have a field named: address.
/home/dsell/slurm-runs/caliptra-bfm/a2/m16-ahb-pv-generic-transfer-20261018-01/pv_generic_transfer_repro.sv:23: error: `beat' has no member `RnW' (after an earlier error on this name).
/home/dsell/slurm-runs/caliptra-bfm/a2/m16-ahb-pv-generic-transfer-20261018-01/pv_generic_transfer_repro.sv:24: error: `beat' has no member `size' (after an earlier error on this name).
/home/dsell/slurm-runs/caliptra-bfm/a2/m16-ahb-pv-generic-transfer-20261018-01/pv_generic_transfer_repro.sv:26: error: `beat' has no member `address' (after an earlier error on this name).
/home/dsell/slurm-runs/caliptra-bfm/a2/m16-ahb-pv-generic-transfer-20261018-01/pv_generic_transfer_repro.sv:27: error: Enable of unknown task ``beat.data.delete''.
/home/dsell/slurm-runs/caliptra-bfm/a2/m16-ahb-pv-generic-transfer-20261018-01/pv_generic_transfer_repro.sv:28: error: Enable of unknown task ``beat.data.push_back''.
/home/dsell/slurm-runs/caliptra-bfm/a2/m16-ahb-pv-generic-transfer-20261018-01/pv_generic_transfer_repro.sv:29: error: Enable of unknown task ``beat.resp.delete''.
/home/dsell/slurm-runs/caliptra-bfm/a2/m16-ahb-pv-generic-transfer-20261018-01/pv_generic_transfer_repro.sv:30: error: Enable of unknown task ``beat.resp.push_back''.
/home/dsell/slurm-runs/caliptra-bfm/a2/m16-ahb-pv-generic-transfer-20261018-01/pv_generic_transfer_repro.sv:25: error: Object qvip_compat_pkg._ivl_0.write.transfer has no method "data.size(...)".
```

## Comparison

Verilator 5.051 devel (`v5.050-196-g7dcd4e0b6`) compiles and runs the same source, printing:

```text
PV_WRITE 00001000 0000000000001234
```

## Caliptra origin

The reduced inheritance pattern comes from the pinned generated PV environment. `pv_ahb_reg_predictor #(type T = int)` extends `ahb_reg_predictor #(.T(T))`; the generated specialization passes `ahb_reg_transfer_t`, a parameterized `ahb_master_burst_transfer` declaring `RnW`, `address`, `size`, `data[$]`, and `resp[$]`. Icarus reports those members missing in both the generated predictor and the QD-BFM predictor. The original PV row 46 compile log and reduced run capture are in `evidence/caliptra-bfm-m16-20261018/attempts/gate-2670-pv-ahb/` and `evidence/caliptra-bfm-m16-20261018/diagnostics/ahb-pv-generic-transfer/`.

Please classify whether this legal-looking inherited class type-parameter/member-access pattern is a simulator defect and fix it if appropriate. No upstream issue was opened.
