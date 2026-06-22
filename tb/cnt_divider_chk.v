task cnt_divider_chk_task;
    reg    [31:0] wdata;
    reg    [31:0] rdata;
    reg           err_flag;
    integer       err_cnt;
    integer       i;
    begin
        $display("=================================================");
        $display("[%0t] STARTING TESTCASE (CNT_06): cnt_divider_chk", $time);
        $display("=================================================");

        err_cnt = 0;

        $display("[%0t] Sweeping valid div_val from 0 to 8...", $time);
        for (i = 0; i <= 8; i = i + 1) begin
            wdata = (i << 8) | 32'h0000_0000; 
            apb_write(12'h000, wdata, 4'b1111, err_flag);
            
            apb_read(12'h000, rdata, err_flag);
            if (rdata[11:8] !== i) begin
                $display(" ERROR: div_val sweep failed at i = %0d! Expected: 0x%08h Got: 0x%08h", i, i, rdata[11:8]);
                err_cnt = err_cnt + 1;
            end
        end

        $display("[%0t] Testing Divide-by-256 Speed (div_val = 8)...", $time);
        
        wdata = (8 << 8) | 32'h0000_0002;
        apb_write(12'h000, wdata, 4'b1111, err_flag);
        
        wdata = (8 << 8) | 32'h0000_0003;
        apb_write(12'h000, wdata, 4'b1111, err_flag);
        
        repeat(600) @(posedge sys_clk);
        
        apb_read(12'h004, rdata, err_flag);
        if (rdata !== 32'h0000_0002) begin
            $display(" ERROR: Divide by 256 failed! Expected TDR0 = 2, Got: %0d", rdata);
            err_cnt = err_cnt + 1;
        end else begin
            $display("[%0t] Divide-by-256 matched perfectly! TDR0 = %0d", $time, rdata);
        end

        wdata = (8 << 8) | 32'h0000_0002;
        apb_write(12'h000, wdata, 4'b1111, err_flag);
        repeat(5) @(posedge sys_clk);

        apb_write(12'h000, 32'h0000_0100, 4'b1111, err_flag);

        $display("=================================================");
        if (err_cnt == 0)
            $display(">> Result: cnt_divider_chk PASSED");
        else
            $display(">> Result: cnt_divider_chk FAILED with %0d errors", err_cnt);
        $display("=================================================");
    end
endtask