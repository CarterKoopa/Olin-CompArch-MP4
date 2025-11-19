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

    always_ff @(posedge clk) begin
        if (reg_write_enable && rd_addr != 5'd0) begin
            regs[rd_addr] <= rd_data;
        end
    end

    assign rs1_data = (rs1_addr != 5'd0) ? regs[rs1_addr] : 32'd0;
    assign rs2_data = (rs2_addr != 5'd0) ? regs[rs2_addr] : 32'd0;


endmodule


