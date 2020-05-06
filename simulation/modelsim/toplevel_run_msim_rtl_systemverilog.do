transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft {C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft/Wave_ROM256.v}
vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity {C:/Users/unnat/Desktop/ECE385/FPGAudacity/sdram_pll.v}
vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity/db {C:/Users/unnat/Desktop/ECE385/FPGAudacity/db/sdram_pll_altpll.v}
vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft {C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft/IWROM256.v}
vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft {C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft/irotator256_v.v}
vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft {C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft/ifft256.v}
vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft {C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft/ifft16.v}
vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft {C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft/WROM256.v}
vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft {C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft/rotator256_v.v}
vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft {C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft/ram2x256.v}
vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft {C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft/mpuc1307.v}
vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft {C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft/mpuc924_383.v}
vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft {C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft/mpuc707.v}
vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft {C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft/mpuc541.v}
vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft {C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft/fft256.v}
vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft {C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft/fft16.v}
vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft {C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft/bufram256c.v}
vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft {C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft/cnorm.v}
vlog -sv -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity {C:/Users/unnat/Desktop/ECE385/FPGAudacity/low_pass_filter.sv}
vlog -sv -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity {C:/Users/unnat/Desktop/ECE385/FPGAudacity/sample_operations.sv}
vlog -sv -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity {C:/Users/unnat/Desktop/ECE385/FPGAudacity/recorder.sv}
vlog -sv -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity {C:/Users/unnat/Desktop/ECE385/FPGAudacity/countdown.sv}
vlog -sv -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity {C:/Users/unnat/Desktop/ECE385/FPGAudacity/sdram_control.sv}
vlog -sv -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity {C:/Users/unnat/Desktop/ECE385/FPGAudacity/dac.sv}
vlog -sv -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity {C:/Users/unnat/Desktop/ECE385/FPGAudacity/adc.sv}
vlog -sv -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity {C:/Users/unnat/Desktop/ECE385/FPGAudacity/ui_control.sv}
vlog -sv -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity {C:/Users/unnat/Desktop/ECE385/FPGAudacity/synchronizer.sv}
vlog -sv -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity {C:/Users/unnat/Desktop/ECE385/FPGAudacity/toplevel.sv}
vcom -93 -work work {C:/Users/unnat/Desktop/ECE385/FPGAudacity/audio_interface.vhd}

vlog -sv -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity {C:/Users/unnat/Desktop/ECE385/FPGAudacity/fft_testbench.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  fft_testbench

add wave *
view structure
view signals
run 100 ns
