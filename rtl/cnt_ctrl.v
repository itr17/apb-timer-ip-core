`include "timer_defines.v"

module cnt_ctrl (
    input wire          sys_clk,
    input wire          sys_rst_n,
    input wire          timer_en,
    input wire          div_en,
    input wire [3:0]    div_val,
    input wire          thcsr_halt_req,
    input wire          dbg_mode,
    output reg          real_count_tick
);

    reg [7:0] pre_count;
    reg [7:0] clk_div_limit;
    wire halt_freeze = dbg_mode & thcsr_halt_req;

    always @(*) begin
        case (div_val)
            4'b0000: clk_div_limit = 8'd0;
            4'b0001: clk_div_limit = 8'd1;
            4'b0010: clk_div_limit = 8'd3;
            4'b0011: clk_div_limit = 8'd7;
            4'b0100: clk_div_limit = 8'd15;
            4'b0101: clk_div_limit = 8'd31;
            4'b0110: clk_div_limit = 8'd63;
            4'b0111: clk_div_limit = 8'd127;
            4'b1000: clk_div_limit = 8'd255;
            default: clk_div_limit = 8'd1;
        endcase
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            pre_count <= 8'h0;
        end else if (!timer_en) begin
            pre_count <= 8'h0;
        end else if (halt_freeze) begin
            pre_count <= pre_count;
        end else if (!div_en) begin
            pre_count <= 8'h0;
        end else begin
            if (pre_count >= clk_div_limit) begin
                pre_count <= 8'h0;
            end else begin
                pre_count <= pre_count + 1'b1;
            end
        end
    end

    always @(*) begin
        if (!timer_en || halt_freeze) begin
            real_count_tick = 1'b0;
        end else if (!div_en) begin
            real_count_tick = 1'b1;
        end else begin
            real_count_tick = (pre_count == clk_div_limit);
        end
    end

endmodule