`timescale 1ns / 1ps

module ws_fsm #(
    parameter N = 16
) (
    input  clk,
    input  rst,
    input  start,

    output [N*$clog2(N)-1:0] weight_rd_addr_flat,
    input  [N*16-1:0]        weight_rd_data_flat,

    output [$clog2(N)-1:0]   input_rd_addr,
    input  [N*16-1:0]        input_rd_data_flat,

    output                   output_we,
    output [$clog2(N)-1:0]   output_wr_addr,
    output [N*16-1:0]        output_wr_data_flat,

    output                   load_en,
    output [$clog2(N)-1:0]   load_row_idx,
    output [N*16-1:0]        weight_bus_flat,
    output                   row0_valid,
    output [N*16-1:0]        row0_act_bus_flat,
    input  [N*16-1:0]        result_flat,

    output reg               busy,
    output reg               done
);

    localparam ADDR_W = $clog2(N);

    // pe_bf16 takes PE_LATENCY_PER_ROW cycles (not 1) to move act/d from one
    // systolic hop to the next -- MUST match pe_bf16.v's act_valid_in ->
    // act_valid_out latency, and the skew scaling used in ws_array.v.
    // (dip_fsm.v already accounts for this; ws_fsm.v previously did not,
    // which is why the WS path was sampling results before they had
    // actually propagated through the array.)
    localparam PE_LATENCY_PER_ROW = 4;

    // We add +4 at the very end to account for the 4-stage BF16 pipeline!
    localparam OUT_START = ((2*N - 1) * PE_LATENCY_PER_ROW) + 4;
    localparam OUT_END   = OUT_START + (N - 1);

    localparam ST_IDLE       = 2'd0;
    localparam ST_LOAD_RUN   = 2'd1;
    localparam ST_COMP_RUN   = 2'd2;

    reg [1:0] state;
    reg [ADDR_W+7:0] cyc; 

    reg [ADDR_W-1:0] w_issue_row;
    always @(*) begin
        if (state == ST_IDLE && start)       w_issue_row = {ADDR_W{1'b0}}; // Preload 0
        else if (state == ST_LOAD_RUN)       w_issue_row = (cyc[ADDR_W-1:0] + 1'b1);
        else                                 w_issue_row = {ADDR_W{1'b0}};
    end

    genvar gc;
    generate
        for (gc = 0; gc < N; gc = gc + 1) begin : WADDR
            // Removed the + gc offset. WS requires flat, unpermuted rows!
            assign weight_rd_addr_flat[gc*ADDR_W +: ADDR_W] = w_issue_row; 
        end
    endgenerate

    assign load_en         = (state == ST_LOAD_RUN);
    assign load_row_idx    = cyc[ADDR_W-1:0];
    assign weight_bus_flat = weight_rd_data_flat;

    reg [ADDR_W-1:0] i_issue_row;
    always @(*) begin
        if (state == ST_LOAD_RUN && cyc == N-1) i_issue_row = {ADDR_W{1'b0}}; // Preload 0
        else if (state == ST_COMP_RUN)          i_issue_row = (cyc[ADDR_W-1:0] + 1'b1);
        else                                    i_issue_row = {ADDR_W{1'b0}};
    end
    assign input_rd_addr = i_issue_row;

    assign row0_valid        = (state == ST_COMP_RUN) && (cyc < N);
    assign row0_act_bus_flat = input_rd_data_flat;

    assign output_we           = (state == ST_COMP_RUN) && (cyc >= OUT_START) && (cyc <= OUT_END);
    assign output_wr_addr      = cyc - OUT_START;
    assign output_wr_data_flat = result_flat;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_IDLE;
            cyc   <= 0;
            busy  <= 1'b0;
            done  <= 1'b0;
        end else begin
            done <= 1'b0; 

            case (state)
                ST_IDLE: begin
                    if (start) begin
                        state <= ST_LOAD_RUN;
                        cyc   <= 0;
                        busy  <= 1'b1;
                    end
                end

                ST_LOAD_RUN: begin
                    if (cyc == N-1) begin
                        state <= ST_COMP_RUN;
                        cyc   <= 0;
                    end else begin
                        cyc <= cyc + 1;
                    end
                end

                ST_COMP_RUN: begin
                    if (cyc == OUT_END) begin
                        state <= ST_IDLE; 
                        done  <= 1'b1;
                        busy  <= 1'b0;
                    end else begin
                        cyc <= cyc + 1;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule