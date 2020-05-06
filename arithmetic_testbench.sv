module arithmetic_testbench ();
  	timeunit 10ns;
  	timeprecision 1ns;

    logic signed [15 : 0] IN; // "sample_in"
    logic signed [15 : 0] OUT; // "sample_out"
    logic signed [7 : 0] ACTUAL;
    logic signed [7 : 0] TOTAL;
    

	sample_scale #($bits(ACTUAL), $bits(TOTAL), $bits(IN)) scaling (.*);
  	
	initial begin: TESTS
		ACTUAL = 8'd1;
		TOTAL = 8'd80;
		IN = 16'h7FFF;
		// C = 6'b111110;
	end
endmodule