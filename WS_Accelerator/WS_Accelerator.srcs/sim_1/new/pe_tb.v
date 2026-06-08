`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.06.2026 11:51:19
// Design Name: 
// Module Name: pe_tb
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

module pe_tb;

    // Inputs
    reg clk;
    reg rst;
    reg weight_en;
    reg pe_en;
    reg signed [7:0] weight_in;
    reg signed [7:0] data_in;
    reg signed [15:0] psum_in;

    // Outputs
    wire signed [7:0] weight_out;
    wire signed [7:0] data_out;
    wire signed [15:0] psum_out;

    // Instantiate the Unit Under Test (UUT)
    pe uut (
        .clk(clk),
        .rst(rst),
        .weight_en(weight_en),
        .pe_en(pe_en),
        .weight_in(weight_in),
        .data_in(data_in),
        .psum_in(psum_in),
        .weight_out(weight_out),
        .data_out(data_out),
        .psum_out(psum_out)
    );

    // Clock generation (50MHz / 20ns period)
    always #1 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        rst = 1;
        weight_en = 0;
        pe_en = 0;
        weight_in = 0;
        data_in = 0;
        psum_in = 0;

        // Hold reset state for 2 clock cycles
        #2;
        rst = 0;
        #2;

        // --- Phase 1: Load Weight ---
        $display("[PE TB] Loading weight = 5");
        weight_in = 8'sd5;
        weight_en = 1;
        #2;
        weight_en = 0;
        weight_in = 8'sd0; // Clear input to prove it locked inside the PE
        #2;

        // --- Phase 2: Compute (MAC) ---
        // Cycle 1: data_in = 3, psum_in = 10 -> Expected output next cycle = 10 + (5 * 3) = 25
        $display("[PE TB] Step 1: data_in = 3, psum_in = 10");
        pe_en = 1;
        data_in = 8'sd3;
        psum_in = 16'sd10;
        #2;
        $display("[PE TB] Output 1 Check: psum_out = %d (Expected: 25), data_out = %d (Expected: 3)", psum_out, data_out);

        // Cycle 2: data_in = -2, psum_in = 25 -> Expected output next cycle = 25 + (5 * -2) = 15
        $display("[PE TB] Step 2: data_in = -2, psum_in = 25");
        data_in = -8'sd2;
        psum_in = 16'sd25;
        #2;
        $display("[PE TB] Output 2 Check: psum_out = %d (Expected: 15), data_out = %d (Expected: -2)", psum_out, data_out);

        // --- Phase 3: Disable Compute (Freeze/Pass-through) ---
        $display("[PE TB] Disabling pe_en (Pass-through mode)");
        pe_en = 0;
        data_in = 8'sd4;   // Should be ignored
        psum_in = 16'sd100; // Should pass straight through to psum_out
        #2;
        $display("[PE TB] Output 3 Check: psum_out = %d (Expected: 100), data_out = %d (Expected: 0)", psum_out, data_out);

        $finish;
    end
      
endmodule