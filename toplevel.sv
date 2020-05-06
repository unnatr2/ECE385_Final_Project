module toplevel (
    input   logic        CLOCK_50,
    input   logic [3:0]  KEY,
    input   logic [17:0] SW,
    input   logic        AUD_DACLRCK,
    input   logic        AUD_ADCDAT,
    input   logic        AUD_ADCLRCK,
    input   logic        AUD_BCLK,
    output  logic        AUD_DACDAT,
    output  logic        AUD_XCK,
    output  logic        I2C_SCLK,
    output  logic        I2C_SDAT,
    output  logic [8:0]  LEDG,
    output  logic [17:0] LEDR,

    // SDRAM
    output  logic        DRAM_CAS_N, // Column Address Select (Active Low)
    output  logic        DRAM_RAS_N, // Row Address Select (Active Low)
    output  logic        DRAM_CLK,   // SDRAM Clock
    output  logic        DRAM_CKE,   // Clock Enable
    output  logic        DRAM_CS_N,  // Chip Select (2 chips -> 1bit) (Active Low)
    output  logic        DRAM_WE_N,  // Write Enable (Active Low)
    output  logic [12:0] DRAM_ADDR,  // Address (for rows AND columns, rows -> 13b, col -> 10b)
    output  logic [3:0]  DRAM_DQM,   // Byte Data Mask (bytemask for each of 4 bytes)
    output  logic [1:0]  DRAM_BA,    // Bank Address (nbanks = 4 -> 2bits)
    inout   wire  [31:0] DRAM_DQ     // Data Bus
);
    // Some useful shorthands
    logic [3:0] KEY_AH;
    logic Clk, Reset_AH;
    logic [17:0] SW_sync;
    assign Clk = CLOCK_50;

    synchronizer #(4)  key_synchronizer(.Clk(Clk), .in(~KEY), .out(KEY_AH));
    synchronizer #(1)  reset_synchronizer (.Clk(Clk), .in(~KEY[0]), .out(Reset_AH));
    synchronizer #(18) switch_synchronizer (.Clk(Clk), .in(SW), .out(SW_sync));

    // Signals for WM8731 driver
    logic DRIVER_INIT; // Raise when you want to start WM873 initialization
    logic AUD_INIT_FINISH; // Raised by WM873 when initialization is complete
    logic AUD_ADC_FULL; // raised when one full 32 bit sample has been read from mic
    logic AUD_DATA_OVER; // raised when data fed into LDATA, RDATA for the speaker
    logic [31:0] ADCDATA, DACDATA; // From MIC: 16-bit Left channel MSBs, 16-bit Right channel LSBs
    logic [7:0] VOLUME_OUT; // Headphone volume used by audio driver
    logic [31:0] INPUT_DATA, OUTPUT_DATA;


    // logic signed [15:0] LEFT_REC_DIV, RIGHT_REC_DIV, LEFT_IN_DIV, RIGHT_IN_DIV;
    // sample_divide #(16, 16) divide_left_rec (.A(REC_OUTPUT_DATA[31:16]), .B(16'd2), .C(LEFT_REC_DIV));
    // sample_divide #(16, 16) divide_right_rec (.A(REC_OUTPUT_DATA[15:0]), .B(16'd2), .C(RIGHT_REC_DIV));
    // sample_divide #(16, 16) divide_left (.A(INPUT_DATA[31:16]), .B(16'd2), .C(LEFT_IN_DIV));
    // sample_divide #(16, 16) divide_right (.A(INPUT_DATA[15:0]), .B(16'd2), .C(RIGHT_IN_DIV));
    // assign OUTPUT_DATA = DO_PLAYBACK ? {LEFT_REC_DIV + LEFT_IN_DIV , RIGHT_REC_DIV + RIGHT_IN_DIV} : INPUT_DATA;

    // Recording signals
    logic DO_PLAYBACK, DO_RECORD, DO_CLEAR;
    logic [24:0] REC_END_TIME, REC_TIME;
    logic [31:0] REC_OUTPUT_DATA;
    
    // SDRAM Controller signals
    logic [31:0] DATA_READ, DATA_WRITE;
    logic [24:0] DATA_ADDR;
    logic WRITE_ENABLE, RW_WRITE, RW_READ, RW_ACK, INIT_DONE;
    assign DRIVER_INIT = 1'b1;

    // Audio Driver
    audio_interface aud_driver(
        // Initialization signals
        .INIT(DRIVER_INIT),  // Raise to initialize WM8731
        .INIT_FINISH(AUD_INIT_FINISH), // Raised when initialization process is complete

        // Speaker output
        .LDATA(DACDATA[31:16]),  // Put bits in for the Left speaker and raise data_over
        .RDATA(DACDATA[15:0]),  // Put bits in for the Right speaker and raise data_over
        .data_over(AUD_DATA_OVER), // raised by driver when data fed into LDATA, RDATA for the speaker
        
        // Microphone input
        .ADCDATA(ADCDATA), // holds data from the mic when adc_over is high
        .adc_full(AUD_ADC_FULL), // Raised by driver when one full 32 bit sample has been read from mic
        
        // Dont need to use these directly
        .clk(Clk), // 50Mhz
        .Reset(Reset_AH),  // Raise to reset the WM8731
        .I2C_SDAT(I2C_SDAT), // I2C data wire
        .I2C_SCLK(I2C_SCLK), // I2C clock wire
        .AUD_MCLK(AUD_XCK), // Output clock divider 50Mhz/4 = 12.5Mhz
        .AUD_BCLK(AUD_BCLK), // Bit clock - from the board
        .AUD_ADCDAT(AUD_ADCDAT),  // Dont use (?)
        .AUD_DACDAT(AUD_DACDAT),  // Dont use (?)
        .AUD_DACLRCK(AUD_DACLRCK), // LR Clock for the speakers - from the board
        .AUD_ADCLRCK(AUD_ADCLRCK) // LR Clock for the mic - from the board
    );

    // ADC Module
    adc ADC(
        .AUD_ADC_FULL(AUD_ADC_FULL), 
        .AUD_INIT_FINISH(AUD_INIT_FINISH), 
        .ADCDATA(ADCDATA),
        .INPUT_DATA(INPUT_DATA)
    );

    logic [31:0] FILTER_OUTPUT;
    logic [4:0]  FILTER_BITMASK;
    logic [4:0] [7:0] FILTER_VALUES;
    filters filt(
        .Clk(Clk),
        .Reset(Reset_AH),
        .Sample_Clk(AUD_ADC_FULL),
        .RAW_AUD_IN(INPUT_DATA),
        .FILTER_BITMASK(FILTER_BITMASK),
        .FILTER_VALUES(FILTER_VALUES),
        .FILTERED_AUD_OUT(FILTER_OUTPUT)
    );


    // DAC Module
    assign OUTPUT_DATA = DO_PLAYBACK ? REC_OUTPUT_DATA : FILTER_OUTPUT;
    dac DAC(
        .AUD_DATA_OVER(AUD_DATA_OVER),
        .AUD_INIT_FINISH(AUD_INIT_FINISH),
        .DACDATA(DACDATA),
        .OUTPUT_DATA(OUTPUT_DATA), // put this back!!
        .VOLUME_OUT(VOLUME_OUT)
    );

    // SDRAM Controller
    sdram_control sdram_controller(
        .*, 
        .Reset(Reset_AH)
    );

    // Recording module (signals are at the top)
    recorder recorder_instance(
        .Clk(Clk),
        .Reset(Reset_AH),
        .SAMPLE_INPUT_CLK(AUD_ADC_FULL),
        .SAMPLE_OUTPUT_CLK(AUD_DATA_OVER),
        .INPUT_DATA(FILTER_OUTPUT),
        .DO_RECORD(DO_RECORD),
        .DO_PLAYBACK(DO_PLAYBACK),
        .DO_CLEAR(DO_CLEAR),
        .OUTPUT_DATA(REC_OUTPUT_DATA),
        .END_TIME(REC_END_TIME),
        .TIME(REC_TIME),
        .RW_ACK(RW_ACK),
        .INIT_DONE(INIT_DONE),
        .DATA_READ(DATA_READ),
        .DATA_ADDR(DATA_ADDR),
        .DATA_WRITE(DATA_WRITE),
        .RW_READ(RW_READ),
        .RW_WRITE(RW_WRITE)
    );

    // UI Controller
    ui_control control(
        .CLK(Clk),
        .RESET(Reset_AH),
        .SW(SW_sync),
        .KEY(KEY_AH),
        .LEDR(LEDR),
        .LEDG(LEDG),
        .VOLUME_OUT(VOLUME_OUT),
        .FILTER_BITMASK(FILTER_BITMASK),
        .FILTER_VALUES(FILTER_VALUES),
        .DO_RECORD(DO_RECORD),
        .DO_PLAYBACK(DO_PLAYBACK),
        .DO_CLEAR(DO_CLEAR),
        .REC_TIME(REC_TIME),
        .REC_END_TIME(REC_END_TIME)
    );

endmodule