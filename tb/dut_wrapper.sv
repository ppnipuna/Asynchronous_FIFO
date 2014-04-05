//`include "interface.sv"
module dut_wrapper(if_wr.DUT if_wr_vi, if_rd.DUT if_rd_vi);
	
	begin
		// instantiate the DUT
		fifo_top #(.WIDTH(32))
		dut1 (
		.write(if_wr_vi.write),
		.wfull(if_wr_vi.wfull),
		.wdata(if_wr_vi.wdata),
		.wclk(if_wr_vi.wclk),
		.wreset_b(if_wr_vi.wreset_b),
		.read(if_rd_vi.read),
		.rempty(if_rd_vi.rempty),
		.rdata(if_rd_vi.rdata),
		.rclk(if_rd_vi.rclk),
		.rreset_b(if_rd_vi.rreset_b)
		);
	end
	
endmodule : dut_wrapper