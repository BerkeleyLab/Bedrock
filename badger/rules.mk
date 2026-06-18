# List of dependencies etc. just for synthesizable files of RTEFI
# The Makefile for any project that depends on RTEFI is expected to include this file

# =====
# Attention!!!!
vpath %.v   $(BADGER_DIR)
vpath %.py  $(BADGER_DIR)
vpath %.csv $(BADGER_DIR)

# =====
# Machine generated code
ITABLES = tx_none_table.csv tx_arp_table.csv tx_icmp_table.csv tx_udp_table.csv
construct_tx_table.v: tx_gen.py $(ITABLES)
	$(PYTHON) $^ > $@

# =====
# Aggregation of clients with rtefi_center
# Minor issue: if you duplicate dependencies, they're not duplicated in $^
# Here is an example client list typically instantiated where rtefi is being included
# RTEFI_CLIENT_LIST = hello.v speed_test.v mem_gateway.v
rtefi_preblob.vh: collect_clients.py $(RTEFI_CLIENT_LIST)
	$(PYTHON) $^ > $@
rtefi_blob.v: rtefi_preblob.v rtefi_preblob.vh
	$(VERILOG) -E -o $@ $<

# =====
# Just lists of files
RTEFI_CENTER_V = rtefi_center.v scanner.v pbuf_writer.v udp_port_cam.v crc8e_guts.v construct.v construct_tx_table.v ones_chksum.v xformer.v ethernet_crc_add.v hack_icmp_cksum.v reg_delay.v reg_tech_cdc.v
RTEFI_CENTER_V += mac_subset.v precog.v test_tx_mac.v
RTEFI_V = rtefi_blob.v $(RTEFI_CENTER_V) $(RTEFI_CLIENT_LIST) $(RTEFI_EXTRA_V)
RTEFI_CLEAN = construct_tx_table.v rtefi_blob.v rtefi_preblob.vh
