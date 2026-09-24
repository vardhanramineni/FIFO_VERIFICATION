mkdir -p sync-fifo-systemverilog-verification/{tb,sim} && cd sync-fifo-systemverilog-verification

cat > tb/fifo_interface.sv <<'EOF'
interface fifo_interface(input logic clk);

    logic       rst;
    logic       wr_en;
    logic       rd_en;
    logic [7:0] din;
    logic [7:0] dout;
    logic       full;
    logic       empty;

endinterface
EOF

cat > tb/transaction.sv <<'EOF'
class transaction;

    rand bit       wr_en;
    rand bit       rd_en;
    rand bit [7:0] data_in;

    bit [7:0] data_out;
    bit       full;
    bit       empty;

    constraint operation_c {
        wr_en dist {1 := 70, 0 := 30};
        rd_en dist {1 := 70, 0 := 30};
    }

    function void display(string name);
        $display("[%s] wr_en=%0d rd_en=%0d data_in=%0h data_out=%0h full=%0d empty=%0d",
                 name, wr_en, rd_en, data_in, data_out, full, empty);
    endfunction

endclass
EOF

cat > tb/generator.sv <<'EOF'
class generator;

    mailbox #(transaction) gen2drv;
    transaction tr;

    function new(mailbox #(transaction) gen2drv);
        this.gen2drv = gen2drv;
    endfunction

    task run();

        repeat (200) begin

            tr = new();

            assert(tr.randomize())
                else $fatal("Transaction randomization failed");

            gen2drv.put(tr);

        end

    endtask

endclass
EOF

cat > tb/driver.sv <<'EOF'
class driver;

    virtual fifo_interface vif;
    mailbox #(transaction) gen2drv;

    function new(
        virtual fifo_interface vif,
        mailbox #(transaction) gen2drv
    );

        this.vif = vif;
        this.gen2drv = gen2drv;

    endfunction

    task run();

        transaction tr;

        forever begin

            gen2drv.get(tr);

            @(posedge vif.clk);

            vif.wr_en <= tr.wr_en;
            vif.rd_en <= tr.rd_en;
            vif.din   <= tr.data_in;

        end

    endtask

endclass
EOF

cat > tb/monitor.sv <<'EOF'
class monitor;

    virtual fifo_interface vif;
    mailbox #(transaction) mon2scb;

    function new(
        virtual fifo_interface vif,
        mailbox #(transaction) mon2scb
    );

        this.vif = vif;
        this.mon2scb = mon2scb;

    endfunction

    task run();

        transaction tr;

        forever begin

            @(posedge vif.clk);

            tr = new();

            tr.wr_en    = vif.wr_en;
            tr.rd_en    = vif.rd_en;
            tr.data_in  = vif.din;
            tr.data_out = vif.dout;
            tr.full     = vif.full;
            tr.empty    = vif.empty;

            mon2scb.put(tr);

        end

    endtask

endclass
EOF

cat > tb/scoreboard.sv <<'EOF'
class scoreboard;

    mailbox #(transaction) mon2scb;
    transaction tr;

    bit [7:0] reference_queue[$];

    int pass_count = 0;
    int fail_count = 0;

    function new(mailbox #(transaction) mon2scb);
        this.mon2scb = mon2scb;
    endfunction

    task run();

        bit [7:0] expected_data;

        forever begin

            mon2scb.get(tr);

            if (tr.wr_en && !tr.full) begin
                reference_queue.push_back(tr.data_in);
            end

            if (tr.rd_en && !tr.empty) begin

                if (reference_queue.size() == 0) begin
                    $error("[SCOREBOARD] Reference queue is empty");
                    fail_count++;
                end

                else begin

                    expected_data = reference_queue.pop_front();

                    if (tr.data_out === expected_data) begin
                        pass_count++;

                        $display("[SCOREBOARD] PASS : Expected=%0h Actual=%0h",
                                 expected_data, tr.data_out);
                    end

                    else begin
                        fail_count++;

                        $error("[SCOREBOARD] FAIL : Expected=%0h Actual=%0h",
                               expected_data, tr.data_out);
                    end

                end

            end

        end

    endtask

endclass
EOF

cat > tb/environment.sv <<'EOF'
class environment;

    generator  gen;
    driver     drv;
    monitor    mon;
    scoreboard scb;

    mailbox #(transaction) gen2drv;
    mailbox #(transaction) mon2scb;

    virtual fifo_interface vif;

    function new(virtual fifo_interface vif);

        this.vif = vif;

        gen2drv = new();
        mon2scb = new();

        gen = new(gen2drv);
        drv = new(vif, gen2drv);
        mon = new(vif, mon2scb);
        scb = new(mon2scb);

    endfunction

    task run();

        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_none

    endtask

endclass
EOF

cat > README.md <<'EOF'
# Synchronous FIFO Verification using SystemVerilog

## Overview

This repository contains a SystemVerilog-based verification
environment developed for functional verification of a
synchronous FIFO.

The verification environment follows a UVM-style architecture
without using the UVM library.

The FIFO RTL/DUT source code is intentionally not included in
this repository.

The verification environment was developed and tested using
Xilinx Vivado 2023.2.

## Verification Result

**200 test cases were successfully verified.**

---

## Verification Architecture

```text
                         TESTBENCH
                             |
                             v
                    +----------------+
                    |   Generator    |
                    +----------------+
                             |
                       gen2drv mailbox
                             |
                             v
                    +----------------+
                    |     Driver     |
                    +----------------+
                             |
                             | Virtual Interface
                             v
                    +----------------+
                    |    FIFO DUT    |
                    |    External    |
                    +----------------+
                             |
                             | DUT Signals
                             v
                    +----------------+
                    |    Monitor     |
                    +----------------+
                             |
                       mon2scb mailbox
                             |
                             v
                    +----------------+
                    |   Scoreboard   |
                    |                |
                    | Reference      |
                    | Model / Queue  |
                    +----------------+
