module hazard_unit(
    rst,
    RegWriteM, RegWriteW,
    RD_M, RD_W,
    Rs1_E, Rs2_E,
    RD_E,
    Rs1_D, Rs2_D,
    ResultSrcE,
    PCSrcE,
    ForwardAE, ForwardBE,
    PCWrite,
    IF_ID_Write,
    FlushE,
    FlushD
);

    input rst;
    input RegWriteM, RegWriteW;
    input [4:0] RD_M, RD_W;
    input [4:0] RD_E;
    input [4:0] Rs1_E, Rs2_E;
    input [4:0] Rs1_D, Rs2_D;
    input [1:0] ResultSrcE;
    input PCSrcE;

    output [1:0] ForwardAE, ForwardBE;
    output PCWrite, IF_ID_Write, FlushE, FlushD;

    wire lwStall;

    assign ForwardAE = ((RegWriteM==1'b1) && (RD_M!=5'h00) && (RD_M==Rs1_E)) ? 2'b10 :
                       ((RegWriteW==1'b1) && (RD_W!=5'h00) && (RD_W==Rs1_E)) ? 2'b01 :
                       2'b00;

    assign ForwardBE = ((RegWriteM==1'b1) && (RD_M!=5'h00) && (RD_M==Rs2_E)) ? 2'b10 :
                       ((RegWriteW==1'b1) && (RD_W!=5'h00) && (RD_W==Rs2_E)) ? 2'b01 :
                       2'b00;

    // load-use hazard only when EX-stage instr is a load (ResultSrcE == 01)
    assign lwStall = (ResultSrcE == 2'b01) & ((RD_E == Rs1_D) | (RD_E == Rs2_D));

    assign PCWrite     = ~lwStall;
    assign IF_ID_Write = ~lwStall;
    assign FlushE      = lwStall | PCSrcE;
    assign FlushD      = PCSrcE;

endmodule