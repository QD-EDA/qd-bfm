#!/usr/bin/env python3
"""Run the M18 row gate with the locally built binary's platform-specific hash."""

import os
import sys
from pathlib import Path

repo = Path(os.environ["M18_REPO_ROOT"]).resolve()
sys.path.insert(0, str(repo / "dv/caliptra_bfm/uvmf_lite/tests"))
import run_m15_test

run_m15_test.IVERILOG_SHA256 = os.environ["M18_IVL_SHA256"]
raise SystemExit(run_m15_test.main())
