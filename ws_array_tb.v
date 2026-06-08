`timescale 10ns/1ns

module ws_array_tb;

    parameter N = 8;

    reg clk;
    reg rst;
    reg weight_en;
    reg pe_en;
    reg signed [7:0]  weight_in [0:N-1];
    reg signed [7:0]  data_in [0:N-1];
    wire signed [15:0] result [0:N-1];

    ws_array #(.N(N)) uut (
        .clk      (clk),
        .rst      (rst),
        .weight_en(weight_en),
        .pe_en    (pe_en),
        .weight_in(weight_in),
        .data_in  (data_in),
        .result   (result)
    );

    reg signed [7:0]  matrix_A [0:N-1][0:N-1];
    reg signed [7:0]  matrix_B [0:N-1][0:N-1];
    reg signed [15:0] expected_C [0:N-1][0:N-1];
    reg signed [15:0] hw_result  [0:N-1][0:N-1];

    integer r, c, cycle, mismatch_count, out_row;

    always #1 clk = ~clk;

    // Software reference multiply
    task compute_expected;
        integer tr, tc, tk;
        begin
            for (tr = 0; tr < N; tr = tr + 1)
                for (tc = 0; tc < N; tc = tc + 1) begin
                    expected_C[tr][tc] = 0;
                    for (tk = 0; tk < N; tk = tk + 1)
                        expected_C[tr][tc] = expected_C[tr][tc]
                            + matrix_A[tr][tk] * matrix_B[tk][tc];
                end
        end
    endtask

    initial begin
        clk = 0; rst = 1; weight_en = 0; pe_en = 0; mismatch_count = 0; out_row = 0;
        
        for (c = 0; c < N; c = c + 1) begin
            weight_in[c] = 8'sb0;
            data_in[c] = 8'sb0;
        end
        #4; rst = 0; #2;

        // Fill matrices with dense test data
        for (r = 0; r < N; r = r + 1) begin
            for (c = 0; c < N; c = c + 1) begin
                matrix_A[r][c] = (r * N) + c + 1;
                matrix_B[r][c] = (r * 2) + c - 3; 
            end
        end

        compute_expected;

        // --- Phase 1: Load weights ---
        $display("[TB] Loading weights...");
        weight_en = 1;
        for (r = N-1; r >= 0; r = r - 1) begin
            for (c = 0; c < N; c = c + 1)
                weight_in[c] = matrix_B[r][c];
            #2;
        end
        weight_en = 0;
        for (c = 0; c < N; c = c + 1) weight_in[c] = 8'sb0;
        #2;

        // --- Phase 2: Stream Data & Capture Outputs ---
        $display("[TB] Streaming Data...");
        pe_en = 1;
        
        // Parameterized loop to handle any size N
        for (cycle = 0; cycle < (4 * N); cycle = cycle + 1) begin
            
            // 1. Unskewed Data Feeding (Internal FIFOs handle the skewing!)
            for (r = 0; r < N; r = r + 1) begin
                if (cycle < N) data_in[r] = matrix_A[cycle][r];
                else           data_in[r] = 8'sb0;
            end

            #2; // Clock tick

            // 2. Unskewed Data Capture 
            // The internal FIFOs align the output rows perfectly.
            // The first valid row arrives exactly at cycle (2N - 2).
            if (cycle >= (2*N - 2) && out_row < N) begin
                for (c = 0; c < N; c = c + 1) begin
                    hw_result[out_row][c] = result[c];
                end
                out_row = out_row + 1;
            end
        end
        pe_en = 0;

        // --- Phase 3: Verification ---
        $display("\n=======================================================");
        for (r = 0; r < N; r = r + 1) begin
            for (c = 0; c < N; c = c + 1) begin
                if (hw_result[r][c] !== expected_C[r][c]) begin
                    $display("❌ MISMATCH at [%0d][%0d]: Normal = %0d, Hardware = %0d", 
                             r, c, expected_C[r][c], hw_result[r][c]);
                    mismatch_count = mismatch_count + 1;
                end
            end
        end

        if (mismatch_count == 0) $display("✅ SUCCESS! All operations match perfectly.");
        else                     $display("❌ FAILED. Found %0d mismatches.", mismatch_count);
        $display("=======================================================\n");

        $finish;
    end
endmodule