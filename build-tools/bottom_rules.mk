.PHONY: clean
CLEAN += *.pyc
CLEAN_DIRS += $(DEPDIR) $(IPX_DIR) $(AUTOGEN_DIR) __pycache__
# The "find" commands below (embedded in check_clean) check that the
# source code satisifies:
#  no hidden files
#  filenames are only alphanumeric, plus hyphen, underscore, and period
#  files don't contain trailing spaces or tabs, space followed by tab, or non-printing-ASCII chars (.eps files excepted)
clean::
	rm -f $(CLEAN)
	rm -rf $(CLEAN_DIRS)
	sh $(BUILD_DIR)/check_clean
