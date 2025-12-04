//
// Olin Computer Architecture - Mini-Project 4
// RISC-V Microprocessor Implementation
//
// Control Module
//
// This module serves to implement the main finite state machine and implement
// read/write protection for the various modules.
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
    
    state_t current_state, next_state;

    // Track if we're in the second execute cycle for branches
    logic in_branch_execute2;

    // Instruction type decode (based on opcode)
    //
    // TODO: implement this to use the same enum structure as is in 
    //
    localparam [6:0] OP_R_TYPE    = 7'b0110011;  // R-type: add, sub, and, or, etc.
    localparam [6:0] OP_I_TYPE    = 7'b0010011;  // I-type: addi, andi, ori, etc.
    localparam [6:0] OP_LOAD      = 7'b0000011;  // Load: lw, lh, lb
    localparam [6:0] OP_STORE     = 7'b0100011;  // Store: sw, sh, sb
    localparam [6:0] OP_BRANCH    = 7'b1100011;  // Branch: beq, bne, blt, bge
    localparam [6:0] OP_JAL       = 7'b1101111;  // Jump and link
    localparam [6:0] OP_JALR      = 7'b1100111;  // Jump and link register
    localparam [6:0] OP_LUI       = 7'b0110111;  // Load upper immediate (20-bits instead of normal 12)
    localparam [6:0] OP_AUIPC     = 7'b0010111;  // Add upper immediate to PC

    // Helper signals to identify instruction types
    logic is_r_type, is_i_type, is_load, is_store, is_branch, is_jal, is_jalr, is_lui, is_auipc;
    
    assign is_r_type = (opcode == OP_R_TYPE);
    assign is_i_type = (opcode == OP_I_TYPE);
    assign is_load   = (opcode == OP_LOAD);
    assign is_store  = (opcode == OP_STORE);
    assign is_branch = (opcode == OP_BRANCH);
    assign is_jal    = (opcode == OP_JAL);
    assign is_jalr   = (opcode == OP_JALR);
    assign is_lui    = (opcode == OP_LUI);
    assign is_auipc  = (opcode == OP_AUIPC);

    // State register - initialize to FETCH
    initial begin
        current_state = FETCH;
        in_branch_execute2 = 1'b0;
    end
    
    always_ff @(posedge clk) begin
        current_state <= next_state;
        
        // Track if we're in the second execute cycle for branches
        if (current_state == EXECUTE && is_branch && !in_branch_execute2) begin
            in_branch_execute2 <= 1'b1;
        end
        else begin
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
                // If branch and in first execute cycle, stay in EXECUTE for second cycle
                if (is_branch && !in_branch_execute2)
                    next_state = EXECUTE;
                // If load or store, go to MEMORY stage
                else if (is_load || is_store)
                    next_state = MEMORY;
                else
                    next_state = WRITEBACK;
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
                
                if (is_r_type) begin
                    // R-type: ALU op with two registers
                    alu_src_a = 2'b01;  // reg_a (rs1)
                    alu_src_b = 2'b00;  // reg_b (rs2)
                end
                else if (is_i_type || is_load) begin
                    // I-type or Load: ALU op with register + immediate
                    alu_src_a = 2'b01;  // reg_a (rs1)
                    alu_src_b = 2'b10;  // reg_imm (immediate)
                end
                else if (is_store) begin
                    // Store: Calculate address = reg_a + immediate
                    alu_src_a = 2'b01;  // reg_a (rs1 = base address)
                    alu_src_b = 2'b10;  // reg_imm (offset)
                end
                else if (is_branch) begin
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
                else if (is_jal) begin
                    // JAL: Calculate target = PC + immediate
                    alu_src_a = 2'b00;  // PC
                    alu_src_b = 2'b10;  // reg_imm (jump offset)
                end
                else if (is_jalr) begin
                    // JALR: Calculate target = reg_a + immediate
                    alu_src_a = 2'b01;  // reg_a (rs1)
                    alu_src_b = 2'b10;  // reg_imm (offset)
                end
                else if (is_lui) begin
                    alu_src_a = 2'b00; // not used
                    alu_src_b = 2'b00; // not used
                end
                else if (is_auipc) begin
                    // AUIPC: PC + immediate
                    alu_src_a = 2'b00;  // PC
                    alu_src_b = 2'b10;  // reg_imm (immediate)
                end
            end
            
            MEMORY: begin
                if (is_load) begin
                    // Load: Read from memory
                    // Address is in alu_out_reg, data will go to mem_data_reg
                    dmem_wren = 1'b0;
                end
                else if (is_store) begin
                    // Store: Write to memory
                    // Address is in alu_out_reg, data is in reg_b
                    dmem_wren = 1'b1;
                end
            end
            
            WRITEBACK: begin
                // Update PC (always happens)
                pc_write = 1'b1;
                
                // Select next PC value
                if (is_jal || is_jalr) begin
                    pc_src = 1'b1;  // Jump to ALU result (target address)
                end
                else if (is_branch && (alu_out_reg != 32'd0)) begin
                    // Branch taken if comparison result is non-zero
                    pc_src = 1'b1;  // Use branch target from saved register
                end
                else begin
                    pc_src = 1'b0;  // PC+4 (sequential)
                end
                
                // Write to register file (except for stores and branches)
                if (!is_store && !is_branch) begin
                    reg_write = 1'b1;
                    
                    // Select writeback source
                    if (is_load) begin
                        writeback_mux = 2'b01;  // mem_data_reg
                    end
                    else if (is_lui) begin
                        writeback_mux = 2'b10;  // reg_imm (immediate value)
                    end
                    else if (is_jal || is_jalr) begin
                        writeback_mux = 2'b11;  // PC+4 (return address)
                    end
                    else begin
                        writeback_mux = 2'b00;  // alu_out_reg (default for R-type, I-type)
                    end
                end
            end
            
            default: begin
                // Keep all signals at default values
            end
        endcase
    end

endmodule

