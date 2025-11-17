module immed_gen (
    input logic [31:0] ir,
    output logic [31:0] imm_value
);

    typedef enum logic [6:0] {
        R_TYPE    = 7'b0110011,
        I_TYPE    = 7'b0010011,
        LOAD_TYPE = 7'b0000011,
        S_TYPE    = 7'b0100011,
        B_TYPE    = 7'b1100011,
        JAL       = 7'b1101111,
        JALR      = 7'b1100111, 
        LUI       = 7'b0110111,
        AUIPC     = 7'b0010111
    } instruction_type;

    instruction_type opcode;
    assign opcode = ir[6:0];

    always_comb begin

        case (opcode) 
            R_TYPE:  imm_value = 32'b0;
            I_TYPE:  imm_value = {{20{ir[31]}}, ir[31:20]};
            S_TYPE:  imm_value = {{20{ir[31]}}, ir[31:25], ir[11:7]};
            B_TYPE:  imm_value = {{20{ir[31]}}, ir[7], ir[30:25], ir[11:8], 1'b0};
            LUI, AUIPC:  imm_value = {ir[31:12], 12'b0};
            JAL:  imm_value = {{12{ir[31]}}, ir[19:12], ir[20], ir[30:21], 1'b0};
            default: imm_value = 32'b0;
        endcase

    end



    
endmodule