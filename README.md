# Olin-CompArch-MP4
Olin Computer Architecture's Mini-Project 4 implementing a RISC-V processor on an FPGA

### Current Architecture Thoughts

Each module is listed below:

#### Program Counter 
Instruction pointer and tells processor where it is and what to do next. 
Holds current PC, updates when enabled
Inputs:
- Increment now flag variable
Output:
- Memory address of next instruction 

#### Instruction Register
-Stores 32-bit registers that could be in top.sv
logic [31:0] ir; 

#### Instruction Decoder
Inputs:
- 32-bit instruction (from Instruction Register)
Outputs:
- opcode[6:0]
- rs1[4:0] (source register 1 address)
- rs2[4:0] (source register 2 address)  
- rd[4:0] (destination register address)
- funct3[2:0]
- funct7[6:0]
- instruction_type (signal indicating R/I/S/B/U/J type)
Other logic:
- Pure combinational parsing - no decision making
- Does NOT determine routing (that's the controller's job)

#### Register File
32 registers, 2 read ports, 1 write port
Inputs:
- clk
- rs1_addr[4:0] comes from instruction[19:15] (from instruction memory)
- rs2_addr[4:0] comes from instruction[24:20] (from instruction memory)
- rd_addr[4:0] comes from instruction[11:7] (from instruction memory)
- rd_data[31:0] comes from writeback mux (could be ALU result, memory data, or PC+4)
- reg_write_enable (control signal)
Output:
- rs1_data[31:0] (value from register rs1) goes to ALU
- rs2_data[31:0] (value from register rs2) goes to ALU or data memory input
Other logic:
- Register addresses come directly from instruction bits
- Register data values flow through ALU and datapath
- For loads: Data memory → mem_data_reg → rd_data → Register File
- For stores: Register File → rs2_data → Data memory
- Register x0 always reads as 0

#### Immediate Generator
Extracts/extends immediate values based on instruction type

#### ALU
Arithmetic/logic operations
Could including address calculation for branches
Inputs:
- Literal function codes
- Literal arithmetic inputs
- Flag to/from ALU
Outputs:
- Literal arithmetic outputs

#### Data Registers
Store intermediate results during multi-cycle instruction execution. Since 
functional units (ALU, memory, register file) output data on wires that don't 
persist across clock cycles, we need registers to "snapshot" these values at 
the end of each stage.

Example: For a load instruction (lw), we:
- Cycle 1: Fetch instruction, save in IR
- Cycle 2: Read register, save in reg_a
- Cycle 3: ALU calculates address (reg_a + offset), save in alu_out
- Cycle 4: Memory reads from alu_out address, save in mem_data_reg
- Cycle 5: Write mem_data_reg to destination register

Without these registers, results from earlier stages would be lost before 
later stages could use them.

#### Controller
Generates all control signals based on current state and instruction type
Input: Instruction type (opcode, maybe funct3/funct7)
Outputs: Control signals for EVERY stage of the multi-cycle execution
- PC_write_enable (when to update PC)
- IR_write (when to latch instruction register)
- reg_write_enable (when to write register file)
- mem_write_enable (when to write memory)
- ALU_src_A, ALU_src_B (mux selects for ALU inputs)
- ALU_op (what operation ALU should do)
- mem_to_reg (write ALU result or memory data to register?)
- PC_src (PC+4 or branch/jump target?)

Internal state: FSM states (FETCH, DECODE, EXECUTE, MEMORY, WRITEBACK)

#### Memory Module
Already provided in memory.sv - implements both instruction and data memory.
Inputs (from your processor):
- clk
- imem_address[31:0] (instruction fetch address - connected to PC)
- dmem_address[31:0] (data memory address - from ALU for load/store)
- dmem_data_in[31:0] (data to write for store instructions)
- dmem_wren (write enable for stores)
- funct3[2:0] (determines word/halfword/byte access)

Outputs (to your processor):
- imem_data_out[31:0] (instruction to be loaded into IR)
- dmem_data_out[31:0] (data read from memory for load instructions)
- reset (reset signal)
- led, red, green, blue (LED control outputs)

Memory Map:
- 0x00000000-0x00000FFF: Data memory (4KB)
- 0x00001000-0x00001FFF: Instruction memory (4KB)
- 0xFFFFFFFC: Memory-mapped LED PWM registers
- 0xFFFFFFF8: Millisecond timer (read-only)
- 0xFFFFFFF4: Microsecond timer (read-only)

How it connects:
- PC → imem_address → imem_data_out → IR
- ALU result → dmem_address (for loads/stores)
- Register file → dmem_data_in (for stores)
- dmem_data_out → mem_data_reg → Register file (for loads)

#### Top level module
State Registers (for multi-cycle)
- pc, ir, alu_out_reg, mem_data_reg
logic [31:0] pc;
logic [31:0] ir;  // instruction register
logic [31:0] alu_out_reg;
logic [31:0] mem_data_reg;

