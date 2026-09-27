`timescale 1ns / 1ps

///// Transaction class 

class transaction;
    randc bit [7:0] din;
    rand bit wr_en;
    rand bit rd_en;
    bit [7:0] dout;
    bit full;
    bit empty;
    
    constraint wr { wr_en dist{0:=50,1:=50};}
    constraint rd {rd_en dist{0:=60,1:=40};}   //// don't requuire semicolon for constraint 
    constraint rd_wr{
        wr_en!=rd_en;
    }
    
    
    function void display(input string tag);
        $display("[%0s] din:%0d \t wr_en:%0d \t rd_en:%0d \t dout:%0d \t full:%0d \t empty:%0d",tag,din,wr_en,rd_en,dout,full,empty);
    endfunction
    
    function transaction copy();
        copy=new();
        copy.din=this.din;
        copy.dout=this.dout;
        copy.wr_en=this.wr_en;
        copy.rd_en=this.rd_en;
        copy.empty=this.empty;
        copy.full=this.full;
    endfunction 
    
endclass


//// Generator class 

class generator;
    transaction tr;
    mailbox #(transaction) mbx;
    mailbox #(transaction) mbxref;
    event done;
    event sconext;
    
    function new(mailbox #(transaction) mbx,mailbox #(transaction) mbxref);
    this.mbx=mbx;
    this.mbxref=mbxref;
    tr=new();
    endfunction
    int i;
    int count;
    
    task run();
        for(i=0;i<count;i++) begin
            assert(tr.randomize()) else $display("[GEN] randomization failed");
            mbx.put(tr.copy());
            mbxref.put(tr.copy());  /// to score board
            $display("%0d",i);
            tr.display("GEN");
            @(sconext);
        end
        ->done;
        $display("[GEN] Generation done");
    endtask
    
endclass

////// Driver class

class driver;
    transaction tr;
    mailbox #(transaction) mbx;
    virtual fifo_if vif;
    
    function new(mailbox #(transaction) mbx);
        this.mbx=mbx;
    endfunction
    
    task reset();
        vif.rst<=1;
        repeat(5)@(posedge vif.clk);
        vif.rst<=0;
        @(posedge vif.clk);
        $display("[DRV] reset done");
    endtask
    
    task run();
        forever begin
            mbx.get(tr);
            vif.din<=tr.din;
            vif.wr_en<=tr.wr_en;
            vif.rd_en<=tr.rd_en;
            @(posedge vif.clk);
            tr.display("DRV");
        end
    endtask

endclass

///// class monitor 

class monitor;
    transaction tr;
    mailbox #(transaction) mbx;
    virtual fifo_if vif;
    
    function new(mailbox #(transaction) mbx);
        this.mbx=mbx;
    endfunction
    
    task run();
        tr=new();
        forever begin
            @(posedge vif.clk);
            tr.din=vif.din;
            tr.wr_en=vif.wr_en;
            tr.rd_en=vif.rd_en;
            #1;
            tr.full=vif.full;
            tr.empty=vif.empty;
            tr.dout=vif.dout;
            mbx.put(tr);
            tr.display("MON");
        end
        
    endtask

endclass

////// Scoreboard class

class scoreboard;
    transaction tr;
    transaction tref;
    mailbox #(transaction) mbx;
    mailbox #(transaction) mbxref;
    event sconext;
    bit [7:0] data[$];
    
    function new(mailbox #(transaction) mbx,mailbox #(transaction) mbxref);
    this.mbx=mbx;
    this.mbxref=mbxref;
    endfunction
    
    task compare();
    bit [7:0] expected;
    if(tref.wr_en && !tr.full)
    data.push_back(tref.din);
    
    if (tref.rd_en && !tref.empty) begin
    if (data.size() == 0) begin
    $display("[SCO] ERROR: Tried to pop from empty reference model");
    return;
    end
    expected = data.pop_front();
    if (expected == tr.dout)
    $display("[SCO] PASS: Output matched: %0d", expected);
    else
    $display("[SCO] FAIL: Expected %0d but got %0d", expected, tr.dout);
    end
    endtask
    
    
    task run();
        forever begin
            mbx.get(tr);
            mbxref.get(tref);
            tr.display("SCO");
            compare();
            $display("---------------------");
            ->sconext;
        end
    
    
    endtask
    
endclass

//// Environment class

class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard sco;
    event next;
    // event done;
    mailbox #(transaction) gdmbx;
    mailbox #(transaction) gsmbx;
    mailbox #(transaction) mbxref;
    
    virtual fifo_if vif;
    
    function new(virtual fifo_if vif);
        gdmbx=new();
        mbxref=new();
        gen=new(gdmbx,mbxref);
        drv=new(gdmbx);
        
        gsmbx=new();
        mon=new(gsmbx);
        sco=new(gsmbx,mbxref);
        
        this.vif=vif;
        drv.vif=this.vif;
        mon.vif=this.vif;
        
        gen.sconext=next;
        sco.sconext=next;
        // gen.done=done;
        // this.done=done;
        
    endfunction
    
    task pre_test();
        drv.reset();
    endtask
    
    task test();
        fork 
            gen.run();
            drv.run();
            mon.run();
            sco.run();
        join_any
    endtask
    
    task post_test();
        $display("[ENV] Post test actions");
        wait(gen.done.triggered);
        $display("[ENV] Generation completed, proceeding to post-test actions");
        $stop();
    endtask
    
    
    task run();
        pre_test();
        test();
        post_test();
    endtask 
    
    
endclass

module fifo_tb;
    
    fifo_if vif();
    sync_fifo dut(vif);
    
    initial begin
        vif.clk<=0;
    end
    
    always #10 vif.clk=~vif.clk;
    
    environment env;
    
    initial begin
        env=new(vif);
        env.gen.count=200;
        env.run();
    end
endmodule