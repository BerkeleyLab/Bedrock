#! /usr/bin/python3

# A bunch of I2C assembler violations

import sys
try:
    import marble_i2c
except ImportError:
    raise Exception("Must set PYTHONPATH=path/to/bedrock/projects/test_marble_family")

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


def violation1():
    print("{:-^80s}".format(" Violation 1. Program size exceeded "))
    m = marble_i2c.MarbleI2C()
    for n in range(256):
        m.bsp_config()
    m.pause(4096)   # Pause for roughly 0.24ms
    m.jump(0)       # Jump back to loop start
    m.check_program()
    return


def violation2():
    print("{:-^80s}".format(" Violation 2. Data (result) size exceeded "))
    m = marble_i2c.MarbleI2C()
    m.set_resx()
    for n in range(64):
        m.read("U34", 0, 30)
    m.buffer_flip()
    m.pause(4096)   # Pause for roughly 0.24ms
    m.jump(0)       # Jump back to loop start
    m.check_program()
    return


def violation3():
    print("{:-^80s}".format(" Violation 3. Backwards jump with no buffer flip "))
    m = marble_i2c.MarbleI2C()
    m.bsp_config()
    m.set_resx()
    m.read("U34", 0, 1)
    # m.buffer_flip()
    m.pause(4096)   # Pause for roughly 0.24ms
    m.jump(0)       # Jump back to loop start
    m.check_program()
    return


def violation4():
    print("{:-^80s}".format(" Violation 4. Read with no buffer flip "))
    m = marble_i2c.MarbleI2C()
    m.bsp_config()
    m.set_resx()
    m.read("U34", 0, 1)
    # m.buffer_flip()
    m.pause(4096)   # Pause for roughly 0.24ms
    m.check_program()
    return


def violation5():
    print("{:-^80s}".format(" Violation 5. Code after backwards jump (unreachable) "))
    m = marble_i2c.MarbleI2C()
    m.bsp_config()
    m.set_resx()
    m.read("U34", 0, 1)
    m.buffer_flip()
    m.jump(0)       # Jump back to loop start
    m.pause(4096)   # Pause for roughly 0.24ms
    m.check_program()
    return


def violation6():
    print("{:-^80s}".format(" Violation 6. Jump out of program "))
    m = marble_i2c.MarbleI2C()
    m.bsp_config()
    m.jump(4)      # Jump out of program space
    m.check_program()
    return


def violation7():
    print("{:-^80s}".format(" Violation 7. Invalid jump out of memory bounds "))
    m = marble_i2c.MarbleI2C()
    m.bsp_config()
    m.jump(40)      # Jump out of allowable range
    m.check_program()
    return


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
        violation7,
    )
    exceptions = [False]*len(violations)
    for n in range(len(violations)):
        if (1 << n) & vMask:
            try:
                violations[n]()
            except marble_i2c.assem.I2C_Assembler_Exception as i2ce:
                print(f"{i2ce}\n")
                exceptions[n] = True
        else:
            # If we're not testing against it, pretend it succeeded
            exceptions[n] = True
    if False in exceptions:
        missed = []
        for n in range(len(exceptions)):
            if not exceptions[n]:
                missed.append(str(n+1))
        ss = "s" if len(missed) > 1 else ""
        print("FAIL: Did not catch all violations. Missed violation{} {}".format(
              ss, ", ".join(missed)))
        return 1
    else:
        print("PASS")
    return 0


if __name__ == "__main__":
    exit(doViolations(sys.argv))
