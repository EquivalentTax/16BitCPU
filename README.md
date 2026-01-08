# 16 Bit CPU
16-Bit RISC Processor Design (VHDL)

Abstract

This project presents the design, synthesis, and simulation of a 16-bit RISC (Reduced Instruction Set Computer) processor. The processor is implemented using VHDL and simulated within the Xilinx Vivado environment. The architecture is inspired by the Harvard Architecture, featuring separate instruction and data memories to optimize the fetch-execute cycle. The core supports a custom Instruction Set Architecture (ISA) including arithmetic, logical, memory access, and control flow operations.

# Features & Specifications

Architecture: 16-bit RISC, Harvard Architecture.

Clocking: Single-cycle data path implementation.

Memory: * ROM: 16-bit Instruction Memory (Read-Only).

RAM: 16-bit Data Memory (Synchronous Read/Write).

Register File: 8 General Purpose Registers (R0–R7).

ALU Operations: ADD, SUB, AND, OR, XOR.

Control Unit: FSM-based (Finite State Machine) with Fetch-Decode-Execute states.

Reset Logic: Asynchronous Active-High Reset.

# System Architecture

The processor consists of two main subsystems: the Datapath and the Control Unit.

1. The Datapath

The datapath performs all data processing operations.

Program Counter (PC): Holds the address of the current instruction. It increments by 1 (or 2) every cycle unless a Branch/Jump occurs.

Register File: A multi-port memory block allowing two simultaneous reads (for ALU inputs) and one write (for storing results).

ALU (Arithmetic Logic Unit): The computational core. It acts as a combinational circuit taking two operands and outputting a result based on the ULA_Op selector.

Multiplexers: Used for routing data (e.g., selecting between ALU Result, Memory Data, or Immediate values for Write-Back).

2. The Control Unit (FSM)

The "Brain" of the CPU. It is implemented as a Finite State Machine that orchestrates the Fetch-Decode-Execute cycle.

Fetch: Enables ROM to retrieve instruction at PC address.

Decode: Parses the Opcode to generate signal lines (RegWrite, ALUSrc, MemRead, etc.).

Execute: Enables the ALU or RAM access.

3. Dataflow Diagram

The data flows as follows:
PC -> ROM -> Instruction Register -> Control Unit Decoder -> Register File -> ALU -> Write-Back Mux -> Destination Register.

 
 Instruction Set Architecture (ISA)

The processor uses a fixed 16-bit instruction format.

Instruction Formats

R-Type (Register): [ Opcode (4) | Rd (3) | Rs1 (3) | Rs2 (3) | Unused (3) ]

I-Type (Immediate): [ Opcode (4) | Rd (3) | Rs1 (3) | Immediate (6) ]



# Simulation & Verification

The design was verified using a VHDL Testbench (cpu_tb.vhd) which generates the Master Clock (clk) and Reset (rst) signals.

Test Case: 3 + 2 = 5

To verify the Arithmetic Logic Unit, the following assembly program was loaded into the ROM:

0x00: ADDI R2, R0, #3   ; Load 3 into R2
0x01: ADDI R3, R0, #2   ; Load 2 into R3
0x02: ADD  R1, R2, R3   ; R1 = R2 + R3 (Expect 5)
0x03: JUMP 0x03         ; Infinite Loop (Halt)


Waveform Analysis

The simulation waveform confirms the correct execution:

Initialization: The rst signal clears the PC to 0x0000.

Fetch: The address bus increments sequentially (0, 1, 2).

Execute (Time T): At the instruction ADD R1, R2, R3, the internal ALU signals show Operand A = 3 and Operand B = 2.

Result: The ALU_Result transitions to 5.

Write-Back: The Register_File updates R1 with 5 on the next clock edge.

Note: Simulation screenshots are available in the /img directory.



# References

Patterson, D. A., & Hennessy, J. L. (2020). Computer Organization and Design RISC-V Edition. Morgan Kaufmann.

Harris, D. M., & Harris, S. L. (2012). Digital Design and Computer Architecture. Morgan Kaufmann.

Xilinx Inc. (2023). Vivado Design Suite User Guide.

IEEE Standard 1076-2008. IEEE Standard VHDL Language Reference Manual.

# Directory Structure

.
├── src/               # VHDL Source Files

│   ├── cpu_top.vhd    # Top Level Module

│   ├── alu.vhd        # Arithmetic Logic Unit

│   ├── control_unit.vhd

│   ├── ram.vhd

│   └── rom.vhd

├── sim/               # Simulation Files

│   └── cpu_tb.vhd     # Testbench

├── img/               # Waveform Screenshots & Diagrams

└── README.md          # This Report

# CPU Testbench

entity cpu_tb is
Empty entity for testbench
end cpu_tb;

architecture Behavioral of cpu_tb is
    -- Component Declaration for your CPU
    component your_cpu_entity
    port( ... ); -- copy ports from your CPU
    end component;
    
    -- Inputs
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    -- Outputs (Signals to observe)
    ...
    
    -- Clock period definition
    constant clk_period : time := 10 ns;
 
begin
    -- Instantiate the Unit Under Test (UUT)
    uut: your_cpu_entity PORT MAP (
          clk => clk,
          rst => rst,
          ...
        );

    -- Clock process definitions
    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin		
        -- hold reset state for 100 ns.
        rst <= '1';
        wait for 100 ns;	
        rst <= '0'; -- Release reset, CPU starts here!
        wait;
    end process;
end Behavioral;


