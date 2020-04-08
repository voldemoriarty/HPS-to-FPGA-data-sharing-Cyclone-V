#**************************************************************
# This .sdc file is created by Terasic Tool.
# Users are recommended to modify this file to match users logic.
#**************************************************************

#**************************************************************
# Create Clock
#**************************************************************
create_clock -period "50.0 MHz" [get_ports FPGA_CLK1_50]
create_clock -period "50.0 MHz" [get_ports FPGA_CLK2_50]
create_clock -period "50.0 MHz" [get_ports FPGA_CLK3_50]

# for enhancing USB BlasterII to be reliable, 25MHz
create_clock -name {altera_reserved_tck} -period 40 {altera_reserved_tck}
set_input_delay -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tdi]
set_input_delay -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tms]
set_output_delay -clock altera_reserved_tck 3 [get_ports altera_reserved_tdo]

set_false_path -from [get_ports {SW[0]}] -to *
set_false_path -from [get_ports {SW[1]}] -to *
set_false_path -from [get_ports {SW[2]}] -to *
set_false_path -from [get_ports {SW[3]}] -to *

set_false_path -from [get_ports {KEY[0]}] -to *
set_false_path -from [get_ports {KEY[1]}] -to *

set_false_path -from * -to [get_ports {LED[0]}]
set_false_path -from * -to [get_ports {LED[1]}]
set_false_path -from * -to [get_ports {LED[2]}]
set_false_path -from * -to [get_ports {LED[3]}]
set_false_path -from * -to [get_ports {LED[4]}]
set_false_path -from * -to [get_ports {LED[5]}]
set_false_path -from * -to [get_ports {LED[6]}]
set_false_path -from * -to [get_ports {LED[7]}]

create_clock -period "1 MHz"  [get_ports {HPS_I2C0_SCLK}]
create_clock -period "1 MHz"  [get_ports {HPS_I2C1_SCLK}]
create_clock -period "48 MHz" [get_ports {HPS_USB_CLKOUT}]


#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************
