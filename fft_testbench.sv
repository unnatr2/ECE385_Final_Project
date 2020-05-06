module fft_testbench ();
	timeunit 10ns;
	timeprecision 1ps;

	logic Clk;
	logic RST;
	logic ED;
	logic START;
	logic [3:0]SHIFT;
	logic [15:0]DR;
	logic [15:0]DI;
	logic RDY;
	logic OVF1;
	logic OVF2;
	logic [7:0]ADDR;
	logic signed [19:0]DOR;
	logic signed [19:0]DOI;

	always begin: MAIN_CLOCK_GENERATION
		#1 Clk = ~Clk;
	end

	initial begin: CLOCK_INITIALIZATION
		Clk = 0;
	end

	logic [7:0] ct256;
	always @(posedge Clk, posedge START) begin
		if (ED)	begin
			if (START) ct256 = 8'b0000_0000;
			else ct256 = ct256+ 'd1;
		end
	end

	Wave_ROM256 UG (
		.ADDR(ct256),
		.DATA_RE(DR), 
		.DATA_IM(DI));

	FFT256 Forward (
		.CLK(Clk),
		.RST(RST),
		.ED(ED),
		.START(START),
		.SHIFT(4'b0010),
		.DR(DR),
		.DI(DI),
		.RDY(RDY),
		.ADDR(ADDR),
		.DOR(DOR),
		.DOI(DOI));


	logic IRDY;
	logic [7:0] IADDR;
	logic signed [19:0] IDOR;
	//  IDOR_buffer;
	logic signed [19:0] IDOI;
	//  IDOI_buffer;	

	// assign IDOR = (IADDR == 8'd34) ? IDOR_buffer : ((IADDR - 8'd2) % 8'd16 == 0) ? -IDOR_buffer : (IADDR >= 8'd32 && IADDR <= 8'd47) ? -IDOR_buffer : IDOR_buffer;
	// assign IDOI = (IADDR == 8'd34) ? IDOI_buffer : ((IADDR - 8'd2) % 8'd16 == 0) ? -IDOI_buffer : (IADDR >= 8'd32 && IADDR <= 8'd47) ? -IDOI_buffer : IDOI_buffer;

	// assign IDOR = IDOR << 3;

	IFFT256 Inverse (
		.CLK(Clk),
		.RST(RST),
		.ED(ED),
		.START(RDY),
		.SHIFT(4'b1111),
		.DR(DOR[15:0]),
		.DI(DOI[15:0]),
		.RDY(IRDY),
		.ADDR(IADDR),
		.DOR(IDOR),
		.DOI(IDOI));

	initial begin: TESTS
		SHIFT = 4'd0;
		ED = 1'b1;
		RST = 1'b0;
		START = 1'b0;
		#13 RST =1'b1;
		#43 RST =1'b0;
		#53 START =1'b1;
		#12 START =1'b0;
	end	  
endmodule