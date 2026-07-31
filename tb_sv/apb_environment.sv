class apb_environment;
    apb_generator gen;
    apb_driver drv;
    apb_monitor mon;
    apb_scoreboard scb;

    mailbox #(apb_trans) gen2drv;
    mailbox #(apb_trans) mons2scb;

    virtual apb_timer_if vif;

    function new(virtual apb_timer_if vif, int num_trans = 10);
        this.vif     = vif;
        gen2drv      = new();
        mons2scb     = new();
        gen          = new(gen2drv, num_trans);
        drv          = new(vif, gen2drv);
        mon          = new(vif, mons2scb);
        scb          = new(vif, mons2scb);
    endfunction

    task pre_test();
        $display("==================================================");
        $display("[%0t] Waiting for Reset...", $time);
        wait(vif.sys_rst_n == 1'b1);
        @(posedge vif.sys_clk);
        $display("[%0t] Reset completed. Ready for test!", $time);
    endtask

    task test();
        $display("\n==================================================");
        $display("[%0t] Starting Simulation...", $time);
        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_none
    endtask

    task post_test();
        $display("\n==================================================");
        $display("[%0t] Test completed. Waiting for clean-up...", $time);
        @(gen.gen_done);
        wait(gen2drv.num() == 0);
        repeat(100) @(posedge vif.sys_clk);
        $display("\n==================================================");
        $display("                      SUMMARY                       ");
        $display("==================================================");
        $display("Number of passed testcase: %d", scb.pass_cnt);
        $display("Number of failed testcase: %d", scb.fail_cnt);
        if (scb.fail_cnt == 0 && scb.pass_cnt > 0) begin
            $display("\n PASSED ALL TESTS!\n");
        end else begin
            $display("\n SOME TESTS FAILED!\n");
        end
        $display("==================================================");
    endtask

    task run();
        pre_test();
        test();
        post_test();
    endtask
endclass