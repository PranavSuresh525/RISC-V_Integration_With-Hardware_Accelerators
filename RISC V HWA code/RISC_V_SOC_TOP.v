`timescale 1ns / 1ps

module RISC_V_SOC_TOP(
    input  sys_clk_p,   // VC707 SYSCLK_P - FPGA pin E19, 200 MHz LVDS
    input  sys_clk_n,   // VC707 SYSCLK_N - FPGA pin E18, 200 MHz LVDS
    input  reset,

    // We only need ONE single output pin to trick Vivado
    output dummy_led
);

    wire clk;           // internal system clock
    wire sys_reset;     // internal system reset

`ifdef __ICARUS__
    // =========================================================================
    // SIMULATION PATH (Icarus Verilog)
    // =========================================================================
    // Icarus doesn't have Xilinx primitives by default. 
    // We bypass the MMCM/IBUFDS and just use sys_clk_p as a standard 
    // single-ended simulation clock.
    assign clk = sys_clk_p;
    assign sys_reset = reset;

`else
    // =========================================================================
    // SYNTHESIS / HARDWARE PATH (Vivado)
    // =========================================================================
    // VC707's on-board oscillator is a fixed 200 MHz LVDS differential pair.
    // IBUFDS turns that into a single-ended clock. The MMCM divides it down 
    // to 100 MHz for internal use so the execute stage can meet timing.
    wire clk_ibufds;
    wire clk_mmcm_out;
    wire clk_fb;
    wire mmcm_locked;
 
    IBUFDS #(
        .DIFF_TERM   ("FALSE"),
        .IBUF_LOW_PWR("FALSE"),
        .IOSTANDARD  ("LVDS")
    ) sysclk_ibufds (
        .O  (clk_ibufds),
        .I  (sys_clk_p),
        .IB (sys_clk_n)
    );
 
    MMCME2_BASE #(
        .CLKIN1_PERIOD     (5.000),   // 200 MHz input period
        .DIVCLK_DIVIDE     (1),
        .CLKFBOUT_MULT_F   (5.000),   // VCO = 200 * 5   = 1000 MHz
        .CLKOUT0_DIVIDE_F  (10.000),  // out  = 1000 / 10 = 100 MHz
        .CLKOUT0_DUTY_CYCLE(0.5),
        .STARTUP_WAIT      ("FALSE")
    ) sysclk_mmcm (
        .CLKIN1  (clk_ibufds),
        .CLKFBIN (clk_fb),
        .CLKFBOUT(clk_fb),
        .CLKOUT0 (clk_mmcm_out),
        .PWRDWN  (1'b0),
        .RST     (reset),
        .LOCKED  (mmcm_locked)
    );
 
    BUFG clk_bufg (
        .I(clk_mmcm_out),
        .O(clk)
    );
 
    assign sys_reset = reset | ~mmcm_locked;
`endif

    // =========================================================================
    // CORE INSTANTIATIONS
    // =========================================================================
    wire unrecognized;
    wire [31:0] wb_data;
    wire [31:0] pc, instruction;

    RISC_V_PROCESSOR processor(
        .clk(clk),
        .reset(sys_reset),
        .unrecognized(unrecognized),
        .wb_data(wb_data),
        .pc_out(pc),
        .instruction_in(instruction)
    );

    INSTRUCTION_MEMORY instruction_memory(
        .clk(clk),
        .reset(sys_reset),
        .pc(pc),
        .instruction(instruction)
    );

    // =========================================================================
    // THE MAGIC TRICK:
    // XOR every bit of wb_data and unrecognized together.
    // This absolutely guarantees Vivado cannot optimize away your math logic!
    // =========================================================================
    assign dummy_led = (^wb_data) ^ unrecognized;

endmodule