class apb_scoreboard;
    virtual apb_timer_if vif;
    mailbox #(apb_trans) mons2scb;
    
    bit [31:0] ref_tcr   = 32'h0000_0100;
    bit [31:0] ref_tdr0  = 32'h0000_0000;
    bit [31:0] ref_tdr1  = 32'h0000_0000;
    bit [31:0] ref_tcmp0 = 32'hFFFF_FFFF;
    bit [31:0] ref_tcmp1 = 32'hFFFF_FFFF;
    bit [31:0] ref_tier  = 32'h0000_0000;
    bit [31:0] ref_tisr  = 32'h0000_0000;
    bit [31:0] ref_thcsr = 32'h0000_0000;

    bit tdr0_wr_req = 0;
    bit tdr1_wr_req = 0;
    bit [31:0] tdr_pwdata = 0;
    bit [3:0] tdr_pstrb = 0;

    bit [63:0] ref_count = 64'h0;

    int pass_cnt = 0;
    int fail_cnt = 0;

    function new (virtual apb_timer_if vif, mailbox #(apb_trans) mbx);
        this.vif      = vif;
        this.mons2scb = mbx;
    endfunction

    task run();
        $display("[%0t] Starting Scoreboard...", $time);
        fork 
            run_apb_checker();
            run_def_timer();
        join
    endtask

    task run_apb_checker();
        apb_trans pending_req;
        forever begin
            apb_trans trans;
            mons2scb.get(trans);
            
            // If transaction is Request
            if (trans.phase_type === "REQ") begin
                pending_req = trans;
            end
            // If transaction is Response
            else if (trans.phase_type === "RSP") begin
                if (trans.tim_pslverr) begin
                    $display("[%0t] Pslverr detected at address: 0x%03h -> Ignore update!", $time, trans.tim_paddr);
                    continue;
                end
                if (pending_req.tim_pwrite) begin
                    if (pending_req.tim_paddr == 12'h004) begin
                        tdr0_wr_req = 1;
                        tdr_pwdata  = pending_req.tim_pwdata;
                        tdr_pstrb   = pending_req.tim_pstrb;
                    end else if (pending_req.tim_paddr == 12'h008) begin
                        tdr1_wr_req = 1;
                        tdr_pwdata  = pending_req.tim_pwdata;
                        tdr_pstrb   = pending_req.tim_pstrb;
                    end else begin
                        update_reference_model(pending_req);
                    end
                end else begin
                    pending_req.exp_rdata = get_expected_data(pending_req.tim_paddr);
                    check_read_data(pending_req, trans);
                end
            end
        end
    endtask

    function bit [31:0] get_expected_data(bit [11:0] paddr);
        case(paddr)
            12'h000: return ref_tcr;
            12'h004: return ref_tdr0;
            12'h008: return ref_tdr1;
            12'h00C: return ref_tcmp0;
            12'h010: return ref_tcmp1;
            12'h014: return ref_tier;
            12'h018: return ref_tisr;
            12'h01C: return ref_thcsr;
            default: return 32'h0;
        endcase
    endfunction

    task run_def_timer();
        bit tcr_timer_en_ff   = 0;
        bit tcr_div_en_ff     = 0;
        bit [3:0] tcr_div_val_ff = 4'b0001;
        bit thcsr_halt_req_ff = 0;

        bit timer_en_q_ff = 0;
        int pre_count_ff  = 0;
        bit [63:0] count_reg_ff = 0;

        bit halt_freeze;
        int clk_div_limit;
        bit real_count_tick;
        bit timer_en_fall_edge;
        int next_pre_count;
        bit [63:0] next_count_reg;

        forever begin
            @(posedge vif.sys_clk);
            #1; 
            if (!vif.sys_rst_n) begin
                tcr_timer_en_ff   = 0;
                tcr_div_en_ff     = 0;
                tcr_div_val_ff    = 4'b0001;
                thcsr_halt_req_ff = 0;

                timer_en_q_ff = 0;
                pre_count_ff  = 0;
                count_reg_ff  = 0;

                ref_count = 0;
            end else begin
                // Stage 1 
                halt_freeze = vif.dbg_mode & thcsr_halt_req_ff;

                case (tcr_div_val_ff)
                    4'b0000: clk_div_limit = 0;
                    4'b0001: clk_div_limit = 1;
                    4'b0010: clk_div_limit = 3;
                    4'b0011: clk_div_limit = 7;
                    4'b0100: clk_div_limit = 15;
                    4'b0101: clk_div_limit = 31;
                    4'b0110: clk_div_limit = 63;
                    4'b0111: clk_div_limit = 127;
                    4'b1000: clk_div_limit = 255;
                    default: clk_div_limit = 1;
                endcase

                if (!tcr_timer_en_ff || halt_freeze) begin
                    real_count_tick = 0;
                end else if (!tcr_div_en_ff) begin 
                    real_count_tick = 1;
                end else begin 
                    real_count_tick = (pre_count_ff == clk_div_limit);
                end
                timer_en_fall_edge = timer_en_q_ff & ~tcr_timer_en_ff;
                if (!tcr_timer_en_ff) begin 
                    next_pre_count = 0;
                end else if (halt_freeze) begin
                    next_pre_count = pre_count_ff;
                end else if (!tcr_div_en_ff) begin
                    next_pre_count = 0;
                end else begin
                    if (pre_count_ff >= clk_div_limit) begin
                        next_pre_count = 0;
                    end else begin
                        next_pre_count = pre_count_ff + 1;
                    end
                end

                // Calculate next_count_reg
                if (tcr_timer_en_ff && real_count_tick) begin 
                    next_count_reg = count_reg_ff + 1;
                end else begin 
                    next_count_reg = count_reg_ff;
                end
                if (timer_en_fall_edge) begin
                    next_count_reg = 0;
                end
                if (halt_freeze) begin
                    next_count_reg = count_reg_ff;
                end
                if (tdr0_wr_req) begin
                    if (tdr_pstrb[0]) next_count_reg[7:0]   = tdr_pwdata[7:0];
                    if (tdr_pstrb[1]) next_count_reg[15:8]  = tdr_pwdata[15:8];
                    if (tdr_pstrb[2]) next_count_reg[23:16] = tdr_pwdata[23:16];
                    if (tdr_pstrb[3]) next_count_reg[31:24] = tdr_pwdata[31:24];
                    tdr0_wr_req = 0;
                end
                
                if (tdr1_wr_req) begin
                    if (tdr_pstrb[0]) next_count_reg[39:32] = tdr_pwdata[7:0];
                    if (tdr_pstrb[1]) next_count_reg[47:40] = tdr_pwdata[15:8];
                    if (tdr_pstrb[2]) next_count_reg[55:48] = tdr_pwdata[23:16];
                    if (tdr_pstrb[3]) next_count_reg[63:56] = tdr_pwdata[31:24];
                    tdr1_wr_req = 0; 
                end
                
                // Stage 2                
                timer_en_q_ff = tcr_timer_en_ff;

                tcr_timer_en_ff   = ref_tcr[0];
                tcr_div_en_ff     = ref_tcr[1];
                tcr_div_val_ff    = ref_tcr[11:8];
                thcsr_halt_req_ff = ref_thcsr[0];

                pre_count_ff  = next_pre_count;
                count_reg_ff  = next_count_reg;

                // Stage 3
                ref_count = count_reg_ff;
                ref_tdr0  = ref_count[31:0];
                ref_tdr1  = ref_count[63:32];

                if (ref_count == {ref_tcmp1, ref_tcmp0}) begin
                    ref_tisr[0] = 1'b1;
                end
            end
        end
    endtask

    function void update_reference_model(apb_trans trans);
        case (trans.tim_paddr) 
            12'h000: begin
                if (trans.tim_pstrb[0]) begin
                    ref_tcr[7:0]        = trans.tim_pwdata[7:0];
                end 
                if (trans.tim_pstrb[1]) begin
                    ref_tcr[15:8]       = trans.tim_pwdata[15:8];
                end 
                if (trans.tim_pstrb[2]) begin
                    ref_tcr[23:16]      = trans.tim_pwdata[23:16];
                end 
                if (trans.tim_pstrb[3]) begin
                    ref_tcr[31:24]      = trans.tim_pwdata[31:24];
                end
                ref_tcr = ref_tcr & 32'h0000_0F03; // TCR only uses bit [11:8], bit 1, bit 0
            end
            12'h004: begin
                if (trans.tim_pstrb[0]) begin
                    ref_tdr0[7:0]       = trans.tim_pwdata[7:0];
                end 
                if (trans.tim_pstrb[1]) begin
                    ref_tdr0[15:8]      = trans.tim_pwdata[15:8];
                end 
                if (trans.tim_pstrb[2]) begin
                    ref_tdr0[23:16]     = trans.tim_pwdata[23:16];
                end 
                if (trans.tim_pstrb[3]) begin
                    ref_tdr0[31:24]     = trans.tim_pwdata[31:24];
                end
            end
            12'h008: begin
                if (trans.tim_pstrb[0]) begin
                    ref_tdr1[7:0]       = trans.tim_pwdata[7:0];
                end 
                if (trans.tim_pstrb[1]) begin
                    ref_tdr1[15:8]      = trans.tim_pwdata[15:8];
                end 
                if (trans.tim_pstrb[2]) begin
                    ref_tdr1[23:16]     = trans.tim_pwdata[23:16];
                end 
                if (trans.tim_pstrb[3]) begin
                    ref_tdr1[31:24]     = trans.tim_pwdata[31:24];
                end
            end
            12'h00C: begin
                if (trans.tim_pstrb[0]) begin
                    ref_tcmp0[7:0]      = trans.tim_pwdata[7:0];
                end 
                if (trans.tim_pstrb[1]) begin
                    ref_tcmp0[15:8]     = trans.tim_pwdata[15:8];
                end 
                if (trans.tim_pstrb[2]) begin
                    ref_tcmp0[23:16]    = trans.tim_pwdata[23:16];
                end 
                if (trans.tim_pstrb[3]) begin
                    ref_tcmp0[31:24]    = trans.tim_pwdata[31:24];
                end
            end
            12'h010: begin
                if (trans.tim_pstrb[0]) begin
                    ref_tcmp1[7:0]      = trans.tim_pwdata[7:0];
                end 
                if (trans.tim_pstrb[1]) begin
                    ref_tcmp1[15:8]     = trans.tim_pwdata[15:8];
                end 
                if (trans.tim_pstrb[2]) begin
                    ref_tcmp1[23:16]    = trans.tim_pwdata[23:16];
                end 
                if (trans.tim_pstrb[3]) begin
                    ref_tcmp1[31:24]    = trans.tim_pwdata[31:24];
                end
            end
            12'h014: begin
                if (trans.tim_pstrb[0]) begin
                    ref_tier[7:0]       = trans.tim_pwdata[7:0];
                end 
                if (trans.tim_pstrb[1]) begin
                    ref_tier[15:8]      = trans.tim_pwdata[15:8];
                end 
                if (trans.tim_pstrb[2]) begin
                    ref_tier[23:16]     = trans.tim_pwdata[23:16];
                end 
                if (trans.tim_pstrb[3]) begin
                    ref_tier[31:24]     = trans.tim_pwdata[31:24];
                end
                ref_tier = ref_tier & 32'h0000_0001; // TIER only uses bit 0 (int_en)
            end
            12'h018: begin
                if (trans.tim_pstrb[0] && trans.tim_pwdata[0] == 1'b1) begin
                    ref_tisr[0]         = 1'b0; 
                end
                ref_tisr = ref_tisr & 32'h0000_0001;
            end
            12'h01C: begin
                if (trans.tim_pstrb[0]) begin
                    ref_thcsr[0]        = trans.tim_pwdata[0];
                end
                ref_thcsr = ref_thcsr & 32'h0000_0003;
            end
            default: begin
            end
        endcase
    endfunction

    function void check_read_data(apb_trans req, apb_trans rsp);
        if (rsp.tim_prdata === req.exp_rdata) begin
            pass_cnt++;
            $display("[%0t] Read data at address: 0x%03h | Actual value: 0x%08h", $time, req.tim_paddr, rsp.tim_prdata);
        end else begin
            fail_cnt++;
            $display("\n==================================================");
            $display("              MISMATCH DETECTED AT %0t             ", $time);
            $display("==================================================");
            $display("Target Address      : 0x%03h", req.tim_paddr);
            $display("Actual value (RTL)  : 0x%08h", rsp.tim_prdata);
            $display("Expected value (TB) : 0x%08h", req.exp_rdata);
            $display("--------------------------------------------------");
            $display("Current Reference Model State:");
            $display("ref_count           : 0x%016h", ref_count);
            $display("ref_tcr             : 0x%08h", ref_tcr);
            $display("tdr0_wr_req         : %0b", tdr0_wr_req);
            $display("tdr_pwdata          : 0x%08h", tdr_pwdata);
            $display("tdr_pstrb           : 4'b%0b", tdr_pstrb);
            $display("==================================================\n");
        end
    endfunction
endclass