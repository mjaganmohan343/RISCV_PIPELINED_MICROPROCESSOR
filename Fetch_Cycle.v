module fetch_cycle (
    input  wire        clk,
    input  wire        rst,

    input  wire        PCWrite,        // From Hazard Unit
    input  wire        IF_ID_Write,    // From Hazard Unit
    input  wire        FlushD,         // From Hazard Unit (Branch flush)

    input  wire [31:0] PCTargetE,      // Branch target
    input  wire        PCSrcE,         // Branch taken

    output wire [31:0] InstrD,
    output wire [31:0] PCD,
    output wire [31:0] PCPlus4D
);

    //========================
    // PC REGISTER
    //========================
    reg [31:0] PCF;
    wire [31:0] PCNext;
    wire [31:0] PCPlus4F;

    assign PCPlus4F = PCF + 32'd4;
    assign PCNext   = PCSrcE ? PCTargetE : PCPlus4F;

    always @(posedge clk or posedge rst) begin
        if (rst)
            PCF <= 32'b0;
        else if (PCWrite)
            PCF <= PCNext;
    end


    //========================
    // INSTRUCTION MEMORY
    //========================
    wire [31:0] InstrF;

    Instruction_Memory imem (
        .A  (PCF),
        .RD (InstrF)
    );


    //========================
    // IF/ID PIPELINE REGISTER
    //========================
    reg [31:0] InstrF_reg;
    reg [31:0] PCF_reg;
    reg [31:0] PCPlus4F_reg;

    always @(posedge clk or posedge rst) begin
        if (rst | FlushD) begin
            InstrF_reg   <= 32'b0;
            PCF_reg      <= 32'b0;
            PCPlus4F_reg <= 32'b0;
        end
        else if (IF_ID_Write) begin
            InstrF_reg   <= InstrF;
            PCF_reg      <= PCF;
            PCPlus4F_reg <= PCPlus4F;
        end
        // else: HOLD values (stall)
    end

    assign InstrD   = InstrF_reg;
    assign PCD      = PCF_reg;
    assign PCPlus4D = PCPlus4F_reg;

endmodule
