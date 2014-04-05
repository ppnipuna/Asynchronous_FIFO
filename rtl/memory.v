module memory
	#(
	parameter DEPTH = 32, // parameter declaration
	WIDTH = 32,
	ADDR = 5
	)
	(
	input wire clk, reset_b, write, wfull, // input - output declaration
	input wire [ADDR-1:0] waddr, raddr,
	input wire [WIDTH-1:0] wdata,
	output wire [WIDTH-1:0] rdata
	);
	
	integer i;
	// creating memory
	reg [WIDTH-1:0] sram [DEPTH-1:0];
	
	// writing in the memory
	always @(posedge clk, negedge reset_b)
		begin
		if(~reset_b)
			begin
			for(i=0;i<DEPTH;i = i+1)
				sram[i] <= 'h0;
			end
		else if(write & ~wfull)
			sram[waddr] <= wdata;
		end	
	
	// reading a memory location
	assign rdata = sram[raddr];
endmodule