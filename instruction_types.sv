package instruction_types

typedef enum logic [6:0] {
    R_TYPE = 7'b0110011,
    I_TYPE = 7'b0010011,
    S_TYPE = 7'b0100011,
    B_TYPE = 7'b1100011,
    J_TYPE = 7'b1101111,
    U_TYPE = 7'b0110111
} instruction_types;

endpackage