module sdram_control (
    input   logic        Clk,
    input   logic        Reset,
    input   logic [24:0] DATA_ADDR,  // 2 Bit Bank, 13 Bit Row, 10 Bit Col
    input   logic [31:0] DATA_WRITE, // Data to write
    input   logic        RW_READ,    // User wants to read
    input   logic        RW_WRITE,   // User wants to write
    output  logic        RW_ACK,     // Send user ack after read/written
    output  logic        INIT_DONE,
    output  logic [31:0] DATA_READ,
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

    const enum logic {Programmed_Burst_Length = 1'b0, Single_Location_Access = 1'b1} write_burst_mode = Programmed_Burst_Length;
    const enum logic [1:0] {Standard_Operation = 2'd0, Reserved_1 = 2'd1, Reserved_2 = 2'd2, Reserved_3 = 2'd3} operating_mode = Standard_Operation;
    const enum logic [2:0] {Two_Cycles = 3'd2, Three_Cycles = 3'd3} cas_latency = Three_Cycles;
    const enum logic {Sequential = 1'b0, Interleaved = 1'b1} burst_type = Sequential;
    const enum logic [2:0] {Burst_One = 3'd0, Burst_Two = 3'd1, Burst_Four = 3'd2, Burst_Eight = 3'd3, Full_Page = 3'd7} burst_length = Burst_One;

    const logic [12:0] MODE_REGISTER = {3'b0, write_burst_mode, operating_mode, cas_latency, burst_type, burst_length};

    // Useful shorthands
    logic [1:0] DATA_ADDR_BA;
    logic [12:0] DATA_ADDR_ROW, DATA_ADDR_COL;
    assign DATA_ADDR_BA = DATA_ADDR[24:23];
    assign DATA_ADDR_ROW = DATA_ADDR[22:10];
    assign DATA_ADDR_COL = {3'd1, DATA_ADDR[9:0]};

    assign DRAM_DQ = (!DRAM_WE_N) ? DATA_WRITE : 32'hZZZZZZZZ;

    // PLL Module
    logic SDRAM_CONTROLLER_CLK;
    sdram_pll pll_clocks(
        .inclk0(Clk), 
        .c0(SDRAM_CONTROLLER_CLK),  // Clock to be used for the SDRAM Controller
        .c1(DRAM_CLK)               // -3ns skewed clock for SDRAM chip
    );


    logic T_count_start, T_count_done;
    countdown #(10000) T_counter(.Clk(Clk), .Start(T_count_start), .Done(T_count_done));

    logic trc_count_start, trc_count_done;
    countdown #(4) trc_counter(.Clk(Clk), .Start(trc_count_start), .Done(trc_count_done));

    logic trp_count_start, trp_count_done;
    countdown #(1) trp_counter(.Clk(Clk), .Start(trp_count_start), .Done(trp_count_done));
    
    logic trcd_count_start, trcd_count_done;
    countdown #(1) trcd_counter(.Clk(Clk), .Start(trcd_count_start), .Done(trcd_count_done));

    logic tac_count_start, tac_count_done;
    countdown #(1) tac_counter(.Clk(Clk), .Start(tac_count_start), .Done(tac_count_done));
    
    logic tmrd_count_start, tmrd_count_done;
    countdown #(2) tmrd_counter(.Clk(Clk), .Start(tmrd_count_start), .Done(tmrd_count_done));

    logic cas_count_start, cas_count_done;
    countdown #(3) cas_counter(.Clk(Clk), .Start(cas_count_start), .Done(cas_count_done));

    // 64000000 ns / 4096 cycles / 20 ns = 783 ~ 750 cycles
    logic refresh_interval_reset, refresh_interval_done;
    countdown #(750) refresh_interval_counter(.Clk(Clk), .Start(refresh_interval_reset), .Done(refresh_interval_done));

    // State Machine
    enum logic [4:0] { PRE_INIT,
                       INIT, 
                       PRECHARGE_INIT,
                       PRECHARGE_INIT_WAIT, 
                       REFRESH_INIT_1, 
                       REFRESH_INIT_1_WAIT,
                       REFRESH_INIT_2, 
                       REFRESH_INIT_2_WAIT,
                       LOAD_MODE_REG, 
                       LOAD_MODE_REG_WAIT,
                       INITIALIZED,
                       IDLE, 
                       REFRESH, 
                       REFRESH_WAIT,
                       PRECHARGE, 
                       PRECHARGE_WAIT,
                       ACTIVATE, 
                       ACTIVATE_WAIT,
                       READ, 
                       READ_WAIT,
                       WRITE } state, next_state;

    initial begin
        state = PRE_INIT;
        next_state = PRE_INIT;
    end

    always_ff @(posedge SDRAM_CONTROLLER_CLK) begin
        if (Reset) state <= PRE_INIT;
        else state <= next_state;
    end

    always_comb begin
        // Defaults
        next_state = state;
        INIT_DONE = 0;
        T_count_start = 0;
        trc_count_start = 0;
        trp_count_start = 0;
        trcd_count_start = 0;
        tac_count_start = 0;
        tmrd_count_start = 0;
        refresh_interval_reset = 0;
        cas_count_start = 0;

        DATA_READ = 32'hZZZZZZZZ;
        RW_ACK = 0;

        // SDRAM No-op
        DRAM_CS_N = 0;
        DRAM_RAS_N = 1;
        DRAM_CAS_N = 1;
        DRAM_WE_N = 1;
        DRAM_CKE = 1;
        DRAM_ADDR = 13'b0;
        DRAM_BA = 2'b0;
        DRAM_DQM = 4'b0;

        unique case (state)
            PRE_INIT : begin
                T_count_start = 1;
                refresh_interval_reset = 1;
                next_state = INIT;
            end
            INIT : begin
                if (T_count_done) begin
                    next_state = PRECHARGE_INIT;
                end
            end
            PRECHARGE_INIT : begin
                // Precharge all banks
                DRAM_CS_N = 0;
                DRAM_RAS_N = 0;
                DRAM_CAS_N = 1;
                DRAM_WE_N = 0;
                DRAM_ADDR[10] = 1; 
                // Wait for T_rp
                trp_count_start = 1;
                next_state = PRECHARGE_INIT_WAIT;
            end
            PRECHARGE_INIT_WAIT :  begin
                if (trp_count_done) begin
                    next_state = REFRESH_INIT_1;
                end
            end
            REFRESH_INIT_1 : begin
                DRAM_CS_N = 0;
                DRAM_RAS_N = 0;
                DRAM_CAS_N = 0;
                DRAM_WE_N = 1;
                // Wait for T_rc
                trc_count_start = 1;
                next_state = REFRESH_INIT_1_WAIT;
            end
            REFRESH_INIT_1_WAIT : begin                
                if (trc_count_done) begin
                    next_state = REFRESH_INIT_2;
                end
            end
            REFRESH_INIT_2 : begin
                DRAM_CS_N = 0;
                DRAM_RAS_N = 0;
                DRAM_CAS_N = 0;
                DRAM_WE_N = 1;
                // Wait for T_rc
                trc_count_start = 1;
                next_state = REFRESH_INIT_2_WAIT;
            end
            REFRESH_INIT_2_WAIT : begin                
                if (trc_count_done) begin
                    next_state = LOAD_MODE_REG;
                end
            end
            LOAD_MODE_REG : begin
                DRAM_CS_N = 0;
                DRAM_RAS_N = 0;
                DRAM_CAS_N = 0;
                DRAM_WE_N = 0;
                DRAM_BA = 0;
                DRAM_ADDR = MODE_REGISTER;
                // Wait for T_mrd
                tmrd_count_start = 1;
                next_state = LOAD_MODE_REG_WAIT;
            end
            LOAD_MODE_REG_WAIT : begin
                if (tmrd_count_done) begin
                    next_state = INITIALIZED;
                end
            end
            INITIALIZED : begin
                INIT_DONE = 1;
                next_state = IDLE;
            end
            IDLE : begin
                if (refresh_interval_done) begin
                    next_state = REFRESH;
                end else if(RW_READ ^ RW_WRITE) begin
                    next_state = ACTIVATE;
                end
            end
            REFRESH : begin
                DRAM_CS_N = 0;
                DRAM_RAS_N = 0;
                DRAM_CAS_N = 0;
                DRAM_WE_N = 1;
                // Wait for T_rc
                trc_count_start = 1;
                next_state = REFRESH_WAIT;
            end
            REFRESH_WAIT : begin
                refresh_interval_reset = 1;
                if (trc_count_done) begin
                    next_state = PRECHARGE;
                end   
            end
            PRECHARGE : begin
                // Precharge all banks
                DRAM_CS_N = 0;
                DRAM_RAS_N = 0;
                DRAM_CAS_N = 1;
                DRAM_WE_N = 0;
                DRAM_ADDR[10] = 1; 
                // Wait for T_rp
                trp_count_start = 1;
                next_state = PRECHARGE_WAIT;
            end
            PRECHARGE_WAIT : begin
                if (trp_count_done) begin
                    next_state = IDLE;
                end
            end
            ACTIVATE : begin
                DRAM_CS_N = 0;
                DRAM_RAS_N = 0;
                DRAM_CAS_N = 1;
                DRAM_WE_N = 1;
                DRAM_BA = DATA_ADDR_BA;
                DRAM_ADDR = DATA_ADDR_ROW;  
                // Wait for T_rcd
                trcd_count_start = 1;
                next_state = ACTIVATE_WAIT;
            end
            ACTIVATE_WAIT : begin
                if (trcd_count_done) begin
                    if (RW_READ) begin
                        next_state = READ;
                    end else if (RW_WRITE) begin
                        next_state = WRITE;
                    end else begin
                        next_state = IDLE;
                    end
                end
            end
            READ : begin
                DRAM_CS_N = 0;
                DRAM_RAS_N = 1;
                DRAM_CAS_N = 0;
                DRAM_WE_N = 1;
                DRAM_BA = DATA_ADDR_BA;
                DRAM_ADDR = DATA_ADDR_COL;
                // Wait for CAS Latency
                cas_count_start = 1;
                next_state = READ_WAIT;
            end
            READ_WAIT : begin
               if (cas_count_done) begin
                    RW_ACK = 1;
                    DATA_READ = DRAM_DQ;
                    next_state = PRECHARGE;
               end
            end
            WRITE : begin
                RW_ACK = 1;
                DRAM_CS_N = 0;
                DRAM_RAS_N = 1;
                DRAM_CAS_N = 0;
                DRAM_WE_N = 0;
                DRAM_BA = DATA_ADDR_BA;
                DRAM_ADDR = DATA_ADDR_COL;
                next_state = PRECHARGE;
            end
        endcase
    end

endmodule