vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/xil_defaultlib

vmap xpm modelsim_lib/msim/xpm
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xpm  -incr -mfcu  -sv "+incdir+../../../../project_1.gen/sources_1/ip/vio_spi/hdl/verilog" "+incdir+../../../../project_1.gen/sources_1/ip/vio_spi/hdl" \
"C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm  -93  \
"C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../../project_1.gen/sources_1/ip/vio_spi/hdl/verilog" "+incdir+../../../../project_1.gen/sources_1/ip/vio_spi/hdl" \
"../../../../project_1.gen/sources_1/ip/vio_spi/sim/vio_spi.v" \

vlog -work xil_defaultlib \
"glbl.v"

