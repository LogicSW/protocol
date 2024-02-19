vlib work
vlib activehdl

vlib activehdl/xpm
vlib activehdl/xil_defaultlib

vmap xpm activehdl/xpm
vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work xpm  -sv2k12 "+incdir+../../../../project_1.gen/sources_1/ip/vio_spi/hdl/verilog" "+incdir+../../../../project_1.gen/sources_1/ip/vio_spi/hdl" \
"C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93  \
"C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../project_1.gen/sources_1/ip/vio_spi/hdl/verilog" "+incdir+../../../../project_1.gen/sources_1/ip/vio_spi/hdl" \
"../../../../project_1.gen/sources_1/ip/vio_spi/sim/vio_spi.v" \

vlog -work xil_defaultlib \
"glbl.v"

