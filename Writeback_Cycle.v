module writeback_cycle(clk, rst, ResultSrcW, PCPlus4W, ALU_ResultW, ReadDataW, ResultW);

input clk, rst;
input [1:0] ResultSrcW;
input [31:0] PCPlus4W, ALU_ResultW, ReadDataW;

output [31:0] ResultW;

// 00=ALU result, 01=Mem data, 10=PC+4 (jal/jalr link)
Mux_3_by_1 result_mux (    
                .a(ALU_ResultW),
                .b(ReadDataW),
                .c(PCPlus4W),
                .s(ResultSrcW),
                .d(ResultW)
                );
endmodule