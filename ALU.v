module ALU(A,B,Result,ALUControl,OverFlow,Carry,Zero,Negative);

    input  [31:0] A,B;
    input  [3:0]  ALUControl;
    output        Carry,OverFlow,Zero,Negative;
    output [31:0] Result;

    wire subtract = (ALUControl == 4'b0001) || (ALUControl == 4'b0101) || (ALUControl == 4'b0110);

    wire [32:0] addsub_result = subtract ? ({1'b0,A} + {1'b0,~B} + 33'b1)
                                          : ({1'b0,A} + {1'b0,B});

    wire        Cout = addsub_result[32];
    wire [31:0] Sum  = addsub_result[31:0];

    wire ovf = subtract ? ((A[31]^B[31]) & (Sum[31]^A[31]))
                         : ((~(A[31]^B[31])) & (Sum[31]^A[31]));

    wire lt_signed   = Sum[31] ^ ovf;
    wire lt_unsigned = ~Cout;

    // Arithmetic shift computed as its own signed sub-expression.
    // (If left inline inside the ternary below, Verilog's conditional-operator
    // context rules strip the sign extension because the other branches are
    // unsigned - the shift silently becomes logical instead of arithmetic.)
    wire [31:0] sra_result = $signed(A) >>> B[4:0];

    assign Result = (ALUControl == 4'b0000) ? Sum :
                    (ALUControl == 4'b0001) ? Sum :
                    (ALUControl == 4'b0010) ? (A & B) :
                    (ALUControl == 4'b0011) ? (A | B) :
                    (ALUControl == 4'b0100) ? (A ^ B) :
                    (ALUControl == 4'b0101) ? {31'b0, lt_signed} :
                    (ALUControl == 4'b0110) ? {31'b0, lt_unsigned} :
                    (ALUControl == 4'b0111) ? (A << B[4:0]) :
                    (ALUControl == 4'b1000) ? (A >> B[4:0]) :
                    (ALUControl == 4'b1001) ? sra_result :
                    32'h00000000;

    assign OverFlow = ovf  & (ALUControl == 4'b0000 || ALUControl == 4'b0001);
    assign Carry    = Cout & (ALUControl == 4'b0000 || ALUControl == 4'b0001);
    assign Zero     = (Result == 32'b0);
    assign Negative = Result[31];

endmodule