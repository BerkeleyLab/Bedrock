# Again preface this with:  I am officially no longer a tcl programmer.
# It seems nobody else around here is, either.
#
# Fragile proof-of-concept
# Revise config_romx git ID in-place using BRAM INIT_xx values
# Absolutely depends on ROM contents that come out of bedrock/build-tools/build_rom.py
# Two variants:
#   swap_gitid8 for the case where the ROM is built with 2 x 8Kx8 BRAM (e.g., prc)
#   swap_gitid16 for the case where the ROM is built with 1 x 4Kx16 BRAM (e.g., marble1)
# Could use some helpful error messages, and stricter search for BRAM instances
#
# In Vivado, when a design is complete and open, run with:
#   set new_commit [string toupper "da39a3ee5e6b4b0d3255bfef95601890afd80709"]
#   set old_commit [string toupper [exec git rev-parse HEAD]]
# Reverse the above two lines, once build_rom gets its --placeholder_rev option turned on
#   source swap_gitid.tcl
#   swap_gitid8 $old_commit $new_commit
# then if happy:
#   set_property BITSTREAM.CONFIG.USERID "32'hFEED0070" [current_design]
#   write_bitstream -force test3.bit

proc reorder_8bit {gitid} {
    set msb ""
    set lsb ""
    for {set jx 0} {$jx < 20} {incr jx} {
        set p [string range $gitid 0 1]
        set lsb "${p}${lsb}"
        set p [string range $gitid 2 3]
        set msb "${p}${msb}"
        set gitid [string range $gitid 4 999]
    }
    # puts "reorder_8bit msb $msb"
    # puts "reorder_8bit lsb $lsb"
    return "$msb $lsb"
}

# Portable string handling
proc gitid_proc8 {old_commit new_commit init0 init1} {
    # Check for config_romx record markers, 800A for 10-word binary records
    if {[string range $init0 67 68] != "0A"} {return 0}
    if {[string range $init0 45 46] != "0A"} {return 0}
    if {[string range $init1 67 68] != "80"} {return 0}
    if {[string range $init1 45 46] != "80"} {return 0}
    # Check that the existing INIT values match $old_commit -- this is key!
    lassign [reorder_8bit $old_commit] old_msb old_lsb
    if {[string range $init0 25 44] != $old_msb} {return 0}
    if {[string range $init1 25 44] != $old_lsb} {return 0}
    # Finally insert $new_commit in place
    lassign [reorder_8bit $new_commit] new_msb new_lsb
    set init0x "[string range $init0 0 24]$new_msb[string range $init0 45 68]"
    set init1x "[string range $init1 0 24]$new_lsb[string range $init1 45 68]"
    puts "old 0 $init0"
    puts "new 0 $init0x"
    puts "--"
    puts "old 1 $init1"
    puts "new 1 $init1x"
    puts "--"
    return "$init0x $init1x"
}

# Simple test routine for the portable code
proc test_proc8 {} {
    set new_commit [string toupper "da39a3ee5e6b4b0d3255bfef95601890afd80709"]
    set old_commit [string toupper "141ea87834abf012c40a255921e0adf812e89ad5"]
    set init0 "256'h388F5DDA0643504C4204D5E8F8E0590A12AB781E0AB3F9B0CD799F8FFF2C1F0A"
    set init1 "256'hE34DC578CA52204E4C409A12AD2125C4F034A814802241CDC38F70929BBB2780"
    set xx [gitid_proc8 $old_commit $new_commit $init0 $init1]
    if {[llength $xx] != 2} {return 0}
    lassign $xx init0x init1x
    if {$init0x != "256'h388F5DDA0643504C420409D89060EF550D6BEE390AB3F9B0CD799F8FFF2C1F0A"} {return 0}
    if {$init1x != "256'hE34DC578CA52204E4C4007AF1895BF324B5EA3DA802241CDC38F70929BBB2780"} {return 0}
    puts OK
    return 1
}

