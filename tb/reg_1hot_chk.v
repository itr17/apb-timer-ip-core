task reg_1hot_chk_task;
    reg    [31:0] wdata;
    reg    [31:0] rdata0;
    reg    [31:0] rdata1;
    reg           err_flag;
    integer       err_cnt;
    integer       i;
    begin
        $display("=================================================");
        $display("[%0t] STARTING TESTCASE (REG_04): reg_1hot_chk", $time);
        $display("=================================================");

        err_cnt = 0;

        $display("[%0t] Performing Walking-1 pattern test on TCMP0 and TCMP1...", $time);
        for (i = 0; i < 32; i = i + 1) begin
            wdata = 32'h0000_0001 << i;
    
            apb_write(12'h00C, wdata, 4'b1111, err_flag);
            apb_write(12'h010, wdata, 4'b1111, err_flag);

            apb_read(12'h00C, rdata0, err_flag);
            apb_read(12'h010, rdata1, err_flag);

            if (rdata0 !== wdata) begin
                $display(" ERROR: Walking-1 failed on TCMP0 at bit %0d! Expected: 0x%08h Got: 0x%08h", i, wdata, rdata0);
                err_cnt = err_cnt + 1;
            end
            if (rdata1 !== wdata) begin
                $display(" ERROR: Walking-1 failed on TCMP1 at bit %0d! Expected: 0x%08h Got: 0x%08h", i, wdata, rdata1);
                err_cnt = err_cnt + 1;
            end
        end

        apb_write(12'h00C, 32'hFFFF_FFFF, 4'b1111, err_flag);
        apb_write(12'h010, 32'hFFFF_FFFF, 4'b1111, err_flag);

        $display("=================================================");
        if (err_cnt == 0)
            $display(">> Result: reg_1hot_chk PASSED");
        else
            $display(">> Result: reg_1hot_chk FAILED with %0d errors", err_cnt);
        $display("=================================================");
    end
endtask