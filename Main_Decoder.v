module Main_Decoder(
    Op,
    RegWrite,
    ImmSrc,
    ALUSrc,
    MemWrite,
    ResultSrc,
    Branch,
    Jump,
    JumpJalr,
    ALUSrcA,
    ALUOp
);

    input  [6:0] Op;

    output       RegWrite, MemWrite, Branch, Jump, JumpJalr, ALUSrc;
    output [2:0] ImmSrc;
    output [1:0] ResultSrc, ALUSrcA, ALUOp;

    localparam OP_RTYPE  = 7'b0110011;
    localparam OP_ITYPE  = 7'b0010011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;

    assign RegWrite = (Op==OP_LOAD)||(Op==OP_RTYPE)||(Op==OP_ITYPE)||
                       (Op==OP_JAL)||(Op==OP_JALR)||(Op==OP_LUI)||(Op==OP_AUIPC);

    assign ImmSrc = (Op==OP_STORE)  ? 3'b001 :
                    (Op==OP_BRANCH) ? 3'b010 :
                    (Op==OP_LUI || Op==OP_AUIPC) ? 3'b011 :
                    (Op==OP_JAL)    ? 3'b100 :
                                      3'b000;   // I-type: addi/lw/jalr

    assign ALUSrc = (Op==OP_LOAD)||(Op==OP_STORE)||(Op==OP_ITYPE)||
                     (Op==OP_JALR)||(Op==OP_LUI)||(Op==OP_AUIPC);

    assign MemWrite = (Op==OP_STORE);

    assign ResultSrc = (Op==OP_LOAD) ? 2'b01 :
                        (Op==OP_JAL || Op==OP_JALR) ? 2'b10 :
                                      2'b00;

    assign Branch   = (Op==OP_BRANCH);
    assign Jump     = (Op==OP_JAL)||(Op==OP_JALR);
    assign JumpJalr = (Op==OP_JALR);

    assign ALUSrcA = (Op==OP_LUI)   ? 2'b01 :  // force 0
                      (Op==OP_AUIPC) ? 2'b10 :  // force PC
                                       2'b00;    // normal rs1

    assign ALUOp = (Op==OP_RTYPE || Op==OP_ITYPE) ? 2'b10 :
                   (Op==OP_BRANCH) ? 2'b01 :
                                     2'b00;

endmodule