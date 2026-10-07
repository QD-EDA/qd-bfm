#!/usr/bin/env python3
"""Mutate copies of real pilot evidence; never alter application sources."""
import json
from pathlib import Path
import shutil
import sys
import tempfile
from check_caliptra_evidence import check

source, caliptra = Path(sys.argv[1]), sys.argv[2]
assert check(source, caliptra, 7)['qualification'] == 'UNKNOWN'
cases = ['missing-command', 'failed-default', 'wrong-delay', 'warning-drift',
         'missing-assertion', 'missing-stalls', 'escaped-fault', 'false-pass',
         'missing-user', 'escaped-user-fault', 'false-user-pass']
for case in cases:
    with tempfile.TemporaryDirectory() as directory:
        target = Path(directory)
        for path in source.iterdir():
            if path.is_file(): shutil.copyfile(path, target/path.name)
        records = json.loads((target/'commands.json').read_text())
        if case == 'missing-command': records.pop()
        elif case == 'failed-default': records[2]['exit_status'] = 1
        elif case == 'wrong-delay': records[2]['argv'].remove('-GRESPONSE_DELAY=7')
        elif case == 'escaped-fault': records[4]['exit_status'] = 0
        elif case == 'escaped-user-fault': records[-1]['exit_status'] = 0
        (target/'commands.json').write_text(json.dumps(records))
        if case == 'warning-drift':
            with (target/'build-upstream-default.stderr').open('a') as out:
                out.write('\n%Warning-NEW: unexpected diagnostic\n')
        elif case == 'missing-assertion':
            (target/'build-assertions.stderr').write_text('')
        elif case == 'missing-stalls':
            path = target/'run-upstream-default.stdout'
            path.write_text(path.read_text().replace('R=30 B=30', 'R=0 B=0'))
        elif case == 'false-pass':
            with (target/'bad-data-upstream-default.stdout').open('a') as out:
                out.write('\nPASS: contradictory result\n')
        elif case == 'missing-user':
            (target/'user-upstream-default.stdout').write_text('')
        elif case == 'false-user-pass':
            with (target/'bad-user-upstream-default.stdout').open('a') as out:
                out.write('\nPASS: contradictory result\n')
        try:
            check(target, caliptra, 7)
        except ValueError:
            print('PASS: rejected '+case)
        else:
            raise AssertionError('accepted corrupted evidence: '+case)
print(f'PASS: real UNKNOWN evidence accepted; {len(cases)} evidence corruptions rejected')