Wire Between Modules
- imm_value, rs1_data, rs2_data, alu_result, opcode, funct3, funct7\
logic [31:0] imm_value;
logic [31:0] rs1_data, rs2_data;
logic [31:0] alu_result;
logic [6:0] opcode;
logic [2:0] funct3;
logic [6:0] funct7;

Control Signals
- pc_write, ir_write, reg_write
-alu_src_a, alu_src_b

Instantiate Modules
-Control, Instruction Decoder, Register File, ALU, Immediate Gen, Memory (provided)

Potential logic for registers:
    always_ff @(posedge clk) begin
        if (pc_write)
            pc <= next_pc;
        if (ir_write)
            ir <= imem_data_out;
        // ... etc
    end

#### High Level Pipeline:
1. Instruction Fetch: Fetches instructions from memory.
2. Instruction Decode: Decodes the instruction and fetches operands.
3. Execute: Performs ALU operations or calculates addresses.
4. Memory: Reads from or writes to memory.
5. Write Back: Writes results back to the register file.

#### Pipeline
Ex instruction memory command to turn off red led:
sw   x12, 0(x10)       # Write 0x00000000 to LED register

1. Fetch (Cycle 1) - PC fetches instruction from instruction memory
The PC holds the address of the sw instruction and outputs it to imem_address.
Memory returns the instruction, which gets saved to IR.

In this case the IR would have the entire encoded instructions of sw   x12, 0(x10)  (32 bits)

2. Decoder parses IR (cycle 2):
opcode = 0100011 (S-type/STORE)
- rs1 = x10 (base register - used to compute memory address)
- rs2 = x12 (source data register - value to store in memory)
- rd = N/A (stores don't write to registers)
- funct3 = 010 (word store)
- funct7 = N/A (not used for S-type instructions)
- imm = 0 (offset)

funct3 usage in Decode:
- Sent to controller to help determine instruction type and control signals
- For stores/loads: Determines byte/halfword/word access (passed to memory module)
- For ALU ops: Combined with opcode and funct7 to generate ALU_op control signal

Register file reads:
rs1_data = value in x10 (rs1) (let's say 0xFFFFFFFC - the LED address)
rs2_data = value in x12 (rs2) (let's say 0x00000000 - the data to store)

Data that needs to be saved this cycle:
reg_a <= rs1_data;   // Save x10's value (0xFFFFFFFC)
reg_b <= rs2_data;   // Save x12's value (0x00000000) and saved for MEMORY stage
reg_imm <= imm_value; // Save immediate (0)

3. Execute (Cycle 3) - ALU calculates the memory address
Controlled by ALU_src_A mux that goes into input_A of the ALU. In this ex with reg_a  
Controlled by ALU_src_B mux that goes into input_B of the ALU. In this case it will be reg_imm
Ther mux selects specific wires through control signals by the Control Unit.

I will have 2 MUXes that are connected to the ALU
The muxes select what goes into the ALU:
- ALU_src_A mux: Selects between PC (00) - calculating PC+4 or branch targets, reg_a (01) - first register val
For store EXECUTE: select reg_a
- ALU_src_B mux: Selects between reg_b (00) - second register val, 4 (01) - PC+4 calc, reg_imm (10) - immediate val
For store EXECUTE: select reg_imm

funct7 usage in Execute:
- For R-type ALU operations: instruction bit 30 (funct7[5]) sent to ALU to distinguish operations
  Examples: add vs sub (both funct3=000, differ by funct7[5]), srl vs sra (both funct3=101, differ by funct7[5])
- For S-type stores: funct7 not used

ALU computes: reg_a + reg_imm = 0xFFFFFFFC + 0 = 0xFFFFFFFC
Save result:
- alu_out <= alu_result;  // Save 0xFFFFFFFC

4. Memory (Cycle 4) The Memory module receives these signals and writes to the LED register
Data that is an input for the memory module:
- dmem_address = alu_out
- dmem_data_in = reg_b (0x00000000 - the value from x12)
- dmem_wren = 1 (write enabled)

The Memory module receives these signals and writes 0x00000000 to the LED register.

5. Writeback (Cycle 5) - CPU updates PC to move to next instruction
For stores, no register writeback occurs:
- reg_write_enable = 0 (stores don't write to registers)
- Writeback MUX output is ignored
- pc <= pc + 4 (move to next instruction)
- pc_write = 1 (allows PC update)

The writeback MUX selects 
the appropriate value (alu_out, mem_data_reg, or PC+4) and reg_write_enable = 1 to 
write the selected value into rd_data of the register file at register rd_addr.

Writeback MUX (rd_sel)
Selects what data gets written to rd_data input of register file:
Inputs (controlled by 2-bit rd_sel signal):
- 00: alu_out (for ALU operations like add, sub, and, or)
- 01: mem_data_reg (for load instructions like lw, lh, lb)
- 10: reg_imm (for immediate instructions like lui)
- 11: PC+4 (for jump-and-link instructions like jal, jalr)

Output: Goes to rd_data[31:0] input of register file














