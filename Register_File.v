
module Register_File(clk,rst,WE3,WD3,A1,A2,A3,RD1,RD2);

    input clk,rst,WE3;
    input [4:0]A1,A2,A3;
    input [31:0]WD3;
    output [31:0]RD1,RD2;

    reg [31:0] Register [31:0];

    always @ (posedge clk)
    begin
        if(WE3 & (A3 != 5'h00))
            Register[A3] <= WD3;
    end

    // Internal Forwarding: If reading the same register that is being written this cycle, forward the write data.
    assign RD1 = (WE3 & (A1 == A3) & (A1 != 5'h00)) ? WD3 : Register[A1];
    assign RD2 = (WE3 & (A2 == A3) & (A2 != 5'h00)) ? WD3 : Register[A2];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            Register[i] = 32'h00000000;
    end

endmodule