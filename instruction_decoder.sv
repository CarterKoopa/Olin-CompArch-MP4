`include "instruction_types"

module instruction_decoder #(
    
) (
    input logic clk,
    input logic[31:0] instruction,
    output logic[6:0] opcode,
    output logic[19:15] rs1,
    output logic[24:20] rs2,
    output logic[11:9] rd,
    output logic[14:12] funct3,
    output logic[30] funct7,
    output logic need_immed
);

    // Parse instruction
    assign opcode = instruction[6:0];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign rd = instruction[11:9];
    assign funct7 = instruction[30];
    assign funct3 = instruction[14:12];

    // Determine if the immed gen is needed based off what instruction type it is
    always_comb begin
        if(opcode == I_TYPE || opcode == U_TYPE || opcode == J_TYPE)
            need_immed = 1'b1;
    end else begin
        need_immed = 1'b0;
    end
    


endmodule