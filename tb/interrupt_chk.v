task interrupt_chk_task;
    reg    [31:0] rdata;
    reg           err_flag;
    integer       err_cnt;
    begin
        $display("=================================================");
        $display("[%0t] STARTING TESTCASE: interrupt_chk", $time);
        $display("=================================================");

        err_cnt = 0;

        dbg_mode = 1'b0; 

        $display("[%0t] Generating Hardware Interrupt (INT_01)...", $time);
        apb_write(12'h00C, 32'd50, 4'b1111, err_flag);
        apb_write(12'h010, 32'd0, 4'b1111, err_flag);
        apb_write(12'h000, 32'h0000_0101, 4'b1111, err_flag);
        #1000;
        apb_read(12'h018, rdata, err_flag);
        if (rdata[0] !== 1'b1) begin
            $display(" ERROR: TISR.int_st was not set to 1 after crossing TCMP0!");
            err_cnt = err_cnt + 1;
        end
        apb_read(12'h004, rdata, err_flag);
        if (rdata <= 32'd50) begin
            $display(" ERROR: Timer stopped counting after match event!");
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Interrupt Enable & Masking (INT_02)...", $time);
        apb_write(12'h014, 32'h0000_0001, 4'b1111, err_flag);
        #10;
        if (tim_int !== 1'b1) begin
            $display(" ERROR: External tim_int is NOT high when TIER.int_en = 1!");
            err_cnt = err_cnt + 1;
        end
        apb_write(12'h014, 32'h0000_0000, 4'b1111, err_flag);
        #10;
        if (tim_int !== 1'b0) begin
            $display(" ERROR: External tim_int did NOT drop to low when masked!");
            err_cnt = err_cnt + 1;
        end
        apb_read(12'h018, rdata, err_flag);
        if (rdata[0] !== 1'b1) begin
            $display(" ERROR: Internal TISR.int_st dropped to 0! It should not change.");
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Write-1-to-Clear logic & Byte Strobe (INT_03)...", $time);
        
        apb_write(12'h018, 32'h0000_0000, 4'b1111, err_flag);
        apb_read(12'h018, rdata, err_flag);
        if (rdata[0] !== 1'b1) begin
            $display(" ERROR: TISR cleared when writing 0.");
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Testing W1C with masked byte strobe (pstrb = 4'b1110)...", $time);
        apb_write(12'h018, 32'h0000_0001, 4'b1110, err_flag);
        apb_read(12'h018, rdata, err_flag);
        if (rdata[0] !== 1'b1) begin
            $display(" ERROR: TISR cleared even when Byte 0 was masked by pstrb!");
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Testing valid W1C (pstrb = 4'b1111)...", $time);
        apb_write(12'h018, 32'h0000_0001, 4'b1111, err_flag);
        apb_read(12'h018, rdata, err_flag);
        if (rdata[0] !== 1'b0) begin
            $display(" ERROR: TISR did NOT clear when writing 1.");
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Set vs Clear Collision priority (INT_04)...", $time);
        apb_write(12'h000, 32'h0000_0000, 4'b1111, err_flag); 
        apb_write(12'h000, 32'h0000_0100, 4'b1111, err_flag);
        
        apb_write(12'h00C, 32'd20, 4'b1111, err_flag);
        apb_write(12'h000, 32'h0000_0101, 4'b1111, err_flag);
        
        repeat(17) @(posedge sys_clk); 
        apb_write(12'h018, 32'h0000_0001, 4'b1111, err_flag); 
        
        #20;
        apb_read(12'h018, rdata, err_flag);
        if (rdata[0] !== 1'b0) begin
            $display(" ERROR: Hardware Set overwrote Software Clear. Priority is wrong!");
            err_cnt = err_cnt + 1;
        end

        apb_write(12'h000, 32'h0000_0000, 4'b1111, err_flag);
        
        $display("=================================================");
        if (err_cnt == 0)
            $display(">> Result: interrupt_chk PASSED");
        else
            $display(">> Result: interrupt_chk FAILED with %0d errors", err_cnt);
        $display("=================================================");
    end
endtask