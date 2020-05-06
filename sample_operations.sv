module sample_operations #(BITSA = 0, BITSB = 0) (
    input  logic signed [BITSA - 1 : 0]         A,
    input  logic signed [BITSB - 1 : 0]         B,
    input  logic        [3 : 0]                 OPERATION,
    output logic signed [BITSA + BITSB - 1 : 0] C
);
    logic signed [BITSA - 1 : 0] add_a, subtract_a, multiply_a, divide_a;
    logic signed [BITSB - 1 : 0] add_b, subtract_b, multiply_b, divide_b;
    logic signed [BITSA + BITSB - 1 : 0] add_c, subtract_c, multiply_c, divide_c;
    sample_add      #($bits(A), $bits(B)) addition       (.A(add_a),      .B(add_b),      .C(add_c));
    sample_subtract #($bits(A), $bits(B)) subtraction    (.A(subtract_a), .B(subtract_b), .C(subtract_c));
    sample_multiply #($bits(A), $bits(B)) multiplication (.A(multiply_a), .B(multiply_b), .C(multiply_c));
    sample_divide   #($bits(A), $bits(B)) division       (.A(divide_a),   .B(divide_b),   .C(divide_c));

    always_comb begin
        case (OPERATION)
            4'b00001 : begin
                // ADD
                add_a = A;
                add_b = B;
                C = add_c;
            end
            4'b00010 : begin
                // SUBTRACT
                subtract_a = A;
                subtract_b = B;
                C = subtract_c;
            end
            4'b00100 : begin
                // MULTIPLY
                multiply_a = A;
                multiply_b = B;
                C = multiply_c;
            end
            4'b01000 : begin
                // DIVIDE
                divide_a = A;
                divide_b = B;
                C = divide_c;
            end
        endcase
    end
endmodule

// A + B = C
module sample_add #(BITSA = 0, BITSB = 0) (
    input  logic signed [BITSA - 1 : 0] A,
    input  logic signed [BITSB - 1 : 0] B,
    output logic signed [BITSA + BITSB - 1 : 0] C
);
    logic signed [BITSA + BITSA - 1 : 0] EXT_A, EXT_B;
    assign EXT_A = { {BITSB{A[BITSA - 1]}} , A };
    assign EXT_B = { {BITSA{B[BITSB - 1]}} , B };
    assign C = EXT_A + EXT_B;
endmodule

// A - B = C
module sample_subtract #(BITSA = 0, BITSB = 0) (
    input  logic signed [BITSA - 1 : 0] A,
    input  logic signed [BITSB - 1 : 0] B,
    output logic signed [BITSA + BITSB - 1 : 0] C
);
    logic signed [BITSA + BITSA - 1 : 0] EXT_A, EXT_B;
    assign EXT_A = { {BITSB{A[BITSA - 1]}} , A };
    assign EXT_B = { {BITSA{B[BITSB - 1]}} , B };
    assign C = EXT_A - EXT_B;
endmodule

// A * B = C
module sample_multiply #(BITSA = 0, BITSB = 0) (
    input  logic signed [BITSA - 1 : 0] A,
    input  logic signed [BITSB - 1 : 0] B,
    output logic signed [BITSA + BITSB - 1 : 0] C
);
    logic signed [BITSA + BITSA - 1 : 0] EXT_A, EXT_B;
    assign EXT_A = { {BITSB{A[BITSA - 1]}} , A };
    assign EXT_B = { {BITSA{B[BITSB - 1]}} , B };
    assign C = EXT_A * EXT_B;
endmodule

// A / B = C
module sample_divide #(BITSA = 0, BITSB = 0) (
    input  logic signed [BITSA - 1 : 0] A,
    input  logic signed [BITSB - 1 : 0] B,
    output logic signed [BITSA + BITSB - 1 : 0] C
);
    logic signed [BITSA + BITSA - 1 : 0] EXT_A, EXT_B;
    assign EXT_A = { {BITSB{A[BITSA - 1]}} , A };
    assign EXT_B = { {BITSA{B[BITSB - 1]}} , B };
    assign C = EXT_A / EXT_B;
endmodule

// (IN * ACTUAL) / TOTAL = OUT
module sample_scale #(BITSACTUAL = 0, BITSTOTAL = 0, BITSIN = 0) (
    input  logic signed [BITSACTUAL - 1 : 0] ACTUAL,
    input  logic signed [BITSTOTAL - 1 : 0] TOTAL,
    input  logic signed [BITSIN - 1 : 0] IN,
    output logic signed [BITSIN - 1 : 0] OUT
);
    logic signed [(BITSACTUAL + BITSIN) - 1 : 0] EXT_ACTUAL, EXT_TOTAL, EXT_IN, EXT_OUT;
    assign EXT_ACTUAL = { {(BITSACTUAL + BITSIN) - BITSACTUAL{ACTUAL[BITSACTUAL - 1]}} , ACTUAL };
    assign EXT_TOTAL = { {(BITSACTUAL + BITSIN) - BITSTOTAL{TOTAL[BITSTOTAL - 1]}} , TOTAL };
    assign EXT_IN = { {(BITSACTUAL + BITSIN) - BITSIN{IN[BITSIN - 1]}} , IN };
    assign EXT_OUT = (EXT_IN * EXT_ACTUAL) / EXT_TOTAL;
    assign OUT = EXT_OUT[BITSIN - 1 : 0];
endmodule