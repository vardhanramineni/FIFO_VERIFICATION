# FIFO_VERIFICATION

cat > sim/run.do <<'EOF'
vlib work

vlog ../rtl/sync_fifo.s
vlog ../tb/fifo_interface.sv
vlog ../tb/transaction.sv
vlog ../tb/generator.sv
vlog ../tb/driver.sv
vlog ../tb/monitor.sv
vlog ../tb/scoreboard.sv
vlog ../tb/environment.sv
vlog ../tb/tb_top.sv

vsim work.tb_top

add wave -r /*
run -all
EOF

cat > README.md <<'EOF'
# Synchronous FIFO Verification using SystemVerilog

## Overview

This project implements and verifies a parameterized synchronous FIFO using SystemVerilog.

The verification environment follows a UVM-style architecture without using the UVM library.

The testbench uses object-oriented programming, constrained randomization, mailboxes, and a reference-model-based scoreboard.

## Features

- Parameterized synchronous FIFO
- 8-bit data width
- FIFO depth of 8
- SystemVerilog verification
- UVM-style architecture
- Transaction-based stimulus
- Constrained randomization
- Generator
- Driver
- Monitor
- Scoreboard
- Environment
- Mailbox-based communication
- Reference model
- Functional checking

## Verification Architecture

Generator
    |
    | mailbox
    v
 Driver
    |
    v
 FIFO DUT
    |
    v
 Monitor
    |
    | mailbox
    v
Scoreboard
    |
    v
Reference Model

## Components

### Transaction
Contains FIFO stimulus and observed information.

### Generator
Generates constrained-random transactions.

### Driver
Drives transaction information onto the DUT interface.

### Monitor
Observes DUT signals and converts them into transactions.

### Scoreboard
Maintains a reference queue and compares expected FIFO output with DUT output.

### Environment
Instantiates and connects all verification components.

## DUT

The FIFO contains:

- Write pointer
- Read pointer
- Memory array
- Occupancy counter
- Full flag
- Empty flag

## Parameters

| Parameter | Value |
|-----------|-------|
| Data Width | 8 bits |
| FIFO Depth | 8 |
| Clock Period | 10 ns |

## Project Structure

sync-fifo-systemverilog/
|
├── rtl/
│   └── sync_fifo.s
|
├── tb/
│   ├── fifo_interface.sv
│   ├── transaction.sv
│   ├── generator.sv
│   ├── driver.sv
│   ├── monitor.sv
│   ├── scoreboard.sv
│   ├── environment.sv
│   └── tb_top.sv
|
├── sim/
│   └── run.do
|
└── README.md

## Tools

- SystemVerilog
- Riviera-PRO / QuestaSim
- EDA Playground
EOF

cat > .gitignore <<'EOF'
work/
transcript
*.wlf
*.vcd
*.log
*.jou
*.pb
*.swp
.DS_Store
EOF

git init
git add .
git commit -m "Initial commit: SystemVerilog FIFO verification environment"

echo ""
echo "============================================"
echo " FIFO VERIFICATION REPOSITORY CREATED"
echo "============================================"
echo ""
echo "Repository: sync-fifo-systemverilog"
echo ""
echo "Files created:"
find . -type f | sort
echo ""
echo "To connect GitHub:"
echo "git branch -M main"
echo "git remote add origin <YOUR_GITHUB_REPOSITORY_URL>"
echo "git push -u origin main"