# This function needs Vivado and a routed design
proc swap_gitid8 {old_commit new_commit} {
    set c0 [get_cells -hier -filter {PRIMITIVE_TYPE =~ BMEM.*.*} *dxx_reg_0]
    if {[llength $c0] != 1} {return 0}
    set c1 [get_cells -hier -filter {PRIMITIVE_TYPE =~ BMEM.*.*} *dxx_reg_1]
    if {[llength $c1] != 1} {return 0}
    if {[get_property READ_WIDTH_A $c0] != 9} {return 0}
    if {[get_property READ_WIDTH_A $c1] != 9} {return 0}
    set init0 [get_property INIT_00 $c0]
    set init1 [get_property INIT_00 $c1]
    set xx [gitid_proc8 $old_commit $new_commit $init0 $init1]
    if {[llength $xx] != 2} {return 0}
    lassign $xx init0x init1x
    set_property INIT_00 $init0x $c0
    set_property INIT_00 $init1x $c1
    puts "swap_gitid8 success $new_commit"
    return 1
}

# Portable string handling
proc reorder_16bit {gitid} {
    set lsb ""
    for {set jx 0} {$jx < 4} {incr jx} {
        set p [string range $gitid 0 3]
        set lsb "${p}${lsb}"
        set gitid [string range $gitid 4 999]
    }
    set msb ""
    for {set jx 0} {$jx < 6} {incr jx} {
        set p [string range $gitid 0 3]
        set msb "${p}${msb}"
        set gitid [string range $gitid 4 999]
    }
    # puts "reorder_16bit msb $msb"
    # puts "reorder_16bit lsb $lsb"
    return "$msb $lsb"
}

# Portable string handling
proc gitid_proc16 {old_commit new_commit init0 init1} {
    # Check for config_romx record markers, 800A for 10-word binary records
    if {[string range $init0 65 68] != "800A"} {return 0}
    if {[string range $init0 21 24] != "800A"} {return 0}
    # Check that the existing INIT values match $old_commit -- this is key!
    lassign [reorder_16bit $old_commit] new_msb new_lsb
    if {[string range $init0 5 20] != $new_lsb} {return 0}
    if {[string range $init1 45 68] != $new_msb} {return 0}
    # Finally insert $new_commit in place
    lassign [reorder_16bit $new_commit] new_msb new_lsb
    set init0x "[string range $init0 0 4]$new_lsb[string range $init0 21 68]"
    set init1x "[string range $init1 0 44]$new_msb"
    puts "old 0 $init0"
    puts "new 0 $init0x"
    puts "--"
    puts "old 1 $init1"
    puts "new 1 $init1x"
    puts "--"
    return "$init0x $init1x"
}

# Simple test routine for the portable code
proc test_proc16 {} {
    set new_commit [string toupper "da39a3ee5e6b4b0d3255bfef95601890afd80709"]
    set old_commit [string toupper "603045a65af2cbae6570df490578e49af0e53f07"]
    set init0 "256'hCBAE5AF245A66030800A0F6858D77AC2B85D06D3D8DF2C3E529A12FBDFF5800A"
    set init1 "256'h78DAC0E66E677469657320546C6572624D6140073F07F0E5E49A0578DF496570"
    set xx [gitid_proc16 $old_commit $new_commit $init0 $init1]
    if {[llength $xx] != 2} {return 0}
    lassign $xx init0x init1x
    puts $init0x
    puts $init1x
    if {$init0x != "256'h4B0D5E6BA3EEDA39800A0F6858D77AC2B85D06D3D8DF2C3E529A12FBDFF5800A"} {return 0}
    if {$init1x != "256'h78DAC0E66E677469657320546C6572624D6140070709AFD818909560BFEF3255"} {return 0}
    puts OK
    return 1
}

# This function needs Vivado and a routed design
proc swap_gitid16 {old_commit new_commit} {
    set c0 [get_cells -hier -filter {PRIMITIVE_TYPE =~ BMEM.*.*} *dxx_reg]
    if {[llength $c0] != 1} {return 0}
    set init0 [get_property INIT_00 $c0]
    set init1 [get_property INIT_01 $c0]
    set xx [gitid_proc16 $old_commit $new_commit $init0 $init1]
    if {[llength $xx] != 2} {return 0}
    lassign $xx init0x init1x
    set_property INIT_00 $init0x $c0
    set_property INIT_01 $init1x $c0
    puts "swap_gitid16 success $new_commit"
    return 1
}
