#!/usr/bin/python3

import os

def make_md_include(fname, title=""):
    flastdir = os.path.basename(os.path.realpath(fname))
    fdir = os.path.dirname(os.path.realpath(fname))
    fbase, fext = os.path.splitext(os.path.basename(fname))

    print(".. _{}:".format(fbase))
    print("")
    print('{}'.format("".join(['-'*len(fbase)])))
    if not title:
        print('{}'.format(fbase))
    else:
        print('{}'.format(title))
    print('{}'.format("".join(['-'*len(fbase)])))
    print("")

    if True:
        print(".. mdinclude:: {}".format(fname))
        print("")

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Generate .rst stubs")
    parser.add_argument("--gen-md-include", default=False, action="store_true",
                        help="Generate .rst stub with mdinclude directive for embedding an .md file")
    parser.add_argument("--title", default="", help="Optional title for .rst document")
    parser.add_argument("file", default="", help=".md input file")
    cmd_args = parser.parse_args()

    do_md_include = cmd_args.gen_md_include
    title = cmd_args.title
    fname = cmd_args.file

    if do_md_include:
        make_md_include(fname, title)

if __name__ == "__main__":
    main()
