module high_pass_filter(
	input	logic [7:0]  FREQ_BIN,
	input 	logic [7:0]  CUTOFF_FREQ,
	input 	logic [15:0] REAL_AMPLITUDE_IN,
	input 	logic [15:0] IMAG_AMPLITUDE_IN,
	output	logic [15:0] REAL_AMPLITUDE_OUT,
	output	logic [15:0] IMAG_AMPLITUDE_OUT
);
	
	assign REAL_AMPLITUDE_OUT = (FREQ_BIN <= CUTOFF_FREQ) ? 16'b0 : REAL_AMPLITUDE_IN;
	assign IMAG_AMPLITUDE_OUT = (FREQ_BIN <= CUTOFF_FREQ) ? 16'b0 : IMAG_AMPLITUDE_IN;

endmodule