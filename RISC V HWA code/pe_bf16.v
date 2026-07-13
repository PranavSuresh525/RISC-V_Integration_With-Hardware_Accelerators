`timescale 1ns / 1ps

module pe_bf16 #(
    parameter ACC_WIDTH  = 32,
    parameter FRAC_BITS  = 16,
    parameter MANT_WIDTH = 16   
)(
    input         clk,
    input         rst,

    input         weight_load_en,
    input  [15:0] weight_in,

    input         act_valid_in,
    input  [15:0] act_in,

    input  [ACC_WIDTH-1:0] d_in,

    output reg        act_valid_out,
    output reg [15:0] act_out,
    (* use_dsp = "yes" *) output reg [ACC_WIDTH-1:0] d_out
);

    // ---- stationary weight ----
    reg [15:0] weight_reg;
    always @(posedge clk) begin
        if (rst)                 weight_reg <= 16'd0;
        else if (weight_load_en) weight_reg <= weight_in;
    end

    // =====================================================================
    // Stage 1: multiply, latch pass-through copies of act/valid/d_in
    // =====================================================================
    wire [15:0] safe_act_in = act_valid_in ? act_in : 16'd0;
    
    wire [31:0] fp32_product_comb;
    bf16_mul_fp32 u_mult (.a(safe_act_in), .b(weight_reg), .result(fp32_product_comb));

    reg [31:0] prod_s1;
    reg        valid_s1;
    reg [15:0] act_s1;
    reg [ACC_WIDTH-1:0] d_s1;

    always @(posedge clk) begin
        if (rst) begin
            prod_s1  <= 32'd0;
            valid_s1 <= 1'b0;
            act_s1   <= 16'd0;
            d_s1     <= {ACC_WIDTH{1'b0}};
        end else begin
            valid_s1 <= act_valid_in;
            d_s1     <= d_in; // Vertical accumulation must always pass through

            // Operand Isolation: Freeze multiplier output and horizontal routing if invalid
            if (act_valid_in) begin
                prod_s1 <= fp32_product_comb;
                act_s1  <= act_in;
            end
        end
    end

    // =====================================================================
    // Stage 2: FP32 -> fixed-point cast of the registered product
    // =====================================================================
    wire        prod_sign_s1 = prod_s1[31];
    wire [7:0]  prod_exp_s1  = prod_s1[30:23];
    wire [22:0] prod_frac_s1 = prod_s1[22:0];

    localparam DROP = 24 - MANT_WIDTH;
    wire [MANT_WIDTH-1:0] prod_mantissa_s1 =
        (prod_exp_s1 == 0) ? {MANT_WIDTH{1'b0}}
                            : {1'b1, prod_frac_s1[22 -: (MANT_WIDTH-1)]};

    wire signed [9:0] prod_shift_s1 =
        $signed({2'b0, prod_exp_s1}) - 10'sd150 + FRAC_BITS + DROP;

    localparam MAX_LSHIFT = ACC_WIDTH - 1;
    localparam MAX_RSHIFT = MANT_WIDTH;
    localparam DW_WIDTH  = MANT_WIDTH + MAX_LSHIFT;
    localparam RSHIFT_W  = $clog2(DW_WIDTH + 1);

    wire [DW_WIDTH-1:0] dw_comb = {prod_mantissa_s1, {MAX_LSHIFT{1'b0}}};
    wire signed [RSHIFT_W:0] rshift_comb = MAX_LSHIFT - prod_shift_s1;
    wire [DW_WIDTH-1:0] dw_shifted_comb = dw_comb >> rshift_comb[RSHIFT_W-1:0];

    reg [ACC_WIDTH-2:0] abs_fixed_comb;
    always @(*) begin
        if ((prod_shift_s1 < -MAX_RSHIFT) || (prod_shift_s1 > MAX_LSHIFT))
            abs_fixed_comb = {(ACC_WIDTH-1){1'b0}};
        else
            abs_fixed_comb = dw_shifted_comb[ACC_WIDTH-2:0];
    end

    // ---- Stage 2a: funnel shift only ----
    reg [ACC_WIDTH-2:0] abs_fixed_s2a;
    reg                 sign_s2a;
    reg                 valid_s2a;
    reg [15:0]          act_s2a;
    reg [ACC_WIDTH-1:0] d_s2a;

    always @(posedge clk) begin
        if (rst) begin
            abs_fixed_s2a <= {(ACC_WIDTH-1){1'b0}};
            sign_s2a      <= 1'b0;
            valid_s2a     <= 1'b0;
            act_s2a       <= 16'd0;
            d_s2a         <= {ACC_WIDTH{1'b0}};
        end else begin
            valid_s2a <= valid_s1;
            d_s2a     <= d_s1;

            // Operand Isolation: Freeze funnel shift registers
            if (valid_s1) begin
                abs_fixed_s2a <= abs_fixed_comb;
                sign_s2a      <= prod_sign_s1;
                act_s2a       <= act_s1;
            end
        end
    end

    // ---- Stage 2b: negate only ----
    wire [ACC_WIDTH-1:0] fixed_product_comb2 =
        sign_s2a ? -$signed({1'b0, abs_fixed_s2a}) : {1'b0, abs_fixed_s2a};

    reg [ACC_WIDTH-1:0] fixed_s2;
    reg        valid_s2;
    reg [15:0] act_s2;
    reg [ACC_WIDTH-1:0] d_s2;

    always @(posedge clk) begin
        if (rst) begin
            fixed_s2 <= {ACC_WIDTH{1'b0}};
            valid_s2 <= 1'b0;
            act_s2   <= 16'd0;
            d_s2     <= {ACC_WIDTH{1'b0}};
        end else begin
            valid_s2 <= valid_s2a;
            d_s2     <= d_s2a;
            
            // Operand Isolation: Freeze negator output
            if (valid_s2a) begin
                fixed_s2 <= fixed_product_comb2;
                act_s2   <= act_s2a;
            end
        end
    end

    // =====================================================================
    // Stage 3: accumulate, final pass-through of act/valid
    // =====================================================================
    always @(posedge clk) begin
        if (rst) begin
            d_out         <= {ACC_WIDTH{1'b0}};
            act_valid_out <= 1'b0;
            act_out       <= 16'd0;
        end else begin
            act_valid_out <= valid_s2;
            d_out         <= valid_s2 ? (d_s2 + fixed_s2) : d_s2;
            
            if (valid_s2) begin
                act_out <= act_s2;
            end
        end
    end

endmodule