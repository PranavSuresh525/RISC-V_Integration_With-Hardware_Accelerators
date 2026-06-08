`timescale 10ns/1ns
module fifo #(
    parameter DEPTH = 1,
    parameter WIDTH = 8
)(
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    en,
    input  wire signed [WIDTH-1:0] data_in,
    output wire signed [WIDTH-1:0] data_out // Changed to wire
);
    reg signed [WIDTH-1:0] fifo_reg [0:DEPTH-1];
    integer i;

    // Continuous assignment: output reflects the last register immediately
    assign data_out = fifo_reg[DEPTH-1];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                fifo_reg[i] <= {WIDTH{1'b0}};
        end else if (en) begin
            fifo_reg[0] <= data_in;
            for (i = 1; i < DEPTH; i = i + 1)
                fifo_reg[i] <= fifo_reg[i-1];
        end
    end
endmodule