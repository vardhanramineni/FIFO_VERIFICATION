`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.06.2025 12:53:35
// Design Name: 
// Module Name: sync_fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sync_fifo(fifo_if vif);
parameter width=8;
parameter depth=8;
logic [$clog2(depth)-1:0] wr_ptr,rd_ptr;
logic [$clog2(depth):0] count;
logic [width-1:0] mem [depth-1:0]; 
integer i=0;
always @(posedge vif.clk) begin
if (vif.rst) begin
wr_ptr <= 0;
rd_ptr <= 0;
count  <= 0;
vif.dout <= 0;
for (i = 0; i < depth; i++) begin
mem[i] <= 0;
end
end else begin
// WRITE to FIFO
if (vif.wr_en && !vif.full) begin
mem[wr_ptr] <= vif.din;
if (wr_ptr == depth - 1)
wr_ptr <= 0;
else
wr_ptr <= wr_ptr + 1;
count <= count + 1;
end

// READ from FIFO
if (vif.rd_en && !vif.empty) begin
vif.dout <= mem[rd_ptr];
if (rd_ptr == depth - 1)
rd_ptr <= 0;
else
rd_ptr <= rd_ptr + 1;
count <= count - 1;
end
else begin
vif.dout <= vif.dout; // retain old value if no read
end
end
end

assign vif.full=(count==depth);
assign vif.empty=(count==0);

endmodule


interface fifo_if;
logic clk;
logic rst;
logic wr_en;
logic rd_en;
logic [7:0] din;
logic [7:0] dout;
logic full;
logic empty;
endinterface


