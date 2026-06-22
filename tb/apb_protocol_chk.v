task apb_protocol_chk_task;
    reg    [31:0] rdata;
    reg           err_flag;
    integer       err_cnt;
    begin
        $display("=================================================");
        $display("[%0t] STARTING TESTCASE (APB_01): apb_protocol_chk", $time);
        $display("=================================================");

        err_cnt = 0;
        
        $display("[%0t] Writing Data: 0x00000503 to TCR...", $time);
        apb_write(12'h000, 32'h0000_0503, 4'b1111, err_flag);

        $display("[%0t] Reading Data from TCR...", $time);
        apb_read(12'h000, rdata, err_flag);

        if (rdata !== 32'h0000_0503) begin
            $display("[%0t] ERROR: Read data mismatch! Expected: 0x00000503, Got: 0x%08h", $time, rdata);
            err_cnt = err_cnt + 1;
        end else begin
            $display("[%0t] PASS: Read data exactly matches Written data.", $time);
        end

        $display("[%0t] Cleaning up: Resetting TCR to 0x00000000...", $time);
        apb_write(12'h000, 32'h0000_0000, 4'b1111, err_flag);

        $display("=================================================");
        if (err_cnt == 0)
            $display(">> Result: apb_protocol_chk PASSED");
        else
            $display(">> Result: apb_protocol_chk FAILED with %0d errors", err_cnt);
        $display("=================================================");
    end
endtask