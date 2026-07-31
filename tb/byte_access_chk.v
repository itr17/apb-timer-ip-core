task byte_access_chk_task;
    reg    [31:0] rdata0;
    reg    [31:0] rdata1;
    reg           err_flag;
    integer       err_cnt;
    begin
        $display("=================================================");
        $display("[%0t] STARTING TESTCASE (APB_03): byte_access_chk", $time);
        $display("=================================================");

        err_cnt = 0;

        apb_write(12'h00C, 32'h0000_0000, 4'b1111, err_flag);
        apb_write(12'h010, 32'h0000_0000, 4'b1111, err_flag);

        
        $display("[%0t] Writing Byte 0 (pstrb = 4'b0001) with 0xAA to TCMP...", $time);
        apb_write(12'h00C, 32'hFFFF_FFAA, 4'b0001, err_flag);
        apb_write(12'h010, 32'hFFFF_FFAA, 4'b0001, err_flag);
        apb_read(12'h00C, rdata0, err_flag);
        apb_read(12'h010, rdata1, err_flag);
        if ((rdata0 !== 32'h0000_00AA) || (rdata1 !== 32'h0000_00AA)) begin
            $display(" ERROR: Byte 0 access failed! Expected: 0x000000AA Got: 0x%08h (TCMP0), 0x%08h (TCMP1)", rdata0, rdata1);
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Writing Byte 1 (pstrb = 4'b0010) with 0xBB to TCMP...", $time);
        apb_write(12'h00C, 32'hFFFF_BBFF, 4'b0010, err_flag);
        apb_write(12'h010, 32'hFFFF_BBFF, 4'b0010, err_flag);
        apb_read(12'h00C, rdata0, err_flag);
        apb_read(12'h010, rdata1, err_flag);
        if ((rdata0 !== 32'h0000_BBAA) || (rdata1 !== 32'h0000_BBAA)) begin
            $display(" ERROR: Byte 1 access failed! Expected: 0x0000BBAA Got: 0x%08h (TCMP0), 0x%08h (TCMP1)", rdata0, rdata1);
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Writing Byte 2 (pstrb = 4'b0100) with 0xCC to TCMP...", $time);
        apb_write(12'h00C, 32'hFFCC_FFFF, 4'b0100, err_flag);
        apb_write(12'h010, 32'hFFCC_FFFF, 4'b0100, err_flag);
        apb_read(12'h00C, rdata0, err_flag);
        apb_read(12'h010, rdata1, err_flag);
        if ((rdata0 !== 32'h00CC_BBAA) || (rdata1 !== 32'h00CC_BBAA)) begin
            $display(" ERROR: Byte 2 access failed! Expected: 0x00CCBBAA Got: 0x%08h (TCMP0), 0x%08h (TCMP1)", rdata0, rdata1);
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Writing Byte 3 (pstrb = 4'b1000) with 0xDD to TCMP...", $time);
        apb_write(12'h00C, 32'hDDFF_FFFF, 4'b1000, err_flag);
        apb_write(12'h010, 32'hDDFF_FFFF, 4'b1000, err_flag);
        apb_read(12'h00C, rdata0, err_flag);
        apb_read(12'h010, rdata1, err_flag);
        if ((rdata0 !== 32'hDDCC_BBAA) || (rdata1 !== 32'hDDCC_BBAA)) begin
            $display(" ERROR: Byte 3 access failed! Expected: 0xDDCCBBAA Got: 0x%08h (TCMP0), 0x%08h (TCMP1)", rdata0, rdata1);
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Writing TCR with pstrb = 4'b1110 (pstrb[0]=0)...", $time);
        apb_write(12'h000, 32'h0000_05FF, 4'b1110, err_flag); 
        apb_read(12'h000, rdata0, err_flag);
        if (rdata0 !== 32'h0000_0500) begin
            $display(" ERROR: TCR Access Failed! Expected: 0x00000500 Got: 0x%08h", rdata0);
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Writing TCR with pstrb = 4'b1101 (pstrb[1]=0)...", $time);
        apb_write(12'h000, 32'h0000_05FF, 4'b1101, err_flag);
        apb_read(12'h000, rdata1, err_flag);
        if (rdata1 !== 32'h0000_0503) begin
            $display(" ERROR: TCR Access Failed! Expected: 0x00000503 Got: 0x%08h", rdata1);
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Coverage fix: Writing TIER (0x014) with pstrb = 4'b1110...", $time);
        apb_write(12'h014, 32'hFFFF_FFFF, 4'b1110, err_flag); 
        apb_read(12'h014, rdata0, err_flag);
        if (rdata0 !== 32'h0000_0000) begin
            $display(" ERROR: TIER Access Failed! Expected: 0x00000000 Got: 0x%08h", rdata0);
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Coverage fix: Writing THCSR (0x01C) with pstrb = 4'b1110...", $time);
        apb_write(12'h01C, 32'hFFFF_FFFF, 4'b1110, err_flag); 
        apb_read(12'h01C, rdata1, err_flag);
        if (rdata1 !== 32'h0000_0000) begin
            $display(" ERROR: THCSR Access Failed! Expected: 0x00000000 Got: 0x%08h", rdata1);
            err_cnt = err_cnt + 1;
        end

        apb_write(12'h000, 32'h0000_0100, 4'b1111, err_flag);
        apb_write(12'h00C, 32'hFFFF_FFFF, 4'b1111, err_flag);
        apb_write(12'h010, 32'hFFFF_FFFF, 4'b1111, err_flag);

        $display("=================================================");
        if (err_cnt == 0)
            $display(">> Result: byte_access_chk PASSED");
        else
            $display(">> Result: byte_access_chk FAILED with %0d errors", err_cnt);
        $display("=================================================");
    end
endtask