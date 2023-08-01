#!/usr/bin/python3

# This is a demonstration use of the tools in 'assem.py' based on ramtest.py

import assem


def build_prog(argv):
    # ======= Program Instructions =======
    sadr = 0x20
    s = assem.I2CAssembler()
    s.pause(2)  # ignored?
    s.hw_config(0)
    s.trig_analyz()
    s.write(sadr, 1, [0xa5, 0x5a])
    s.pause(4)
    s.read(sadr, 2, 1, reg_name="REG_FOO")
    s.read(sadr, 1, 2, reg_name="REG_BAR")
    jump_n = s.jump_pad()

    s.set_resx(1)
    s.read(sadr, 1, 1, reg_name="REG_BAZ")
    s.buffer_flip()
    s.pause(34)
    s.jump(jump_n)
    # ======= End Program =======
    if len(argv) > 1:
        op = argv[1]
        s.write_reg_map(style=op)
    else:
        s.write_program()
    return


if __name__ == "__main__":
    import sys
    build_prog(sys.argv)
