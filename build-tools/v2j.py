#!/usr/bin/env python

import json
import os


def v2j(vfile):
    basename = os.path.basename(vfile)
    base = os.path.splitext(basename)[0]
    assert(basename.endswith('.v'))
    autofile = '/tmp/{}_auto.vh'.format(base)
    with open(autofile, 'w') as f:
        f.write('')
    jfile = '/tmp/{}.json'.format(base)
    yfile = '/tmp/yosys_v2j.ys'
    with open(yfile, "w") as f:
        f.write('read_verilog -sv -I/tmp {0}\n'
                'write_json {1}'.format(vfile, jfile))
    os.system('yosys -q {}'.format(yfile))
    with open(jfile, 'r') as f:
        return json.load(f)


if __name__ == "__main__":
    import sys
    assert(len(sys.argv) == 2)
    v2j(sys.argv[1])
