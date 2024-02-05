vlib work
vlib riviera

vlib riviera/xpm
vlib riviera/xil_defaultlib

vmap xpm riviera/xpm
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xpm  -sv2k12 "+incdir+../../../../uart_hello.gen/sources_1/ip/vio_uart_hello/hdl/verilog" "+incdir+../../../../uart_hello.gen/sources_1/ip/vio_uart_hello/hdl" \
"C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93  \
"C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../uart_hello.gen/sources_1/ip/vio_uart_hello/hdl/verilog" "+incdir+../../../../uart_hello.gen/sources_1/ip/vio_uart_hello/hdl" \
"../../../../uart_hello.gen/sources_1/ip/vio_uart_hello/sim/vio_uart_hello.v" \

vlog -work xil_defaultlib \
"glbl.v"

