module dac (
    input   logic               AUD_DATA_OVER,
    input   logic               AUD_INIT_FINISH,
    input   logic        [7:0]  VOLUME_OUT,
    input   logic        [31:0] OUTPUT_DATA,
    output  logic        [31:0] DACDATA
);
    // Max volume setting for the headphones [0, 80] is 80
    const logic signed [7:0] VOLUME_MAX = 8'd80;

    logic [15:0] SCALED_LEFT_BUFFER, SCALED_RIGHT_BUFFER;
    sample_scale #($bits(VOLUME_OUT), $bits(VOLUME_MAX), $bits(OUTPUT_DATA[31:16])) vol_scale_left(
        .ACTUAL(VOLUME_OUT),
        .TOTAL(VOLUME_MAX),
        .IN(OUTPUT_DATA[31:16]),
        .OUT(SCALED_LEFT_BUFFER)
    );
    sample_scale #($bits(VOLUME_OUT), $bits(VOLUME_MAX), $bits(OUTPUT_DATA[15:0])) vol_scale_right(
        .ACTUAL(VOLUME_OUT),
        .TOTAL(VOLUME_MAX),
        .IN(OUTPUT_DATA[15:0]),
        .OUT(SCALED_RIGHT_BUFFER)
    );

    // Triggered when AUD_DAC_OVER is raised
    always_ff @(posedge AUD_DATA_OVER) begin
        if (AUD_INIT_FINISH) begin
            // data is ready to be written
            if (AUD_DATA_OVER) begin
                if (VOLUME_OUT == 7'b0) begin 
                    DACDATA[31:0] <= 32'b0;
                end else begin
                    DACDATA[31:16] <= SCALED_LEFT_BUFFER;
                    DACDATA[15:0] <= SCALED_RIGHT_BUFFER;
                end
            end 
        end
    end
endmodule