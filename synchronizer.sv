module synchronizer #(N=16) (
    input   logic         Clk,
    input   logic [N-1:0] in,
    output  logic [N-1:0] out
);
    always_ff @(posedge Clk) begin
        out <= in;
    end
endmodule