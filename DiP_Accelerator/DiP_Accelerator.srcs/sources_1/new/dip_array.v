`timescale 1ns /1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.06.2026 12:09:30
// Design Name: 
// Module Name: dip_array
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

module dip_array #(
    parameter N = 8
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        weight_en,
    input  wire        pe_en,
    // single column of weights loaded per cycle
    input  wire signed [7:0] weight_in [0:N-1],

    //  column of A fed per cycle from west edge
    // one element per row, already staggered by FIFOs
    input  wire signed [7:0] data_in [0:N-1],

    // N results from bottom row
    output wire signed [15:0] result [0:N-1]
);

wire signed [15:0] psum_wire   [0:N][0:N-1];
wire signed [7:0]  data_wire   [0:N-1][0:N];
wire signed [7:0]  weight_wire [0:N][0:N-1];

genvar i,j,j0,m,n;

generate
for ( n=0; n<N; n=n+1) begin: boundry_gen
    assign psum_wire[0][n] = 16'sb0; // initial psum is zero
    assign weight_wire[0][n] = weight_in[n]; // feed weights into top row
end
endgenerate

// declare PE array
// Row 0: feeds directly from data_in
generate
    for (j0 = 0; j0 < N; j0 = j0 + 1) begin : row0
        pe pe_inst (
            .clk       (clk),
            .rst       (rst),
            .weight_en (weight_en),
            .pe_en     (pe_en),
            .weight_in (weight_in[j0]),
            .data_in   (data_in[j0]),
            .psum_in   (psum_wire[0][j0]),
            .weight_out(weight_wire[1][j0]),
            .data_out  (data_wire[0][j0+1]),
            .psum_out  (psum_wire[1][j0])
        );
    end
endgenerate

// Rows 1 to N-1: diagonal input from row above
generate
    for (i = 1; i < N; i = i + 1) begin : row_gen
        for (j = 0; j < N; j = j + 1) begin : col_gen
            pe pe_inst (
                .clk       (clk),
                .rst       (rst),
                .weight_en (weight_en),
                .pe_en     (pe_en),
                .weight_in (weight_wire[i][j]),
                .data_in   (data_wire[i-1][((j+1) % N) + 1]),
                .psum_in   (psum_wire[i][j]),
                .weight_out(weight_wire[i+1][j]),
                .data_out  (data_wire[i][j+1]),
                .psum_out  (psum_wire[i+1][j])
            );
        end
    end
endgenerate

generate
for ( m=0; m<N; m=m+1) begin: out_gen
    assign result[m] = psum_wire[N][m];
end
endgenerate

endmodule

