# Very simple for stand-alone testing.
# In Bedrock context, should be ignored in favor of $(BUILD_DIR)/bottom_rules.mk
.PHONY: clean
CLEAN += *.pyc
clean::
	rm -f $(CLEAN)
	rm -rf $(CLEAN_DIRS)
