//
// Olin Computer Architecture - Mini-Project 4
// RISC-V Microprocessor Implementation
//
// Control Module - Version 2
//
// This module serves to implement the main finite state machine and implement
// read/write protection for the various modules.
//
// This implementation is refactored to use the instruction_type enum and case
// statement-based logic for greater synthesis capability.
module control_unit (
    input logic clk,
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic [31:0] alu_out_reg,
    
    // Control signal outputs
    output logic pc_write,
    output logic ir_write,
    output logic reg_write,
    output logic dmem_wren,
    output logic [1:0] alu_src_a,
    output logic [1:0] alu_src_b,
    output logic [1:0] writeback_mux,
    output logic pc_src
);

    // FSM States
    typedef enum logic [2:0] {
        FETCH     = 3'b000,
        DECODE    = 3'b001,
        EXECUTE   = 3'b010,
        MEMORY    = 3'b011,
        WRITEBACK = 3'b100
    } state_t;
    
    state_t current_state = FETCH;
    state_t next_state = FETCH;

    // Track if we're in the second execute cycle for branches
    logic in_branch_execute2 = 1'b0;

    // Instruction type decode (based on opcode)
    //
    // TODO: implement this to use the same enum structure as is in 
    //
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

    instruction_type current_i_type;
    assign current_i_type = instruction_type'(opcode);
    // assign current_i_type = (opcode);
    
    always_ff @(posedge clk) begin  
        // Track if we're in the second execute cycle for branches
        if (current_state == EXECUTE && current_i_type == B_TYPE && !in_branch_execute2) begin
            current_state <= next_state;
            in_branch_execute2 <= 1'b1;
        end
        else begin
            current_state <= next_state;
            in_branch_execute2 <= 1'b0;
        end
    end

    // Next state logic
    always_comb begin
        case (current_state)
            FETCH: begin
                next_state = DECODE;
            end
            
            DECODE: begin
                next_state = EXECUTE;
            end
            
            EXECUTE: begin
                case(current_i_type)
                    B_TYPE: begin
                        if(in_branch_execute2) begin
                            next_state = WRITEBACK;
                        end
                        else begin
                            next_state = EXECUTE;
                        end
                    end
                    LOAD_TYPE: begin
                        next_state = MEMORY;
                    end
                    S_TYPE: begin
                        next_state = MEMORY;
                    end
                    default: begin
                        next_state = WRITEBACK;
                    end
                endcase
            end
            
            MEMORY: begin
                next_state = WRITEBACK;
            end
            
            WRITEBACK: begin
                next_state = FETCH;
            end
            
            default: begin
                next_state = FETCH;
            end
        endcase
    end

    // Control signal outputs based on current state
    always_comb begin
        // Default values (all disabled)
        pc_write = 1'b0;
        ir_write = 1'b0;
        reg_write = 1'b0;
        dmem_wren = 1'b0;
        alu_src_a = 2'b00;
        alu_src_b = 2'b00;
        writeback_mux = 2'b00;
        pc_src = 1'b0;

        case (current_state)
            FETCH: begin
                // Load instruction from memory into IR
                ir_write = 1'b1;
            end
            
            DECODE: begin
                // Register file reads happen automatically (combinational)
                // Immediate generation happens automatically (combinational)
                // Just wait for values to propagate and get saved in always_ff block
            end
            
            EXECUTE: begin
                // Configure ALU inputs based on instruction type
                case (current_i_type)
                    R_TYPE: begin
                        // R-type: ALU op with two registers
                        alu_src_a = 2'b01;  // reg_a (rs1)
                        alu_src_b = 2'b00;  // reg_b (rs2)
                    end
                    I_TYPE: begin
                        // I-type or Load: ALU op with register + immediate
                        alu_src_a = 2'b01;  // reg_a (rs1)
                        alu_src_b = 2'b10;  // reg_imm (immediate)
                    end
                    LOAD_TYPE: begin
                        // I-type or Load: ALU op with register + immediate
                        alu_src_a = 2'b01;  // reg_a (rs1)
                        alu_src_b = 2'b10;  // reg_imm (immediate)
                    end
                    S_TYPE: begin
                        // Store: Calculate address = reg_a + immediate
                        alu_src_a = 2'b01;  // reg_a (rs1 = base address)
                        alu_src_b = 2'b10;  // reg_imm (offset)
                    end
                    B_TYPE: begin
                        if (!in_branch_execute2) begin
                            // First execute cycle: Calculate target = PC + immediate
                            alu_src_a = 2'b00;  // PC
                            alu_src_b = 2'b10;  // reg_imm (branch offset)
                        end
                        else begin
                            // Second execute cycle: Compare rs1 vs rs2 for branch condition
                            alu_src_a = 2'b01;  // reg_a (rs1)
                            alu_src_b = 2'b00;  // reg_b (rs2)
                        end
                    end
                    JAL: begin
                        // JAL: Calculate target = PC + immediate
                        alu_src_a = 2'b00;  // PC
                        alu_src_b = 2'b10;  // reg_imm (jump offset)
                    end
                    JALR: begin
                        // JALR: Calculate target = reg_a + immediate
                        alu_src_a = 2'b01;  // reg_a (rs1)
                        alu_src_b = 2'b10;  // reg_imm (offset)
                    end
                    LUI: begin
                        alu_src_a = 2'b00; // not used
                        alu_src_b = 2'b00; // not used
                    end
                    AUIPC: begin
                        // AUIPC: PC + immediate
                        alu_src_a = 2'b00;  // PC
                        alu_src_b = 2'b10;  // reg_imm (immediate)
                    end
                    default: begin
                        // AUIPC: PC + immediate
                        alu_src_a = 2'b00;  // PC
                        alu_src_b = 2'b10;  // reg_imm (immediate)
                    end

                endcase
                    
            end
            
            MEMORY: begin
                case(current_i_type)
                    LOAD_TYPE: begin
                        // Load: Read from memory
                        // Address is in alu_out_reg, data will go to mem_data_reg
                        dmem_wren = 1'b0;
                    end
                    S_TYPE: begin
                        // Store: Write to memory
                        // Address is in alu_out_reg, data is in reg_b
                        dmem_wren = 1'b1;
                    end
                endcase
            end
            
            WRITEBACK: begin
                case(current_i_type)
                    JAL: begin
                        pc_src = 1'b1;  // Jump to ALU result (target address)
                        pc_write = 1'b1;
                        writeback_mux = 2'b11;
                        reg_write = 1'b1;
                    end
                    JALR: begin
                        pc_src = 1'b1;  // Jump to ALU result (target address)
                        pc_write = 1'b1;
                        writeback_mux = 2'b11;
                        reg_write = 1'b1;
                    end
                    B_TYPE: begin
                        pc_src = 1'b1;
                        pc_write = 1'b1;
                    end
                    LOAD_TYPE: begin
                        pc_write = 1'b1;
                        reg_write = 1'b1;
                        writeback_mux = 2'b01;
                    end
                    LUI: begin
                        reg_write = 1'b1;
                        pc_write = 1'b1;
                        writeback_mux = 2'b10;
                    end
                    default: begin
                        writeback_mux = 2'b00;
                        pc_write = 1'b1;
                        reg_write = 1'b1;
                    end
                endcase
            end
            
            default: begin
                // Keep all signals at default values
            end
        endcase
    end

endmodule

