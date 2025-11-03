# Olin-CompArch-MP4
Olin Computer Architecture's Mini-Project 4 implementing a RISC-V processor on an FPGA

### Current Architecture Thoughts

Each module is listed below:

#### Program Counter 
Inputs:
- Increment now flag variable
Output:
- Memory address of next instruction 
Other logic:
- Needs to handle jump or branch logic in this module

#### Instruction Counter
Inputs:
- 32-bit instruction from memory
Outputs:
- Each parsed part of the instruction, OR immediate value
- Literals passed as literals; memory addresses passed as addressed
Other logic:
- Determine here if the value should be fed to the register file or immediate
generator.

#### Register File
Inputs:
- Each parsed memory address
- ALU outputs
- Flag to/from ALU
Output:
- Literal values to pass to ALU
- Writes data to data memory
Other logic:
- Reads data from data memory

#### ALU
Inputs:
- Literal function codes
- Literal arithmetic inputs
- Flag to/from ALU
Outputs:
- Literal arithmetic outputs

#### Immediate Generator
What does this do?

#### Top level module?
- What needs to happen here besides connecting modules together?