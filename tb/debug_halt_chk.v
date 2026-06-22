task debug_halt_chk_task;
    reg    [31:0] rdata;
    reg    [31:0] frozen_val;
    reg    [31:0] resume_val;
    reg           err_flag;
    integer       err_cnt;
    begin
        $display("=================================================");
        $display("[%0t] STARTING TESTCASE: debug_halt_chk", $time);
        $display("=================================================");

        err_cnt = 0;

        dbg_mode = 1'b1;
        $display("[%0t] System environment: dbg_mode is being set to 1...", $time);
        
        $display("[%0t] Starting Timer...", $time);
        // div_val=1, div_en=1, timer_en=1
        apb_write(12'h000, 32'h0000_0103, 4'b1111, err_flag);
        repeat(20) @(posedge sys_clk);
        
        $display("[%0t] Requesting Halt (THCSR.halt_req = 1) (CNT_04)...", $time);
        apb_write(12'h01C, 32'h0000_0001, 4'b1111, err_flag);
        repeat(5) @(posedge sys_clk);
        
        apb_read(12'h01C, rdata, err_flag);
        if (rdata[1:0] !== 2'b11) begin
            $display(" ERROR: THCSR.halt_ack did not assert! Got THCSR: 0x%08h", rdata);
            err_cnt = err_cnt + 1;
        end
        
        apb_read(12'h004, frozen_val, err_flag);
        $display("[%0t] Timer frozen at TDR0 = %0d", $time, frozen_val);
        repeat(20) @(posedge sys_clk);
        
        apb_read(12'h004, rdata, err_flag);
        if (rdata !== frozen_val) begin
            $display(" ERROR: Timer is not frozen! TDR0 changed from %0d to %0d", frozen_val, rdata);
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Forcing timer_en High -> Low while halted (CNT_05)...", $time);
        apb_write(12'h000, 32'h0000_0102, 4'b1111, err_flag);
        repeat(5) @(posedge sys_clk);
        
        apb_read(12'h004, rdata, err_flag);
        if (rdata === 32'h0) begin
            $display(" ERROR: Halt did not prevent Hardware Clear (TDR0 is 0).");
            err_cnt = err_cnt + 1;
        end else if (rdata !== frozen_val) begin
            $display(" ERROR: Value unexpectedly changed to %0d.", rdata);
            err_cnt = err_cnt + 1;
        end

        $display("[%0t] Resuming Timer (CNT_04)...", $time);
        apb_write(12'h000, 32'h0000_0103, 4'b1111, err_flag); 
        apb_write(12'h01C, 32'h0000_0000, 4'b1111, err_flag); 
        repeat(20) @(posedge sys_clk);
        
        apb_read(12'h004, resume_val, err_flag);
        if (resume_val <= frozen_val) begin
            $display(" ERROR: Timer did not resume counting! TDR0 stuck at %0d", resume_val);
            err_cnt = err_cnt + 1;
        end

        dbg_mode = 1'b0;
        apb_write(12'h000, 32'h0000_0102, 4'b1111, err_flag); 
        apb_write(12'h000, 32'h0000_0100, 4'b1111, err_flag); 
        
        $display("=================================================");
        if (err_cnt == 0)
            $display(">> Result: debug_halt_chk PASSED");
        else
            $display(">> Result: debug_halt_chk FAILED with %0d errors", err_cnt);
        $display("=================================================");
    end
endtask