task cnt_ctrl_chk_task;
    reg    [31:0] val_norm;
    reg    [31:0] val_div2;
    reg    [31:0] val_div4;
    reg    [31:0] rdata0;
    reg    [31:0] rdata1;
    reg           err_flag;
    integer       err_cnt;
    begin
        $display("=================================================");
        $display("[%0t] STARTING TESTCASE: cnt_ctrl_chk", $time);
        $display("=================================================");

        err_cnt = 0;

        $display("[%0t] Testing Normal Speed (CNT_02)...", $time);
        apb_write(12'h000, 32'h0000_0101, 4'b1111, err_flag);
        repeat(100) @(posedge sys_clk); 
        apb_read(12'h004, val_norm, err_flag);
        apb_write(12'h000, 32'h0000_0100, 4'b1111, err_flag); 
        repeat(5) @(posedge sys_clk);

        $display("[%0t] Testing Divide-by-2 Speed (CNT_02)...", $time);
        apb_write(12'h000, 32'h0000_0103, 4'b1111, err_flag); 
        repeat(100) @(posedge sys_clk);
        apb_read(12'h004, val_div2, err_flag);
        apb_write(12'h000, 32'h0000_0102, 4'b1111, err_flag); 
        repeat(5) @(posedge sys_clk);

        $display("[%0t] Testing Divide-by-4 Speed (CNT_02)...", $time);
        apb_write(12'h000, 32'h0000_0202, 4'b1111, err_flag); 
        apb_write(12'h000, 32'h0000_0203, 4'b1111, err_flag); 
        repeat(100) @(posedge sys_clk);
        apb_read(12'h004, val_div4, err_flag);
        apb_write(12'h000, 32'h0000_0202, 4'b1111, err_flag); 
        repeat(5) @(posedge sys_clk);
        
        apb_write(12'h000, 32'h0000_0100, 4'b1111, err_flag);
        repeat(5) @(posedge sys_clk);

        $display("Counts after 100 cycles -> Normal: %0d | Div2: %0d | Div4: %0d", val_norm, val_div2, val_div4);
        
        if ((^val_norm === 1'bx) || (^val_div2 === 1'bx) || (^val_div4 === 1'bx)) begin
            $display(" ERROR: Speed Test FAILED: Registers contain unknown (X) values.");
            err_cnt = err_cnt + 1;
        end else begin
            if (val_div2 > (val_norm/2 + 3) || val_div2 < (val_norm/2 - 3)) begin
                $display(" ERROR: Divide by 2 ratio is incorrect!");
                err_cnt = err_cnt + 1;
            end
            if (val_div4 > (val_norm/4 + 3) || val_div4 < (val_norm/4 - 3)) begin
                $display(" ERROR: Divide by 4 ratio is incorrect!");
                err_cnt = err_cnt + 1;
            end
        end

        $display("[%0t] Starting Timer for Auto-clear test (CNT_03)...", $time);
        apb_write(12'h000, 32'h0000_0101, 4'b1111, err_flag);
        repeat(20) @(posedge sys_clk);
        
        $display("[%0t] Disabling Timer (High -> Low) (CNT_03)...", $time);
        apb_write(12'h000, 32'h0000_0100, 4'b1111, err_flag);
        repeat(5) @(posedge sys_clk);
        
        apb_read(12'h004, rdata0, err_flag);
        apb_read(12'h008, rdata1, err_flag);
        
        if ((rdata0 !== 32'h0) || (rdata1 !== 32'h0)) begin
            $display(" ERROR: TDR0/TDR1 not cleared to 0! Got: %08h_%08h", rdata1, rdata0);
            err_cnt = err_cnt + 1;
        end

        $display("=================================================");
        if (err_cnt == 0)
            $display(">> Result: cnt_ctrl_chk PASSED");
        else
            $display(">> Result: cnt_ctrl_chk FAILED with %0d errors", err_cnt);
        $display("=================================================");
    end
endtask