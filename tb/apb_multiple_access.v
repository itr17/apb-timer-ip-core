task apb_multiple_access_task;
    reg    [31:0] rdata1;
    reg    [31:0] rdata2;
    reg    [31:0] rdata3;
    reg           err_flag;
    integer       err_cnt;
    begin
        $display("=================================================");
        $display("[%0t] STARTING TESTCASE (APB_02): apb_multiple_access", $time);
        $display("=================================================");

        err_cnt = 0;

        $display("[%0t] Performing Back-to-back Writes...", $time);
        @(posedge sys_clk);
        tim_paddr     <= 12'h00C;
        tim_pwrite    <= 1'b1;
        tim_pwdata    <= 32'h1111_2222;
        tim_pstrb     <= 4'b1111;
        tim_psel      <= 1'b1;
        tim_penable   <= 1'b0;
        
        @(posedge sys_clk);
        tim_penable   <= 1'b1;
        
        @(posedge sys_clk);
        @(posedge sys_clk);
        tim_paddr     <= 12'h010;
        tim_pwdata    <= 32'h3333_4444;
        tim_psel      <= 1'b1;
        tim_penable   <= 1'b0;
        
        @(posedge sys_clk);
        tim_penable   <= 1'b1;
        
        @(posedge sys_clk);
        @(posedge sys_clk);
        tim_paddr     <= 12'h014;
        tim_pwdata    <= 32'h0000_0001;
        tim_psel      <= 1'b1;
        tim_penable   <= 1'b0;
        
        @(posedge sys_clk);
        tim_penable   <= 1'b1;
        
        @(posedge sys_clk);
        @(posedge sys_clk);
        tim_psel      <= 1'b0;
        tim_penable   <= 1'b0;

        $display("[%0t] Performing Back-to-back Reads...", $time);
        apb_read(12'h00C, rdata1, err_flag);
        apb_read(12'h010, rdata2, err_flag);
        apb_read(12'h014, rdata3, err_flag);
        
        if (rdata1 !== 32'h1111_2222) begin
            $display(" ERROR: TCMP0 data corrupted during Back-to-back! Got: 0x%08h", rdata1);
            err_cnt = err_cnt + 1;
        end
        if (rdata2 !== 32'h3333_4444) begin
            $display(" ERROR: TCMP1 data corrupted during Back-to-back! Got: 0x%08h", rdata2);
            err_cnt = err_cnt + 1;
        end
        if (rdata3 !== 32'h0000_0001) begin
            $display(" ERROR: TIER data corrupted during Back-to-back! Got: 0x%08h", rdata3);
            err_cnt = err_cnt + 1;
        end

        apb_write(12'h00C, 32'hFFFF_FFFF, 4'b1111, err_flag);
        apb_write(12'h010, 32'hFFFF_FFFF, 4'b1111, err_flag);
        apb_write(12'h014, 32'h0000_0000, 4'b1111, err_flag);
        $display("=================================================");
        if (err_cnt == 0)
            $display(">> Result: apb_multiple_access PASSED");
        else
            $display(">> Result: apb_multiple_access FAILED with %0d errors", err_cnt);
        $display("=================================================");
    end
endtask