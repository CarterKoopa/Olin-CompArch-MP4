//
// Olin Computer Architecture - Mini-Project 4
// RISC-V Microprocessor Implementation
//
// Top-Level Module
//
// This module instantiate and orchestrates all modules needed to implement
// a RISC-V 32i instruction set microprocessor. Additionally, this module
// connects the memory-mapped peripherals in the memory module to the physical
// hardware of the iceBlinkPico FPGA board.

`include "memory/memory.sv"
`include "instruction_decoder.sv"
`include "immed_gen.sv"
`include "reg_file.sv"
`include "alu.sv"
`include "control_unit_2.sv"
`include "pc_alu.sv"
//import instruction_types::*;

module top (
    input logic clk, 
    output logic LED, 
    output logic RGB_R, 
    output logic RGB_G, 
    output logic RGB_B
);

    // Memory interface wires
    logic [31:0] dmem_address;
    logic [31:0] dmem_data_in;
    logic [31:0] dmem_data_out;
    logic [31:0] imem_address;
    logic [31:0] imem_data_out;

    logic reset;
    /*
    logic led;
    logic red;
    logic green;
    logic blue;
    */

    // State registers to hold persistent state across clock cycles
    logic [31:0] pc = 32'h00001000;  // Start at instruction memory base address
    logic [31:0] ir;  // instruction register
    logic [31:0] alu_out_reg;
    logic [31:0] mem_data_reg;
    logic [31:0] reg_a;
    logic [31:0] reg_b;
    logic [31:0] reg_imm;
    logic [31:0] branch_target_reg;

    // Wires between modules that connect module outputs to inputs within same clock cycle
    logic [31:0] next_pc; // eventually when we add next pc logic
    logic [31:0] pc_alu_update; // PC+4 output from pc_alu
    logic [31:0] imm_value;
    logic [4:0] rs1_addr, rs2_addr, rd_addr;
    logic [31:0] rs1_data, rs2_data, rd_data; //rd_data for output from Writeback MUX
    logic [31:0] alu_input_a, alu_input_b, alu_result;
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    // Control signals
    logic pc_src, pc_write, ir_write, reg_write, dmem_wren;
    logic [1:0] alu_src_a, alu_src_b, writeback_src;


    // *Wire Assignments (Connections)*
    
    // Connect PC to instruction memory address
    assign imem_address = pc;
    
    // Connect ALU output register to data memory address
    assign dmem_address = alu_out_reg;
    
    // Connect reg_b (rs2 value) to data memory input for stores
    assign dmem_data_in = reg_b;


    // *Sequential Logic - State Registers*
    always_ff @(posedge clk) begin
        // Update PC when control unit signals
        if (pc_write)
            pc <= next_pc;
        
        // Fetch: Load instruction into instruction register
        if (ir_write)
            ir <= imem_data_out;
        
        // Decode: Save register values and immediate
        reg_a <= rs1_data;
        reg_b <= rs2_data;
        reg_imm <= imm_value;
        
        // Execute: Save ALU result
        alu_out_reg <= alu_result;
        
        // For branches: Save target address from first execute cycle
        // Check if this is a branch instruction (opcode 7'b1100011) and alu_src_a == 00 (PC)
        if (opcode == 7'b1100011 && alu_src_a == 2'b00) begin
            branch_target_reg <= alu_result;
        end
        
        // Memory: Save memory read data
        mem_data_reg <= dmem_data_out;
    end

    // *Module Instantiations*

    
    // Instruction Decoder - takes 32 bit instruction and splits it up
    // Takes: ir
    // Outputs: opcode, rs1_addr, rs2_addr, rd_addr, funct3, funct7
    instruction_decoder inst_decoder (
        .instruction    (ir),
        .opcode         (opcode),
        .rs1            (rs1_addr),
        .rs2            (rs2_addr),
        .rd             (rd_addr),
        .funct3         (funct3),
        .funct7         (funct7)
    );

    // Immediate Generator - extracts and sign-extends immediate values
    // Takes: ir
    // Outputs: imm_value
    immed_gen immed_generator (
        .ir             (ir),
        .imm_value      (imm_value)
    );

    // Register File - reads two registers and writes one register each cycle
    // Takes: clk, rs1_addr, rs2_addr, rd_addr, rd_data, reg_write_enable
    // Outputs: rs1_data, rs2_data
    reg_file register_file (
        .clk                (clk),
        .rs1_addr           (rs1_addr),
        .rs2_addr           (rs2_addr),
        .rd_addr            (rd_addr),
        .rd_data            (rd_data),
        .reg_write_enable   (reg_write),
        .rs1_data           (rs1_data),
        .rs2_data           (rs2_data)
    );

    // ALU - performs arithmetic and logical operations
    // Takes: alu_input_a, alu_input_b, funct3, funct7
    // Outputs: alu_result
    alu arithmetic_unit (
        .input1_value       (alu_input_a),
        .input2_value       (alu_input_b),
        .funct3             (funct3),
        .funct7             (funct7),
        .alu_output_value   (alu_result),
        .op_code            (opcode)
    );

    // PC ALU - adds 4 to the PC
    pc_alu pc_alu_unit (
        .pc                 (pc),
        .pc_alu_update      (pc_alu_update)
    );


    // Control Unit - provides control signals to coordinate processor
    // Takes: clk, opcode, funct3, funct7, alu_out_reg
    // Outputs: ALL control signals
    control_unit controller (
        .clk                (clk),
        .opcode             (opcode),
        .funct3             (funct3),
        .funct7             (funct7),
        .alu_out_reg        (alu_out_reg),
        .pc_write           (pc_write),
        .ir_write           (ir_write),
        .reg_write          (reg_write),
        .dmem_wren          (dmem_wren),
        .alu_src_a          (alu_src_a),
        .alu_src_b          (alu_src_b),
        .writeback_mux      (writeback_src),
        .pc_src             (pc_src)
    );

    // memory - implements both instruction and data memory
    memory #(
        .IMEM_INIT_FILE_PREFIX  ("led_test")
    ) u1 (
        .clk            (clk), 
        .funct3         (funct3), 
        .dmem_wren      (dmem_wren), 
        .dmem_address   (dmem_address), 
        .dmem_data_in   (dmem_data_in), 
        .imem_address   (imem_address), 
        .imem_data_out  (imem_data_out), 
        .dmem_data_out  (dmem_data_out), 
        .reset          (reset), 
        .led            (~LED), 
        .red            (~RGB_R), 
        .green          (~RGB_G), 
        .blue           (~RGB_B)
    );

    // *Multiplexers*
    
    // ALU Source A Mux
    always_comb begin
        case (alu_src_a)
            2'b00: alu_input_a = pc;       // For PC+4 or branch eventual calculations
            2'b01: alu_input_a = reg_a;    // For normal ALU ops with rs1
            default: alu_input_a = 32'd0;
        endcase
    end

    // ALU Source B Mux
    always_comb begin
        case (alu_src_b)
            2'b00: alu_input_b = reg_b;       // For R-type ops (reg + reg)
            2'b01: alu_input_b = 32'd4;       // For PC+4 calculation
            2'b10: alu_input_b = reg_imm;     // For I-type ops (reg + immediate)
            default: alu_input_b = 32'd0;
        endcase
    end

    // Writeback Mux - selects data to write back to register file
    always_comb begin
        case (writeback_src)
            2'b00: rd_data = alu_out_reg;     // For ALU operations (add, sub, and, or, etc.)
            2'b01: rd_data = mem_data_reg;    // For load instructions (lw, lh, lb)
            2'b10: rd_data = reg_imm;         // For lui (load upper immediate)
            2'b11: rd_data = pc_alu_update;   // For jal/jalr (return address = PC+4)
            default: rd_data = 32'd0;
        endcase
    end

    // Program Counter Mux
    always_comb begin
        case (pc_src)
            1'b0: next_pc = pc_alu_update;    // For PC+4 calculation (normal sequential)
            1'b1: begin
                // Check if this is a branch (use saved branch target) or jump (use ALU result)
                if (opcode == 7'b1100011)  // Branch opcode
                    next_pc = branch_target_reg;
                else  // JAL/JALR
                    next_pc = alu_out_reg;
            end
            default: next_pc = 32'd0;
        endcase
    end
endmodule
