`timescale 10ns/1ns

module fifo_tb;

    // Parameters
    parameter TEST_DEPTH = 3;

    // Inputs
    reg clk;
    reg rst;
    reg en;
    reg signed [7:0] data_in;

    // Outputs
    wire signed [7:0] data_out;

    // Instantiate UUT with dynamic depth configuration
    fifo #(.DEPTH(TEST_DEPTH)) uut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .data_in(data_in),
        .data_out(data_out)
    );

    always #1 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        en = 0;
        data_in = 0;
        #2;
        rst = 0;
        #2;

        // Stream data in continuously
        en = 1;
        
        $display("[FIFO TB] Shifting in sequence: 10, 20, 30, 40...");
        
        data_in = 8'sd10; #2; // Cycle 1 (10 enters index 0)
        data_in = 8'sd20; #2; // Cycle 2 (10 shifts to index 1, 20 enters index 0)
        
        data_in = 8'sd30; #2; // Cycle 3 (10 shifts to index 2)
        // Because DEPTH=3 and we use a continuous wire, '10' is instantly visible right now!
        $display("[FIFO TB] Cycle 3 Output: %d (Expected: 10)", data_out);
        
        data_in = 8'sd40; #2; // Cycle 4 (20 shifts to index 2)
        $display("[FIFO TB] Cycle 4 Output: %d (Expected: 20)", data_out);

        // Test the Freeze Feature
        $display("[FIFO TB] Disabling enable signal (Freezing delay pipeline)");
        en = 0;
        data_in = 8'sd99; #2; // Data should be ignored completely
        $display("[FIFO TB] Frozen Output Check: %d (Expected: 20)", data_out);
        data_in = 8'sd88; #2; // Data should be ignored completely
        $display("[FIFO TB] Frozen Output Check: %d (Expected: 20)", data_out);

        // Re-enable to empty out remaining entries
        en = 1;
        data_in = 8'sd0; #2; // 30 shifts to index 2
        $display("[FIFO TB] Resumed Output Check: %d (Expected: 30)", data_out);
        
        data_in = 8'sd0; #2; // 40 shifts to index 2
        $display("[FIFO TB] Resumed Output Check: %d (Expected: 40)", data_out);

        $display("=======================================================\n");
        $finish;
    end

endmodule