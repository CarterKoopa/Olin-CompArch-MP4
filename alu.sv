//
// Olin Computer Architecture - Mini-Project 4
// RISC-V Microprocessor Implementation
//
// Arithmetic Logic Unit
import instruction_types::*;

module alu (
    input logic [6:0] funct7,
    input logic [2:0] funct3,
    input logic [31:0] input1_value,
    input logic [31:0] input2_value,
    input logic [6:0] op_code,
    output [31:0] alu_output_value
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

    instruction_type current_instruction_type;
    assign current_instruction_type = op_code;
    // This always_comb block computes outputs for all R and I type instructions
    // For these two instruction types, there is parity in the meaning of the
    // funct7 and funct3 codes. In the other instruction types, values of these
    // function codes begin to take on new meanings depending on the instruction
    // type (defined by the op code). While this could later be implemented in
    // this module rather easily, for right now, we're choosing the abstract
    // away the instruction type from this module and do that processing
    // elsewhere.
    always_comb begin
        // funct3 is the main controller of what mathematical operator is
        // carried out, with funct7 setting a variant of that operator for
        // some. As such, use a case statement with later if statements for
        // checking the funct3 and funct7 values, respectively.
        case (current_instruction_type)
            R_TYPE:
                case (funct3)
                    3'h0:
                        if(funct7 == 7'h0) begin
                            alu_output_value = input1_value + input2_value;
                        end
                        else begin
                            alu_output_value = input1_value - input2_value;
                        end
                    3'h4:
                        // XOR bitwise
                        alu_output_value = input1_value ^ input2_value;
                    3'h6:
                        // OR bitwise
                        alu_output_value = input1_value | input2_value;
                    3'h7:
                        // AND bitwise
                        alu_output_value = input1_value & input2_value;
                    3'h1:
                        // Shift left logical
                        alu_output_value = input1_value << input2_value;
                    3'h5:
                        if(funct7 == 7'h0) begin
                            // Shift right logical
                            alu_output_value = input1_value >> input2_value;
                        end
                        else begin
                            // Shift right arithmetic 
                            alu_output_value = input1_value >>> input2_value;
                        end
                    3'h2:
                        // Set less than
                        alu_output_value = (input1_value < input2_value);
                    3'h3:
                        // Set less than unsigned
                        alu_output_value = (input1_value < input2_value);
                    default:
                        alu_output_value = 0;
                endcase
            I_TYPE:
                case (funct3)
                    3'h0:
                        // Addition
                        alu_output_value = input1_value + input2_value;
                    3'h4:
                        // XOR bitwise
                        alu_output_value = input1_value ^ input2_value;
                    3'h6:
                        // OR bitwise
                        alu_output_value = input1_value | input2_value;
                    3'h7:
                        // AND bitwise
                        alu_output_value = input1_value & input2_value;
                    3'h1:
                        // Shift left logical
                        alu_output_value = input1_value << input2_value;
                    3'h5:
                        if(input2_value[11:5] == 7'h0) begin
                            // Shift right logical
                            alu_output_value = input1_value >> input2_value[4:0];
                        end
                        else begin
                            // Shift right arithmetic 
                            alu_output_value = input1_value >>> input2_value[4:0];
                        end
                    3'h2:
                        // Set less than
                        alu_output_value = (input1_value < input2_value);
                    3'h3:
                        // Set less than unsigned
                        alu_output_value = (input1_value < input2_value);
                    default:
                        alu_output_value = 32'b0;
                endcase
            LOAD_TYPE, S_TYPE:
                // All loading just adds the immediate to rs1; slicing depending
                // on the load length happens externally.
                alu_output_value = input1_value + input2_value;
            B_TYPE:
                case (funct3)
                    3'h0:
                        // Branch ==
                        alu_output_value = (input1_value == input2_value) ? 32'hFFFFFF : 32'h0;
                    3'h1:
                        // Branch !=
                        alu_output_value = (input1_value != input2_value) ? 32'hFFFFFF : 32'h0;
                    3'h4:
                        // Branch <
                        alu_output_value = (input1_value < input2_value) ? 32'hFFFFFF : 32'h0;
                    3'h5:
                        // Branch >=
                        alu_output_value = (input1_value >= input2_value) ? 32'hFFFFFF : 32'h0;
                    3'h6:
                        // Branch < (Unsigned)
                        alu_output_value = (input1_value < input2_value) ? 32'hFFFFFF : 32'h0;
                    3'h7:
                        // Branch >= (Unsigned)
                        alu_output_value = (input1_value >= input2_value) ? 32'hFFFFFF : 32'h0;
                    default:
                        alu_output_value = 32'b0;
                endcase
            JAL, JALR:
                alu_output_value = input1_value + input2_value;
            LUI:
                alu_output_value = input1_value << 12;
            AUIPC:
                alu_output_value = input1_value + (input2_value << 12);
            default:
                alu_output_value = 32'b0;
        endcase
    end

endmodule