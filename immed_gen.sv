'include instruction_types

module immediate_generator (

) (
    input logic [31:0] ir,
    output logic [31:0] imm_value
);

    instruction_types opcode;
    opcode = ir[6:0];

    always_comb begin

        case (opcode) 
            R_TYPE: imm_value = 32'b0;
            I_TYPE: imm_value = ir[31:20];
            S_TYPE: imm_value = {21{ir[31]}, ir[30:25], ir[12:7]};
            B_TYPE: imm_value = {20{ir[31]}, ir[7], ir[30:25], ir[11:8], 1'b0}
            U_TYPE: imm_value = {ir[31:12], 12'b0};
            J_TYPE: imm_value = {ir[31], ir[19:12], ir[20], ir[30:21], 1'b0}
            default: 
        endcase

    end



    
endmodule