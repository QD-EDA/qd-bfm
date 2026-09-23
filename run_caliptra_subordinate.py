#!/usr/bin/env python3
"""Collect two distinct Caliptra configurations; assertion failures never become PASS."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

PIN = '49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e'


def main():
    if len(sys.argv) != 3:
        print('usage: run_caliptra_subordinate.py CALIPTRA_ROOT EVIDENCE_DIR', file=sys.stderr)
        return 1
    root, out = (Path(p).resolve() for p in sys.argv[1:])
    repo = Path(__file__).resolve().parent
    records = []
    try:
        if (subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip() != PIN or
                subprocess.check_output(['git', 'status', '--porcelain'], cwd=root, text=True)):
            raise ValueError('expected clean pinned Caliptra v2.1.2 checkout')
        out.mkdir(parents=True, exist_ok=True)
        env = dict(os.environ, CALIPTRA_ROOT=str(root))
        def run(name, argv):
            start = time.monotonic()
            result = subprocess.run(argv, cwd=repo, env=env, capture_output=True, text=True, timeout=120)
            (out/(name+'.stdout')).write_text(result.stdout)
            (out/(name+'.stderr')).write_text(result.stderr)
            records.append(dict(name=name, argv=argv, exit_status=result.returncode,
                                seconds=time.monotonic()-start))
            return result
        version = run('version', ['verilator', '--version'])
        if version.returncode:
            raise ValueError('Verilator version query failed')
        filelist = root/'src/axi/config/axi_sub.vf'
        inputs = [filelist] + [repo/name for name in
                  ['qd_axi4_single_master.sv', 'qd_caliptra_axi_single_master.sv', 'tb_caliptra_axi_sub.sv']]
        # Record listed sources plus declared header trees; not a proven include closure.
        for line in filelist.read_text().splitlines():
            if line.startswith('+incdir+'):
                directory = Path(line[8:].replace('${CALIPTRA_ROOT}', str(root)))
                inputs.extend(directory.rglob('*.sv*'))
            elif line.strip():
                inputs.append(Path(line.replace('${CALIPTRA_ROOT}', str(root))))
        inputs.extend((root/'src/caliptra_prim/rtl').rglob('*.sv*'))
        hashes = {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(set(inputs))}
        (out/'inputs.json').write_text(json.dumps(hashes, indent=2)+'\n')
        unknown = False
        for mode in ('assertions', 'upstream-default'):
            obj = out/('obj-'+mode)
            # -Wno-fatal permits evidence collection only; warnings set overall UNKNOWN.
            argv = ['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
                    '--top-module', 'tb_caliptra_axi_sub', '--timescale', '1ns/1ps',
                    '--Mdir', str(obj), '-I'+str(root/'src/caliptra_prim/rtl')]
            if mode == 'assertions': argv.append('-DCLP_ASSERT_ON')
            argv += ['-f', str(filelist)] + [str(p) for p in inputs[1:4]]
            build = run('build-'+mode, argv)
            log = build.stdout + build.stderr
            for line in log.splitlines():
                if line.startswith(('%Warning', '%Error')): print(line)
            unknown |= '%Warning' in log
            if build.returncode:
                if mode == 'upstream-default': raise ValueError('default configuration failed to build')
                unknown = True
                print('UNKNOWN: assertion-enabled configuration failed; see raw build logs')
                continue
            sim = str(obj/'Vtb_caliptra_axi_sub')
            good = run('run-'+mode, [sim])
            if good.returncode or 'PASS: real Caliptra axi_sub transfers=12 stalled=24' not in good.stdout:
                raise ValueError(mode+': behavioral scoreboard failed')
            bad = run('bad-data-'+mode, [sim, '+BAD_DATA'])
            if (not bad.returncode or 'read data scoreboard mismatch' not in bad.stdout+bad.stderr or
                    'PASS:' in bad.stdout+bad.stderr):
                raise ValueError(mode+': injected data error was not detected correctly')
            print(mode+': 12 transfers, 24 held cycles, data fault detected')
        if subprocess.check_output(['git', 'status', '--porcelain'], cwd=root, text=True):
            raise ValueError('application working tree changed during pilot')
        print('UNKNOWN: diagnostics or unavailable assertions' if unknown else 'PASS: bounded target pilot only')
        return 2 if unknown else 0
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f'pilot: {error}', file=sys.stderr)
        return 1
    finally:
        if out.is_dir(): (out/'commands.json').write_text(json.dumps(records, indent=2)+'\n')


if __name__ == '__main__':
    raise SystemExit(main())
