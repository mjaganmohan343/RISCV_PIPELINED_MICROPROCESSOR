module Pipeline_top(clk, rst, dummy_out);

    input clk, rst;
    output dummy_out;

    wire PCSrcE, PCWrite, IF_ID_Write, FlushE, FlushD;
    wire RegWriteW, RegWriteE, ALUSrcE, MemWriteE;
    wire BranchE, RegWriteM, MemWriteM;
    wire MemReadE;
    wire JumpE, JumpJalrE;

    wire [3:0] ALUControlE;
    wire [1:0] ResultSrcE, ResultSrcM, ResultSrcW;
    wire [1:0] ALUSrcAE;
    wire [2:0] funct3E;

    wire [4:0] RD_E, RD_M, RD_W;
    wire [4:0] RS1_E, RS2_E;
    wire [4:0] RS1_D, RS2_D;

    wire [1:0] ForwardBE, ForwardAE;

    wire [31:0] PCTargetE, InstrD, PCD, PCPlus4D;
    wire [31:0] ResultW, RD1_E, RD2_E, Imm_Ext_E;
    wire [31:0] PCE, PCPlus4E, PCPlus4M;
    wire [31:0] WriteDataM, ALU_ResultM;
    wire [31:0] PCPlus4W, ALU_ResultW, ReadDataW;

    fetch_cycle Fetch (
        .clk(clk), .rst(rst), .PCWrite(PCWrite), .IF_ID_Write(IF_ID_Write),
        .FlushD(FlushD), .PCSrcE(PCSrcE), .PCTargetE(PCTargetE),
        .InstrD(InstrD), .PCD(PCD), .PCPlus4D(PCPlus4D)
    );

    decode_cycle Decode (
        .clk(clk), .rst(rst), .FlushE(FlushE),
        .InstrD(InstrD), .PCD(PCD), .PCPlus4D(PCPlus4D),
        .RegWriteW(RegWriteW), .RD_W(RD_W), .ResultW(ResultW),
        .RegWriteE(RegWriteE), .MemWriteE(MemWriteE), .MemReadE(MemReadE),
        .ALUSrcE(ALUSrcE), .ResultSrcE(ResultSrcE), .BranchE(BranchE),
        .JumpE(JumpE), .JumpJalrE(JumpJalrE), .ALUSrcAE(ALUSrcAE), .funct3E(funct3E),
        .ALUControlE(ALUControlE),
        .RD1_E(RD1_E), .RD2_E(RD2_E), .Imm_Ext_E(Imm_Ext_E),
        .RD_E(RD_E), .RS1_E(RS1_E), .RS2_E(RS2_E),
        .PCE(PCE), .PCPlus4E(PCPlus4E),
        .RS1_D(RS1_D), .RS2_D(RS2_D)
    );

    execute_cycle Execute (
        .clk(clk), .rst(rst), .RegWriteE(RegWriteE), .ALUSrcE(ALUSrcE),
        .MemWriteE(MemWriteE), .ResultSrcE(ResultSrcE), .BranchE(BranchE),
        .JumpE(JumpE), .JumpJalrE(JumpJalrE), .ALUSrcAE(ALUSrcAE), .funct3E(funct3E),
        .ALUControlE(ALUControlE),
        .RD1_E(RD1_E), .RD2_E(RD2_E), .Imm_Ext_E(Imm_Ext_E), .RD_E(RD_E),
        .PCE(PCE), .PCPlus4E(PCPlus4E), .PCSrcE(PCSrcE), .PCTargetE(PCTargetE),
        .RegWriteM(RegWriteM), .MemWriteM(MemWriteM), .ResultSrcM(ResultSrcM),
        .RD_M(RD_M), .PCPlus4M(PCPlus4M), .WriteDataM(WriteDataM), .ALU_ResultM(ALU_ResultM),
        .ResultW(ResultW), .ForwardA_E(ForwardAE), .ForwardB_E(ForwardBE)
    );

    memory_cycle Memory (
        .clk(clk), .rst(rst), .RegWriteM(RegWriteM), .MemWriteM(MemWriteM),
        .ResultSrcM(ResultSrcM), .RD_M(RD_M), .PCPlus4M(PCPlus4M),
        .WriteDataM(WriteDataM), .ALU_ResultM(ALU_ResultM),
        .RegWriteW(RegWriteW), .ResultSrcW(ResultSrcW), .RD_W(RD_W),
        .PCPlus4W(PCPlus4W), .ALU_ResultW(ALU_ResultW), .ReadDataW(ReadDataW)
    );

    writeback_cycle WB(
        .clk(clk), .rst(rst), .ResultSrcW(ResultSrcW),
        .PCPlus4W(PCPlus4W), .ALU_ResultW(ALU_ResultW), .ReadDataW(ReadDataW),
        .ResultW(ResultW)
    );

    hazard_unit HU(
        .rst(rst),
        .RegWriteM(RegWriteM), .RegWriteW(RegWriteW),
        .RD_M(RD_M), .RD_W(RD_W), .Rs1_E(RS1_E), .Rs2_E(RS2_E),
        .RD_E(RD_E), .Rs1_D(RS1_D), .Rs2_D(RS2_D),
        .ResultSrcE(ResultSrcE), .PCSrcE(PCSrcE),
        .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
        .PCWrite(PCWrite), .IF_ID_Write(IF_ID_Write),
        .FlushE(FlushE), .FlushD(FlushD)
    );

    assign dummy_out = ^WriteDataM ^ ^ALU_ResultM;

endmodule