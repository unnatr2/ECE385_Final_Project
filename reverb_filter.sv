module reverb_filter(
    input  logic               CLK,
    input  logic        [7:0]  DECAY,
    input  logic signed [15:0] SAMPLE_IN,
    output logic signed [15:0] SAMPLE_OUT
);

    logic signed [31:0] MIX_SCRATCHPAD;
    logic signed [31:0] SAMPLE_IN_SEXT;
    const logic signed [31:0] NUM = 32'd5000;
    const logic signed [31:0] DEN = 32'd5001;

    initial begin
        MIX_SCRATCHPAD = 32'b0;
    end

    assign SAMPLE_IN_SEXT = { {16{SAMPLE_IN[15]}} , SAMPLE_IN };
    
    always_ff @(posedge CLK) begin
        MIX_SCRATCHPAD <= ((((MIX_SCRATCHPAD + SAMPLE_IN_SEXT) / 2) * NUM) / DEN);
    end

    assign SAMPLE_OUT = MIX_SCRATCHPAD[15:0];

    // const int history_interval_base = 1; // 2 -> every 4 samples, 3 -> every 8 samples, ...
    // const int buffer_len = 1024 * 22;    // Half a second of samples at 44.1kHz

    // logic signed [buffer_len - 1:0] [15:0] DECAY_BUFFER;
    // logic [history_interval_base-1:0] sample_intervalometer;

    // always_ff @(posedge CLK) begin
    //     // Increment intervalometer
    //     sample_intervalometer <= sample_intervalometer + 1;
    //     // Only record new sample on interval
    //     if (sample_intervalometer == 0) begin
    //         // Shift buffer and append new sample
    //         DECAY_BUFFER <= { DECAY_BUFFER[buffer_len - 2: 0] , SAMPLE_IN };
    //     end

    // end

    // // always_comb begin
    // //     for (int i = 0; i < 256; i++) begin
    // //         if (i < DECAY) begin
    // //             SAMPLE_OUT += DECAY_BUFFER[i] / (2 * (i + 1));
    // //         end
    // //     end
    // // end

    // assign SAMPLE_OUT = (DECAY_BUFFER[0]/8) + (DECAY_BUFFER[1]/16) + (DECAY_BUFFER[2]/32) + (DECAY_BUFFER[3]/64) + (DECAY_BUFFER[4]/128);

endmodule