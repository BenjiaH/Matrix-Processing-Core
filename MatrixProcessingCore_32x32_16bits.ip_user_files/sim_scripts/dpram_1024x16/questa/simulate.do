onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib dpram_1024x16_opt

do {wave.do}

view wave
view structure
view signals

do {dpram_1024x16.udo}

run -all

quit -force
