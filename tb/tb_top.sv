`timescale 1ns / 1ns
module tb_top;
	
	// Parameter declaration
	parameter DEPTH = 32,
			  WIDTH = 32,
			  ADDR = 5,
			  wclk_PERIOD = 10,
			  rclk_PERIOD = 100;
	
	// define clock signals and generate clocks
	logic rclk, wclk;
	logic [ADDR:0] rptr, wptr; 
	
	assign rptr = $root.dut_wr_inst.dut1.rptr.binary;
	assign wptr = $root.dut_wr_inst.dut1.wptr.binary;
	
	//generate two clock signals
	initial
		begin 
			wclk = 1'b0;
			rclk = 1'b0;
			
			fork
				begin
					forever #(wclk_PERIOD / 2) wclk <= ~wclk;
				end
			
				begin
					#5 forever #(rclk_PERIOD / 2) rclk <= ~rclk;
				end	
			join_none
		end
	
	// define the interfaces 
	if_wr #(.DATA(WIDTH)) if_wr_inst(wclk);
	if_rd #(.DATA(WIDTH)) if_rd_inst(rclk);
	//program block instance
	test testcase(if_wr_inst,if_rd_inst);	
	// DUT wrapper instance
	dut_wrapper dut_wr_inst(if_wr_inst,if_rd_inst); 
	
endmodule
	