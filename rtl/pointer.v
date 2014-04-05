module pointer
	#(
	parameter ADDR = 5	// parameterized size of pointers
	)
	(
	input wire clk,reset_b,op,fifo_status, // input-output declaration
	output reg [ADDR:0] gray,binary
	); 
	integer i;
	
	always@(posedge clk, negedge reset_b)
		begin
		if(~reset_b)
			begin
			binary = 'd0;
			gray = 'd0;
			end	
		else if(op & ~fifo_status)
			binary <= binary + 1; 
		end
	
	always @(binary)
		begin
			gray[ADDR] = binary[ADDR];
			for (i=ADDR-1;i>=0;i=i-1)
				gray[i] = binary[i] ^ binary[i+1];
		end
		
endmodule	