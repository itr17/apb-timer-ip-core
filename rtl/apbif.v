`include "timer_defines.v"

module apbif (
    // APB Bus Interface
    input wire          sys_clk,
    input wire          sys_rst_n,
    input wire          tim_psel,
    input wire          tim_penable,
    input wire          tim_pwrite,
    input wire [11:0]   tim_paddr,
    input wire [31:0]   tim_pwdata,
    input wire [3:0]    tim_pstrb,
    output wire [31:0]  tim_prdata,
    output wire         tim_pready,
    output wire         tim_pslverr,

    // Interfaces from Internal Logic
    input wire [31:0]   prdata_in, // Data read from regset.v
    input wire          timer_en_in, // Current timer_en (from TCR)
    input wire          div_en_in, // Current div_en (from TCR)
    input wire [3:0]    div_val_in, // Current div_val (from TCR)

    // Decoded Write Enables to Internal Registers
    output wire         wr_en_tcr,
    output wire         wr_en_tdr0,
    output wire         wr_en_tdr1,
    output wire         wr_en_tcmp0,
    output wire         wr_en_tcmp1,
    output wire         wr_en_tier,
    output wire         wr_en_tisr,
    output wire         wr_en_thcsr
);
    localparam IDLE     = 2'b00;
    localparam SETUP    = 2'b01;
    localparam ACCESS   = 2'b10;

    reg [1:0] current_state, next_state;
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (tim_psel && !tim_penable)
                    next_state = SETUP;
            end
            SETUP: begin
                if (tim_psel && tim_penable)
                    next_state = ACCESS;
            end
            ACCESS: begin
                if (tim_psel && !tim_penable)
                    next_state = SETUP;
                else if (!tim_psel)
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end


    assign tim_pready = (current_state == ACCESS);
    wire apb_write_valid = tim_psel & tim_penable & tim_pwrite & tim_pready;

    // Error detection
    wire is_addr_tcr = (tim_paddr == `ADDR_TCR);
    wire err_invalid_div = is_addr_tcr & tim_pstrb[1] & (tim_pwdata[11:8] > `MAX_VALID_DIV_VAL);

    wire err_change_div_en = tim_pstrb[0] & (tim_pwdata[1] != div_en_in);
    wire err_change_div_val = tim_pstrb[1] & (tim_pwdata[11:8] != div_val_in);
    wire err_change_running = is_addr_tcr & timer_en_in & (err_change_div_en | err_change_div_val);

    wire apb_error_flag = err_invalid_div | err_change_running;

    assign tim_pslverr = apb_error_flag & apb_write_valid;

    // Address Decoding
    wire safe_write_req = apb_write_valid & ~apb_error_flag;

    assign wr_en_tcr   = safe_write_req & (tim_paddr == `ADDR_TCR);
    assign wr_en_tdr0  = safe_write_req & (tim_paddr == `ADDR_TDR0);
    assign wr_en_tdr1  = safe_write_req & (tim_paddr == `ADDR_TDR1);
    assign wr_en_tcmp0 = safe_write_req & (tim_paddr == `ADDR_TCMP0);
    assign wr_en_tcmp1 = safe_write_req & (tim_paddr == `ADDR_TCMP1);
    assign wr_en_tier  = safe_write_req & (tim_paddr == `ADDR_TIER);
    assign wr_en_tisr  = safe_write_req & (tim_paddr == `ADDR_TISR);
    assign wr_en_thcsr = safe_write_req & (tim_paddr == `ADDR_THCSR);

    // Read data
    assign tim_prdata = (tim_psel && tim_penable && !tim_pwrite) ? prdata_in : 32'h0;

endmodule