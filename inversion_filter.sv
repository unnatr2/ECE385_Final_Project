module inversion_filter(
	input 	logic signed [15:0] SAMPLE_IN,
	output	logic signed [15:0] SAMPLE_OUT
);
	
	assign SAMPLE_OUT = -SAMPLE_IN;

endmodule