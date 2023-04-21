onbreak {quit -f}
onerror {quit -f}

vsim -voptargs="+acc" -t 1ps -L xil_defaultlib -L secureip -L xpm -lib xil_defaultlib xil_defaultlib.dpram_1024x64_D

do {wave.do}

view wave
view structure
view signals

do {dpram_1024x64_D.udo}

run -all

quit -force
