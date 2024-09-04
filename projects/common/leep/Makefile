# A Makefile to run LEEP tests
THIS_DIR := $(realpath $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
include $(THIS_DIR)/../../../dir_list.mk

PYTHON=python3

LEEP_CORE=base.py raw.py ca.py file.py logic.py

all: test_cli

test_cli: $(LEEP_CORE) cli.py
	PYTHONPATH="$(THIS_DIR)/..:$(BUILD_DIR)" $(PYTHON) -m leep.test.test_cli test

# This is a test target currently only used for manual testing. Development is in progress
# for including this in automated regression tests.
server: $(LEEP_CORE) cli.py
	PYTHONPATH="$(THIS_DIR)/..:$(BUILD_DIR)" $(PYTHON) -m leep.test.test_cli server

CLEANS=test.json

clean:
	rm -rf $(CLEANS)
