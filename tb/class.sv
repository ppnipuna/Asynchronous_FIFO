// parameters
parameter WIDTH = 32;
parameter ADDR = 5;

// ********** Packet Class ******** //
class Packet; 
// define the class properties
bit [2:0] Frame_id;  // any random 3 bit values will be assigned 
bit [7:0] Src, Dst; // any random 8 bit values will be assigned
bit [11:0] Data;
bit Parity;

//default constructor method
// as the properties are defined as 2 state variables default constructor will initialize them to 0

// constructor to assign passed argument values
function new(int _Frame); // _Frame contains randomized data values
this.Frame_id = _Frame[31:29];
this.Src = _Frame[28:21];
this.Dst = _Frame[20:13];
this.Data = _Frame[12:1];
this.Parity = _Frame[0];
endfunction

// function will pack the contents into a frame
function void pack(ref logic[WIDTH-1:0] Pkd_Frame);
Pkd_Frame = {Frame_id,Src,Dst,Data,Parity};
$display("%0d: Packed frame with ID: %0d to be sent to DUT is: %h",$time,Frame_id,Pkd_Frame);
endfunction	

// function will unpack contents of a frame into the packet
function void unpack(ref logic[31:0] _Frame);
this.Frame_id = _Frame[31:29];
this.Src = _Frame[28:21];
this.Dst = _Frame[20:13];
this.Data = _Frame[12:1];
this.Parity = _Frame[0];
$display("%0d: UnPacked frame with ID: %0d received from DUT",$time,Frame_id);
endfunction

// function will display the contents of the packet
function void display(); 
$display ("%0t:\t ******** Packet Contents ******** ",$time);
$display ("\tFrame Id: %d", this.Frame_id);
$display ("\tSource: %d",this.Src);
$display ("\tDestination: %d",this.Dst);
$display ("\tData: %d",this.Data);
$display ("\tParity: %b",this.Parity);
$display ("\t ******** Packet Contents finished *******");
endfunction

// function will compare contents of 2 packets
// returns 1 if matched, else return 0
function int compare(Packet _pkt1);
if(_pkt1.Frame_id == this.Frame_id && _pkt1.Src == this.Src && _pkt1.Dst == this.Dst && _pkt1.Data == this.Data && _pkt1.Parity == this.Parity)
	return 1; // packets match
else
	return 0; // mismatch in the packets
endfunction

endclass : Packet 


