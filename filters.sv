module filters(
    input  logic        Clk,
    input  logic        Sample_Clk,
	input  logic        Reset,
    input  logic [31:0] RAW_AUD_IN,
	input  logic [4:0]	FILTER_BITMASK,
	input  logic [4:0] [7:0] FILTER_VALUES,
	output logic [31:0] FILTERED_AUD_OUT
);
	// FILTER_BITMASK = PITCH, INVERSION, REVERB, HPF, LPF 
	logic PITCH_EN, INVERSION_EN, REVERB_EN, HPF_EN, LPF_EN;
	assign PITCH_EN = FILTER_BITMASK[4];
	assign INVERSION_EN = FILTER_BITMASK[3];
	assign REVERB_EN = FILTER_BITMASK[2];
	assign HPF_EN = FILTER_BITMASK[1];
	assign LPF_EN = FILTER_BITMASK[0];

	// Inversion
	logic [15:0] PRE_INVERSION, POST_INVERSION;
	assign PRE_INVERSION = RAW_AUD_IN[31:16];
	inversion_filter inversion (
		.SAMPLE_IN(PRE_INVERSION),
		.SAMPLE_OUT(POST_INVERSION)
	);
	
	// Reverb
	logic [15:0] PRE_REVERB, POST_REVERB;
	assign PRE_REVERB = INVERSION_EN ? POST_INVERSION : PRE_INVERSION;
	reverb_filter reverb (
		.CLK(Sample_Clk),
		.DECAY(FILTER_VALUES[2]),
		.SAMPLE_IN(PRE_REVERB),
		.SAMPLE_OUT(POST_REVERB)
	);

	logic RDY, IRDY;
	logic START, started;
	logic [7:0] ADDR, IADDR;
	logic signed [16:0] DR;
	logic signed [19:0] DOR, DOI;
	logic signed [19:0] IDOR, IDOI;
	logic signed [19:0] IDOR_buffer, IDOI_buffer;

	// FFT Startup
    initial begin
        START = 0;
        started = 0;
    end
    always_ff @(posedge Sample_Clk) begin
        if (!started) begin
            START <= 1;
            started <= 1;
        end else begin
            START <= 0;
        end 
	end
		
	// Foward FFT
	assign DR = REVERB_EN ? POST_REVERB : PRE_REVERB;
	FFT256 Forward (
		.CLK(Sample_Clk),
		.RST(Reset),
		.ED(1),
		.START(START),
		.SHIFT(4'b0000),
		.DR(DR),
		.DI(16'b0),
		.RDY(RDY),
		.ADDR(ADDR),
		.DOR(DOR),
		.DOI(DOI)
	);

	// Low pass filter
	logic signed [15:0] REAL_PRE_LPF, REAL_POST_LPF;
	logic signed [15:0] IMAG_PRE_LPF, IMAG_POST_LPF;
	assign REAL_PRE_LPF = DOR[15:0];
	assign IMAG_PRE_LPF = DOI[15:0];
	low_pass_filter lpf (
		.FREQ_BIN(ADDR),
		.CUTOFF_FREQ(FILTER_VALUES[0]),
		.REAL_AMPLITUDE_IN(REAL_PRE_LPF),
		.IMAG_AMPLITUDE_IN(IMAG_PRE_LPF),
		.REAL_AMPLITUDE_OUT(REAL_POST_LPF),
		.IMAG_AMPLITUDE_OUT(IMAG_POST_LPF)
	);

	// High pass filter
	logic signed [15:0] REAL_PRE_HPF, REAL_POST_HPF;
	logic signed [15:0] IMAG_PRE_HPF, IMAG_POST_HPF;
	assign REAL_PRE_HPF = LPF_EN ? REAL_POST_LPF : REAL_PRE_LPF;
	assign IMAG_PRE_HPF = LPF_EN ? IMAG_POST_LPF : IMAG_PRE_LPF;
	high_pass_filter hpf (
		.FREQ_BIN(ADDR),
		.CUTOFF_FREQ(FILTER_VALUES[1]),
		.REAL_AMPLITUDE_IN(REAL_PRE_HPF),
		.IMAG_AMPLITUDE_IN(IMAG_PRE_HPF),
		.REAL_AMPLITUDE_OUT(REAL_POST_HPF),
		.IMAG_AMPLITUDE_OUT(IMAG_POST_HPF)
	);
	
	// Pitch filter
	logic signed [15:0] REAL_PRE_PITCH, REAL_POST_PITCH;
	logic signed [15:0] IMAG_PRE_PITCH, IMAG_POST_PITCH;
	assign REAL_PRE_PITCH = HPF_EN ? REAL_POST_HPF : REAL_PRE_HPF;
	assign IMAG_PRE_PITCH = HPF_EN ? IMAG_POST_HPF : IMAG_PRE_HPF;
	pitch_filter pitch (
		.CLK(Sample_Clk),
		.FREQ_BIN(ADDR),
		.PITCH(FILTER_VALUES[4]),
		.REAL_AMPLITUDE_IN(REAL_PRE_PITCH),
		.IMAG_AMPLITUDE_IN(IMAG_PRE_PITCH),
		.REAL_AMPLITUDE_OUT(REAL_POST_PITCH),
		.IMAG_AMPLITUDE_OUT(IMAG_POST_PITCH)
	);

	// Inverse FFT
	logic signed [15:0] REAL_PRE_IFFT, IMAG_PRE_IFFT;
	assign REAL_PRE_IFFT = PITCH_EN ? REAL_POST_PITCH : REAL_PRE_PITCH;
	assign IMAG_PRE_IFFT = PITCH_EN ? IMAG_POST_PITCH : IMAG_PRE_PITCH;
	IFFT256 Inverse (
		.CLK(Sample_Clk),
		.RST(Reset),
		.ED(1),
		.START(RDY),
		.SHIFT(4'b0010),
		.DR(REAL_PRE_IFFT),
		.DI(IMAG_PRE_IFFT),
		.RDY(IRDY),
		.ADDR(IADDR),
		.DOR(IDOR_buffer),
		.DOI(IDOI_buffer)
	);
		
	// Trial and error tuning (ModelSim obervations)
	// Whack shit, please dont do this at home
	assign IDOR = (IADDR == 8'd34) ? IDOR_buffer : ((IADDR - 8'd2) % 8'd16 == 0) ? -IDOR_buffer : (IADDR >= 8'd32 && IADDR <= 8'd47) ? -IDOR_buffer : IDOR_buffer;
	assign IDOI = (IADDR == 8'd34) ? IDOI_buffer : ((IADDR - 8'd2) % 8'd16 == 0) ? -IDOI_buffer : (IADDR >= 8'd32 && IADDR <= 8'd47) ? -IDOI_buffer : IDOI_buffer;
	// Skip the frequency domain if not necessary
	assign FILTERED_AUD_OUT = (!LPF_EN && !HPF_EN && !PITCH_EN) ? {DR, DR} : {IDOR[15:0], IDOR[15:0]};

endmodule