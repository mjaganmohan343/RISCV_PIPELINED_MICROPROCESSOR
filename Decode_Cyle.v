module decode_cycle (
    input  wire        clk,
    input  wire        rst,
    input  wire        FlushE,

    input  wire [31:0] InstrD,
    input  wire [31:0] PCD,
    input  wire [31:0] PCPlus4D,

    input  wire        RegWriteW,
    input  wire [4:0]  RD_W,
    input  wire [31:0] ResultW,

    output reg         RegWriteE,
    output reg         MemWriteE,
    output reg         MemReadE,
    output reg         ALUSrcE,
    output reg  [1:0]  ResultSrcE,
    output reg         BranchE,
    output reg         JumpE,
    output reg         JumpJalrE,
    output reg  [1:0]  ALUSrcAE,
    output reg  [2:0]  funct3E,
    output reg  [3:0]  ALUControlE,

    output reg  [31:0] RD1_E,
    output reg  [31:0] RD2_E,
    output reg  [31:0] Imm_Ext_E,
    output reg  [4:0]  RD_E,
    output reg  [4:0]  RS1_E,
    output reg  [4:0]  RS2_E,
    output reg  [31:0] PCE,
    output reg  [31:0] PCPlus4E,

    output wire [4:0]  RS1_D,
    output wire [4:0]  RS2_D
);

    assign RS1_D = InstrD[19:15];
    assign RS2_D = InstrD[24:20];

    wire [31:0] RD1D, RD2D;

    Register_File rf (
        .clk(clk), .rst(rst), .WE3(RegWriteW),
        .A1(InstrD[19:15]), .A2(InstrD[24:20]), .A3(RD_W), .WD3(ResultW),
        .RD1(RD1D), .RD2(RD2D)
    );

    wire RegWriteD, MemWriteD, MemReadD, ALUSrcD;
    wire [1:0] ResultSrcD, ALUSrcAD;
    wire BranchD, JumpD, JumpJalrD;
    wire [2:0] ImmSrcD;
    wire [3:0] ALUControlD;

    Control_Unit_Top control (
        .Op(InstrD[6:0]),
        .RegWrite(RegWriteD), .ImmSrc(ImmSrcD), .ALUSrc(ALUSrcD),
        .MemWrite(MemWriteD), .ResultSrc(ResultSrcD), .Branch(BranchD),
        .Jump(JumpD), .JumpJalr(JumpJalrD), .ALUSrcA(ALUSrcAD),
        .funct3(InstrD[14:12]), .funct7(InstrD[31:25]), .ALUControl(ALUControlD)
    );

    wire [31:0] ImmExtD;
    Sign_Extend se ( .In(InstrD), .ImmSrc(ImmSrcD), .Imm_Ext(ImmExtD) );

    always @(posedge clk or posedge rst) begin
        if (rst || FlushE) begin
            RegWriteE<=0; MemWriteE<=0; MemReadE<=0; ALUSrcE<=0; ALUControlE<=0;
            RD1_E<=0; RD2_E<=0; Imm_Ext_E<=0; RD_E<=0; RS1_E<=0; RS2_E<=0;
            PCE<=0; PCPlus4E<=0; ResultSrcE<=0; BranchE<=0;
            JumpE<=0; JumpJalrE<=0; ALUSrcAE<=0; funct3E<=0;
        end
        else begin
            RegWriteE  <= RegWriteD;
            MemWriteE  <= MemWriteD;
            MemReadE   <= MemReadD;
            ALUSrcE    <= ALUSrcD;
            ALUControlE<= ALUControlD;
            RD1_E      <= RD1D;
            RD2_E      <= RD2D;
            Imm_Ext_E  <= ImmExtD;
            RD_E       <= InstrD[11:7];
            RS1_E      <= InstrD[19:15];
            RS2_E      <= InstrD[24:20];
            PCE        <= PCD;
            PCPlus4E   <= PCPlus4D;
            ResultSrcE <= ResultSrcD;
            BranchE    <= BranchD;
            JumpE      <= JumpD;
            JumpJalrE  <= JumpJalrD;
            ALUSrcAE   <= ALUSrcAD;
            funct3E    <= InstrD[14:12];
        end
    end

endmodule