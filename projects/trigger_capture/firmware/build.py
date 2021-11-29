#!/usr/bin/env python3

#
# This file is part of LiteX.
#
# Copyright (c) 2020 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

import os
import argparse

def main():
    parser = argparse.ArgumentParser(description="LiteX Bare Metal App.")
    parser.add_argument("--build-path", help="Target's build path (ex build/board_name).", required=True)
    parser.add_argument("--app-dir-path", help="Application directory.", required=True)
    parser.add_argument("--with-cxx",   action="store_true", help="Enable CXX support.")
    args = parser.parse_args()

    # Create build directory
    os.makedirs("build", exist_ok=True)

    # Copy contents to build directory
    os.system(f"cp {os.path.abspath(os.path.dirname(__file__))}/* build")

    # Compile app
    build_path = args.build_path if os.path.isabs(args.build_path) else os.path.join("..", args.build_path)
    print(args.app_dir_path)
    os.system(f"export BUILD_DIR={build_path} && export APP_DIR={args.app_dir_path} && {'export WITH_CXX=1 &&' if args.with_cxx else ''} cd build && make")

    # Copy demo.bin
    os.system("cp build/app.bin ./")

if __name__ == "__main__":
    main()
