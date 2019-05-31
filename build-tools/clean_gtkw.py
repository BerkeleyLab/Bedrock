#!/usr/bin/env python
'''
Remove unnecessary header info from gtkwave project files.

These header lines leak local setup information to the outside.
Including them in git creates spurious modification history
when multiple people or workstations are working on a project.
'''
from glob import iglob
import argparse
from os.path import join, basename
from re import match

GTKWAVE_GLOB = '**/*.gtkw'

# only the first N_LINES are checked
N_LINES = 8

# lines starting with BAD_PREFIXES are removed
BAD_PREFIXES = ['[*]', '[dumpfile_', '[savefile]']


def clean_line(l):
    ''' returns a cleaned up version of l '''
    if any((l.startswith(p) for p in BAD_PREFIXES)):
        return ''
    # do not allow absolute path to the .vcd file
    m = match(r'\[dumpfile\] "(.*)"', l)
    if m:
        # replace by filename only
        return '[dumpfile] "{:}"\n'.format(basename(m.group(1)))
    return l


def clean_gtkw_file(fName, overwrite=False):
    ''' returns True if .gtkw file is dirty '''
    with open(fName, 'r') as f:
        lines = f.readlines()

    dirty_flag = False
    for i, l in enumerate(lines[:N_LINES]):
        cl = clean_line(l)
        if cl != l:
            # print(l, "-->", cl)
            dirty_flag = True
            lines[i] = cl

    if dirty_flag and overwrite:
        print('cleaning', fName)
        with open(fName, 'w') as f:
            f.writelines(lines)
        return False

    if dirty_flag:
        print('dirty', fName)

    return dirty_flag


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        'root_path',
        help='where to start searching recursively for .gtkw files'
    )
    p.add_argument(
        '--w',
        help='remove header info from files',
        action='store_true'
    )
    args = p.parse_args()
    g = join(args.root_path, GTKWAVE_GLOB)
    dirty = False
    for fName in iglob(g, recursive=True):
        dirty |= clean_gtkw_file(fName, overwrite=args.w)
    if dirty:
        print('to fix it use: ./clean_gtkw.py {:} --w'.format(args.root_path))
        exit(1)
