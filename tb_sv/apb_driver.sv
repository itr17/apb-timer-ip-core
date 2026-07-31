class apb_driver;

    virtual apb_timer_if vif;
    mailbox #(apb_trans) gen2drv;

    function new(virtual apb_timer_if vif, mailbox #(apb_trans) mbx);
        this.vif = vif;
        this.gen2drv = mbx;
    endfunction

    task reset_bus();
        vif.tim_psel    <= 0;
        vif.tim_penable <= 0;
        vif.tim_pwrite  <= 0;
        vif.tim_paddr   <= 0;
        vif.tim_pwdata  <= 0;
        vif.tim_pstrb   <= 0;
    endtask

    task run();
        apb_trans req;
        reset_bus();
        
        forever begin
            if (gen2drv.num() == 0) begin
                vif.tim_psel    <= 1'b0;
                vif.tim_penable <= 1'b0;
                gen2drv.get(req); 
                @(posedge vif.sys_clk);
            end else begin
                gen2drv.get(req);
            end
            // SETUP phase
            vif.tim_psel    <= 1'b1;         
            vif.tim_penable <= 1'b0;        
            vif.tim_paddr   <= req.tim_paddr;
            vif.tim_pwrite  <= req.tim_pwrite;
            vif.tim_pstrb   <= req.tim_pstrb;
            if (req.tim_pwrite) begin 
                vif.tim_pwdata <= req.tim_pwdata;
            end
            // ACCESS phase
            @(posedge vif.sys_clk);
            vif.tim_penable <= 1'b1;
            // Wait state 
            do begin
                @(posedge vif.sys_clk);
            end while (vif.tim_pready == 1'b0);
        end
    endtask

endclass