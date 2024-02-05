vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/xil_defaultlib

vmap xpm modelsim_lib/msim/xpm
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xpm  -incr -mfcu  -sv "+incdir+../../../../uart_hello.gen/sources_1/ip/vio_uart_hello/hdl/verilog" "+incdir+../../../../uart_hello.gen/sources_1/ip/vio_uart_hello/hdl" \
"C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm  -93  \
"C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../../uart_hello.gen/sources_1/ip/vio_uart_hello/hdl/verilog" "+incdir+../../../../uart_hello.gen/sources_1/ip/vio_uart_hello/hdl" \
"../../../../uart_hello.gen/sources_1/ip/vio_uart_hello/sim/vio_uart_hello.v" \

vlog -work xil_defaultlib \
"glbl.v"

