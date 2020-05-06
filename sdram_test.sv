module sdram_test (
    input    logic        Clk,
    input    logic        Reset,
    input    logic        RW_ACK,
    input    logic        INIT_DONE,
    input    logic [31:0] DATA_READ,
    output   logic [24:0] DATA_ADDR,  // 2 Bit Bank, 13 Bit Row, 10 Bit Col
    output   logic [31:0] DATA_WRITE, // Data to write
    output   logic        RW_READ,    // User wants to read
    output   logic        RW_WRITE,
    output   logic        PASS,
    output   logic        FAIL,
    output   logic        LEDR_0
);

    enum logic [3:0] { INIT_WAIT,
                       WRITE,
                       READ,
                       CHECK,
                       INCREMENT_ADDR,
                       DISPLAY_RESULT } state, next_state;

    logic [24:0] curr_addr;
    logic [31:0] actual, actual_next;
    logic failed, failed_next;
    logic done_init, done_init_next;

    assign LEDR_0 = done_init;

    initial begin
        done_init = 0;
        done_init_next = 0;
        failed = 0;
        failed_next = 0;
        actual = 32'b0;
        actual_next = 32'b0;
        state = INIT_WAIT;
        next_state = INIT_WAIT;
        curr_addr = 25'b0;
    end

    always_ff @(posedge Clk) begin
        if (Reset) state <= INIT_WAIT;
        else state <= next_state;

        if (state == INCREMENT_ADDR) curr_addr <= curr_addr + 25'd1;
        actual <= actual_next;
        failed <= failed_next;
        done_init <= done_init_next;
    end 

    always_comb begin
        actual_next = actual;
        next_state = state;
        failed_next = failed;
        done_init_next = done_init;
        
        FAIL = 0;
        PASS = 0;
        DATA_WRITE = 32'bZ;
        RW_WRITE = 0;
        RW_READ = 0;
        DATA_ADDR = 24'bZ;

        unique case (state)
            INIT_WAIT : begin
                if (INIT_DONE) begin
                    next_state = WRITE;
                    done_init_next = 1;
                end
            end
            WRITE : begin
                DATA_ADDR = curr_addr;
                DATA_WRITE = {6'b0, curr_addr};
                RW_WRITE = 1;
                if (RW_ACK) begin
                    next_state = READ;
                end
            end
            READ : begin
                DATA_ADDR = curr_addr;
                RW_READ = 1;
                actual_next = DATA_READ;
                if (RW_ACK) begin
                    next_state = CHECK;
                end
            end
            CHECK : begin
                if (actual[24:0] != curr_addr) begin
                    failed_next = 1;
                    next_state = DISPLAY_RESULT;
                end else begin
                    next_state = INCREMENT_ADDR;
                end
            end
            INCREMENT_ADDR: begin
                if (curr_addr != 25'hFFFFFFF) begin
                    next_state = WRITE;
                end else begin
                    next_state = DISPLAY_RESULT;
                end
            end
            DISPLAY_RESULT : begin
                if (failed) begin
                    FAIL = 1;
                end else begin
                    PASS = 1;
                end
            end
        endcase
    end
endmodule