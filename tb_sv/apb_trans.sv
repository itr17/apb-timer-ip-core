class apb_trans;
    // Input signals 
    rand bit [11:0]     tim_paddr;
    rand bit            tim_pwrite;
    rand bit [31:0]     tim_pwdata;
    rand bit [3:0]      tim_pstrb;
    // Output signals
    bit [31:0]          tim_prdata;
    bit                 tim_pslverr;
    // Request - Response
    string phase_type;
    bit [31:0] exp_rdata;

    constraint valid_addr {
        tim_paddr inside {
            12'h000, // TCR
            12'h004, // TDR0
            12'h008, // TDR1
            12'h00C, // TCMP0
            12'h010, // TCMP1
            12'h014, // TIER
            12'h018, // TISR
            12'h01C // THCSR
        };
    }

    function apb_trans copy();
        apb_trans tr    = new();
        tr.tim_paddr    = this.tim_paddr;
        tr.tim_pwrite   = this.tim_pwrite;
        tr.tim_pwdata   = this.tim_pwdata;
        tr.tim_pstrb    = this.tim_pstrb;
        tr.tim_prdata   = this.tim_prdata;
        tr.tim_pslverr  = this.tim_pslverr;
        tr.phase_type   = this.phase_type;
        tr.exp_rdata    = this.exp_rdata;
        return tr;
    endfunction

    function void print (string name = "APB_TRANS");
        string mode = tim_pwrite ? "WRITE" : "READ";
        $display("[%s] %s | ADDR: 0x%03h | WDATA: 0x%08h | STRB: 4'b%0b | RDATA: 0x%08h | ERR: %0b", 
                name, mode, tim_paddr, tim_pwdata, tim_pstrb, tim_prdata, tim_pslverr);
    endfunction

endclass