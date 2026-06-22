task cnt_counting_chk_task;
    reg    [31:0] rdata0;
    reg    [31:0] rdata1;
    reg           err_flag;
    integer       err_cnt;
    begin
        $display("=================================================");
        $display("[%0t] STARTING TESTCASE (CNT_01): cnt_counting_chk", $time);
        $display("=================================================");

        err_cnt = 0;

        $display("[%0t] Preloading TDR0 and TDR1 to near max value...", $time);
        apb_write(12'h004, 32'hFFFF_FFFC, 4'b1111, err_flag);
        apb_write(12'h008, 32'hFFFF_FFFF, 4'b1111, err_flag);
        
        $display("[%0t] Enabling Timer (div_en = 0, timer_en = 1)...", $time);
        apb_write(12'h000, 32'h0000_0101, 4'b1111, err_flag);
        
        repeat(20) @(posedge sys_clk); 
        
        apb_read(12'h004, rdata0, err_flag);
        apb_read(12'h008, rdata1, err_flag);
        $display("[%0t] Reading TDR0 and TDR1 after overflow... --> TDR1_TDR0: 0x%08h_%08h", $time, rdata1, rdata0);
        
        if (rdata1 !== 32'h0000_0000) begin
            $display(" ERROR: TDR1 did not overflow to 0! Got: 0x%08h", rdata1);
            err_cnt = err_cnt + 1;
        end else if (rdata0 < 32'h0000_0010 || rdata0 > 32'h0000_0050) begin 
            $display(" ERROR: TDR0 did not wrap correctly! Got: 0x%08h", rdata0);
            err_cnt = err_cnt + 1;
        end

        apb_write(12'h000, 32'h0000_0100, 4'b1111, err_flag);

        $display("=================================================");
        if (err_cnt == 0)
            $display(">> Result: cnt_counting_chk PASSED");
        else
            $display(">> Result: cnt_counting_chk FAILED with %0d errors", err_cnt);
        $display("=================================================");
    end
endtask