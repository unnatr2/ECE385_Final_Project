module countdown #(COUNT_CYCLES=0) (
    input  logic Clk,
    input  logic Start,
    output logic Done
);
    // Clounter needs enough bits to hold COUNT_CYCLES
    logic [$clog2(COUNT_CYCLES + 1) - 1:0] count, count_next;

    always_ff @(posedge Clk) begin
        if (Start) count <= COUNT_CYCLES;
        else if (count != 0) count <= count - 1;
    end

    assign Done = (count == 0);
    
endmodule