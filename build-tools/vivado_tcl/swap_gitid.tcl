# Functions related to Vivado and git

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
# Default string in case of missing git repo.  It's made to have sense
# as 8 and 24 digits and to avoid to run bit_stamp_mod
variable NO_GIT_RETURN_VAL "no_gitid_sha_information__________-dirty"

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

##########################
# On to functions that use info about the current git commit
# to set file names and embedded gitid strings

# Return full 40-digit commit id and timestamp as tcl array.
# Recommend use -> array set array_name [get_full_git_id]
proc get_full_git_id {} {
    set id [get_dirty_git_id 40]
    set time [get_git_timestamp]
    return [list id $id time $time]
}

# Provide the timestamp of current git commit
# sometimes called SOURCE_DATE_EPOCH
proc get_git_timestamp {} {
    if [catch {exec git log -1 --pretty=%ct} result] {
        return 0
    } else {
        return $result
    }
}

# Returns the N-digit git id sha ending with '-dirty' in case of local
# modification (or the first N-digit of NO_GIT_RETURN_VAL in case it's
# executed outside a git project)
proc get_dirty_git_id {N} {
    if [catch {exec git describe --always --abbrev=$N --dirty --exclude "*"} result] {
        return [string range $::NO_GIT_RETURN_VAL 0 $N-1]
    } else {
        return $result
    }
}

# Returns the N-digit git id sha or the first N-digit of NO_GIT_RETURN_VAL
# in case it's executed outside a git project
proc get_git_id {N} {
    return [regsub {\-dirty} [get_dirty_git_id $N] ""]
}

# Utility for local modification presence check
proc is_git_dirty {gitid} {
    switch -glob -- $gitid {
        *-dirty      {return 1}
        default      {return 0}
    }
}

# Generate 40 digits git commit id where the latest 16 digits
# are zeros in case of local modification
proc generate_extended_git_id {git_id dirtiness} {
    if {[string length $git_id] < 40} {
        error "generate_extended_git_id error: [
            ]received a git id shorter than 40 digits!"
    }
    if {$dirtiness} {
        return [string range $git_id 0 23]0000000000000000
    } else {
        return $git_id
    }
}

# Print git hash in huge and colored way
proc git_id_print {gitid_arg} {
    puts -nonewline "#[string repeat "-" 48]\n# "
    orange_print "gitid $gitid_arg"
    puts "#[string repeat "-" 48]"
}

proc orange_print {text} {
    set orange_color "\033\[93m"
    set reset_color "\033\[0m"
    puts "${orange_color}"
    puts "${text}"
    puts "${reset_color}"
}

# Primary access to the assembled info about this git repo
proc get_git_context {} {
    # single-source-of-truth
    array set git_status [get_full_git_id]
    # everything else derived from that
    set git_id [string range $git_status(id) 0 39]
    set git_id_short [string range $git_status(id) 0 7]
    set git_dirty [is_git_dirty $git_status(id)]
    set dirty_suffix ""
    if {$git_dirty} {set dirty_suffix "-dirty"}
    set new_commit [generate_extended_git_id $git_status(id) $git_dirty]
    # return list is an array (recommend use of array set)
    return [list short_id $git_id_short dirty $git_dirty suffix[
        ] $dirty_suffix full_id $new_commit time $git_status(time)]
}

# function to handle get_git_context as list instead of an array
# i.e. set git_as_list [array_to_list [get_git_context]]
proc array_to_list {array_arg} {
    array set array_tmp $array_arg
    foreach key [array names array_tmp] {
        lappend array_list $array_tmp($key)
    }
    return $array_list
}

# Convert $filename_base.x.bit to $filename_base.bit,
# using bit_stamp_mod or not, as appropriate.
proc apply_bit_stamp_mod {filename_base git_dirty source_stamp} {
    if {! [file readable $filename_base.x.bit]} {
        error "bitfile $filename_base.x.bit missing; no action taken"
    }
    if {$git_dirty} {
        puts "modified code; not coercing bitfile header timestamp"
    } elseif [file executable ./bit_stamp_mod] {
        puts "pristine code; setting bitfile header timestamp to $source_stamp"
        puts [exec ./bit_stamp_mod -s $source_stamp $filename_base.bit < $filename_base.x.bit]
        file delete $filename_base.x.bit
        puts [exec sha256sum $filename_base.bit]
        return
    } else {
        puts "bit_stamp_mod not available; not coercing bitfile header timestamp"
    }
    file rename -force $filename_base.x.bit $filename_base.bit
}
