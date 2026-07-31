interface apb_timer_if (input logic sys_clk, input logic sys_rst_n);
    logic [11:0]    tim_paddr; 
    logic           tim_pwrite; 
    logic           tim_psel; 
    logic           tim_penable;
    logic [31:0]    tim_pwdata;
    logic [3:0]     tim_pstrb;

    logic [31:0]    tim_prdata;
    logic           tim_pready;
    logic           tim_pslverr;

    logic           tim_int;
    logic           dbg_mode;
endinterface
