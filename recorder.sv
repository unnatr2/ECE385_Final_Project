module recorder(
    input    logic        Clk,
    input    logic        Reset,
    input    logic        SAMPLE_INPUT_CLK,
    input    logic        SAMPLE_OUTPUT_CLK,
    input    logic [31:0] INPUT_DATA,
    input    logic        DO_RECORD,
    input    logic        DO_PLAYBACK,
    input    logic        DO_CLEAR,
    output   logic [31:0] OUTPUT_DATA,
    output   logic [24:0] END_TIME,
    output   logic [24:0] TIME,

    // SDRAM Controls
    input    logic        RW_ACK,
    input    logic        INIT_DONE,
    input    logic [31:0] DATA_READ,
    output   logic [24:0] DATA_ADDR,
    output   logic [31:0] DATA_WRITE,
    output   logic        RW_READ,
    output   logic        RW_WRITE
);
    // Internal register to hold on to the last sample
    logic [31:0] OUTPUT_DATA_BUFFER, NEXT_OUTPUT_DATA_BUFFER;
    logic [31:0] RECORD_BUFFER, NEXT_RECORD_BUFFER;
    logic signed [15:0] LEFT_RECORD_BUFFER, RIGHT_RECORD_BUFFER, LEFT_INPUT_BUFFER, RIGHT_INPUT_BUFFER;

    assign LEFT_INPUT_BUFFER = INPUT_DATA[31:16];
    assign RIGHT_INPUT_BUFFER = INPUT_DATA[15:0];
    assign LEFT_RECORD_BUFFER = RECORD_BUFFER[31:16];
    assign RIGHT_RECORD_BUFFER = RECORD_BUFFER[15:0];

    assign OUTPUT_DATA = (DO_PLAYBACK) ? OUTPUT_DATA_BUFFER : 32'b0;
    
    enum logic [3:0] { INIT_WAIT,
                       IDLE,
                       PRE,
                       PRE_RECORD,
                       RECORD,
                       CLEAR,
                       CLEAR_INC,
                       PLAYBACK,
                       INCREMENT,
                       WAIT_FOR_SAMPLE } state, next_state; 
                       
    logic [24:0] NEXT_TIME;
    logic [24:0] NEXT_END_TIME; // END_TIME is passed in as ouput

    // Edge detectors for the in/out sample clocks
    logic INPUT_SAMPLE_PREV, INPUT_SAMPLE_CURR;
    logic OUTPUT_SAMPLE_PREV, OUTPUT_SAMPLE_CURR;
    always_ff @(posedge Clk) begin
        INPUT_SAMPLE_PREV <= INPUT_SAMPLE_CURR;
        INPUT_SAMPLE_CURR <= SAMPLE_INPUT_CLK;
        OUTPUT_SAMPLE_PREV <= OUTPUT_SAMPLE_CURR;
        OUTPUT_SAMPLE_CURR <= SAMPLE_OUTPUT_CLK;
        if (Reset) begin
            INPUT_SAMPLE_CURR <= 0;
            INPUT_SAMPLE_PREV <= 0;
            OUTPUT_SAMPLE_CURR <= 0;
            OUTPUT_SAMPLE_PREV <= 0;
        end 
    end

    logic INPUT_SAMPLE_POS_EDGE, OUTPUT_SAMPLE_POS_EDGE;
    assign INPUT_SAMPLE_POS_EDGE = (INPUT_SAMPLE_CURR == 1 && INPUT_SAMPLE_PREV == 0) ? 1 : 0;
    assign OUTPUT_SAMPLE_POS_EDGE = (OUTPUT_SAMPLE_CURR == 1 && OUTPUT_SAMPLE_PREV == 0) ? 1 : 0;

    initial begin
        state = IDLE;
        next_state = IDLE;
        TIME = 0;
        NEXT_TIME = 0;
        END_TIME = 0;
        NEXT_END_TIME = 0;
        RECORD_BUFFER = 0;
        NEXT_RECORD_BUFFER = 0;
        OUTPUT_DATA_BUFFER = 0;
        NEXT_OUTPUT_DATA_BUFFER = 0;
        INPUT_SAMPLE_CURR = 0;
        INPUT_SAMPLE_PREV = 0;
        OUTPUT_SAMPLE_CURR = 0;
        OUTPUT_SAMPLE_PREV = 0;
    end
    
    always_ff @(posedge Clk) begin
        if (Reset) begin
            state <= IDLE;
            TIME <= 0;
            END_TIME <= 0;
            OUTPUT_DATA_BUFFER <= 0;
            RECORD_BUFFER <= 0;
        end else begin
            state <= next_state;
            TIME <= NEXT_TIME;
            END_TIME <= NEXT_END_TIME;
            OUTPUT_DATA_BUFFER <= NEXT_OUTPUT_DATA_BUFFER;
            RECORD_BUFFER <= NEXT_RECORD_BUFFER;
        end
    end

    always_comb begin
        // Latches
        next_state = state;
        NEXT_TIME = TIME;
        NEXT_END_TIME = END_TIME;
        NEXT_OUTPUT_DATA_BUFFER = OUTPUT_DATA_BUFFER;
        NEXT_RECORD_BUFFER = RECORD_BUFFER;

        // Defaults
        DATA_ADDR = 25'bZ;
        DATA_WRITE = 32'bZ;
        RW_READ = 1'b0;
        RW_WRITE = 1'b0;

        unique case (state)
            INIT_WAIT : begin
                if (INIT_DONE) begin
                    next_state = IDLE;
                end
            end
            IDLE : begin
                if (DO_RECORD ^ DO_PLAYBACK ^ DO_CLEAR) begin
                    next_state = PRE;
                end
            end
            PRE : begin
                NEXT_TIME = 25'b0;
                if (DO_RECORD && INPUT_SAMPLE_POS_EDGE) begin
                    next_state = PRE_RECORD;
                end else if (DO_PLAYBACK && OUTPUT_SAMPLE_POS_EDGE) begin
                    next_state = PLAYBACK;
                end else if (DO_CLEAR) begin
                    next_state = CLEAR;
                end
            end
            CLEAR : begin
                DATA_ADDR = TIME;
                DATA_WRITE = 32'b0;
                RW_WRITE = 1;
                if (RW_ACK) begin
                    next_state = CLEAR_INC;
                end
            end
            CLEAR_INC : begin
                NEXT_TIME = TIME + 25'd1;
                if (TIME >= 25'h142FF8) begin
                    next_state = IDLE;
                end else begin
                    next_state = CLEAR;
                end
            end
            PRE_RECORD : begin
                DATA_ADDR = TIME;
                RW_READ = 1;
                NEXT_RECORD_BUFFER = DATA_READ;
                if (RW_ACK) begin
                    next_state = RECORD;
                end 
            end
            RECORD : begin
                // Track the end of recording
                NEXT_END_TIME = TIME;
                // Write the sample to SDRAM
                DATA_ADDR = TIME;
                DATA_WRITE = {LEFT_INPUT_BUFFER + LEFT_RECORD_BUFFER, RIGHT_INPUT_BUFFER + RIGHT_RECORD_BUFFER};
                RW_WRITE = 1;
                if (RW_ACK) begin
                    next_state = INCREMENT;
                end
            end
            PLAYBACK : begin
                DATA_ADDR = TIME;
                RW_READ = 1;
                NEXT_OUTPUT_DATA_BUFFER = DATA_READ;
                if (RW_ACK) begin
                    next_state = INCREMENT;
                end
            end
            INCREMENT : begin
                NEXT_TIME = TIME + 25'd1;
                if (DO_PLAYBACK && END_TIME <= TIME) begin
                    // Done playing back the recording
                    next_state = IDLE;
                end else begin
                    // Continue to next sample
                    next_state = WAIT_FOR_SAMPLE;
                end
            end
            WAIT_FOR_SAMPLE : begin 
                if (DO_RECORD) begin
                    if (INPUT_SAMPLE_POS_EDGE) begin
                        next_state = PRE_RECORD;
                    end
                end else if (DO_PLAYBACK) begin
                    if (OUTPUT_SAMPLE_POS_EDGE) begin
                        next_state = PLAYBACK;
                    end
                end
                if (TIME == 25'hFFFFFFF || (!DO_RECORD && !DO_PLAYBACK)) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

endmodule