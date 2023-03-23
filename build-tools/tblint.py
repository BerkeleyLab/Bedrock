#! /usr/bin/python3

# Call out any testbenches that don't conform to our conventions
# USAGE: python3 tblint.py filename

import os
import re

DISPLAYPASS = '$display("PASS");'
DISPLAYFAIL = '$display("FAIL");'
FINISH = '$finish();'
STOP = '$stop();'

SYNTAX_RULES = f"""
Syntax Rules for checking test benches:
0.  All test benches must have file names that end with "_tb.v" or "_tb.sv"
1.  All test benches must pass with {DISPLAYPASS} {FINISH} and fail with
    {DISPLAYFAIL} {STOP}
    The exit strings must begin with "PASS" or "FAIL" which can be followed by
    explanatory text.
"""


class TBLinter():
    @staticmethod
    def _getDisplay(s):
        match = re.match(r"[^/$\"']*\$display\(([^\)]*)", s)  # Should not trigger when commented-out or within string
        if match:
            innerText = match.group(1)
            return True, innerText
        return False, None

    @classmethod
    def _isDisplayPass(cls, s):
        isDisplay, innerText = cls._getDisplay(s)
        if isDisplay:
            match = re.match(r"[\"']+(PASS|Pass|pass)", innerText)   # TODO Should we be this permissive?
            if match:
                return True
            return False
        return False

    @classmethod
    def _isDisplayFail(cls, s):
        isDisplay, innerText = cls._getDisplay(s)
        if isDisplay:
            match = re.match(r"[\"']+(FAIL|Fail|fail)", innerText)   # TODO Should we be this permissive?
            if match:
                return True
            return False
        return False

    @staticmethod
    def _isFinish(s):
        match = re.match(r"[^/$\"']*\$finish[(;]", s)  # Should not trigger when commented-out or within string
        if match:
            return True
        return False

    @staticmethod
    def _isStop(s):
        match = re.match(r"[^/$\"']*\$stop[(;]", s)  # Should not trigger when commented-out or within string
        if match:
            return True
        return False

    def __init__(self, filename):
        if os.path.exists(filename):
            self._filename = filename
        else:
            print(f"ERROR: Could not find {filename}.")
            self._filename = None

    def lint(self):
        if self._filename is None:
            return False
        if not (self._filename.endswith("_tb.v") or self._filename.endswith("_tb.sv")):
            print("Test bench filename must end in _tb.v or _tb.sv")
            return False
        finishCount = 0
        finishLines = []
        displayPass = False
        displayPassLines = []
        stopCount = 0
        stopLines = []
        displayFail = False
        displayFailLines = []
        nLine = 0
        with open(self._filename, 'r') as fd:
            line = True
            while line:
                # Handle escaped line breaks (continued lines)
                lines = []
                while True:
                    line = fd.readline()
                    nLine += 1
                    if len(line.strip()) > 0 and line.strip()[-1] == '\\':
                        lines.append(line.strip().strip('\\'))
                    else:
                        lines.append(line.strip())
                        break
                rdline = ' '.join(lines)
                if self._isDisplayPass(rdline):
                    displayPass = True
                    displayPassLines.append(nLine)
                if self._isDisplayFail(rdline):
                    displayFail = True
                    displayFailLines.append(nLine)
                if self._isFinish(rdline):
                    finishCount += 1
                    finishLines.append(nLine)
                if self._isStop(rdline):
                    stopCount += 1
                    stopLines.append(nLine)
        # ================= Lint Syntax Rules (pass/fail) =====================
        if finishCount == 0:
            print(f"ERROR: Must exit with {FINISH} on success.")
            return False
        elif not displayPass:
            print(f"ERROR: Line {finishLines[-1]}: Must use {DISPLAYPASS} before {FINISH} on success.")
            return False
        if stopCount > 0 and not displayFail:
            print(f"ERROR: Line {stopLines[-1]}: Must use {DISPLAYFAIL} when exiting with {STOP}")
            return False
        return True


