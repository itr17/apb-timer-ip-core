`include "timer_defines.v"

module timer_top (
    // System signals
    input wire          sys_clk,
    input wire          sys_rst_n,

    // APB Bus Interface
    input wire          tim_psel,
    input wire          tim_penable,
    input wire          tim_pwrite,
    input wire [11:0]   tim_paddr,
    input wire [31:0]   tim_pwdata,
    input wire [3:0]    tim_pstrb,
    output wire [31:0]  tim_prdata,
    output wire         tim_pready,
    output wire         tim_pslverr,

    // Interrupt Output
    output wire         tim_int,
    // Debug Interface
    input wire          dbg_mode
);

    // Internal Wires
    // Connection from apbif to regset
    wire wr_en_tcr;
    wire wr_en_tcmp0;
    wire wr_en_tcmp1;
    wire wr_en_tier;
    wire wr_en_tisr;
    wire wr_en_thcsr;
    wire [31:0] prdata_to_apb;
    // Connection from apbif to counter
    wire wr_en_tdr0;
    wire wr_en_tdr1;
    // Connection from regset to apbif
    wire tcr_timer_en;
    wire tcr_div_en;
    wire [3:0] tcr_div_val;
    // Connection from regset to counter and cnt_ctrl
    wire [31:0] tcmp0_reg;
    wire [31:0] tcmp1_reg;
    wire tier_int_en;
    wire thcsr_halt_req;
    wire thcsr_halt_ack;
    // Connection from counter to regset
    wire [63:0] count_val;
    wire match_event;
    wire tisr_int_st;
    // Connection from cnt_ctrl to counter
    wire real_count_tick;

    // Sub module Instantiations
    apbif u_apbif (
        .sys_clk        (sys_clk),
        .sys_rst_n      (sys_rst_n),
        .tim_psel       (tim_psel),
        .tim_penable    (tim_penable),
        .tim_pwrite     (tim_pwrite),
        .tim_paddr      (tim_paddr),
        .tim_pwdata     (tim_pwdata),
        .tim_pstrb      (tim_pstrb),
        .tim_prdata     (tim_prdata),
        .tim_pready     (tim_pready),
        .tim_pslverr    (tim_pslverr),

        .prdata_in      (prdata_to_apb),
        .timer_en_in    (tcr_timer_en),
        .div_en_in      (tcr_div_en),
        .div_val_in     (tcr_div_val),

        .wr_en_tcr      (wr_en_tcr),
        .wr_en_tdr0     (wr_en_tdr0),
        .wr_en_tdr1     (wr_en_tdr1),
        .wr_en_tcmp0    (wr_en_tcmp0),
        .wr_en_tcmp1    (wr_en_tcmp1),
        .wr_en_tier     (wr_en_tier),
        .wr_en_tisr     (wr_en_tisr),
        .wr_en_thcsr    (wr_en_thcsr)
    );

    regset u_regset (
        .sys_clk        (sys_clk),
        .sys_rst_n      (sys_rst_n),
        .tim_paddr      (tim_paddr),
        .tim_pwdata     (tim_pwdata),
        .tim_pstrb      (tim_pstrb),
        .prdata_in      (prdata_to_apb),

        .wr_en_tcr      (wr_en_tcr),
        .wr_en_tcmp0    (wr_en_tcmp0),
        .wr_en_tcmp1    (wr_en_tcmp1),
        .wr_en_tier     (wr_en_tier),
        .wr_en_tisr     (wr_en_tisr),
        .wr_en_thcsr    (wr_en_thcsr),

        .count_val      (count_val),
        .match_event    (match_event),
        .dbg_mode       (dbg_mode),

        .tcr_timer_en   (tcr_timer_en),
        .tcr_div_en     (tcr_div_en),
        .tcr_div_val    (tcr_div_val),
        .tcmp0_reg      (tcmp0_reg),
        .tcmp1_reg      (tcmp1_reg),
        .tier_int_en    (tier_int_en),
        .tisr_int_st    (tisr_int_st),
        .thcsr_halt_req (thcsr_halt_req),
        .thcsr_halt_ack (thcsr_halt_ack)
    );

    cnt_ctrl u_cnt_ctrl (
        .sys_clk        (sys_clk),
        .sys_rst_n      (sys_rst_n),
        .timer_en       (tcr_timer_en),
        .div_en         (tcr_div_en),
        .div_val        (tcr_div_val),
        .thcsr_halt_req (thcsr_halt_req),
        .dbg_mode       (dbg_mode),
        .real_count_tick(real_count_tick)
    );

    counter u_counter (
        .sys_clk        (sys_clk),
        .sys_rst_n      (sys_rst_n),
        .real_count_tick(real_count_tick),

        .wr_en_tdr0     (wr_en_tdr0),
        .wr_en_tdr1     (wr_en_tdr1),
        .tim_pwdata     (tim_pwdata),
        .tim_pstrb      (tim_pstrb),

        .timer_en       (tcr_timer_en),
        .tcmp0_reg      (tcmp0_reg),
        .tcmp1_reg      (tcmp1_reg),
        .thcsr_halt_req (thcsr_halt_req),
        .dbg_mode       (dbg_mode),

        .count_val      (count_val),
        .match_event    (match_event)
    );

    assign tim_int = tisr_int_st & tier_int_en;

endmodule