//
// Olin Computer Architecture - Mini-Project 4
// RISC-V Microprocessor Implementation
//
// Arithmetic Logic Unit

module alu (
    parameter TEST;
)(
    input logic [6:0] funct7,
    input logic [2:0] funct3,
    input logic [31:0] input1_value,
    input logic [31:0] input2_value
    input logic [31:0] immed_input,
    input logic immed_select,
    output [31:0] alu_output_value
);

    // Implement multiplexer for either taking the second value to be the 
    // register input or immediate generator output, based on a flag set
    // externally based on the current instruction type.
    logic [31:0] current_input2;
    assign current_input2 = immed_select ? immed_input : input2_value;

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
        case funct3
            3'h0:
                if(funct7 == 7'h0) begin
                    alu_output_value = input1_value + current_input2;
                end
                else begin
                    alu_output_value = input1_value - current_input2;
                end
            3'h4:
                // XOR bitwise
                alu_output_value = input1_value ^ current_input2;
            3'h6:
                // OR bitwise
                alu_output_value = input1_value | current_input2;
            3'h7:
                // AND bitwise
                alu_output_value = input1_value & current_input2;
            3'h1:
                // Shift left logical
                alu_output_value = input1_value << current_input2;
            3'h5:
                if(funct7 == 7'h0) begin
                    // Shift right logical
                    alu_output_value = input1_value >> current_input2;
                end
                else begin
                    // Shift right arithmetic 
                    alu_output_value = input1_value >>> current_input2;
                end
            3'h2:
                // Set less than
                alu_output_value = (input1_value < input2_value)
            3'h3:
                // Set less than unsigned
                alu_output_value = (input1_value < input2_value)
            default:
                alu_output_value = 0;
        endcase
    end

endmodule