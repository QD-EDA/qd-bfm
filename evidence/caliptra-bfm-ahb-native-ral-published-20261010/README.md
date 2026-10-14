# Native AHB RAL subword frontdoor regression

Date: 2026-10-10

This standalone test connects the native UVM AHB agent to the repository's
byte-addressable AHB memory subordinate. The RAL model performs an 8-bit
write/read at the highest byte lane, a 16-bit write/read at the top two byte
lanes, and one read with an injected AHB ERROR. Auto-prediction is disabled;
the completed-transfer monitor stream updates the byte and halfword mirrors.
The same test runs with the 32-bit Adams Bridge profile and the default 64-bit
Caliptra profile.

| Bus width | IEEE edition | Result | Transactions | UVM warnings/errors/fatals |
| ---: | ---: | --- | ---: | --- |
| 32 | 2012 | PASS | 5 | 1 / 0 / 0 |
| 32 | 2017 | PASS | 5 | 1 / 0 / 0 |
| 32 | 2023 | PASS | 5 | 1 / 0 / 0 |
| 64 | 2012 | PASS | 5 | 1 / 0 / 0 |
| 64 | 2017 | PASS | 5 | 1 / 0 / 0 |
| 64 | 2023 | PASS | 5 | 1 / 0 / 0 |

The single expected warning is UVM `PREDICT_NOK`: the predictor skips the
injected failed read. The monitor reports two writes, two successful reads,
one error read, and no protocol errors. This validates the native driver,
adapter, monitor, predictor, and subword behavior against the open synthetic
memory target; it does not test narrow writes against a Caliptra peripheral.

The runs use Accellera UVM 2020.3.1 and clean published Icarus
`4b3f3424c440aca6af92153b6860a7253b925234`. No Caliptra source is compiled in
this test.

Reproduce from the QD-EDA repository root:

```sh
set -eu
for width in 32 64; do
  for edition in 2012 2017 2023; do
    logfile="evidence/caliptra-bfm-ahb-native-ral-published-20261010/logs/native-ral-${width}bit-sv-$edition.log"
    IVERILOG_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/iverilog \
    VVP_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/vvp \
    SV_EDITION="$edition" AHB_DATA_WIDTH="$width" \
      dv/caliptra_bfm/ahb_lite/tests/run_caliptra_ahb_native_ral.sh >"$logfile" 2>&1
    gzip -n "$logfile"
  done
done
```

The source was based on QD-EDA `dcec257bc440f20d00d38d527506453259c62b44`.
SHA-256: [testbench](../../dv/caliptra_bfm/ahb_lite/tests/tb_ahb_lite_caliptra_native_ral.sv)
`b7a65d5ff5634937ad1aeb578df8e28d23f3238885790501c3d9d2467f47fe43`;
[runner](../../dv/caliptra_bfm/ahb_lite/tests/run_caliptra_ahb_native_ral.sh)
`cb4f48bf8b87ca87524f2f675e4d8a78b4334768c14cbf6a914ef5358ddbd857`.

Log hashes:

| Log | SHA-256 |
| --- | --- |
| [32-bit IEEE 2012](logs/native-ral-32bit-sv-2012.log.gz) | `ff8fa8c9200f6b74864bb1cae43d2a841b473d35ca2ce540906ff787996a4ab9` |
| [32-bit IEEE 2017](logs/native-ral-32bit-sv-2017.log.gz) | `4f00e45a9bc0e4b55398e7d125239a9619c89a192bfac8490541ed21a7d8a3e8` |
| [32-bit IEEE 2023](logs/native-ral-32bit-sv-2023.log.gz) | `76443cd078b24be535eb4fe932212d417fab487a7efcc31105b548191e7c6095` |
| [64-bit IEEE 2012](logs/native-ral-64bit-sv-2012.log.gz) | `c3048624b81fc38c50a97017ec88455dd8a1af2a4cb55c57a96df0a03969e11d` |
| [64-bit IEEE 2017](logs/native-ral-64bit-sv-2017.log.gz) | `12b91ee6c07c7630197c5265a072462e65791b1250d51261d88f262f701243ce` |
| [64-bit IEEE 2023](logs/native-ral-64bit-sv-2023.log.gz) | `abde48eb9a5a36452df980a436f9a8daa7f2ea1d96fc276b4dd8e8c93e106f97` |
