`timescale 1ns/1ps

module test_bench;

    // DUT's input signals
    reg             sys_clk;
    reg             sys_rst_n;

    // APB Bus
    reg             tim_psel;
    reg             tim_penable;
    reg             tim_pwrite;
    reg    [11:0]   tim_paddr;
    reg    [31:0]   tim_pwdata;
    reg    [3:0]    tim_pstrb;

    // Debug
    reg             dbg_mode;

    // DUT's output signals
    wire   [31:0]   tim_prdata;
    wire            tim_pready;
    wire            tim_pslverr;
    wire            tim_int;

    initial begin
        sys_clk = 1'b0;
    end
    always #5 sys_clk = ~sys_clk;

    timer_top dut (
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
        .tim_int        (tim_int),
        .dbg_mode       (dbg_mode)
    );

    task apb_write;
        input   [11:0]  addr;
        input   [31:0]  data;
        input   [3:0]   strb;
        output          slverr;
        begin
            @(posedge sys_clk);
            tim_psel    <= 1'b1;
            tim_penable <= 1'b0;
            tim_pwrite  <= 1'b1;
            tim_paddr   <= addr;
            tim_pwdata  <= data;
            tim_pstrb   <= strb;

            @(posedge sys_clk);
            tim_penable <= 1'b1;

            wait(tim_pready == 1'b1);
            #1;
            slverr      = tim_pslverr;

            @(posedge sys_clk);
            tim_psel    <= 1'b0;
            tim_penable <= 1'b0;
            tim_pwrite  <= 1'b0;
            tim_pstrb   <= 1'b0;
        end
    endtask

    task apb_read;
        input   [11:0]  addr;
        output  [31:0]  rdata;
        output          slverr;
        begin
            @(posedge sys_clk);
            tim_psel    <= 1'b1;
            tim_penable <= 1'b0;
            tim_pwrite  <= 1'b0;
            tim_paddr   <= addr;

            @(posedge sys_clk);
            tim_penable <= 1'b1;

            wait(tim_pready == 1'b1);
            #1;
            rdata       = tim_prdata;
            slverr      = tim_pslverr;

            @(posedge sys_clk);
            tim_psel    <= 1'b0;
            tim_penable <= 1'b0;
        end
    endtask

    `include "reg_init_chk.v"
    `include "reg_rw_chk.v"
    `include "reg_reserved_chk.v"
    `include "reg_1hot_chk.v"
    `include "apb_protocol_chk.v"
    `include "apb_multiple_access.v"
    `include "byte_access_chk.v"
    `include "error_logic_chk.v"
    `include "cnt_counting_chk.v"
    `include "cnt_ctrl_chk.v"
    `include "debug_halt_chk.v"
    `include "interrupt_chk.v"
    `include "cnt_divider_chk.v"

    reg [8*30:1] current_test;

    initial begin
        `ifdef __ICARUS__
            $dumpfile("dump.vcd");
            $dumpvars(0, test_bench.dut); 
        `endif
        sys_rst_n   = 1'b0;
        tim_psel    = 1'b0;
        tim_penable = 1'b0;
        tim_pwrite  = 1'b0;
        tim_paddr   = 12'h0;
        tim_pwdata  = 32'h0;
        tim_pstrb   = 4'h0;
        dbg_mode    = 1'b0;

        #25;
        sys_rst_n   = 1'b1;
        #20;

        if ($value$plusargs("TESTNAME=%s", current_test)) begin
            if (current_test == "reg_init_chk") reg_init_chk_task();
            else if (current_test == "reg_rw_chk") reg_rw_chk_task();
            else if (current_test == "reg_reserved_chk") reg_reserved_chk_task();
            else if (current_test == "reg_1hot_chk") reg_1hot_chk_task();

            else if (current_test == "apb_protocol_chk") apb_protocol_chk_task();
            else if (current_test == "apb_multiple_access") apb_multiple_access_task();
            else if (current_test == "byte_access_chk") byte_access_chk_task();
            else if (current_test == "error_logic_chk") error_logic_chk_task();

            else if (current_test == "cnt_counting_chk") cnt_counting_chk_task();
            else if (current_test == "cnt_ctrl_chk") cnt_ctrl_chk_task();
            else if (current_test == "debug_halt_chk") debug_halt_chk_task();

            else if (current_test == "interrupt_chk") interrupt_chk_task();

            else if (current_test == "cnt_divider_chk") cnt_divider_chk_task();

            else $display("ERROR: No task for testcase '%0s'", current_test);

        end else begin
            $display("ERROR: Cannot find parameter +TESTNAME from vsim!");
        end

        #50;
        $finish;
    end

endmodule