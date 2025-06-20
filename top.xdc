# Arty S7-50 Rev E Constraints File - secp256k1 Bitcoin Keypair Generator

# Clock input (12 MHz)
set_property PACKAGE_PIN F14 [get_ports CLK12MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK12MHZ]
create_clock -name sys_clk_pin -period 83.33 -waveform {0 41.66} [get_ports CLK12MHZ]

# Buttons
set_property PACKAGE_PIN G15 [get_ports {btn[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[0]}]

set_property PACKAGE_PIN K16 [get_ports {btn[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[1]}]

set_property PACKAGE_PIN J16 [get_ports {btn[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[2]}]

set_property PACKAGE_PIN H13 [get_ports {btn[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[3]}]

# UART TX - FPGA to host serial
set_property PACKAGE_PIN R12 [get_ports uart_rxd_out]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rxd_out]

# LEDs for debug/heartbeat
set_property PACKAGE_PIN E18 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN F13 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN E13 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

set_property PACKAGE_PIN H15 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

# Configuration: SPI Flash and Voltage Settings
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

# VREF for BANK 34 (for 3.3V I/O tolerance)
set_property INTERNAL_VREF 0.675 [get_iobanks 34]
