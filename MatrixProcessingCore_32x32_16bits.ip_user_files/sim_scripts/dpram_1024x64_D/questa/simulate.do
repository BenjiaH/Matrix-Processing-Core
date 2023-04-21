onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib dpram_1024x64_D_opt

do {wave.do}

view wave
view structure
view signals

do {dpram_1024x64_D.udo}

run -all

quit -force
