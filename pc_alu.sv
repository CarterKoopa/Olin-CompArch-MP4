//
// Olin Computer Architecture - Mini-Project 4
// RISC-V Microprocessor Implementation
//
// Program Counter ALU
//
// This module is a simple arithmetic logic unit to advance the program counter
// to the next instruction.

module pc_alu (
    input logic [31:0] pc,
    output logic [31:0] pc_alu_update
);

    assign pc_alu_update = pc + 4'd4; // add 4 to the PC

endmodule