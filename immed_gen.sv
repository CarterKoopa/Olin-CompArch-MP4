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
    assign opcode = instruction_type'(ir[6:0]);

    logic sign_bit;
    assign sign_bit = ir[31];

    logic [11:0] i_type_immed;
    assign i_type_immed = ir[31:20];

    logic [6:0] s_type_immed_1;
    logic [4:0] s_type_immed_2;
    assign s_type_immed_1 = ir[31:25];
    assign s_type_immed_2 = ir[11:7];

    logic b_type_immed_1;
    logic [5:0] b_type_immed_2;
    logic [3:0] b_type_immed_3;
    assign b_type_immed_1 = ir[7];
    assign b_type_immed_2 = ir[30:25];
    assign b_type_immed_3 = ir[11:8];

    logic [19:0] lui_immed;
    assign lui_immed = ir[31:12];

    logic [7:0] jal_immed_1;
    logic jal_immed_2;
    logic [9:0] jal_immed_3;
    assign jal_immed_1 = ir[19:12];
    assign jal_immed_2 = ir[20];
    assign jal_immed_3 = ir[30:21];


    always_comb begin
        case (opcode) 
            R_TYPE:  imm_value = 32'b0;
            I_TYPE:  imm_value = {{20{sign_bit}}, i_type_immed};
            S_TYPE:  imm_value = {{20{sign_bit}}, s_type_immed_1, s_type_immed_2};
            B_TYPE:  imm_value = {{20{sign_bit}}, b_type_immed_1, b_type_immed_2, b_type_immed_3, 1'b0};
            LUI, AUIPC:  imm_value = {lui_immed, 12'b0};
            JAL:  imm_value = {{12{sign_bit}}, jal_immed_1, jal_immed_2, jal_immed_3, 1'b0};
            default: imm_value = 32'b0;
        endcase

    end



    
endmodule