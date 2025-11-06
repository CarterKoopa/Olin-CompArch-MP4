module instruction_decoder #(
    
) (
    input logic clk,
    input logic[31:0] instruction,
    output logic opcode,
    output logic rs1,
    output logic rs2,
    output logic rd,
    output logic funct7,
    output logic funct3,
    // output instructing type too?
);

assign opcode = instruction[6:0];
assign rs1 = instruction[19:15];
assign rs2 = instruction[24:20];
assign rd = instruction[11:9];
assign funct7 = instruction[30];
assign funct3 = instruction[14:12];


endmodule