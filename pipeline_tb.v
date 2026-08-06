`timescale 1ns/1ps

module riscv_pipeline_tb;

    reg clk, reset;
    integer cycle;
    integer errors;

    Pipeline_top dut (
        .clk   (clk),
        .rst   (reset),
        .dummy_out()
    );

    initial begin
        clk = 0;
        cycle = 0;
        errors = 0;
    end
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!reset) cycle = cycle + 1;
    end

    // Cycle-by-cycle pipeline monitor (kept from original, still useful for debug)
    always @(negedge clk) begin
        if (!reset) begin
            $display("\n================ CYCLE %0d ================", cycle);
            $display("[FETCH]     PC: %h | Instr: %h", dut.Fetch.PCF, dut.Fetch.InstrF);
            $display("[DECODE]    PC: %h | Instr: %h | Rs1: x%0d | Rs2: x%0d | Rd: x%0d",
                dut.Decode.PCD, dut.Decode.InstrD, dut.Decode.RS1_D, dut.Decode.RS2_D, dut.Decode.InstrD[11:7]);
            $display("[EXECUTE]   PC: %h | ALUResult: %h | Rd: x%0d | PCSrcE: %b",
                dut.Execute.PCE, dut.Execute.ResultE, dut.RD_E, dut.PCSrcE);
            $display("[MEMORY]    ALUResult: %h | Rd: x%0d", dut.Memory.ALU_ResultM, dut.Memory.RD_M);
            $display("[WRITEBACK] Result: %h | RegWrite: %b | Rd: x%0d",
                dut.ResultW, dut.RegWriteW, dut.RD_W);

            if (dut.RegWriteW && dut.RD_W != 0)
                $display("  ---> [EVENT] REG WRITE: x%0d = %h (%0d)", dut.RD_W, dut.ResultW, $signed(dut.ResultW));
            if (dut.MemWriteM)
                $display("  ---> [EVENT] MEM WRITE: Addr %h = %h", dut.ALU_ResultM, dut.WriteDataM);
            if (~dut.PCWrite || ~dut.IF_ID_Write)
                $display("  ---> [HAZARD] STALL (Load-Use)");
            if (dut.FlushD || dut.FlushE)
                $display("  ---> [HAZARD] FLUSH: D=%b E=%b", dut.FlushD, dut.FlushE);
        end
    end

    // Self-checking task: compares one register against expected value
    task check_reg(input [4:0] idx, input [31:0] expected);
        reg [31:0] actual;
        begin
            actual = dut.Decode.rf.Register[idx];
            if (actual !== expected) begin
                $display("  [FAIL] x%0d = %h, expected %h", idx, actual, expected);
                errors = errors + 1;
            end else begin
                $display("  [PASS] x%0d = %h", idx, actual);
            end
        end
    endtask

    task check_mem(input [31:0] word_idx, input [31:0] expected);
        reg [31:0] actual;
        begin
            actual = dut.Memory.dmem.mem[word_idx];
            if (actual !== expected) begin
                $display("  [FAIL] mem[%0d] = %h, expected %h", word_idx, actual, expected);
                errors = errors + 1;
            end else begin
                $display("  [PASS] mem[%0d] = %h", word_idx, actual);
            end
        end
    endtask

    initial begin
        reset = 1;
        #27;
        reset = 0;

        // Extended runtime: 44 instructions + branches/jumps + pipeline fill.
        // Generous margin since the program ends in a self-loop (beq x0,x0,DONE).
        #900;

        $display("\n============================================");
        $display("               FINAL RESULTS                ");
        $display("============================================");

        $display("\n-- New ALU / Logic / Shift instructions --");
        check_reg(1,  32'd5);
        check_reg(2,  32'd3);
        check_reg(3,  32'h00000006); // xor
        check_reg(4,  32'h00000007); // or
        check_reg(5,  32'h00000001); // and
        check_reg(6,  32'h00000001); // sltu
        check_reg(7,  32'h0000000a); // xori
        check_reg(8,  32'h0000000d); // ori
        check_reg(9,  32'h00000001); // andi
        check_reg(10, 32'h00000014); // slli
        check_reg(11, 32'h0000000a); // srli
        check_reg(12, 32'hfffffff8); // addi negative
        check_reg(13, 32'hfffffffc); // srai
        check_reg(14, 32'h00000028); // sll
        check_reg(15, 32'h00000005); // srl
        check_reg(16, 32'hffffffff); // sra
        check_reg(17, 32'h00000001); // sltiu

        $display("\n-- LUI / AUIPC --");
        check_reg(18, 32'h12345000); // lui
        check_reg(19, 32'h00001048); // auipc

        $display("\n-- Branches (bne/blt/bge/bltu/bgeu) --");
        check_reg(20, 32'd111);  // bne taken
        check_reg(21, 32'd222);  // blt taken
        check_reg(22, 32'd333);  // bge taken
        check_reg(23, 32'd444);  // bltu taken
        check_reg(24, 32'd555);  // bgeu taken

        $display("\n-- Jumps (jal/jalr) --");
        check_reg(25, 32'h0000008c); // jal link addr
        check_reg(26, 32'd666);      // landed after jal
        check_reg(27, 32'h00000094); // auipc for jalr base
        check_reg(28, 32'h0000009c); // jalr link addr
        check_reg(30, 32'd777);      // landed after jalr

        $display("\n-- Load/Store still correct --");
        check_mem(0, 32'h12345000);
        check_reg(31, 32'h12345000); // lw back from mem[0]

        $display("\n============================================");
        if (errors == 0)
            $display("  [SUCCESS] ALL %0d CHECKS PASSED!", 25);
        else
            $display("  [ERROR] %0d CHECK(S) FAILED!", errors);
        $display("============================================");

        $finish;
    end

endmodule