`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.06.2026 12:12:30
// Design Name: 
// Module Name: dip_array_tb
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

module dip_tb;

    parameter N = 8;

    reg clk;
    reg rst;
    reg weight_en;
    reg pe_en;
    reg signed [7:0] weight_in [0:N-1];
    reg signed [7:0] data_in [0:N-1];
    wire signed [15:0] result [0:N-1];

    // Instantiate DiP Array
    dip_array #(.N(N)) uut (
        .clk(clk),
        .rst(rst),
        .weight_en(weight_en),
        .pe_en(pe_en),
        .weight_in(weight_in),
        .data_in(data_in),
        .result(result)
    );

    // Matrix Storage
    reg signed [7:0]  matrix_A [0:N-1][0:N-1];
    reg signed [7:0]  matrix_B [0:N-1][0:N-1];
    reg signed [7:0]  dip_matrix_B [0:N-1][0:N-1]; // Permuted Weights 
    reg signed [15:0] expected_C [0:N-1][0:N-1];
    reg signed [15:0] hw_result  [0:N-1][0:N-1];

    integer r, c, k, cycle, out_row, mismatch_count;

    always #1 clk = ~clk;

    initial begin
        // -------------------------------------------------------------------------
        // 1. INITIALIZATION & TEST VECTOR SETUP
        // -------------------------------------------------------------------------
        clk = 0; rst = 1; weight_en = 0; pe_en = 0; out_row = 0; mismatch_count = 0;
        
        for (r = 0; r < N; r = r + 1) begin
            weight_in[r] = 0; data_in[r] = 0;
            for (c = 0; c < N; c = c + 1) begin
                expected_C[r][c] = 0;
                hw_result[r][c] = 0;
                
                // Dense test vectors
                matrix_A[r][c] = (r * N) + c + 1; 
                matrix_B[r][c] = (r * 2) + c - 3; 
            end
        end
        #4; rst = 0; #2;

        // -------------------------------------------------------------------------
        // 2. SOFTWARE MATH & DIP WEIGHT PERMUTATION
        // -------------------------------------------------------------------------
        for (r = 0; r < N; r = r + 1) begin
            for (c = 0; c < N; c = c + 1) begin
                // Standard Software MatMul
                for (k = 0; k < N; k = k + 1) begin
                    expected_C[r][c] = expected_C[r][c] + (matrix_A[r][k] * matrix_B[k][c]);
                end
                
                // DiP Magic: Cyclically shift weights upwards to match diagonal flow
                dip_matrix_B[r][c] = matrix_B[(r + c) % N][c];
            end
        end

        // -------------------------------------------------------------------------
        // 3. LOAD PERMUTED WEIGHTS
        // -------------------------------------------------------------------------
        $display("[TB] Loading Permuted Weights...");
        weight_en = 1;
        for (r = N-1; r >= 0; r = r - 1) begin
            for (c = 0; c < N; c = c + 1) weight_in[c] = dip_matrix_B[r][c];
            #2;
        end
        weight_en = 0;
        for (c = 0; c < N; c = c + 1) weight_in[c] = 0;
        #2;

        // -------------------------------------------------------------------------
        // 4. COMPUTE PHASE (ZERO INPUT FIFOS REQUIRED)
        // -------------------------------------------------------------------------
        $display("[TB] Streaming Unskewed Data Rows...");
        pe_en = 1;
        
        for (cycle = 0; cycle < 2*N; cycle = cycle + 1) begin
            
            // Feed entire row of Matrix A simultaneously into the top edge
            for (c = 0; c < N; c = c + 1) begin
                if (cycle < N) data_in[c] = matrix_A[cycle][c]; 
                else           data_in[c] = 8'sb0;
            end

            #2; // Clock tick

            // Capture results as they drop out of the bottom edge
            if (cycle >= N-1 && out_row < N) begin
                for (c = 0; c < N; c = c + 1) begin
                    hw_result[out_row][c] = result[c];
                end
                out_row = out_row + 1;
            end
        end
        pe_en = 0;

        // -------------------------------------------------------------------------
        // 5. VERIFICATION
        // -------------------------------------------------------------------------
        $display("\n=======================================================");
        for (r = 0; r < N; r = r + 1) begin
            for (c = 0; c < N; c = c + 1) begin
                if (hw_result[r][c] !== expected_C[r][c]) begin
                    $display("❌ MISMATCH at Row %0d, Col %0d: Expected = %0d, Hardware = %0d", 
                             r, c, expected_C[r][c], hw_result[r][c]);
                    mismatch_count = mismatch_count + 1;
                end
            end
        end

        if (mismatch_count == 0) begin
            $display("✅ SUCCESS! All 512 operations match perfectly.");
            $display("✅ True DiP Architecture verified.");
        end else begin
            $display("❌ FAILED. Found %0d mismatched elements.", mismatch_count);
        end
        $display("=======================================================\n");

        $finish;
    end
endmodule

