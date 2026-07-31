class apb_generator;
    mailbox #(apb_trans) gen2drv;
    int num_trans;
    event gen_done;

    function new(mailbox #(apb_trans) mbx, int num_trans = 10);
        this.gen2drv = mbx;
        this.num_trans = num_trans;
    endfunction

    task run();
        $display("[%0t] Start generating %0d transactions...", $time, num_trans);
        for (int i = 0; i < num_trans; i++) begin
            apb_trans trans;
            trans = new();
            if (!trans.randomize()) begin
                $error("[%0t] Error: Cannot generate random transactions!", $time);
            end
            $display ("[%0t] Successfully generate transaction number %0d", $time, i + 1);
            trans.print("GEN");
            gen2drv.put(trans);
        end
        $display("[%0t] Successfully put all %0d transactions to mailbox", $time, num_trans);
        -> gen_done;
    endtask
endclass