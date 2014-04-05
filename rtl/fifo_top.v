module fifo_top
	#(
	parameter DEPTH = 32,
	WIDTH = 32,
	ADDR = 5
	)
	(
	input wire write, wreset_b, wclk, read, rreset_b, rclk,
	input wire [WIDTH-1:0] wdata,
	output wire [WIDTH-1:0] rdata,
	output wire rempty, wfull
	);
	
	// function to convert from gray to binary
	function [ADDR:0] G2B_Fn;
	input [ADDR:0] gray;
	reg [ADDR:0] binary;
	integer i;
	begin
	binary[ADDR] = gray [ADDR];	
	for (i=ADDR-1;i >= 0;i=i-1)
				binary[i] = (binary[i+1] ^ gray[i]);
	
	G2B_Fn = binary;
	end	
	endfunction
	
	// declare connecting wires
	wire [ADDR:0]   wptr_b,wptr_g,  // binary and gray signals from write pointer
					rptr_b,rptr_g;  // binary and gray signals from read pointer
	
	reg [ADDR:0]   g2b_wd_op,			// function G2B_Fn output in the write domain
					g2b_rd_op;			// function G2B_Fn output in the read domain
	wire [ADDR:0]	g2b_wd_ip,			// function G2B_Fn input in the write domain
					g2b_rd_ip;			// function G2B_Fn input in the read domain
	
	//assign intermediate wires
	always @(g2b_wd_ip or g2b_rd_ip)
		begin
			g2b_wd_op = G2B_Fn(g2b_wd_ip);  
			g2b_rd_op = G2B_Fn(g2b_rd_ip);
		end
					
		// instantiate write pointer
	pointer wptr(
	.clk(wclk),
	.reset_b(wreset_b),
	.op(write),
	.fifo_status(wfull),
	.gray(wptr_g),
	.binary(wptr_b)
	);
	
	//instantiate read pointer
	pointer rptr(
	.clk(rclk),
	.reset_b(rreset_b),
	.op(read),
	.fifo_status(rempty),
	.gray(rptr_g),
	.binary(rptr_b)
	);
					
	//instantiate memory module
		memory m1(
		.clk(wclk),
		.reset_b(wreset_b),
		.write(write),
		.wfull(wfull),
		.waddr(wptr_b[ADDR-1:0]),
		.raddr(rptr_b[ADDR-1:0]),
		.wdata(wdata),
		.rdata(rdata)
		); 
	
	
	//instantiate read->write synchronizer
	sync_r2w syncr2w(
	.clk(wclk),
	.reset_b(wreset_b),
	.rptr(rptr_g),
	.rptr_wr(g2b_wd_ip)
	);
	
	//instantiate write->read synchronizer
	sync_w2r syncw2r(
	.clk(rclk),
	.reset_b(rreset_b),
	.wptr(wptr_g),
	.wptr_rd(g2b_rd_ip)
	);
	
		
	//instantiate write domain comparator
	compare_wr cmp_wr(
	.rptr(g2b_wd_op),
	.wptr(wptr_b),
	.full(wfull)
	);
	
	//instantiate write domain comparator
	compare_rd cmp_rd(
	.rptr(rptr_b),
	.wptr(g2b_rd_op),
	.empty(rempty)
	);
	
endmodule