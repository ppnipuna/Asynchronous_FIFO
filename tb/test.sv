`timescale 1ns /1ns

program automatic test(if_wr _if_wr_vi,if_rd _if_rd_vi);

	// parameter needed for test cases
	parameter FIFO_CAPACITY = 32; 
	// declare virtual interfaces
	virtual if_wr if_wr_vi;
	virtual if_rd if_rd_vi;
	// declare an environment handle
	Environment env;
	
	initial 
		begin
			if_wr_vi = _if_wr_vi;
			if_rd_vi = _if_rd_vi;
			$display("Inside Test: Program block started\n");
			env = new(if_wr_vi,if_rd_vi); // create environment object			
			env.run(); 
			
			// <<<<<<<< Test case 1 >>>>>>>>> // 
			// check FIFO full condition : handled by fifo_status() task in scoreboard
			//env.drvr.write(FIFO_CAPACITY);	// num_of_clocks should be equal to FIFO depth 
			
			// <<<<<<<< Test case 2 >>>>>>>>> // 
			//check FIFO empty condition : handled by fifo_status() task in scoreboard 
			//env.rcvr.read(FIFO_CAPACITY);	// num_of_clocks should be equal to FIFO depth
			
			// <<<<<<<< Test case 3 >>>>>>>>> //
			// simultaneous read and write : to check DATA sent == DATA received
			//fork
			//env.drvr.write(2);	// num_of_clocks less than FIFO depth 
			//env.rcvr.read(2);
			//join
			// <<<<<<<< Test case 4 >>>>>>>>> //
			// Display message when FIFO overflow takes place
			// Handled by separate task fifo_overflow() in scoreboard
			env.drvr.write(FIFO_CAPACITY + 10);	// num_of_clocks should be greater than FIFO depth 
			
			// <<<<<<<< Test case 5 >>>>>>>>> //
			// Display message when FIFO underflow takes place
			// Handled by separate task fifo_underflow() in scoreboard
			//env.rcvr.read(FIFO_CAPACITY + 10);	// num_of_clocks should be greater than FIFO depth 
			
			#20;
			$finish;
		end
	final
		$display("%0d : Inside Test: Program block completed!\n",$time);
	
endprogram : test