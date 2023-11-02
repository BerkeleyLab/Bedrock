#! /usr/bin/python3

# A bunch of I2C assembler violations

import sys
try:
    import assem
except ImportError:
    raise Exception("Must set PYTHONPATH=path/to/bedrock/peripheral_drivers/i2cbridge")

# Violations:
#   1. Program size exceeded
#   2. Data (result) size exceeded
#   3. Backwards jump with no buffer flip
#   4. Read with no buffer flip
#   5. Code after backwards jump (unreachable)
#   6. Jump out of program


def _int(x):
    try:
        return int(x)
    except ValueError:
        try:
            return int(x, 16)
        except ValueError:
            return int(x, 2)


def doViolations(argv):
    if len(argv) > 1:
        vMask = _int(argv[1])
    else:
        vMask = 0xFF
    violations = (
        violation1,
        violation2,
        violation3,
        violation4,
        violation5,
        violation6,
    )
    for n in range(len(violations)):
        if (1 << n) & vMask:
            try:
                violations[n]()
            except assem.I2C_Assembler_Exception as i2ce:
                print(f"{i2ce}\n")
    return


def violation1():
    print("{:-^80s}".format(" Violation 1. Program size exceeded "))
    m = assem.I2CAssembler()
    for n in range(256):
        m.write(0x80, 0, [1, 2, 3, 4, 5, 6, 7])
    m.pause(4096)   # Pause for roughly 0.24ms
    m.jump(0)       # Jump back to loop start
    m.check_program()
    return


def violation2():
    print("{:-^80s}".format(" Violation 2. Data (result) size exceeded "))
    m = assem.I2CAssembler()
    for n in range(64):
        m.read(0x80, 0, 30)
    m.pause(4096)   # Pause for roughly 0.24ms
    m.jump(0)       # Jump back to loop start
    m.check_program()
    return


def violation3():
    print("{:-^80s}".format(" Violation 3. Backwards jump with no buffer flip "))
    m = assem.I2CAssembler()
    m.read(0x80, 0, 1)
    m.pause(4096)   # Pause for roughly 0.24ms
    m.jump(0)       # Jump back to loop start
    m.check_program()
    return


def violation4():
    print("{:-^80s}".format(" Violation 4. Read with no buffer flip "))
    m = assem.I2CAssembler()
    m.read(0x80, 0, 1)
    m.pause(4096)   # Pause for roughly 0.24ms
    m.check_program()
    return


def violation5():
    print("{:-^80s}".format(" Violation 5. Code after backwards jump (unreachable) "))
    m = assem.I2CAssembler()
    m.read(0x80, 0, 1)
    m.jump(0)       # Jump back to loop start
    m.pause(4096)   # Pause for roughly 0.24ms
    m.check_program()
    return


def violation6():
    print("{:-^80s}".format(" Violation 6. Jump out of program "))
    m = assem.I2CAssembler()
    m.jump(40)      # Jump out of program space
    m.check_program()
    return


if __name__ == "__main__":
    doViolations(sys.argv)
