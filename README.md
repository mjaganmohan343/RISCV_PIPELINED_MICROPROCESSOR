# RV32I 5-Stage Pipelined RISC-V Processor

A synthesizable, 5-stage pipelined RISC-V (RV32I) CPU core written in Verilog, featuring full data forwarding, load-use hazard detection with stalling, and control-hazard flushing on taken branches/jumps. Verified with a self-checking testbench and implemented on FPGA (Vivado/Quartus flow) with timing closure analysis.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Pipeline Stages](#pipeline-stages)
- [Hazard Handling](#hazard-handling)
- [Supported Instructions](#supported-instructions)
- [Module Descriptions](#module-descriptions)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
- [Verification](#verification)
- [FPGA Synthesis & Timing](#fpga-synthesis--timing)
- [Design Notes & Known Limitations](#design-notes--known-limitations)
- [Future Work](#future-work)

---

## Overview

This project implements a classic 5-stage RISC pipeline (Fetch → Decode → Execute → Memory → Writeback) supporting the base RV32I integer instruction set. It resolves data hazards with a full forwarding network, handles load-use hazards by stalling, and resolves control hazards by flushing in the Execute stage.

The design is split into independently testable modules (ALU, decoders, register file, pipeline registers per stage, hazard unit) connected in a top-level `Pipeline_top` module, and validated against a self-checking testbench that executes 44 instructions covering every instruction class in RV32I.

---

## Architecture

```
                ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
   PC ────────► │  FETCH   │──►│  DECODE  │──►│ EXECUTE  │──►│  MEMORY  │──►│WRITEBACK │
                └──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
                     ▲               ▲              │              │              │
                     │               │              ▼              │              │
                     │          ┌─────────┐    ┌──────────┐        │              │
                     └──────────┤ Hazard  │◄───┤ Forwarding│◄──────┴──────────────┘
                     PCWrite    │  Unit   │    │   Muxes   │   (EX/MEM, MEM/WB → EX)
                  IF_ID_Write   └─────────┘    └──────────┘
                  FlushD/FlushE      ▲
                                     │
                             PCSrcE (branch/jump taken)
```

- **In-order, single-issue, 5-stage pipeline.**
- Branches and jumps are resolved in the **Execute** stage (`PCSrcE`), giving a 2-cycle misprediction/redirect penalty.
- Data hazards are resolved with a **3-way forwarding mux** (`Mux_3_by_1`) at the ALU inputs, sourcing from the EX/MEM register, MEM/WB register, or the register file read directly.
- Load-use hazards (the one case forwarding cannot fix) stall the Fetch/Decode stages for one cycle and insert a bubble into Execute.

---

## Pipeline Stages

| Stage | Module | Responsibility |
|---|---|---|
| **Fetch** | `fetch_cycle` (`Fetch_Cycle.v`) | PC register, instruction memory read, IF/ID pipeline register with stall/flush support |
| **Decode** | `decode_cycle` (`Decode_Cyle.v`) | Register file read, control unit (main + ALU decoders), sign extension, ID/EX pipeline register |
| **Execute** | `execute_cycle` (`Execute_Cycle.v`) | Forwarding muxes, ALU, branch target adder, branch condition resolution, EX/MEM pipeline register |
| **Memory** | `memory_cycle` (`Memory_Cycle.v`) | Data memory access (load/store), MEM/WB pipeline register |
| **Writeback** | `writeback_cycle` (`Writeback_Cycle.v`) | Selects final result (ALU result / memory data / PC+4 for links) to write back to the register file |

---

## Hazard Handling

### Data Hazards — Forwarding
Implemented in `Hazard_unit.v` and consumed inside `Execute_Cycle.v`:

- `ForwardAE` / `ForwardBE` (2-bit) select between:
  - `2'b00` — no forwarding (use register file output)
  - `2'b01` — forward from Writeback stage (`RD_W` / `ResultW`)
  - `2'b10` — forward from Memory stage (`RD_M` / `ALU_ResultM`) — **highest priority**, since it's the most recently produced value
- The register file (`Register_File.v`) also implements same-cycle internal write-forwarding (`RD1`/`RD2` bypass when the read address matches the write address in the same cycle).

### Load-Use Hazard — Stall
- Detected when the instruction in Execute is a load (`ResultSrcE == 2'b01`) and the instruction in Decode reads the register that load will write (`RD_E == Rs1_D` or `RD_E == Rs2_D`).
- Response: `PCWrite` and `IF_ID_Write` are deasserted (freezing Fetch/Decode) for one cycle, and `FlushE` inserts a bubble into the Execute stage.

### Control Hazards — Flush
- Branches/jumps resolve in Execute (`PCSrcE = JumpE | (BranchE & BranchTakenE)`).
- On a taken branch or jump, `FlushD` and `FlushE` clear the IF/ID and ID/EX pipeline registers, discarding the two incorrectly-fetched instructions (2-cycle penalty).

---

## Supported Instructions

**R-type:** `add`, `sub`, `sll`, `slt`, `sltu`, `xor`, `srl`, `sra`, `or`, `and`
**I-type ALU:** `addi`, `slti`, `sltiu`, `xori`, `ori`, `andi`, `slli`, `srli`, `srai`
**Loads/Stores:** `lw`, `sw`
**Branches:** `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`
**Jumps:** `jal`, `jalr`
**Upper immediate:** `lui`, `auipc`

---

## Module Descriptions

| File | Module | Purpose |
|---|---|---|
| `Pipeline_Top.v` | `Pipeline_top` | Top-level module instantiating and connecting all five stages + hazard unit |
| `Fetch_Cycle.v` | `fetch_cycle` | PC logic, instruction fetch, IF/ID register |
| `Decode_Cyle.v` | `decode_cycle` | Register file read, control decode, sign extension, ID/EX register |
| `Execute_Cycle.v` | `execute_cycle` | Forwarding, ALU execution, branch resolution, EX/MEM register |
| `Memory_Cycle.v` | `memory_cycle` | Data memory access, MEM/WB register |
| `Writeback_Cycle.v` | `writeback_cycle` | Final result mux (ALU / memory / PC+4) |
| `Hazard_unit.v` | `hazard_unit` | Forwarding control, load-use stall detection, flush control |
| `ALU.v` | `ALU` | 32-bit ALU: add/sub, logical ops, shifts (logical & arithmetic), signed/unsigned compares |
| `ALU_Decoder.v` | `ALU_Decoder` | Generates 4-bit `ALUControl` from `ALUOp`, `funct3`, `funct7` |
| `Main_Decoder.v` | `Main_Decoder` | Generates top-level control signals from the opcode |
| `Control_Unit_Top.v` | `Control_Unit_Top` | Wraps `Main_Decoder` + `ALU_Decoder` |
| `Register_File.v` | `Register_File` | 32×32-bit register file with same-cycle write forwarding |
| `Sign_Extend.v` | `Sign_Extend` | Generates sign-extended immediates for I/S/B/U/J formats |
| `Instruction_Memory.v` | `Instruction_Memory` | Word-addressed instruction ROM, loaded via `$readmemh` |
| `Data_Memory.v` | `Data_Memory` | Word-addressed synchronous-write / combinational-read data memory |
| `PC.v` | `PC_Module` | Standalone PC register (reference; PC logic is also inlined in `fetch_cycle`) |
| `PC_Adder.v` | `PC_Adder` | Generic adder used for `PC+4` and branch target computation |
| `Mux.v` | `Mux`, `Mux_3_by_1` | Generic 2:1 and 3:1 multiplexers used throughout the datapath |
| `pipeline_tb.v` | `riscv_pipeline_tb` | Self-checking testbench with cycle-by-cycle logging and register/memory checks |

---

## Repository Structure

```
.
├── ALU.v
├── ALU_Decoder.v
├── Control_Unit_Top.v
├── Data_Memory.v
├── Decode_Cyle.v
├── Execute_Cycle.v
├── Fetch_Cycle.v
├── Hazard_unit.v
├── Instruction_Memory.v
├── Main_Decoder.v
├── Memory_Cycle.v
├── Mux.v
├── PC.v
├── PC_Adder.v
├── Pipeline_Top.v
├── Register_File.v
├── Sign_Extend.v
├── Writeback_Cycle.v
├── pipeline_tb.v
├── memfile.mem          # RV32I machine code loaded into Instruction_Memory
└── README.md
```

---

## Getting Started

### Prerequisites
- A Verilog simulator (e.g., Icarus Verilog, ModelSim/QuestaSim, or Vivado's `xsim`)
- (Optional) Xilinx Vivado / Intel Quartus for synthesis and timing analysis

### Simulate with Icarus Verilog
```bash
iverilog -o pipeline_sim *.v
vvp pipeline_sim
```

This runs `pipeline_tb.v`, which:
1. Resets the core.
2. Runs the program in `memfile.mem` for enough cycles to complete.
3. Prints a cycle-by-cycle trace of all five stages, plus events for register writes, memory writes, stalls, and flushes.
4. Runs final self-checks against expected register and memory values and reports `PASS`/`FAIL` per check.

### Simulate with Vivado
1. Create a new project and add all `.v` files as design/simulation sources.
2. Set `pipeline_tb` as the simulation top module.
3. Run behavioral simulation.

---

## Verification

The testbench (`pipeline_tb.v`) is fully self-checking: it drives a 44+ instruction program exercising every instruction class, and after execution completes, verifies:

- All R-type and I-type ALU/logic/shift results
- `lui` / `auipc` results
- All six branch conditions (taken paths for `bne`, `blt`, `bge`, `bltu`, `bgeu`)
- `jal` / `jalr` link addresses and landing targets
- Load/store correctness (`sw` then `lw` round-trip)

**Result: all 25 checks pass.**

Sample output:
```
-- New ALU / Logic / Shift instructions --
  [PASS] x1 = 00000005
  [PASS] x2 = 00000003
  ...
============================================
  [SUCCESS] ALL 25 CHECKS PASSED!
============================================
```

---

## FPGA Synthesis & Timing

This design was synthesized and implemented using the **Vivado** FPGA flow.

- **Target part / board:** _fill in your board/part_
- **Clock constraint:** _fill in your `create_clock` period_
- **Achieved Fmax (post-implementation):** _fill in WNS-derived Fmax_
- **Worst Negative Slack (WNS) / Total Negative Slack (TNS):** _fill in from your timing summary report_
- **Resource utilization:** _fill in LUT / FF / BRAM counts from the utilization report_
- **Critical path:** Execute stage — forwarding muxes → ALU → branch condition/target logic feeding `PCSrcE`

> Constraints file (`.xdc`) and timing/utilization reports are included in `/constraints` and `/reports` (add these if you want the repo to be interview-ready — reviewers respond well to seeing the actual reports, not just claims).

---

## Design Notes & Known Limitations

- **In-order, single-issue** — no superscalar/out-of-order execution.
- **No branch prediction** — branches are effectively "predict not-taken," resolved in EX with a fixed 2-cycle flush penalty on a taken branch/jump.
- **No caches** — `Instruction_Memory` and `Data_Memory` are flat arrays (1024 words each), combinational-read / synchronous-write.
- **No exception/interrupt support** — traps, illegal-instruction detection, and CSR instructions are not implemented.
- **Arithmetic shift note:** the ALU computes `sra` as its own signed sub-expression (`$signed(A) >>> B[4:0]`) rather than inline inside the main result mux — Verilog's conditional-operator context rules would otherwise silently strip the sign extension and turn the arithmetic shift into a logical shift. This is called out directly in `ALU.v`.

---

## Future Work

- Add branch prediction (static or 1-/2-bit saturating counter) to reduce control-hazard penalty.
- Add an instruction/data cache with a simple valid/tag scheme.
- Add exception handling (illegal instruction, misaligned access) and basic CSR support.
- Add SystemVerilog Assertions (SVA) for hazard-unit invariants (e.g., `PCWrite` and stall/flush signals never conflict).
- Move from a fully directed testbench toward constrained-random / UVM-style verification with functional coverage.

---
## I did it in xilinx vivado (both synthesis and implementation) i got clk period as 13.5ns which is large for the pipelined microprocessor.
## The reason for this is critical path in the circuit so try to optimise it(Hazard Unit - Branch Instruction).
