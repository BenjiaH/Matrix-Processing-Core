// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Sun Apr  9 03:25:14 2023
// Host        : wvd-eng1prd-12 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub -rename_top dpram_1024x64 -prefix
//               dpram_1024x64_ dpram_1024x64_D_stub.v
// Design      : dpram_1024x64_D
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a15tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_2,Vivado 2018.3" *)
module dpram_1024x64(clka, wea, addra, dina, clkb, enb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[9:0],dina[63:0],clkb,enb,addrb[9:0],doutb[63:0]" */;
  input clka;
  input [0:0]wea;
  input [9:0]addra;
  input [63:0]dina;
  input clkb;
  input enb;
  input [9:0]addrb;
  output [63:0]doutb;
endmodule
