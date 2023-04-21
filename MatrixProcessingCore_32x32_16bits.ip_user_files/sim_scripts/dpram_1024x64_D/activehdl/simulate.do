onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+dpram_1024x64_D -L xil_defaultlib -L xpm -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.dpram_1024x64_D xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {dpram_1024x64_D.udo}

run -all

endsim

quit -force
