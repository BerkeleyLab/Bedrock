# Revise config_romx git ID in-place using BRAM INIT_xx values
# Absolutely depends on ROM contents that come out of bedrock/build-tools/build_rom.py
# Two distinct cases:
#   rowwidth = 8  for the case where the ROM is built with 2 x 8Kx8 BRAM (e.g., prc)
#   rowwidth = 16 for the case where the ROM is built with 1 x 4Kx16 BRAM (e.g., marble1)
# Could use stricter search for BRAM instances?
#
# In Vivado, when a design is complete and open, run with:
#   set new_commit [string toupper "da39a3ee5e6b4b0d3255bfef95601890afd80709"]
#   set old_commit [string toupper [exec git rev-parse HEAD]]
# Reverse the above two lines, once build_rom gets its --placeholder_rev option turned on
#   source swap_gitid.tcl
#   swap_gitid $old_commit $new_commit 8 0
# then if happy:
#   set_property BITSTREAM.CONFIG.USERID "32'hFEED0070" [current_design]
#   write_bitstream -force test.bit

# Useful constants
variable GITID_LENGTH 40
variable INIT_LENGTH  69
variable RECORD_MARKER 800A

# Comment about INIT_LENGTH: that's the length of the string Vivado uses
# to describe the (partial) initial contents of a Xilinx block memory.
# It takes the form
# "256'h388F5DDA0643504C420409D89060EF550D6BEE390AB3F9B0CD799F8FFF2C1F0A"
# i.e., 64 hex digits describing 256 data bits, plus the Verilog-inspired
# leading "256'h", for a total of 69 characters.

# Checks if GIT ID has a proper length
proc check_gitid {gitid} {
    if {[string length $gitid] != $::GITID_LENGTH } {
        puts "ERROR: Git commit ID must be $::GITID_LENGTH characters long!"
        return 0
    }

}

# Checks if init files has a proper length and proper record markers at the correct place
proc check_init {init0 init1 rowwidth} {
    if {[string length $init0] != $::INIT_LENGTH } {
        puts "ERROR: Unexpected length of init0"
        return 0
    }
    if {[string length $init1] != $::INIT_LENGTH } {
        puts "ERROR: Unexpected length of init1"
        return 0
    }

    switch $rowwidth {
        8 {
            if { [string range $init0 67 68] != "0A" || \
                 [string range $init0 45 46] != "0A" || \
                 [string range $init1 67 68] != "80" || \
                 [string range $init1 45 46] != "80"} {
                puts "Could not locate record markers ($::RECORD_MARKER) inside Init files !"
                return 0
            }
        }
        16 {
            if { [string range $init0 65 68] != "800A" || \
                 [string range $init0 21 24] != "800A"} {
                puts "Could not locate record markers ($::RECORD_MARKER) inside Init files !"
                return 0
            }
        }
    }
}

proc reorder_bits {gitid rowwidth} {
    if {!($rowwidth == 8 || $rowwidth == 16)} {
        puts "ERROR: rowwidth must be 8 or 16! It is currently: $rowwidth"
        return 0
    }

    set msb ""
    set lsb ""

    switch $rowwidth {
        8 {
            for {set jx 0} {$jx < 20} {incr jx} {
                set p [string range $gitid 0 1]
                set lsb "${p}${lsb}"
                set p [string range $gitid 2 3]
                set msb "${p}${msb}"
                set gitid [string range $gitid 4 999]
            }
            return "$msb $lsb"
        }

        16 {
            for {set jx 0} {$jx < 4} {incr jx} {
                set p [string range $gitid 0 3]
                set lsb "${p}${lsb}"
                set gitid [string range $gitid 4 999]
            }
            for {set jx 0} {$jx < 6} {incr jx} {
                set p [string range $gitid 0 3]
                set msb "${p}${msb}"
                set gitid [string range $gitid 4 999]
            }
            return "$msb $lsb"
         }
        default {puts "Invalid rowwidth parameter"}
    }
}

