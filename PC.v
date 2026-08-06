

module PC_Module(clk,rst,PCWrite,PC,PC_Next);
    input clk,rst,PCWrite;
    input [31:0]PC_Next;
    output reg [31:0]PC;
    

   always @(posedge clk or posedge rst)
begin
    if (rst)
        PC <= 0;
    else if (PCWrite)
        PC <= PC_Next;
end


endmodule