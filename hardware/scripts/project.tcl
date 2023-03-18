# Copyright (c) 2023 Christopher R. Bowman.  All rights reserved.
# contact: <my initials>@ChrisBowman.com

# TCL script to generate the Vivado project and optionally generate a bitstream file
#

proc print_help {} {
  variable script_file
  puts "\nDescription:"
  puts "Automated generation of project or project and bitstream
  puts "Syntax:"
  puts "$script_file"
  puts "$script_file -tclargs \[--generate_bit <path>\]"
  puts "$script_file -tclargs \[--help\]\n"
  puts "Usage:"
  puts "Name                   Description"
  puts "-------------------------------------------------------------------------"
  puts "\[--project_name <name>\] Create project with the specified name. Default"
  puts "                       name is the name of the project from where this"
  puts "                       script was generated.\n"
  puts "\[--generate_bit\]       Generate the bit stream in addition to creating the project.\n"
  puts "\[--help\]               Print help information for this script"
  puts "-------------------------------------------------------------------------\n"
  exit 0
}

if { $::argc > 0 } {
  for {set i 0} {$i < $::argc} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "--generate_bit" { set generate_bit 1}
      "--help"         { print_help }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
          return 1
        }
      }
    }
  }
}

if { $::argc > 0 } {
  for {set i 0} {$i < $::argc} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "--generate_bit" { set generate_bit 1}
      "--help"         { print_help }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
          return 1
        }
      }
    }
  }
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]

  set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]


  # Create ports
  set clk [ create_bd_port -dir I -type clk -freq_hz 100000000 clk ]

  # Create instance: myip_0, and set properties
  #set myip_0 [ create_bd_cell -type ip -vlnv user.org:user:myip:1.0 myip_0 ]
  set myip_0 [ create_bd_cell -type module -reference mm_axi_ssd mm_axi_ssd_inst ]

  # Create instance: processing_system7_0, and set properties
  set processing_system7_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0 ]
  source ../scripts/ps7prop_dict.tcl
  set_property -dict $ps7prop_dict $processing_system7_0

  # Create instance: ps7_0_axi_periph, and set properties
  set ps7_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 ps7_0_axi_periph ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
 ] $ps7_0_axi_periph

  # Create instance: rst_ps7_0_100M, and set properties
  set rst_ps7_0_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_100M ]

  # Create interface connections
  connect_bd_intf_net -intf_net processing_system7_0_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins processing_system7_0/DDR]
  connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins processing_system7_0/FIXED_IO]
  connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP0 [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins ps7_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M00_AXI [get_bd_intf_pins mm_axi_ssd_inst/axi_interface] [get_bd_intf_pins ps7_0_axi_periph/M00_AXI]

  # Create port connections
  connect_bd_net -net clk_0_1 [get_bd_ports clk] [get_bd_pins /clk]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins mm_axi_ssd_inst/S0_axi_aclk] [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins ps7_0_axi_periph/ACLK] [get_bd_pins ps7_0_axi_periph/M00_ACLK] [get_bd_pins ps7_0_axi_periph/S00_ACLK] [get_bd_pins rst_ps7_0_100M/slowest_sync_clk]
  connect_bd_net -net processing_system7_0_FCLK_RESET0_N [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins rst_ps7_0_100M/ext_reset_in]
  connect_bd_net -net rst_ps7_0_100M_peripheral_aresetn [get_bd_pins mm_axi_ssd_inst/S0_axi_aresetn] [get_bd_pins ps7_0_axi_periph/ARESETN] [get_bd_pins ps7_0_axi_periph/M00_ARESETN] [get_bd_pins ps7_0_axi_periph/S00_ARESETN] [get_bd_pins rst_ps7_0_100M/peripheral_aresetn]

  # Create address segments
  assign_bd_address -offset 0x43C00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs mm_axi_ssd_inst/axi_interface/reg0] -force

  # Restore current instance
  current_bd_instance $oldCurInst

  create_bd_port -dir O -from 4 -to 1 -type data ja_p
  create_bd_port -dir O -from 4 -to 1 -type data ja_n
  create_bd_port -dir O -from 4 -to 1 -type data jb_p
  create_bd_port -dir O -from 4 -to 1 -type data jb_n
  create_bd_port -dir O -from 3 -to 0 -type data led
  connect_bd_net [get_bd_ports ja_p] [get_bd_pins mm_axi_ssd_inst/ja_p]
  connect_bd_net [get_bd_ports ja_n] [get_bd_pins mm_axi_ssd_inst/ja_n]
  connect_bd_net [get_bd_ports jb_p] [get_bd_pins mm_axi_ssd_inst/jb_p]
  connect_bd_net [get_bd_ports jb_n] [get_bd_pins mm_axi_ssd_inst/jb_n]
  connect_bd_net [get_bd_ports led] [get_bd_pins mm_axi_ssd_inst/led]
  connect_bd_net [get_bd_ports clk] [get_bd_pins mm_axi_ssd_inst/clk]
  validate_bd_design
  save_bd_design
}

create_project my_project my_project -part xc7z020clg400-1
config_ip_cache -disable_cache
set_param board.repoPaths ../board_files
get_boards {*di*}
#set_property board_part digilentinc.com:arty-z7-20:part0:1.1 [current_project]
import_files -fileset constrs_1 -norecurse ../source/constraints/Arty-Z7-20-Master.xdc
import_files -fileset sources_1 -norecurse {../source/verilog/mm_axi_ssd.v ../source/verilog/mm_axi_ssd_core.v}

create_bd_design "axi_ssd_top"
create_root_design  ""

make_wrapper -files [get_files ./my_project/my_project.srcs/sources_1/bd/axi_ssd_top/axi_ssd_top.bd] -top
add_files -norecurse ./my_project/my_project.gen/sources_1/bd/axi_ssd_top/hdl/axi_ssd_top_wrapper.v
update_compile_order -fileset sources_1

# Disabling source management mode.  This is to allow the top design properties to be set without GUI intervention.
set_property source_mgmt_mode None [current_project]
set_property top axi_ssd_top_wrapper [current_fileset]
# Re-enabling previously disabled source management mode.
set_property source_mgmt_mode All [current_project]
update_compile_order -fileset sources_1

save_bd_design
# default is to just generate the project but if you add -tclargs --generate_bit
# the lanch the implementation step al the way to bitstream generation
if {$generate_bit==1} {
  launch_runs impl_1 -to_step write_bitstream -jobs 4
  wait_on_run impl_1
  set githash [exec git rev-parse --short=8 HEAD]
  puts "git hash: $githash"
#  set_property BITSTREAM.CONFIG.USERID $githash [current_design]
#  set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]
#  current_design rtl_1
#  write_bitstream [current_design]
#  puts "bitstream timestamp: [get_property REGISTER.USR_ACCESS [lindex [get_hw_devices 0]]]"
}
exit
