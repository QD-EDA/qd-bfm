#!/usr/bin/env python3
"""Check this pinned pilot's evidence without promoting UNKNOWN to qualification."""
import json
from pathlib import Path
import sys


def check(directory, caliptra, delay):
    directory, caliptra = Path(directory), Path(caliptra).resolve()
    records = json.loads((directory/'commands.json').read_text())
    expected = ['version', 'build-assertions', 'build-upstream-default',
                'run-upstream-default', 'bad-data-upstream-default',
                'user-upstream-default', 'bad-user-upstream-default']
    if ([r['name'] for r in records] != expected or
            [r['exit_status'] == 0 for r in records] !=
            [True, False, True, True, False, True, False]):
        raise ValueError('pilot command/status matrix changed; review required')
    for record in records[1:3]:
        if '-GRESPONSE_DELAY='+str(delay) not in record['argv']:
            raise ValueError('response delay configuration mismatch')
    def log(name):
        return (directory/(name+'.stdout')).read_text() + (directory/(name+'.stderr')).read_text()
    def diagnostics(name):
        return [line.replace(str(caliptra)+'/', '') for line in log(name).splitlines()
                if line.startswith(('%Warning', '%Error'))]
    unsupported = 'Unsupported: eventually[] (in property expression)'
    errors = [f'%Error-UNSUPPORTED: src/axi/rtl/{file}.sv:{line}:{col}: {unsupported}'
              for file, line, col in [('axi_sub_rd',400,154), ('axi_sub_rd',401,153),
                                     ('axi_sub_wr',397,154), ('axi_sub_wr',398,153),
                                     ('axi_sub_wr',399,153)]]
    errors.append('%Error: Exiting due to 5 error(s)')
    if diagnostics('build-assertions') != errors:
        raise ValueError('assertion diagnostics changed; review required')
    width = "Operator VAR 'size' expects 3 bits on the Initial value, but Initial value's CLOG2 generates 32 bits."
    warnings = [f'%Warning-WIDTHTRUNC: src/axi/rtl/axi_if.sv:{line}:{col}: {width}'
                for line, col in [(230,43), (334,45)]]
    warnings.append("%Warning-WIDTHEXPAND: src/axi/rtl/axi_if.sv:370:42: Operator EQ expects 32 bits on the RHS, but RHS's VARREF 'len' generates 8 bits.")
    if diagnostics('build-upstream-default') != warnings:
        raise ValueError('default build diagnostics changed; review required')
    stalls = {0: 0, 7: 30}[delay]
    good, bad = log('run-upstream-default'), log('bad-data-upstream-default')
    if (f'COVERAGE: response stalls R={stalls} B={stalls}' not in good or
            'PASS: real Caliptra axi_sub transfers=12 stalled=24' not in good):
        raise ValueError('behavior/coverage evidence missing')
    if 'read data scoreboard mismatch' not in bad or 'PASS:' in bad:
        raise ValueError('data-fault evidence missing or contradictory')
    user, wrong = log('user-upstream-default'), log('bad-user-upstream-default')
    if ('PASS: real Caliptra axi_sub USER transfers=6' not in user or
            'PASS: real Caliptra axi_sub transfers=18 stalled=36' not in user or
            f'COVERAGE: response stalls R={stalls + (15 if delay else 0)} B={stalls + (15 if delay else 0)}' not in user):
        raise ValueError('USER behavior/coverage evidence missing')
    if ('component address/control scoreboard mismatch' not in wrong or 'PASS:' in wrong):
        raise ValueError('wrong-USER evidence missing or contradictory')
    return {'qualification': 'UNKNOWN', 'response_delay': delay,
            'transfers': 12, 'component_stall_cycles': 24,
            'user_transfers': 6,
            'r_stall_cycles': stalls, 'b_stall_cycles': stalls,
            'assertion_build_errors': errors, 'default_build_warnings': warnings}


if __name__ == '__main__':
    try:
        print(json.dumps(check(sys.argv[1], sys.argv[2], int(sys.argv[3])), indent=2))
    except (OSError, ValueError, KeyError, IndexError) as error:
        sys.exit('evidence check: '+str(error))
