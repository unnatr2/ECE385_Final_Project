module ui_control (
    input   logic        CLK,
    input   logic        RESET, // Active High
    input   logic [17:0] SW,
    input   logic [3:0]  KEY,
    input   logic [24:0] REC_END_TIME,
    input   logic [24:0] REC_TIME,
    output  logic [17:0] LEDR,
    output  logic [8:0]  LEDG,
    output  logic [7:0]  VOLUME_OUT,
    output  logic        DO_RECORD,
    output  logic        DO_PLAYBACK,
    output  logic        DO_CLEAR,
    output  logic [4:0]  FILTER_BITMASK,
    output  logic [4:0] [7:0]  FILTER_VALUES
);
    const logic [7:0] INITIAL_VOL = 40;
    logic [7:0] current_vol, next_vol;
    logic mute, mute_next;
    assign VOLUME_OUT = mute ? 8'b0 : current_vol;

    // Filter settings and latches
    logic [4:0] FILTER_BITMASK_NEXT;
    logic [4:0] [7:0] FILTER_VALUES_NEXT;

    const int MODE_VOL = (18'b1 << 0);
    const int MODE_LPF = (18'b1 << 1);
    const int MODE_HPF = (18'b1 << 2);
    const int MODE_REVERB = (18'b1 << 3);
    const int MODE_INVERSION = (18'b1 << 4);
    const int MODE_PITCH = (18'b1 << 5);
    const int MODE_REC = (18'b1 << 17);

    // Range progress from 0 to 7 (for LEDGs) as a ratio of playback time vs end time.
    logic [31:0] PLAYBACK_PROGRESS;
    logic [31:0] TEMP_REC_TIME, TEMP_REC_END_TIME;
    assign TEMP_REC_TIME = {7'b0, REC_TIME};
    assign TEMP_REC_END_TIME = {7'b0, REC_END_TIME};
    assign PLAYBACK_PROGRESS = (TEMP_REC_TIME * 32'd9) / TEMP_REC_END_TIME;

    // Calculate a 2Hz clock as a clock divider of base clock
    logic [25:0] two_hz_ctr;
    logic two_hz_pulse;
    assign two_hz_pulse = two_hz_ctr[25];
    always_ff @(posedge CLK) begin
        two_hz_ctr <= two_hz_ctr + 1;
    end

    // Handle push-button presses
    logic [3:0] key_curr, key_prev;
    always_ff @(posedge CLK) begin
        key_prev <= key_curr;
        key_curr <= KEY;
        if (RESET) begin
            key_curr <= 3'b0;
            key_prev <= 3'b0;
        end 
        
    end

    initial begin
        current_vol = INITIAL_VOL;
        mute = 0;
        two_hz_ctr = 25'b0;
        FILTER_BITMASK = 5'b0;
        FILTER_VALUES[0] = 8'hFF;
        FILTER_VALUES[1] = 8'h00;
        FILTER_VALUES[2] = 8'h00;
        FILTER_VALUES[3] = 8'd128;
        FILTER_VALUES[4] = 8'd128;
    end

    always_ff @(posedge CLK) begin
        if (RESET) begin
            current_vol <= INITIAL_VOL;
            mute <= 0;
            FILTER_BITMASK <= 5'b0;
            FILTER_VALUES[0] = 8'hFF;
            FILTER_VALUES[1] = 8'h00;
            FILTER_VALUES[2] = 8'h00;
            FILTER_VALUES[3] = 8'd128;
            FILTER_VALUES[4] = 8'd128;
        end else begin
            current_vol <= next_vol; 
            mute <= mute_next;
            FILTER_BITMASK <= FILTER_BITMASK_NEXT;
            for (int i = 0; i < 5; i++) begin
                FILTER_VALUES[i] <= FILTER_VALUES_NEXT[i];
            end
        end
    end
    
    always_comb begin
        // Default assignments
        next_vol = current_vol;
        mute_next = mute;
        LEDR = SW;
        LEDG = 0;
        DO_RECORD = 0;
        DO_PLAYBACK = 0;
        DO_CLEAR = 0;
        FILTER_BITMASK_NEXT = FILTER_BITMASK;
        for (int i = 0; i < 5; i++) begin
            FILTER_VALUES_NEXT[i] = FILTER_VALUES[i];
        end

        case (SW)
            MODE_VOL: begin
                // Is a button pressed?
                if (key_curr[3] == 1'b1 && key_prev[3] == 1'b0) begin
                    next_vol = (current_vol < 8'd2) ? 8'b0: current_vol - 8'd2;
                end
                if (key_curr[2] == 1'b1 && key_prev[2] == 1'b0) begin
                    next_vol = (current_vol <= 8'd78) ? current_vol + 8'd2 : 8'd80;
                end
                if (key_curr[1] == 1'b1 && key_prev[1] == 1'b0) begin
                    mute_next = ~mute;
                end
                // Reflect the current volume on the green leds
                if (current_vol == 8'd0)       LEDG[7:0] = 8'b00000000;
                else if (current_vol <= 8'd10) LEDG[7:0] = 8'b10000000;
                else if (current_vol <= 8'd20) LEDG[7:0] = 8'b11000000;
                else if (current_vol <= 8'd30) LEDG[7:0] = 8'b11100000;
                else if (current_vol <= 8'd40) LEDG[7:0] = 8'b11110000;
                else if (current_vol <= 8'd50) LEDG[7:0] = 8'b11111000;
                else if (current_vol <= 8'd60) LEDG[7:0] = 8'b11111100;
                else if (current_vol <= 8'd70) LEDG[7:0] = 8'b11111110;
                else                           LEDG[7:0] = 8'b11111111;
                
                // Mute feedback
                if (mute) LEDG[7:0] = 8'b00000000;
                LEDG[8] = ~mute;
            end
            MODE_REC : begin
               if (KEY[3]) begin
                   DO_RECORD = 1;
                   if (two_hz_pulse) begin
                        LEDG[7:0] = 8'hFF;
                   end
               end else if (KEY[2]) begin
                   DO_PLAYBACK = 1;
                   case (PLAYBACK_PROGRESS[3:0])
                        4'd0 :   LEDG[7:0] = 8'b00000000;
                        4'd1 :   LEDG[7:0] = 8'b10000000;
                        4'd2 :   LEDG[7:0] = 8'b11000000;
                        4'd3 :   LEDG[7:0] = 8'b11100000;
                        4'd4 :   LEDG[7:0] = 8'b11110000;
                        4'd5 :   LEDG[7:0] = 8'b11111000;
                        4'd6 :   LEDG[7:0] = 8'b11111100;
                        4'd7 :   LEDG[7:0] = 8'b11111110;
                        4'd8 :   LEDG[7:0] = 8'b11111111;
                        4'd9 :   LEDG[7:0] = 8'b11111111;
                   endcase
               end 
               if (KEY[1]) begin
                   DO_CLEAR = 1;
               end
               LEDG[8] = KEY[3] | KEY[2];
            end
            MODE_LPF : begin
                if (key_curr[1] == 1'b1 && key_prev[1] == 1'b0) begin
                    FILTER_BITMASK_NEXT[0] = ~FILTER_BITMASK[0];
                end
                if (key_curr[3] == 1'b1 && key_prev[3] == 1'b0) begin
                    FILTER_VALUES_NEXT[0] = (FILTER_VALUES[0] < 8'd8) ? 8'b0: FILTER_VALUES[0] - 8'd8;
                end
                if (key_curr[2] == 1'b1 && key_prev[2] == 1'b0) begin
                    FILTER_VALUES_NEXT[0] = (FILTER_VALUES[0] <= 8'd247) ? FILTER_VALUES[0] + 8'd8 : 8'd255;
                end
                if (FILTER_VALUES[0] == 8'd0)        LEDG[7:0] = 8'b00000000;
                else if (FILTER_VALUES[0] <= 8'd32)  LEDG[7:0] = 8'b10000000;
                else if (FILTER_VALUES[0] <= 8'd64)  LEDG[7:0] = 8'b11000000;
                else if (FILTER_VALUES[0] <= 8'd96)  LEDG[7:0] = 8'b11100000;
                else if (FILTER_VALUES[0] <= 8'd128) LEDG[7:0] = 8'b11110000;
                else if (FILTER_VALUES[0] <= 8'd160) LEDG[7:0] = 8'b11111000;
                else if (FILTER_VALUES[0] <= 8'd192) LEDG[7:0] = 8'b11111100;
                else if (FILTER_VALUES[0] <= 8'd224) LEDG[7:0] = 8'b11111110;
                else                                 LEDG[7:0] = 8'b11111111;
                LEDG[8] = FILTER_BITMASK[0];
            end
            MODE_HPF : begin
                if (key_curr[1] == 1'b1 && key_prev[1] == 1'b0) begin
                    FILTER_BITMASK_NEXT[1] = ~FILTER_BITMASK[1];
                end
                if (key_curr[3] == 1'b1 && key_prev[3] == 1'b0) begin
                    FILTER_VALUES_NEXT[1] = (FILTER_VALUES[1] < 8'd8) ? 8'b0: FILTER_VALUES[1] - 8'd8;
                end
                if (key_curr[2] == 1'b1 && key_prev[2] == 1'b0) begin
                    FILTER_VALUES_NEXT[1] = (FILTER_VALUES[1] <= 8'd247) ? FILTER_VALUES[1] + 8'd8 : 8'd255;
                end
                if (FILTER_VALUES[1] == 8'd0)        LEDG[7:0] = 8'b00000000;
                else if (FILTER_VALUES[1] <= 8'd32)  LEDG[7:0] = 8'b10000000;
                else if (FILTER_VALUES[1] <= 8'd64)  LEDG[7:0] = 8'b11000000;
                else if (FILTER_VALUES[1] <= 8'd96)  LEDG[7:0] = 8'b11100000;
                else if (FILTER_VALUES[1] <= 8'd128) LEDG[7:0] = 8'b11110000;
                else if (FILTER_VALUES[1] <= 8'd160) LEDG[7:0] = 8'b11111000;
                else if (FILTER_VALUES[1] <= 8'd192) LEDG[7:0] = 8'b11111100;
                else if (FILTER_VALUES[1] <= 8'd224) LEDG[7:0] = 8'b11111110;
                else                                 LEDG[7:0] = 8'b11111111;
                LEDG[8] = FILTER_BITMASK[1];
            end
            MODE_REVERB : begin
                if (key_curr[1] == 1'b1 && key_prev[1] == 1'b0) begin
                    FILTER_BITMASK_NEXT[2] = ~FILTER_BITMASK[2];
                end
                if (key_curr[3] == 1'b1 && key_prev[3] == 1'b0) begin
                    FILTER_VALUES_NEXT[2] = (FILTER_VALUES[2] < 8'd8) ? 8'b0: FILTER_VALUES[2] - 8'd8;
                end
                if (key_curr[2] == 1'b1 && key_prev[2] == 1'b0) begin
                    FILTER_VALUES_NEXT[2] = (FILTER_VALUES[2] <= 8'd247) ? FILTER_VALUES[2] + 8'd8 : 8'd255;
                end
                if (FILTER_VALUES[2] == 8'd0)        LEDG[7:0] = 8'b00000000;
                else if (FILTER_VALUES[2] <= 8'd32)  LEDG[7:0] = 8'b10000000;
                else if (FILTER_VALUES[2] <= 8'd64)  LEDG[7:0] = 8'b11000000;
                else if (FILTER_VALUES[2] <= 8'd96)  LEDG[7:0] = 8'b11100000;
                else if (FILTER_VALUES[2] <= 8'd128) LEDG[7:0] = 8'b11110000;
                else if (FILTER_VALUES[2] <= 8'd160) LEDG[7:0] = 8'b11111000;
                else if (FILTER_VALUES[2] <= 8'd192) LEDG[7:0] = 8'b11111100;
                else if (FILTER_VALUES[2] <= 8'd224) LEDG[7:0] = 8'b11111110;
                else                                 LEDG[7:0] = 8'b11111111;
                LEDG[8] = FILTER_BITMASK[2];
            end
            MODE_INVERSION : begin
                if (key_curr[1] == 1'b1 && key_prev[1] == 1'b0) begin
                    FILTER_BITMASK_NEXT[3] = ~FILTER_BITMASK[3];
                end
                if (key_curr[3] == 1'b1 && key_prev[3] == 1'b0) begin
                    FILTER_VALUES_NEXT[3] = (FILTER_VALUES[3] < 8'd8) ? 8'b0: FILTER_VALUES[3] - 8'd8;
                end
                if (key_curr[2] == 1'b1 && key_prev[2] == 1'b0) begin
                    FILTER_VALUES_NEXT[3] = (FILTER_VALUES[3] <= 8'd247) ? FILTER_VALUES[3] + 8'd8 : 8'd255;
                end
                if (FILTER_VALUES[3] == 8'd0)        LEDG[7:0] = 8'b00000000;
                else if (FILTER_VALUES[3] <= 8'd32)  LEDG[7:0] = 8'b10000000;
                else if (FILTER_VALUES[3] <= 8'd64)  LEDG[7:0] = 8'b11000000;
                else if (FILTER_VALUES[3] <= 8'd96)  LEDG[7:0] = 8'b11100000;
                else if (FILTER_VALUES[3] <= 8'd128) LEDG[7:0] = 8'b11110000;
                else if (FILTER_VALUES[3] <= 8'd160) LEDG[7:0] = 8'b11111000;
                else if (FILTER_VALUES[3] <= 8'd192) LEDG[7:0] = 8'b11111100;
                else if (FILTER_VALUES[3] <= 8'd224) LEDG[7:0] = 8'b11111110;
                else                                 LEDG[7:0] = 8'b11111111;
                LEDG[8] = FILTER_BITMASK[3];
            end
            MODE_PITCH : begin
                if (key_curr[1] == 1'b1 && key_prev[1] == 1'b0) begin
                    FILTER_BITMASK_NEXT[4] = ~FILTER_BITMASK[4];
                end
                if (key_curr[3] == 1'b1 && key_prev[3] == 1'b0) begin
                    FILTER_VALUES_NEXT[4] = (FILTER_VALUES[4] < 8'd1) ? 8'b0: FILTER_VALUES[4] - 8'd1;
                end
                if (key_curr[2] == 1'b1 && key_prev[2] == 1'b0) begin
                    FILTER_VALUES_NEXT[4] = (FILTER_VALUES[4] <= 8'd254) ? FILTER_VALUES[4] + 8'd1 : 8'd255;
                end
                if (FILTER_VALUES[4] == 8'd0)        LEDG[7:0] = 8'b00000000;
                else if (FILTER_VALUES[4] <= 8'd32)  LEDG[7:0] = 8'b10000000;
                else if (FILTER_VALUES[4] <= 8'd64)  LEDG[7:0] = 8'b11000000;
                else if (FILTER_VALUES[4] <= 8'd96)  LEDG[7:0] = 8'b11100000;
                else if (FILTER_VALUES[4] <= 8'd128) LEDG[7:0] = 8'b11110000;
                else if (FILTER_VALUES[4] <= 8'd160) LEDG[7:0] = 8'b11111000;
                else if (FILTER_VALUES[4] <= 8'd192) LEDG[7:0] = 8'b11111100;
                else if (FILTER_VALUES[4] <= 8'd224) LEDG[7:0] = 8'b11111110;
                else                                 LEDG[7:0] = 8'b11111111;
                LEDG[8] = FILTER_BITMASK[4];
            end
            default : begin
                // This isnt a valid setting mode, do nothing
                LEDR = {12'b0, FILTER_BITMASK, 1'b0};
                LEDG = 0;
            end
        endcase
    end 

endmodule