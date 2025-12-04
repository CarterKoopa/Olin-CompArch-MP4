// This package attempted to define a common enum for use across modules
// so the raw op code did not need to be passed (for easier code visibility &
// troubleshooting, given they take the same logic space). However, the current
// Yosys/iverlog implementation does not support this functionality completely.
package instruction_types

    typedef enum logic [6:0] {
        R_TYPE    = 7'b0110011,
        I_TYPE    = 7'b0010011,
        LOAD_TYPE = 7'b0000011,
        S_TYPE    = 7'b0100011,
        B_TYPE    = 7'b1100011,
        JAL       = 7'b1101111,
        JALR      = 7'b1100111, 
        LUI       = 7'b0110111,
        AUIPI     = 7'b0010111
    } instruction_type;

endpackage