module program_counter #( 

) (
    input clk,
    input logic increment_en,
    input logic[31:0] current_pc
    output logic[31:0] next_pc
);


// I'm not sure it makes sense for this module to handle jumps and branch logic
// With he architecture we are following, those operations seem external to
// what the PC actually tracks. Like then this module would be responsible for 
// decoding instruction bits and doing timing for when to write

// just sequential logic: on posedge clock if increment_en, next_pc = current_pc?

    always_ff @(posedge clk) begin
        if(increment_en) begin
            next_pc <= current_pc;
        end
    end

endmodule