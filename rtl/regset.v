`include "timer_defines.v"

module regset (
    input wire          sys_clk,
    input wire          sys_rst_n,

    // Communicate with APB Interface
    input wire [11:0]   tim_paddr,
    input wire [31:0]   tim_pwdata,
    input wire [3:0]    tim_pstrb,
    output reg [31:0]   prdata_in,

    // Write Enable from APB Interface
    input wire          wr_en_tcr,
    input wire          wr_en_tcmp0,
    input wire          wr_en_tcmp1,
    input wire          wr_en_tier,
    input wire          wr_en_tisr,
    input wire          wr_en_thcsr,

    // Communicate with Counter and cnt_ctrl
    input wire [63:0]   count_val,
    input wire          match_event,
    input wire          dbg_mode,

    output reg          tcr_timer_en,
    output reg          tcr_div_en,
    output reg [3:0]    tcr_div_val,
    output reg [31:0]   tcmp0_reg,
    output reg [31:0]   tcmp1_reg,
    output reg          tier_int_en,
    output reg          tisr_int_st,
    output reg          thcsr_halt_req,
    output wire         thcsr_halt_ack
);

    // Timer Control Register (TCR)
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            tcr_timer_en <= 1'b0;
            tcr_div_en <= 1'b0;
            tcr_div_val <= 4'b0001;
        end else if (wr_en_tcr) begin
            if (tim_pstrb[0]) begin
                tcr_timer_en <= tim_pwdata[0];
                tcr_div_en <= tim_pwdata[1];
            end
            if (tim_pstrb[1]) begin
                tcr_div_val <= tim_pwdata[11:8];
            end
        end
    end

    // Timer Compare Register (TCMP0 & TCMP1)
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            tcmp0_reg <= `RST_VAL_TCMP0;
        end else if (wr_en_tcmp0) begin
            if (tim_pstrb[0])
                tcmp0_reg[7:0] <= tim_pwdata[7:0];
            if (tim_pstrb[1])
                tcmp0_reg[15:8] <= tim_pwdata[15:8];
            if (tim_pstrb[2])
                tcmp0_reg[23:16] <= tim_pwdata[23:16];
            if (tim_pstrb[3])
                tcmp0_reg[31:24] <= tim_pwdata[31:24];
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            tcmp1_reg <= `RST_VAL_TCMP1;
        end else if (wr_en_tcmp1) begin
            if (tim_pstrb[0])
                tcmp1_reg[7:0] <= tim_pwdata[7:0];
            if (tim_pstrb[1])
                tcmp1_reg[15:8] <= tim_pwdata[15:8];
            if (tim_pstrb[2])
                tcmp1_reg[23:16] <= tim_pwdata[23:16];
            if (tim_pstrb[3])
                tcmp1_reg[31:24] <= tim_pwdata[31:24];
        end
    end

    // Timer Interrupt Enable Register (TIER)
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            tier_int_en <= 1'b0;
        end else if (wr_en_tier && tim_pstrb[0]) begin
            tier_int_en <= tim_pwdata[0];
        end
    end

    // Timer Interrupt Status Register (TISR)
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            tisr_int_st <= 1'b0;
        end else if (wr_en_tisr && tim_pstrb[0] && tim_pwdata[0]) begin
            tisr_int_st <= 1'b0;
        end else if (match_event) begin
            tisr_int_st <= 1'b1;
        end
    end

    // Timer Halt Control Status (THCSR)
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin   
            thcsr_halt_req <= 1'b0;
        end else if (wr_en_thcsr && tim_pstrb[0]) begin
            thcsr_halt_req <= tim_pwdata[0];
        end
    end
    assign thcsr_halt_ack = thcsr_halt_req & dbg_mode;

    // Read Data MUX
    always @(*) begin
        case(tim_paddr)
            `ADDR_TCR:      prdata_in = {20'h0, tcr_div_val, 6'h0, tcr_div_en, tcr_timer_en};
            `ADDR_TDR0:     prdata_in = count_val[31:0];
            `ADDR_TDR1:     prdata_in = count_val[63:32];
            `ADDR_TCMP0:    prdata_in = tcmp0_reg;
            `ADDR_TCMP1:    prdata_in = tcmp1_reg;
            `ADDR_TIER:     prdata_in = {31'h0, tier_int_en};
            `ADDR_TISR:     prdata_in = {31'h0, tisr_int_st};
            `ADDR_THCSR:    prdata_in = {30'h0, thcsr_halt_ack, thcsr_halt_req};
            default:        prdata_in = 32'h0;
        endcase
    end

endmodule