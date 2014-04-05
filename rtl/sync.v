// to synchronize from fast clock domain to slow clock domain (write -> read)
module sync_w2r 
	#( 
	parameter ADDR = 5
	)
	(
	input wire clk, reset_b,
	input wire [ADDR:0] wptr,
	output reg [ADDR:0] wptr_rd
	);
	
	reg [ADDR:0] q;
	always @(posedge clk or negedge reset_b)
		begin
			if(~reset_b)
				begin
					q <= 'd0;
					wptr_rd <= 'd0;
				end
			else
				begin
					q <= wptr;
					wptr_rd <= q;
				end
		end
	
endmodule

// to synchronize from slow clock domain to fast clock domain (read -> write)
module sync_r2w
	#(
	parameter ADDR = 5
	)
	(
	input wire clk, reset_b,
	input wire [ADDR:0] rptr,
	output reg [ADDR:0]	rptr_wr
	); 
	
	reg [ADDR:0] q;
	always @(posedge clk or negedge reset_b)
		begin
			if(~reset_b)
				begin
					q <= 'd0;
					rptr_wr <= 'd0;
				end
			else
				begin
					q <= rptr;
					rptr_wr <= q;
				end
		end
endmodule
	
	