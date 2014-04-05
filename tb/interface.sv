`timescale 1ns / 1ns
/* ************  Write Domain interface ************ */

interface if_wr #(parameter DATA = 32)(input logic wclk);
// declare the signals for write domain
	logic write, wfull, wreset_b;
	logic [DATA-1:0] wdata;
	
// declare the clocking block
// block for DUT side
clocking cb_DUT @(posedge wclk);
output wdata;
input wfull;
endclocking	 : cb_DUT

// declare the modport for Driver
modport DUT(
output wfull,
input wdata, write, wreset_b,wclk);

//declare the modports using clocking block
modport TB(clocking cb_DUT,
output write, wreset_b);

endinterface : if_wr  

/* ************  Read Domain interface ************ */ 

interface if_rd #(parameter DATA = 8)(input logic rclk);
// declare the signals for read domain
	logic read, rempty, rreset_b;
	logic [DATA-1:0] rdata;
	
// declare the clocking block	
// block for DUT side
clocking cb_DUT @(posedge rclk);
input rdata, rempty;
endclocking	 : cb_DUT

// declare the modports using clocking block
modport DUT(
output rempty, rdata,
input read, rreset_b,rclk);

//declare the modports using clocking block
modport TB(clocking cb_DUT,
output read,rreset_b);

endinterface : if_rd	

