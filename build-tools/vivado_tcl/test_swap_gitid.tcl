# This tcl script provides unit testing for swap_gitid.tcl

source swap_gitid.tcl

# Test vectors for rowwidth of 8 #############################
set new_commit_8 [string toupper "da39a3ee5e6b4b0d3255bfef95601890afd80709"]
set old_commit_8 [string toupper "141ea87834abf012c40a255921e0adf812e89ad5"]
set init0_8 "256'h388F5DDA0643504C4204D5E8F8E0590A12AB781E0AB3F9B0CD799F8FFF2C1F0A"
set init1_8 "256'hE34DC578CA52204E4C409A12AD2125C4F034A814802241CDC38F70929BBB2780"

# Expected Values
set golden_init0_8 "256'h388F5DDA0643504C420409D89060EF550D6BEE390AB3F9B0CD799F8FFF2C1F0A"
set golden_init1_8 "256'hE34DC578CA52204E4C4007AF1895BF324B5EA3DA802241CDC38F70929BBB2780"
##########

# Test vectors for rowwidth of 16 #############################
set new_commit_16 [string toupper "da39a3ee5e6b4b0d3255bfef95601890afd80709"]
set old_commit_16 [string toupper "603045a65af2cbae6570df490578e49af0e53f07"]
set init0_16 "256'hCBAE5AF245A66030800A0F6858D77AC2B85D06D3D8DF2C3E529A12FBDFF5800A"
set init1_16 "256'h78DAC0E66E677469657320546C6572624D6140073F07F0E5E49A0578DF496570"

# Expected values
set golden_init0_16 "256'h4B0D5E6BA3EEDA39800A0F6858D77AC2B85D06D3D8DF2C3E529A12FBDFF5800A"
set golden_init1_16 "256'h78DAC0E66E677469657320546C6572624D6140070709AFD818909560BFEF3255"
#########


# Program return code -- start optimistic
set rc 0

# Test Procedure for 8
set rowwidth 8
lassign [gitid_proc $old_commit_8 $new_commit_8 $init0_8 $init1_8 $rowwidth] result_init0 result_init1

if {$result_init0 != $golden_init0_8 || $result_init1 != $golden_init1_8} {
  puts "Result of rowwidth=8 output is WRONG!"
  set rc 1
} else {
  puts "Results for rowwidth=8 output is CORRECT!"
}


# Test Procedure for 16
set rowwidth 16
lassign [gitid_proc $old_commit_16 $new_commit_16 $init0_16 $init1_16 $rowwidth] result_init0 result_init1

if {$result_init0 != $golden_init0_16 || $result_init1 != $golden_init1_16} {
  puts "Result of rowwidth=16 output is WRONG!"
  set rc 1
} else {
  puts "Results for rowwidth=16 output is CORRECT!"
}

if {$rc == 0} {puts PASS}
exit $rc
