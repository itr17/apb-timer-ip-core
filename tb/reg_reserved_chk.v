task reg_reserved_chk_task;
    reg    [31:0] rdata;
    reg           err_flag;
    integer       err_cnt;
    begin
        $display("=================================================");
        $display("[%0t] STARTING TESTCASE (REG_03): reg_reserved_chk", $time);
        $display("=================================================");

        err_cnt = 0;

        $display("[%0t] Testing Reserved bits in TCR...", $time);
        apb_write(12'h000, 32'hFFFF_F1FC, 4'b1111, err_flag);
        apb_read(12'h000, rdata, err_flag);
        if ((rdata & 32'hFFFF_F0FC) !== 32'h0) begin
            $display(" ERROR: TCR Reserved bits overwritten! Got: 0x%08h", rdata);
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Testing Reserved bits in TIER...", $time);
        apb_write(12'h014, 32'hFFFF_FFFF, 4'b1111, err_flag);
        apb_read(12'h014, rdata, err_flag);
        if ((rdata & 32'hFFFF_FFFE) !== 32'h0) begin
            $display(" ERROR: TIER Reserved bits overwritten! Got: 0x%08h", rdata);
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Testing Reserved bits in TISR...", $time);
        apb_write(12'h018, 32'hFFFF_FFFF, 4'b1111, err_flag);
        apb_read(12'h018, rdata, err_flag);
        if ((rdata & 32'hFFFF_FFFE) !== 32'h0) begin
            $display(" ERROR: TISR Reserved bits overwritten! Got: 0x%08h", rdata);
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Testing Reserved bits in THCSR...", $time);
        apb_write(12'h01C, 32'hFFFF_FFFF, 4'b1111, err_flag);
        apb_read(12'h01C, rdata, err_flag);
        if ((rdata & 32'hFFFF_FFFE) !== 32'h0) begin
            $display(" ERROR: THCSR Reserved bits overwritten! Got: 0x%08h", rdata);
            err_cnt = err_cnt + 1;
        end

        // Dọn dẹp trả về giá trị Reset mặc định
        apb_write(12'h000, 32'h0000_0000, 4'b1111, err_flag); 
        apb_write(12'h014, 32'h0000_0000, 4'b1111, err_flag); 
        apb_write(12'h018, 32'hFFFF_FFFF, 4'b1111, err_flag); 
        apb_write(12'h01C, 32'h0000_0000, 4'b1111, err_flag); 

        $display("=================================================");
        if (err_cnt == 0)
            $display(">> Result: reg_reserved_chk PASSED");
        else
            $display(">> Result: reg_reserved_chk FAILED with %0d errors", err_cnt);
        $display("=================================================");
    end
endtask