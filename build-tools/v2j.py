#!/usr/bin/env python

import json
import os
import subprocess
import tempfile


# Use Yosys to make a json file describing Verilog code.
# Pass the Verilog file name, and the json string _is_ the return value.
# If you need to debug this process, add delete=False to the
# tempfile.TemporaryDirectory() call, otherwise the tempfile cleanup
# phase will get in the way.  Only valid on python 3.12 or later.
def v2j(vfile, *, yosys='yosys', quiet_flag='-q'):
    basename = os.path.basename(vfile)
    base = os.path.splitext(basename)[0]
    assert (basename.endswith('.v') or basename.endswith('.sv'))
    with tempfile.TemporaryDirectory() as tdir:
        # print(f"v2j tdir {tdir}")
        # make a placeholder (empty) _auto.vh file
        # XXX uses Unix "/" instead of official filename building funcs
        with open(f'{tdir}/{base}_auto.vh', 'w') as f:
            f.write('')
        jfile = f'{tdir}/{base}.json'
        ycmd = f'read_verilog -sv -I{tdir} {vfile}; proc; write_json {jfile}'
        # print("v2j ycmd", ycmd)
        retcode = subprocess.call([yosys, quiet_flag, "-p", ycmd])
        if retcode != 0:
            raise ValueError(f"yosys crashed ({retcode}) on {vfile}!  Fix the Verilog!")
        with open(jfile, 'r') as f:
            return json.load(f)


if __name__ == "__main__":
    import sys
    assert (len(sys.argv) == 2)
    v2j(sys.argv[1])
