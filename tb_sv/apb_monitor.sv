class apb_monitor;
    virtual apb_timer_if vif;
    mailbox #(apb_trans) mons2scb;

    function new(virtual apb_timer_if vif, mailbox #(apb_trans) mbx);
        this.vif = vif;
        this.mons2scb = mbx;
    endfunction

    task run();
        $display("[%0t] Turned on Monitor...", $time);
        forever begin
            @(posedge vif.sys_clk);
            // SETUP phase
            if (vif.tim_psel === 1'b1 && vif.tim_penable === 1'b0) begin
                apb_trans req       = new();
                req.phase_type      = "REQ";
                req.tim_paddr       = vif.tim_paddr;
                req.tim_pwrite      = vif.tim_pwrite;
                req.tim_pstrb       = vif.tim_pstrb;
                req.tim_pwdata      = vif.tim_pwdata;
                req.tim_prdata      = vif.tim_prdata;
                req.tim_pslverr     = vif.tim_pslverr;
                mons2scb.put(req);
            end
            // ACCESS phase
            if (vif.tim_psel === 1'b1 && vif.tim_penable === 1'b1 && vif.tim_pready === 1'b1) begin
                apb_trans rsp       = new();
                rsp.phase_type      = "RSP";
                rsp.tim_paddr       = vif.tim_paddr;
                rsp.tim_pwrite      = vif.tim_pwrite;
                rsp.tim_prdata      = vif.tim_prdata;
                rsp.tim_pslverr     = vif.tim_pslverr;
                mons2scb.put(rsp);
            end
        end
    endtask
endclass