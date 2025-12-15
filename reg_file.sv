//
// Olin Computer Architecture - Mini-Project 4
// RISC-V Microprocessor Implementation
//
// Register File
//
// This module implements the 32, 32-bit registers available, in addition to
// enabling reading and writing to these registers.

module reg_file (
    input clk,
    input logic[4:0] rs1_addr,
    input logic[4:0] rs2_addr,
    input logic[4:0] rd_addr,
    input logic[31:0] rd_data,
    input logic reg_write_enable,
    output logic[31:0] rs1_data,
    output logic[31:0] rs2_data
);

    logic[31:0] regs[31:0];

    initial begin
        for (int i = 0; i < 32; i++) begin
            regs[i] = 32'd0;
        end
    end

    always_ff @(posedge clk) begin
        if (reg_write_enable && rd_addr != 5'd0) begin
            regs[rd_addr] <= rd_data;
        end
    end

    assign rs1_data = (rs1_addr != 5'd0) ? regs[rs1_addr] : 32'd0;
    assign rs2_data = (rs2_addr != 5'd0) ? regs[rs2_addr] : 32'd0;


    //First 11 registers declared so they can be analyzed in simulation
    logic[31:0] reg0;
    assign reg0 = regs[0];

    logic[31:0] reg1;
    assign reg1 = regs[1];

    logic[31:0] reg2;
    assign reg2 = regs[2];

    logic[31:0] reg3;
    assign reg3 = regs[3];

    logic[31:0] reg4;
    assign reg4 = regs[4];

    logic[31:0] reg5;
    assign reg5 = regs[5];

    logic[31:0] reg6;
    assign reg6 = regs[6];

    logic[31:0] reg7;
    assign reg7 = regs[7];

    logic[31:0] reg8;
    assign reg8 = regs[8];

    logic[31:0] reg9;
    assign reg9 = regs[9];

    logic[31:0] reg10;
    assign reg10 = regs[10];
endmodule


