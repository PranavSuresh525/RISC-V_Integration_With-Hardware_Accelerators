`timescale 10ns/1ns

module compare_tb;

    parameter N = 8;

    // Hardware Signals
    reg clk;
    reg rst;
    reg weight_en;
    reg pe_en;
    reg signed [7:0]  weight_in [0:N-1];
    reg signed [7:0]  data_in [0:N-1];
    wire signed [15:0] result [0:N-1];

    // Instantiate your working Systolic Array
    ws_array #(.N(N)) uut (
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
    reg signed [15:0] normal_C [0:N-1][0:N-1];  
    reg signed [15:0] hardware_C [0:N-1][0:N-1];

    // Tracking & Stopwatch Variables
    integer r, c, k, cycle;
    integer mismatch_count;
    integer hw_start_time, hw_end_time, hw_cycles;
    integer normal_cycles;

    always #1 clk = ~clk; // Clock period is 2 time units

    initial begin
        clk = 0; rst = 1; weight_en = 0; pe_en = 0; mismatch_count = 0;
        
        for (r = 0; r < N; r = r + 1) begin
            weight_in[r] = 0; data_in[r] = 0;
            for (c = 0; c < N; c = c + 1) begin
                normal_C[r][c] = 0;
                hardware_C[r][c] = 0;
                matrix_A[r][c] = (r * N) + c + 1; 
                matrix_B[r][c] = (r * 2) + c - 3; 
            end
        end
        #4; rst = 0; #2;

        // -------------------------------------------------------------------------
        // 1. THE "NORMAL" MATMUL (Behavioral Check)
        // -------------------------------------------------------------------------
        for (r = 0; r < N; r = r + 1) begin
            for (c = 0; c < N; c = c + 1) begin
                for (k = 0; k < N; k = k + 1) begin
                    normal_C[r][c] = normal_C[r][c] + (matrix_A[r][k] * matrix_B[k][c]);
                end
            end
        end
        
        // A standard CPU executing sequentially takes N^3 cycles
        normal_cycles = N * N * N; 

        // -------------------------------------------------------------------------
        // 2. HARDWARE RUN: WEIGHT LOADING
        // -------------------------------------------------------------------------
        weight_en = 1;
        for (r = N - 1; r >= 0; r = r - 1) begin
            for (c = 0; c < N; c = c + 1) weight_in[c] = matrix_B[r][c];
            #2; 
        end
        weight_en = 0;
        for (c = 0; c < N; c = c + 1) weight_in[c] = 0; 
        #2;

        // -------------------------------------------------------------------------
        // 3. HARDWARE RUN: COMPUTE & STAGGERED CAPTURE
        // -------------------------------------------------------------------------
        pe_en = 1;
        hw_start_time = $time; // ⏱️ START THE STOPWATCH
        
        for (cycle = 0; cycle < 40; cycle = cycle + 1) begin
            
            for (r = 0; r < N; r = r + 1) begin
                if (r == 0) begin
                    if (cycle > 0 && cycle <= N) data_in[r] = matrix_A[cycle-1][r];
                    else data_in[r] = 8'sb0;
                end else begin
                    if (cycle < N) data_in[r] = matrix_A[cycle][r];
                    else data_in[r] = 8'sb0;
                end
            end

            #2; 

            if (cycle >= 15 && (cycle - 15) < N) begin
                hardware_C[cycle - 15][7] = result[7];
            end
            
            if (cycle >= 16 && (cycle - 16) < N) begin
                for (c = 0; c < N-1; c = c + 1) begin
                    hardware_C[cycle - 16][c] = result[c];
                end
                
                // ⏱️ STOP THE STOPWATCH when the absolute last row (Row 7) drops
                if ((cycle - 16) == N - 1) begin
                    hw_end_time = $time;
                end
            end
        end
        pe_en = 0;

        // Calculate actual hardware cycles (Period = 2)
        hw_cycles = (hw_end_time - hw_start_time) / 2;

        // -------------------------------------------------------------------------
        // 4. AUTOMATED COMPARISON & PERFORMANCE REPORT
        // -------------------------------------------------------------------------
        $display("\n=======================================================");
        $display("               MATHEMATICAL VERIFICATION               ");
        $display("=======================================================");
        for (r = 0; r < N; r = r + 1) begin
            for (c = 0; c < N; c = c + 1) begin
                if (hardware_C[r][c] !== normal_C[r][c]) begin
                    $display("❌ MISMATCH at [%0d][%0d]: Normal = %0d, Hardware = %0d", 
                             r, c, normal_C[r][c], hardware_C[r][c]);
                    mismatch_count = mismatch_count + 1;
                end
            end
        end

        if (mismatch_count == 0) $display("✅ SUCCESS! All 512 operations match perfectly.");
        else                     $display("❌ FAILED. Found %0d mismatched elements.", mismatch_count);

        $display("\n=======================================================");
        $display("                 PERFORMANCE COMPARISON                ");
        $display("=======================================================");
        $display(" Normal CPU/Sequential Method : %0d Clock Cycles", normal_cycles);
        $display(" Systolic Array Hardware      : %0d Clock Cycles", hw_cycles);
        $display(" Speedup Factor               : ~%0dx Faster", (normal_cycles / hw_cycles));
        $display("=======================================================\n");

        $finish;
    end
endmodule