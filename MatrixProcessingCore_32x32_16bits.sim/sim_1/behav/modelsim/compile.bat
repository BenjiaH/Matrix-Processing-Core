@echo off
REM ****************************************************************************
REM Vivado (TM) v2018.3.1 (64-bit)
REM
REM Filename    : compile.bat
REM Simulator   : Mentor Graphics ModelSim Simulator
REM Description : Script for compiling the simulation design source files
REM
REM Generated by Vivado on Mon Apr 10 00:48:17 +0100 2023
REM SW Build 2489853 on Tue Mar 26 04:20:25 MDT 2019
REM
REM Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
REM
REM usage: compile.bat
REM
REM ****************************************************************************
set bin_path=D:\\modeltech64_10.6c\\win64
call %bin_path%/vsim  -c -do "do {tb_IntMatProCore_compile.do}" -l compile.log
if "%errorlevel%"=="1" goto END
if "%errorlevel%"=="0" goto SUCCESS
:END
exit 1
:SUCCESS
exit 0
