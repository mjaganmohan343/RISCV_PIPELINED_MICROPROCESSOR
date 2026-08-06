module Data_Memory(clk,rst,WE,WD,A,RD);

    input clk,rst,WE;
    input [31:0]A,WD;
    output [31:0]RD;

    reg [31:0] mem [1023:0];

    always @ (posedge clk)
    begin
        if(WE)
            mem[A[31:2]] <= WD;
    end

    assign RD = mem[A[31:2]];

    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = 32'h00000000;
        mem[0] = 32'hd10;
    end


endmodule