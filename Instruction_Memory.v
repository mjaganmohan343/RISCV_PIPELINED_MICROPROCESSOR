module Instruction_Memory(A, RD);

  input  [31:0] A;
  output [31:0] RD;

  reg [31:0] mem [0:1023];

  assign RD = mem[A[31:2]];   // word aligned addressing

  initial begin
      $readmemh("memfile.mem", mem);
  end

endmodule