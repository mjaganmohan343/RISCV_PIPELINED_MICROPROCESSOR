module ALU_Decoder(ALUOp,funct3,funct7,op,ALUControl);

    input  [1:0] ALUOp;
    input  [2:0] funct3;
    input  [6:0] funct7,op;
    output [3:0] ALUControl;

    wire isRtype = op[5];     // 1 for 0110011 (R-type), 0 for 0010011 (I-type ALU)
    wire altFunc = funct7[5]; // bit 30 of instruction

    wire [3:0] RtypeCtrl =
        (funct3 == 3'b000) ? ((isRtype & altFunc) ? 4'b0001 : 4'b0000) : // sub / add(i)
        (funct3 == 3'b001) ? 4'b0111 :                                   // sll(i)
        (funct3 == 3'b010) ? 4'b0101 :                                   // slt(i)
        (funct3 == 3'b011) ? 4'b0110 :                                   // sltu(i)
        (funct3 == 3'b100) ? 4'b0100 :                                   // xor(i)
        (funct3 == 3'b101) ? (altFunc ? 4'b1001 : 4'b1000) :             // sra(i)/srl(i)
        (funct3 == 3'b110) ? 4'b0011 :                                   // or(i)
        (funct3 == 3'b111) ? 4'b0010 :                                   // and(i)
                              4'b0000;

    assign ALUControl = (ALUOp == 2'b00) ? 4'b0000 : // load/store/jalr/lui/auipc address
                         (ALUOp == 2'b01) ? 4'b0001 : // branch compare
                         (ALUOp == 2'b10) ? RtypeCtrl :
                                            4'b0000;
endmodule