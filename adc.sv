module adc(
    input   logic               AUD_ADC_FULL, 
    input   logic               AUD_INIT_FINISH, 
    input   logic        [31:0] ADCDATA,
    output  logic        [31:0] INPUT_DATA
);
    logic [31:0] INPUT_DATA_NEXT;
    assign INPUT_DATA_NEXT = INPUT_DATA;
    
    // Triggered when AUD_ADC_FULL is raised
    always_ff @(posedge AUD_ADC_FULL) begin
        if (AUD_INIT_FINISH) begin
            // data is ready to be read
            if (AUD_ADC_FULL) begin
                INPUT_DATA <= ADCDATA;
            end else begin
                INPUT_DATA <= INPUT_DATA_NEXT;
            end
        end
    end
endmodule