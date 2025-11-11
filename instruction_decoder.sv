`include "instruction_types"

module instruction_decoder #(
    
) (
    input logic[31:0] instruction,
    output logic[6:0] opcode,
    output logic[4:0] rs1,
    output logic[4:0] rs2,
    output logic[4:0] rd,
    output logic[2:0] funct3,
    output logic[6:0] funct7,
    output logic is_r_type,
    output logic is_i_type,
    output logic is_s_type,
    output logic is_b_type,
    output logic is_u_type,
    output logic is_j_type
);

    // Parse instruction
    assign opcode = instruction[6:0];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign rd = instruction[11:9];
    assign funct7 = instruction[31:25];
    assign funct3 = instruction[14:12];


    // Determine instruction type
    assign is_r_type = (opcode == R_TYPE);
    assign is_i_type = (opcode == I_TYPE);
    assign is_s_type = (opcode == S_TYPE);
    assign is_b_type = (opcode == B_TYPE);
    assign is_u_type = (opcode == U_TYPE);
    assign is_j_type = (opcode == J_TYPE);


endmodule