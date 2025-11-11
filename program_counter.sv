module program_counter #( 

) (
    input clk,
    input logic increment_en,
    input logic[31:0] next_pc,
    output logic[31:0] current_pc
);

    always_ff @(posedge clk) begin
        if(increment_en) begin
            current_pc <= next_pc;
        end
    end

endmodule