// ********** Driver Class ******** //
class Driver;

	// define packet handle
	Packet Pkt; 
	// declare virtual interface
	 
	// declare parameterized mailbox to communicate with scoreboard
	mailbox #(Packet) drvr2sb;
	virtual if_wr if_wr_vi; 
	// class constructor : will be used to connect mailbox and interface
	function new (input mailbox #(Packet) _mb, input virtual if_wr _if_wr_vi);
		if(_mb == null || _if_wr_vi == null) begin
			$display(" %0d: Inside Driver: ERROR: Mailbox/Interface from environment is null",$time);
			$finish;
		end
		else begin
			this.if_wr_vi = _if_wr_vi;
			this.drvr2sb = _mb;
		end
	endfunction	
	
	// task 'write' that will run for n cycles
	task automatic write(int n);	
			logic [31:0] arr;	// this will hold the packed frame
			$display("%0d: Inside Driver: Create a packet to send to DUT",$time);
			repeat(n)
			begin
				
				repeat(2)@(if_wr_vi.cb_DUT);
				
				// create a packet, randomize it and pack it into a frame
				Pkt = new($random);	// create a new randomized packet
				Pkt.pack(arr); // pack the randomized packet into a frame
				Pkt.display();
				
				// create conditions for writing into FIFO				
				if_wr_vi.DUT.write <= 1'b1;
				if_wr_vi.cb_DUT.wdata <= arr;
				
				@(if_wr_vi.cb_DUT);	
				if_wr_vi.DUT.write <= 1'b0;				
				$display("%0d: Inside Driver: Frame No. %d sent to DUT",$time,Pkt.Frame_id);
				
				// Send the packet to the scoreboard
				drvr2sb.put(Pkt);
				$display("%0d: Inside Driver: Packet No. %d sent to Score Board",$time,Pkt.Frame_id);
				
			end
			$display("%0d: Inside Driver: All packets sent !\n",$time);
			
	endtask	: write
	
endclass : Driver

// ********** Receiver Class ******** //  
class Receiver;	

    //define packet handle
	Packet Pkt; 
	// declare virtual interface
	virtual if_rd if_rd_vi;
	// declare parameterized mailbox to communicate with scoreboard
	mailbox #(Packet) rcvr2sb;	
	
	// class constructor : will be used to connect mailbox and interface
	function new (mailbox #(Packet) _mb, virtual if_rd _if_rd_vi);
		if(_mb == null || _if_rd_vi == null) begin
			$display(" Inside Receiver: ERROR: Mailbox/Interface from environment is null");
			$finish;
		end
		else begin
			this.if_rd_vi = _if_rd_vi;
			this.rcvr2sb = _mb;
		end
	endfunction
	
	// Following task will read from FIFO and communicate with scoreboard
	task automatic read(int n);	
			logic [31:0] arr;	// this will hold the packed frame
			$display("%0d: Inside Receiver: Create a packet to send to Scoreboard",$time);
			repeat(n)
			begin
				repeat(2)@if_rd_vi.cb_DUT;
				Pkt = new(arr);
				// create conditions for reading from FIFO
				if_rd_vi.DUT.read <= 1'b1;
				arr = if_rd_vi.cb_DUT.rdata; 
				
				@(if_rd_vi.cb_DUT); 
				if_rd_vi.DUT.read <= 1'b0;
				
				// create a packet from the received frame 				
				Pkt.unpack(arr); // unpack the frame into a packet
				Pkt.display();
				
				// Send the packet to the scoreboard
				rcvr2sb.put(Pkt);
				$display("%0d: Inside Receiver: Packet %0d sent to Score Board",$time,Pkt.Frame_id);	
				
				@if_rd_vi.cb_DUT;
				
			end
			
	endtask	: read
	
endclass : Receiver	

// ********** Score Board Class ******** // 	 
class Scoreboard;
	// declare parameterized mailbox to communicate with Driver and Receiver
	mailbox #(Packet) rcvr2sb, drvr2sb;
	Packet pkt1, pkt2;
	int data_frames_lost = 'd0;	// will be used by fifo_overflow()
	bit overflow = 'd0;
	int read_cycles_wasted = 'd0; // will be used by fifo_underflow()
	bit underflow = 'd0;
	bit fifo_status = 0; // used by fifo_full and fifo_empty tasks
	
	// class constructor : will be used to connect mailboxes 
	function new (input mailbox #(Packet) _drvr_mb, input mailbox #(Packet) _rcvr_mb);
		if(_drvr_mb == null || _rcvr_mb == null) begin
			$display(" Inside Scoreboard: ERROR: Mailboxes from environment are null");
			$finish;
		end
		else begin
			this.rcvr2sb = _rcvr_mb;
			this.drvr2sb = _drvr_mb;
		end
	endfunction
	
	// Full / Empty condition
	task fifo_full();
		forever begin	
			if(~fifo_status) begin
				if({~($root.dut_wr_inst.dut1.cmp_wr.wptr[ADDR]), $root.dut_wr_inst.dut1.cmp_wr.wptr[ADDR-1:0]} == $root.dut_wr_inst.dut1.cmp_wr.rptr[ADDR:0])
					begin
						$display("%0d: Inside Scoreboard : FIFO full!", $time);
						fifo_status = 1;
						//overflow = 1'b1;
					end
			end
			
			//if(overflow) begin
			//	data_frames_lost = data_frames_lost + 1;
			//end
			@$root.if_wr_inst.cb_DUT;	
		end
	endtask : fifo_full 
	
	task fifo_empty();
			forever begin	
			if(fifo_status) begin
				if($root.dut_wr_inst.dut1.cmp_rd.wptr[ADDR:0] == $root.dut_wr_inst.dut1.cmp_rd.rptr[ADDR:0])
					begin
						$display("%0d: Inside Scoreboard : FIFO empty!", $time);
						fifo_status = 0;
					end
			end
			@$root.if_wr_inst.cb_DUT;
		end
	endtask : fifo_empty
	
	// Compare Packets
	task pkt_compare();
		int result;
		forever begin
			result = 'd9;
			rcvr2sb.get(pkt1);
			$display("%0d: Inside Scoreboard: Received packet: %0d from receiver!",$time,pkt1.Frame_id);
			drvr2sb.get(pkt2);
			$display("%0d: Inside Scoreboard: Received packet: %0d from driver!",$time,pkt2.Frame_id);
			// call the compare function inside any of the packets
			result = pkt1.compare(pkt2); 
			if(result == 'd0)
				$display("%0d: Inside Scoreboard: Data received NOT EQUAL TO Data sent!",$time);
			else if(result == 'd1)
				$display("%0d: Inside Scoreboard: Data received EQUAL TO Data sent!",$time);
			else
				$display("%0d: Inside Scoreboard: *** Error *** Packet comparison failed!",$time); 
		end
	endtask : pkt_compare
	
	// will report FIFO overflow
	task fifo_overflow();		
	$display("@%0d: Inside Scoreboard : Overflow check ", $time);
	forever begin
		if($root.dut_wr_inst.dut1.wfull) begin 
			if($root.dut_wr_inst.dut1.write) begin
				@(posedge $root.dut_wr_inst.dut1.wclk)	data_frames_lost++;
				$display("@%0d: Inside Scoreboard : Last %0d Data packets lost due to Overflow !", $time, data_frames_lost);
			end
		end
			
			@$root.if_wr_inst.cb_DUT;
		end		   
	endtask : fifo_overflow
	
	// will report FIFO underflow
	task fifo_underflow(); 	
	$display("@%0d: Inside Scoreboard : Underflow check ", $time);
	forever begin
		if($root.dut_wr_inst.dut1.rempty) begin 
			if($root.dut_wr_inst.dut1.read) begin
				@(posedge $root.dut_wr_inst.dut1.rclk)	read_cycles_wasted++;
				$display("@%0d: Inside Scoreboard : Last %0d read cycles wasted due to Underflow !", $time, read_cycles_wasted);
			end
		end
			
			@$root.if_rd_inst.cb_DUT;
		end			
	endtask : fifo_underflow
	
	// Parent task
	task automatic start();
		fork
				pkt_compare();
				fifo_full();
				fifo_empty();
				fifo_overflow();
				//fifo_underflow();
		join_none
		
	endtask : start
endclass : Scoreboard

// ********** Environment Class ******** //	
class Environment;
	// declare mailboxes 
	mailbox #(Packet) drvr_mb, rcvr_mb;	 
	// declare virtual interfaces
	virtual if_wr if_wr_vi;
	virtual if_rd if_rd_vi;
	// declare driver and receiver 
	Driver drvr;
	Receiver rcvr;
	Scoreboard scbd;
	
	
	// constructor method
	function new(input virtual if_wr _if_wr_vi,input virtual if_rd _if_rd_vi);
		$display("%0d: Inside Environment: Environment object created!",$time);
		// assign the virtual interfaces
		this.if_wr_vi = _if_wr_vi;
		this.if_rd_vi = _if_rd_vi;
	endfunction : new
	
	// instantiate all the testbench components
	task automatic build();
		$display("%0d: Inside Environment: Build task started",$time);
		// mailboxes
		drvr_mb = new();
		rcvr_mb = new();
		// driver,receiver and scoreboard
		drvr = new(drvr_mb,if_wr_vi);
		rcvr = new(rcvr_mb,if_rd_vi);
		scbd = new(drvr_mb,rcvr_mb);
		$display("%0d: Inside Environment: Build task completed",$time);
	endtask : build
	
	// reset the DUT
	task automatic reset();
		$display("%0d: Inside Environment: Reset task started",$time);
		//reset the DUT by asserting reset and making input signals low for 10 clocks of the faster clock
		
		if_wr_vi.cb_DUT.wdata <= 'd0;
		if_wr_vi.DUT.write <= 1'b0;
		if_rd_vi.DUT.read <= 1'b0;
		
		if_wr_vi.DUT.wreset_b <= 1'd0;
		if_rd_vi.DUT.rreset_b <= 1'd0;
		repeat(12) @(if_wr_vi.cb_DUT); 
		
		// de-assert reset signals
		if_wr_vi.DUT.wreset_b <= 1'b1;
		if_rd_vi.DUT.rreset_b <= 1'b1;
		$display("%0d: Inside Environment: Reset task completed",$time);
	endtask : reset
	
	// this task will start the scoreboard
	task automatic start();
		$display("%0d: Inside Environment: Start task started",$time); 
		fork
		scbd.start();
		join_none
		$display("%0d: Inside Environment: Start task completed",$time);
	endtask : start	
	
	// this task will call the build, reset and start tasks
	task automatic run();
		$display("%0d: Inside Environment: Run task started",$time);
		this.build();
		this.reset();
		this.start();
		$display("%0d: Inside Environment: Run task completed",$time);
	endtask : run

endclass : Environment