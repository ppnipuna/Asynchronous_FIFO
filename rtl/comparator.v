module compare_wr
	#(
	 parameter ADDR = 5	// declare parameter for memory address
	)				  
	(
	input wire [ADDR:0] rptr,wptr,  // declare inputs and outputs
	output wire full
	);	
	//check for full condition: Write pointer has wrapped around but read pointer has not
	
		assign full = (wptr[ADDR] != rptr[ADDR]) & (wptr[ADDR-1:0] == rptr[ADDR-1:0]);
endmodule 

module compare_rd
	#(
	 parameter ADDR = 5	// declare parameter for memory address
	)				  
	(
	input wire [ADDR:0] rptr,wptr,  // declare inputs and outputs
	output wire empty
	);	
	//check for full condition: WRITE and READ pointers have NOT wrapped around
		
		assign	empty = wptr[ADDR:0] == rptr[ADDR:0];
endmodule