task reg_init_chk_task;
    reg    [31:0] rdata;
    reg           err_flag;
    integer       err_cnt;
    begin
        $display("=================================================");
        $display("[%0t] STARTING TESTCASE (REG_01): reg_init_chk", $time);
        $display("=================================================");

        err_cnt = 0;

        $display("[%0t] Asserting System Reset...", $time);
        @(negedge sys_clk); 
        sys_rst_n = 1'b0;
        
        repeat(5) @(negedge sys_clk);
        sys_rst_n = 1'b1;
        
        repeat(2) @(posedge sys_clk);
        $display("[%0t] System Reset Released. Checking default values...", $time);

        apb_read(12'h000, rdata, err_flag);
        if (rdata !== 32'h0000_0100) begin
            $display("[%0t] ERROR: TCR Reset value mismatch! Expected: 0x00000100, Got: 0x%08h", $time, rdata);
            err_cnt = err_cnt + 1;
        end else
            $display("[%0t] PASS: TCR Reset value is correct.", $time);

        apb_read(12'h004, rdata, err_flag);
        if (rdata !== 32'h0000_0000) begin
            $display("[%0t] ERROR: TDR0 Reset value mismatch! Expected: 0x00000000, Got: 0x%08h", $time, rdata);
            err_cnt = err_cnt + 1;
        end else
            $display("[%0t] PASS: TDR0 Reset value is correct.", $time);

        apb_read(12'h008, rdata, err_flag);
        if (rdata !== 32'h0000_0000) begin
            $display("[%0t] ERROR: TDR1 Reset value mismatch! Expected: 0x00000000, Got: 0x%08h", $time, rdata);
            err_cnt = err_cnt + 1;
        end else
            $display("[%0t] PASS: TDR1 Reset value is correct.", $time);

        apb_read(12'h00C, rdata, err_flag);
        if (rdata !== 32'hFFFF_FFFF) begin
            $display("[%0t] ERROR: TCMP0 Reset value mismatch! Expected: 0xFFFFFFFF, Got: 0x%08h", $time, rdata);
            err_cnt = err_cnt + 1;
        end else
            $display("[%0t] PASS: TCMP0 Reset value is correct.", $time);

        apb_read(12'h010, rdata, err_flag);
        if (rdata !== 32'hFFFF_FFFF) begin
            $display("[%0t] ERROR: TCMP1 Reset value mismatch! Expected: 0xFFFFFFFF, Got: 0x%08h", $time, rdata);
            err_cnt = err_cnt + 1;
        end else
            $display("[%0t] PASS: TCMP1 Reset value is correct.", $time);

        apb_read(12'h014, rdata, err_flag);
        if (rdata !== 32'h0000_0000) begin
            $display("[%0t] ERROR: TIER Reset value mismatch! Expected: 0x00000000, Got: 0x%08h", $time, rdata);
            err_cnt = err_cnt + 1;
        end else
            $display("[%0t] PASS: TIER Reset value is correct.", $time);

        apb_read(12'h018, rdata, err_flag);
        if (rdata !== 32'h0000_0000) begin
            $display("[%0t] ERROR: TISR Reset value mismatch! Expected: 0x00000000, Got: 0x%08h", $time, rdata);
            err_cnt = err_cnt + 1;
        end else
            $display("[%0t] PASS: TISR Reset value is correct.", $time);

        apb_read(12'h01C, rdata, err_flag);
        if (rdata !== 32'h0000_0000) begin
            $display("[%0t] ERROR: THCSR Reset value mismatch! Expected: 0x00000000, Got: 0x%08h", $time, rdata);
            err_cnt = err_cnt + 1;
        end else
            $display("[%0t] PASS: THCSR Reset value is correct.", $time);

        $display("=================================================");
        if (err_cnt == 0)
            $display(">> Result: reg_init_chk PASSED");
        else
            $display(">> Result: reg_init_chk FAILED with %0d errors", err_cnt);
        $display("=================================================");

    end
endtask