`include "timer_defines.v"

module counter (
    input wire          sys_clk,
    input wire          sys_rst_n,

    // From cnt_ctrl.v
    input wire          real_count_tick,

    // From apbif.v
    input wire          wr_en_tdr0,
    input wire          wr_en_tdr1,
    input wire [31:0]   tim_pwdata,
    input wire [3:0]    tim_pstrb,

    // From regset.v
    input wire          timer_en,
    input wire [31:0]   tcmp0_reg,
    input wire [31:0]   tcmp1_reg,
    input wire          thcsr_halt_req,

    input wire          dbg_mode,
    output wire [63:0]  count_val,
    output reg          match_event
);

    reg [63:0] count_reg;
    assign count_val = count_reg;

    // Falling Edge Detector
    reg timer_en_q;
    wire timer_en_fall_edge;
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            timer_en_q <= 1'b0;
        end else begin
            timer_en_q <= timer_en;
        end
    end
    assign timer_en_fall_edge = timer_en_q & ~timer_en;

    // 64-bit Up Counter
    reg [63:0] next_count;
    wire halt_freeze = dbg_mode & thcsr_halt_req;

    always @(*) begin
        // 1st Stage
        if (timer_en && real_count_tick) begin
            next_count = count_reg + 1'b1;
        end else begin
            next_count = count_reg;
        end
        // 3rd Stage
        if (timer_en_fall_edge) begin
            next_count = 64'h0;
        end
        // 4th Stage
        if (halt_freeze) begin
            next_count = count_reg;
        end
        // 2nd Stage
        if (wr_en_tdr0) begin
            if (tim_pstrb[0])
                next_count[7:0] = tim_pwdata[7:0];
            if (tim_pstrb[1])
                next_count[15:8] = tim_pwdata[15:8];
            if (tim_pstrb[2])
                next_count[23:16] = tim_pwdata[23:16];
            if (tim_pstrb[3])
                next_count[31:24] = tim_pwdata[31:24];
        end
        if (wr_en_tdr1) begin
            if (tim_pstrb[0])
                next_count[39:32] = tim_pwdata[7:0];
            if (tim_pstrb[1])
                next_count[47:40] = tim_pwdata[15:8];
            if (tim_pstrb[2])
                next_count[55:48] = tim_pwdata[23:16];
            if (tim_pstrb[3])
                next_count[63:56] = tim_pwdata[31:24];
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            count_reg <= 64'h0;
        end else begin
            count_reg <= next_count;
        end
    end

    // Match Event Logic
    wire [63:0] compare_val = {tcmp1_reg, tcmp0_reg};
    always @(*) begin
        match_event = (count_reg == compare_val);
    end

endmodule