def testfunction(testDict, fn):
    failCount = 0
    for key, val in testDict.items():
        result = fn(key)
        if result != val:
            failCount += 1
            print(f"FAILED on string {key}")
    return failCount


def test_isFinish():
    print("Testing _isFinish()")
    # Test-string: Should pass?
    d = {
        "$finish();": True,
        "    $finish()": True,
        "\t\t$finish;": True,
        "if (foo) $finish();": True,
        "finish": False,
        "$Finish();": False,
        "$finishThings();": False,
        "//$finish()": False,
        "    //$finish()": False,
        "'$finish();'": False,
        '"$finish();"': False
    }
    return testfunction(d, TBLinter._isFinish)


def test_isStop():
    print("Testing _isStop()")
    # Test-string: Should pass?
    d = {
        "$stop();": True,
        "    $stop()": True,
        "\t\t$stop;": True,
        "if (foo) $stop();": True,
        "stop": False,
        "$Stop();": False,
        "$stopThings();": False,
        "//$stop()": False,
        "    //$stop()": False,
        "'$stop();'": False,
        '"$stop();"': False
    }
    return testfunction(d, TBLinter._isStop)


def test_isDisplayPass():
    print("Testing _isDisplayPass()")
    # Test-string: Should pass?
    d = {
        '$display("PASS");': True,
        '$display("Pass");': True,
        '$display("pass");': True,  # ?
        "$display('PASS');": True,
        '    $display("PASS");': True,
        '\t\t$display("PASS");': True,
        'if (foo) $display("PASS");': True,
        '$display("PASS:Explanatory text");': True,
        '$display("YOU SHALL NOT PASS!");': False,
        '$display("PAST");': False,
        '//$display("PASS");': False,
        '"$display("PASS");"': False,
        "'$display('PASS');'": False
    }
    return testfunction(d, TBLinter._isDisplayPass)


def test_isDisplayFail():
    print("Testing _isDisplayFail()")
    # Test-string: Should pass?
    d = {
        '$display("FAIL");': True,
        '$display("Fail");': True,
        '$display("fail");': True,  # ?
        "$display('FAIL');": True,
        '    $display("FAIL");': True,
        '\t\t$display("FAIL");': True,
        'if (foo) $display("FAIL");': True,
        '$display("FAIL:Explanatory text");': True,
        '$display("Too big to FAIL");': False,
        '$display("FALL");': False,
        '//$display("FAIL");': False,
        '"$display("FAIL");"': False,
        "'$display('FAIL');'": False
    }
    return testfunction(d, TBLinter._isDisplayFail)


def doTests(argv=None):
    failCount = 0
    failCount += test_isFinish()
    failCount += test_isStop()
    failCount += test_isDisplayPass()
    failCount += test_isDisplayFail()
    if failCount > 0:
        print(f"{failCount} tests failed")
        return 1
    else:
        print("All tests passed")
    return 0


def testMatch(argv):
    USAGE = "python3 {} testString".format(argv[0])
    if len(argv) < 2:
        print(USAGE)
        return 1
    s = argv[1]
    print("Checking: {}".format(s))
    if TBLinter._isDisplayPass(s):
        print("Got display-pass")
    if TBLinter._isDisplayFail(s):
        print("Got display-fail")
    if TBLinter._isFinish(s):
        print("Got finish")
    if TBLinter._isStop(s):
        print("Got stop")
    return


def doLint(argv):
    USAGE = ("python3 {0} filename\n" +
            "  Use python3 {0} --selftest to run regex syntax tests").format(argv[0])
    if len(argv) < 2:
        print(USAGE)
        print(SYNTAX_RULES)
        return 1
    filename = argv[1]
    if filename == "--selftest":
        return doTests()
    linter = TBLinter(filename)
    if linter.lint():
        print(f"Lint PASS: {filename}")
        return 0
    else:
        print(f"Lint FAIL: {filename}")
        return 1


if __name__ == "__main__":
    import sys
    # sys.exit(testMatch(sys.argv))
    sys.exit(doLint(sys.argv))
