module execute_cycle(clk, rst, RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE, JumpE, JumpJalrE,
    ALUSrcAE, funct3E, ALUControlE, RD1_E, RD2_E, Imm_Ext_E, RD_E, PCE, PCPlus4E, PCSrcE, PCTargetE,
    RegWriteM, MemWriteM, ResultSrcM, RD_M, PCPlus4M, WriteDataM, ALU_ResultM, ResultW, ForwardA_E, ForwardB_E);

    input clk, rst, RegWriteE,ALUSrcE,MemWriteE,BranchE,JumpE,JumpJalrE;
    input [1:0] ResultSrcE;
    input [1:0] ALUSrcAE;
    input [2:0] funct3E;
    input [3:0] ALUControlE;
    input [31:0] RD1_E, RD2_E, Imm_Ext_E;
    input [4:0] RD_E;
    input [31:0] PCE, PCPlus4E;
    input [31:0] ResultW;
    input [1:0] ForwardA_E, ForwardB_E;

    output PCSrcE, RegWriteM, MemWriteM;
    output [1:0] ResultSrcM;
    output [4:0] RD_M; 
    output [31:0] PCPlus4M, WriteDataM, ALU_ResultM;
    output [31:0] PCTargetE;

    wire [31:0] Src_A_fwd, Src_A, Src_B_interim, Src_B;
    wire [31:0] ResultE;
    wire ZeroE, OverFlowE, CarryE, NegativeE;

    reg RegWriteE_r, MemWriteE_r;
    reg [1:0] ResultSrcE_r;
    reg [4:0] RD_E_r;
    reg [31:0] PCPlus4E_r, RD2_E_r, ResultE_r;

    // Forwarding mux for rs1
    Mux_3_by_1 srca_mux ( .a(RD1_E), .b(ResultW), .c(ALU_ResultM), .s(ForwardA_E), .d(Src_A_fwd) );

    // lui/auipc source-A override: 00=rs1(fwd) 01=zero(lui) 10=PC(auipc)
    Mux_3_by_1 srca_override_mux ( .a(Src_A_fwd), .b(32'h00000000), .c(PCE), .s(ALUSrcAE), .d(Src_A) );

    Mux_3_by_1 srcb_mux ( .a(RD2_E), .b(ResultW), .c(ALU_ResultM), .s(ForwardB_E), .d(Src_B_interim) );

    Mux alu_src_mux ( .a(Src_B_interim), .b(Imm_Ext_E), .s(ALUSrcE), .c(Src_B) );

    ALU alu (
            .A(Src_A), .B(Src_B), .Result(ResultE), .ALUControl(ALUControlE),
            .OverFlow(OverFlowE), .Carry(CarryE), .Zero(ZeroE), .Negative(NegativeE)
            );

    wire [31:0] PCTargetE_adder;
    PC_Adder branch_adder ( .a(PCE), .b(Imm_Ext_E), .c(PCTargetE_adder) );

    // Branch condition select via funct3
    wire lt_signed   = NegativeE ^ OverFlowE;
    wire lt_unsigned = ~CarryE;

    wire BranchTakenE =
        (funct3E == 3'b000) ? ZeroE        :   // beq
        (funct3E == 3'b001) ? ~ZeroE       :   // bne
        (funct3E == 3'b100) ? lt_signed    :   // blt
        (funct3E == 3'b101) ? ~lt_signed   :   // bge
        (funct3E == 3'b110) ? lt_unsigned  :   // bltu
        (funct3E == 3'b111) ? ~lt_unsigned :   // bgeu
                              1'b0;

    assign PCSrcE    = JumpE | (BranchE & BranchTakenE);
    assign PCTargetE = JumpJalrE ? {ResultE[31:1], 1'b0} : PCTargetE_adder;

    always @(posedge clk or posedge rst) begin
        if(rst == 1'b1) begin
            RegWriteE_r<=0; MemWriteE_r<=0; ResultSrcE_r<=0; RD_E_r<=0;
            PCPlus4E_r<=0; RD2_E_r<=0; ResultE_r<=0;
        end
        else begin
            RegWriteE_r <= RegWriteE; 
            MemWriteE_r <= MemWriteE; 
            ResultSrcE_r<= ResultSrcE;
            RD_E_r      <= RD_E;
            PCPlus4E_r  <= PCPlus4E; 
            RD2_E_r     <= Src_B_interim; 
            ResultE_r   <= ResultE;
        end
    end

    assign RegWriteM  = RegWriteE_r;
    assign MemWriteM  = MemWriteE_r;
    assign ResultSrcM = ResultSrcE_r;
    assign RD_M       = RD_E_r;
    assign PCPlus4M   = PCPlus4E_r;
    assign WriteDataM = RD2_E_r;
    assign ALU_ResultM= ResultE_r;

endmodule