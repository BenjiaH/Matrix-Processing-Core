vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vcom -work xil_defaultlib -64 -93 \
"../../../../MatrixProcessingCore_32x32_16bits.srcs/sources_1/ip/dpram_1024x64_D/dpram_1024x64_D_sim_netlist.vhdl" \


