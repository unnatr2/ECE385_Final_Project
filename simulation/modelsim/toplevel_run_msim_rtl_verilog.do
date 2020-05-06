transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity {C:/Users/unnat/Desktop/ECE385/FPGAudacity/sdram_pll.v}
vlog -vlog01compat -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity/db {C:/Users/unnat/Desktop/ECE385/FPGAudacity/db/sdram_pll_altpll.v}
vlog -sv -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity {C:/Users/unnat/Desktop/ECE385/FPGAudacity/countdown.sv}
vlog -sv -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity {C:/Users/unnat/Desktop/ECE385/FPGAudacity/sdram_control.sv}

vlog -sv -work work +incdir+C:/Users/unnat/Desktop/ECE385/FPGAudacity {C:/Users/unnat/Desktop/ECE385/FPGAudacity/sdram_testbench.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  sdram_testbench

add wave *
view structure
view signals
run 10000 ns
