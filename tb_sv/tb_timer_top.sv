`timescale 1ns/1ps
`include "apb_trans.sv"
`include "apb_driver.sv"
`include "apb_generator.sv"
`include "apb_monitor.sv"
`include "apb_scoreboard.sv"
`include "apb_timer_if.sv"
`include "apb_environment.sv"

module tb_timer_top;

    logic sys_clk;
    logic sys_rst_n;
    logic dbg_mode;

    initial begin
        sys_clk = 1'b0;
        forever #5 sys_clk = ~sys_clk;
    end

    initial begin
        sys_rst_n = 1'b0;
        dbg_mode  = 1'b0;
        #22;
        sys_rst_n = 1'b1;
    end

    apb_timer_if vif(sys_clk, sys_rst_n);
    assign vif.dbg_mode = dbg_mode;
    timer_top u_dut (
        .sys_clk        (sys_clk),
        .sys_rst_n      (sys_rst_n),
    
        .tim_psel       (vif.tim_psel),
        .tim_penable    (vif.tim_penable),
        .tim_pwrite     (vif.tim_pwrite),
        .tim_paddr      (vif.tim_paddr),
        .tim_pwdata     (vif.tim_pwdata),
        .tim_pstrb      (vif.tim_pstrb),
        .tim_prdata     (vif.tim_prdata),
        .tim_pready     (vif.tim_pready),
        .tim_pslverr    (vif.tim_pslverr),
        
        .tim_int        (vif.tim_int),
        .dbg_mode       (vif.dbg_mode)
    );
    apb_environment env;

    initial begin
        $dumpfile("timer_sim_waves.vcd");
        $dumpvars(0, tb_timer_top);

        $display("\n=======================================================");
        $display("              START SIMULATION FOR TIMER IP           ");
        $display("=======================================================\n");

        env = new(vif, 10000); 

        env.run();

        $display("\n=======================================================");
        $display("                    END OF SIMULATION                    ");
        $display("=======================================================\n");
        
        $finish; 
    end
endmodule