# localbus shared memory testbench

This simulation is for merging two masters (picorv32 and localbus master)
with handle of reading/writing collisions. Testbench is configured to have 3
expected collisions when localbus master has priority to push through.

The CPU will execute commands from MEM.
These commands will write some data into the shared memory block.

XXX needs to fix address decoding.
