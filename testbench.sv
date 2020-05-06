module testbench ();
  	timeunit 10ns;
  	timeprecision 1ns;

    logic        Clk;
    logic        Reset;
    logic        SAMPLE_INPUT_CLK;
    logic        SAMPLE_OUTPUT_CLK;
    logic [31:0] INPUT_DATA;
    logic        DO_RECORD;
    logic        DO_PLAYBACK;
	logic		 DO_CLEAR;
    logic [31:0] OUTPUT_DATA;
	logic [24:0] TIME;
    logic [24:0] END_TIME;

    // SDRAM Controls
    logic        RW_ACK;
    logic        INIT_DONE;
    logic [31:0] DATA_READ;
    logic [24:0] DATA_ADDR;
    logic [31:0] DATA_WRITE;
    logic        RW_READ;
    logic        RW_WRITE;

    always begin: MAIN_CLOCK_GENERATION
    	#1 Clk = ~Clk;
    end

    always begin: SAMPLE_INPUT_CLOCK
		#2 SAMPLE_INPUT_CLK = ~SAMPLE_INPUT_CLK;
	end

	always_ff @(posedge Clk) begin
		if (Reset) INPUT_DATA <= 32'b0;
		else INPUT_DATA <= INPUT_DATA + 1;
	end

    always begin: SAMPLE_OUTPUT_CLOCK
		#1 SAMPLE_OUTPUT_CLK = ~SAMPLE_OUTPUT_CLK;
		#1;
	end
  
	initial begin: CLOCK_INITIALIZATION
     	Clk = 0;
		SAMPLE_INPUT_CLK = 0;
		SAMPLE_OUTPUT_CLK = 1;
    end
  	
  	recorder audio_recorder(.*);
  	
	initial begin: TESTS
		DO_PLAYBACK = 0;
		DO_RECORD = 0;
		DO_CLEAR = 0;
		#2 Reset = 1;
		#2 Reset = 0;
		#2 RW_ACK = 1;
		#2 DATA_READ = 32'hFABBDAAD;
		#10 INIT_DONE = 1;
		
		#2 DO_RECORD = 1;
		#1000; // Record for LONG time
		#2 DO_RECORD = 0;
		#2 DO_PLAYBACK = 1;
		#3000; // Playback time
		#2 DO_PLAYBACK = 0;
		#2 DO_CLEAR = 1;
		#1000; // Clear time
		#2 DO_CLEAR = 0;

	end



endmodule