proc gitid_proc {old_commit new_commit init0 init1 rowwidth} {
    # Security checks
    check_gitid $old_commit
    check_gitid $new_commit
    check_init $init0 $init1 $rowwidth

    # Get the MSB and LSB from the old commit hash
    lassign [reorder_bits $old_commit $rowwidth] old_msb old_lsb

    switch $rowwidth {
        8 {
            # Check that the existing INIT values match $old_commit -- this is key!
            if {[string range $init0 25 44] != $old_msb} {
                puts "ERROR: init0 file and old MSB values do not match!"
                return 0
                }
            if {[string range $init1 25 44] != $old_lsb} {
                puts "ERROR: init1 file and old LSB values do not match!"
                return 0
                }

            # Finally insert $new_commit in place
            lassign [reorder_bits $new_commit $rowwidth] new_msb new_lsb
            set new_init0 "[string range $init0 0 24]$new_msb[string range $init0 45 68]"
            set new_init1 "[string range $init1 0 24]$new_lsb[string range $init1 45 68]"
        }

        16 {
            # Check that the existing INIT values match $old_commit -- this is key!
            if {[string range $init0 5 20] != $old_lsb} {
                puts "ERROR: init0 file and old MSB values do not match!"
                return 0
                }
            if {[string range $init1 45 68] != $old_msb} {
                puts "ERROR: init1 file and old LSB values do not match!"
                return 0
                }

            # Finally insert $new_commit in place
            lassign [reorder_bits $new_commit $rowwidth] new_msb new_lsb
            set new_init0 "[string range $init0 0 4]$new_lsb[string range $init0 21 68]"
            set new_init1 "[string range $init1 0 44]$new_msb"
        }

    }
    # Chatter
    puts "INFO: old 0 $init0"
    puts "INFO: new 0 $new_init0"
    puts "INFO: --"
    puts "INFO: old 1 $init1"
    puts "INFO: new 1 $new_init1"
    puts "INFO: --"
    return "$new_init0 $new_init1"
}


# Above this point are general string handling functions,
# which can be tested by a vanilla tclsh.  See test_swap_gitid.tcl.
# The functions below need Vivado and a routed design.

# Checks if vivado has finished implementation
proc check_impl {} {
    set impl_runs [get_runs impl_*]
    if {$impl_runs eq ""} {
        puts "ERROR: Did not find active Vivado implemenation run"
    }
}

proc check_bmem {pattern width} {
    set c [get_cells -hier -filter {PRIMITIVE_TYPE =~ BMEM.*.*} $pattern]
    if {[llength $c] != 1} {
        puts "ERROR: Unexpected number of $pattern!"
        return 0
    }
    set n [get_property READ_WIDTH_A $c]
    if {$n != $width} {
        puts "ERROR: Read Width of $pattern must be $width (not $n)!"
        return 0
    }
    return $c
}

proc swap_gitid {old_commit new_commit rowwidth dry_run} {
    # Checks if implementation stage is there
    check_impl

    switch $rowwidth {
        8 {
            set c0 [check_bmem "*dxx_reg_0" 9]
            set c1 [check_bmem "*dxx_reg_1" 9]
            if {$c0 == 0 || $c1 == 0} {return 0}
            set init0 [get_property INIT_00 $c0]
            set init1 [get_property INIT_00 $c1]
            set xx [gitid_proc $old_commit $new_commit $init0 $init1 $rowwidth]
            if {[llength $xx] != 2} {return 0}
            lassign $xx init0x init1x
            if {$dry_run != 1} {
                set_property INIT_00 $init0x $c0
                set_property INIT_00 $init1x $c1
            } else {
                puts "Dry run only"
            }
        }

        16 {
            set c0 [check_bmem "*dxx_reg" 18]
            if {$c0 == 0} {return 0}
            set init0 [get_property INIT_00 $c0]
            set init1 [get_property INIT_01 $c0]
            set xx [gitid_proc $old_commit $new_commit $init0 $init1 $rowwidth]
            if {[llength $xx] != 2} {return 0}
            lassign $xx init0x init1x
            if {$dry_run != 1} {
                set_property INIT_00 $init0x $c0
                set_property INIT_01 $init1x $c0
            } else {
                puts "Dry run only"
            }
        }

    }
    puts OK
    return 1
}
