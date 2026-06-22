task reg_rw_chk_task;
    reg    [31:0] rdata;
    reg           err_flag;
    integer       err_cnt;
    begin
        $display("=================================================");
        $display("[%0t] STARTING TESTCASE (REG_02): reg_rw_chk", $time);
        $display("=================================================");

        err_cnt = 0;

        apb_write(12'h000, 32'h0000_0000, 4'b1111, err_flag);

        $display("[%0t] Testing TCMP0 (0x00C)...", $time);
        apb_write(12'h00C, 32'h5555_5555, 4'b1111, err_flag);
        apb_read(12'h00C, rdata, err_flag);
        if (rdata !== 32'h5555_5555) begin
            $display(" ERROR: TCMP0 0x55 mismatch! Expected: 0x55555555 Got: 0x%08h", rdata);
            err_cnt = err_cnt + 1;
        end
        apb_write(12'h00C, 32'hAAAA_AAAA, 4'b1111, err_flag);
        apb_read(12'h00C, rdata, err_flag);
        if (rdata !== 32'hAAAA_AAAA) begin
            $display(" ERROR: TCMP0 0xAA mismatch! Expected: 0xAAAAAAAA Got: 0x%08h", rdata);
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Testing TCMP1 (0x010)...", $time);
        apb_write(12'h010, 32'h5555_5555, 4'b1111, err_flag);
        apb_read(12'h010, rdata, err_flag);
        if (rdata !== 32'h5555_5555) begin
            $display(" ERROR: TCMP1 0x55 mismatch! Got: 0x%08h", rdata);
            err_cnt = err_cnt + 1;
        end
        apb_write(12'h010, 32'hAAAA_AAAA, 4'b1111, err_flag);
        apb_read(12'h010, rdata, err_flag);
        if (rdata !== 32'hAAAA_AAAA) begin
            $display(" ERROR: TCMP1 0xAA mismatch! Got: 0x%08h", rdata);
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Testing TDR0 (0x004)...", $time);
        apb_write(12'h004, 32'h5555_5555, 4'b1111, err_flag);
        apb_read(12'h004, rdata, err_flag);
        if (rdata !== 32'h5555_5555) begin
            $display(" ERROR: TDR0 0x55 mismatch! Got: 0x%08h", rdata);
            err_cnt = err_cnt + 1;
        end
        apb_write(12'h004, 32'hAAAA_AAAA, 4'b1111, err_flag);
        apb_read(12'h004, rdata, err_flag);
        if (rdata !== 32'hAAAA_AAAA) begin
            $display(" ERROR: TDR0 0xAA mismatch! Got: 0x%08h", rdata);
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Testing TDR1 (0x008)...", $time);
        apb_write(12'h008, 32'h5555_5555, 4'b1111, err_flag);
        apb_read(12'h008, rdata, err_flag);
        if (rdata !== 32'h5555_5555) begin
            $display(" ERROR: TDR1 0x55 mismatch! Got: 0x%08h", rdata);
            err_cnt = err_cnt + 1;
        end
        apb_write(12'h008, 32'hAAAA_AAAA, 4'b1111, err_flag);
        apb_read(12'h008, rdata, err_flag);
        if (rdata !== 32'hAAAA_AAAA) begin
            $display(" ERROR: TDR1 0xAA mismatch! Got: 0x%08h", rdata);
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Testing RW bits in TIER & THCSR...", $time);
        
        apb_write(12'h014, 32'h5555_5555, 4'b1111, err_flag);
        apb_read(12'h014, rdata, err_flag);
        if ((rdata & 32'h1) !== 32'h1) begin
            $display(" ERROR: TIER bit 0 RW failed on 0x55! Got: 0x%08h", rdata);
            err_cnt = err_cnt + 1;
        end
        apb_write(12'h014, 32'hAAAA_AAAA, 4'b1111, err_flag);
        apb_read(12'h014, rdata, err_flag);
        if ((rdata & 32'h1) !== 32'h0) begin
            $display(" ERROR: TIER bit 0 RW failed on 0xAA! Got: 0x%08h", rdata);
            err_cnt = err_cnt + 1;
        end

        apb_write(12'h01C, 32'h5555_5555, 4'b1111, err_flag);
        apb_read(12'h01C, rdata, err_flag);
        if ((rdata & 32'h1) !== 32'h1) begin
            $display(" ERROR: THCSR bit 0 RW failed on 0x55! Got: 0x%08h", rdata);
            err_cnt = err_cnt + 1;
        end
        apb_write(12'h01C, 32'hAAAA_AAAA, 4'b1111, err_flag);
        apb_read(12'h01C, rdata, err_flag);
        if ((rdata & 32'h1) !== 32'h0) begin
            $display(" ERROR: THCSR bit 0 RW failed on 0xAA! Got: 0x%08h", rdata);
            err_cnt = err_cnt + 1;
        end

        apb_write(12'h004, 32'h0000_0000, 4'b1111, err_flag);
        apb_write(12'h008, 32'h0000_0000, 4'b1111, err_flag);
        apb_write(12'h00C, 32'hFFFF_FFFF, 4'b1111, err_flag);
        apb_write(12'h010, 32'hFFFF_FFFF, 4'b1111, err_flag);
        apb_write(12'h014, 32'h0000_0000, 4'b1111, err_flag);
        apb_write(12'h01C, 32'h0000_0000, 4'b1111, err_flag);

        $display("=================================================");
        if (err_cnt == 0)
            $display(">> Result: reg_rw_chk PASSED");
        else
            $display(">> Result: reg_rw_chk FAILED with %0d errors", err_cnt);
        $display("=================================================");
    end
endtask