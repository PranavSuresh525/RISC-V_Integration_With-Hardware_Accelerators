`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.06.2026 12:09:30
// Design Name: 
// Module Name: pe
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module pe (
    input  wire              clk,
    input  wire              rst,
    input  wire              weight_en,
    input  wire              pe_en,
    input  wire signed [7:0]  weight_in,
    input  wire signed [7:0]  data_in,
    input  wire signed [15:0] psum_in,
    output reg  signed [7:0]  weight_out,
    output reg  signed [7:0]  data_out,
    output reg  signed [15:0] psum_out
);
    reg signed [7:0] weight_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            weight_reg <= 8'sb0;
            weight_out <= 8'sb0;
            data_out   <= 8'sb0;
            psum_out   <= 16'sb0;
        end else begin
            // weight loads and passes through vertically
            if (weight_en) begin
                weight_reg <= weight_in;
                weight_out <= weight_in; // pass current input, not old reg
            end
            // MAC only when pe_en high
            if (pe_en) begin
                data_out <= data_in;
                psum_out <= psum_in + (weight_reg * data_in);
            end else begin
                psum_out <= psum_in; // pass through unchanged
                data_out <= 8'sb0;
            end
        end
    end
endmodule