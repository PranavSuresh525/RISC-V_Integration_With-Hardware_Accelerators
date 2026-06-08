`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.06.2026 11:44:55
// Design Name: 
// Module Name: ws_array
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

module ws_array #(
    parameter N = 8
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        weight_en,
    input  wire        pe_en,
    input  wire signed [7:0] weight_in [0:N-1],
    input  wire signed [7:0] data_in   [0:N-1], // one element per row per cycle
    output wire signed [15:0] result   [0:N-1]
);

    wire signed [15:0] psum_wire   [0:N][0:N-1];
    wire signed [7:0]  data_wire   [0:N-1][0:N];
    wire signed [7:0]  weight_wire [0:N][0:N-1];
    wire signed [7:0]  data_delayed[0:N-1];

    // --- PE grid ---
    genvar i, j;
    generate
        for (i = 0; i < N; i = i + 1) begin : row_gen
            for (j = 0; j < N; j = j + 1) begin : col_gen
                pe pe_inst (
                    .clk       (clk),
                    .rst       (rst),
                    .weight_en (weight_en),
                    .pe_en     (pe_en),
                    .weight_in ((i == 0) ? weight_in[j] : weight_wire[i][j]),
                    .data_in   (data_wire[i][j]),
                    .psum_in   (psum_wire[i][j]),
                    .weight_out(weight_wire[i+1][j]),
                    .data_out  (data_wire[i][j+1]),
                    .psum_out  (psum_wire[i+1][j])
                );
            end
        end
    endgenerate

    // --- Boundary conditions ---
    genvar m;
    generate
        for (m = 0; m < N; m = m + 1) begin : boundary_gen
            assign psum_wire[0][m]   = 16'sb0;
            assign weight_wire[0][m] = weight_in[m];
        end
    endgenerate

    // --- Input FIFOs ---
    // row 0 gets data directly, no delay needed
    assign data_wire[0][0] = data_in[0];

    genvar k;
    generate
        for (k = 1; k < N; k = k + 1) begin : fifo_in_gen
            fifo #(.DEPTH(k), .WIDTH(8)) in_fifo (
                .clk     (clk),
                .rst     (rst),
                .en      (pe_en),
                .data_in (data_in[k]),      // each row gets its own stream
                .data_out(data_delayed[k])
            );
            assign data_wire[k][0] = data_delayed[k];
        end
    endgenerate

    // --- Output FIFOs: deskew results ---
    // col 0 needs depth N-1=7, col N-2 needs depth 1, col N-1 needs depth 0
    genvar p;
    generate
        for (p = 0; p < N; p = p + 1) begin : fifo_out_gen
            if (p == N-1) begin : last_col
                assign result[p] = psum_wire[N][p];
            end else begin : other_cols
                fifo #(.DEPTH(N-1-p), .WIDTH(16)) out_fifo (
                    .clk     (clk),
                    .rst     (rst),
                    .en      (pe_en),
                    .data_in (psum_wire[N][p]),
                    .data_out(result[p])
                );
            end
        end
    endgenerate

endmodule
