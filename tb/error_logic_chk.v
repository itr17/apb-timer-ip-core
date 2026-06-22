task error_logic_chk_task;
    reg    [31:0] rdata;
    reg           err_flag;
    integer       err_cnt;
    reg    [31:0] wdata;
    begin
        $display("=================================================");
        $display("[%0t] STARTING TESTCASE: error_logic_chk", $time);
        $display("=================================================");

        err_cnt = 0;

        $display("[%0t] Test 1 (APB_04): Writing invalid div_val (9) to TCR...", $time);
        apb_write(12'h000, 32'h0000_0900, 4'b1111, err_flag);
        if (err_flag !== 1'b1) begin
            $display(" ERROR: Hardware did not assert tim_pslverr for invalid div_val!");
            err_cnt = err_cnt + 1;
        end
        
        apb_read(12'h000, rdata, err_flag);
        if (rdata == 32'h0000_0900) begin
            $display(" ERROR: TCR was illegally overwritten despite the error!");
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Test 2 (APB_06 part 1): Error Recovery & Safe Ignore...", $time);
        apb_write(12'h000, 32'h0000_0100, 4'b1111, err_flag);
        if (err_flag !== 1'b0) begin
            $display(" ERROR: Bus failed to recover! tim_pslverr stuck at 1 on valid write.");
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Test 3 (APB_05): Changing div_en while Timer is running...", $time);
        apb_write(12'h000, 32'h0000_0101, 4'b1111, err_flag); 
        apb_write(12'h000, 32'h0000_0103, 4'b1111, err_flag); 
        if (err_flag !== 1'b1) begin
            $display(" ERROR: Hardware did not assert tim_pslverr when changing div_en!");
            err_cnt = err_cnt + 1;
        end
        apb_write(12'h000, 32'h0000_0100, 4'b1111, err_flag); 

        $display("[%0t] Test 4 (APB_05): Changing div_val while Timer is running...", $time);
        wdata = (1 << 8) | 32'h0000_0003; 
        apb_write(12'h000, wdata, 4'b1111, err_flag); 
        repeat(2) @(posedge sys_clk);
        
        wdata = (2 << 8) | 32'h0000_0003;
        apb_write(12'h000, wdata, 4'b1111, err_flag); 
        if (err_flag !== 1'b1) begin
            $display(" ERROR: Hardware did not assert tim_pslverr when changing div_val!");
            err_cnt = err_cnt + 1;
        end
        apb_write(12'h000, 32'h0000_0100, 4'b1111, err_flag); 

        
        $display("[%0t] Test 5 (APB_06 part 2): Writing to Unmapped Address (0x020)...", $time);
        apb_write(12'h020, 32'hDEAD_BEEF, 4'b1111, err_flag);
        if (err_flag === 1'b1) begin
            $display(" ERROR: Hardware incorrectly asserted tim_pslverr for unmapped address! It should just RAZ/WI.");
            err_cnt = err_cnt + 1;
        end

        
        apb_write(12'h000, 32'h0000_0000, 4'b1111, err_flag);

        $display("=================================================");
        if (err_cnt == 0)
            $display(">> Result: error_logic_chk PASSED");
        else
            $display(">> Result: error_logic_chk FAILED with %0d errors", err_cnt);
        $display("=================================================");
    end
endtask