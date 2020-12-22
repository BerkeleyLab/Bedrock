# Formal verification
This directory contains rules for formal verification with [SymbiYosys](https://symbiyosys.readthedocs.io/en/latest/index.html):

  * `f_pack_peripheral.v`: rules to verify a peripheral on the picorv32 bus
  * `f_pack.sby` [script](https://symbiyosys.readthedocs.io/en/latest/reference.html) to orchestrate verification of several peripheral modules (similar to a Makefile). Run it with `sby f_pack.sby` to verify all modules, or `sby f_pack.sby sfr_pack` to only verify the sfr_pack module.
