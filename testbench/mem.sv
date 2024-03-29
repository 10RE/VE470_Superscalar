///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//  Modulename : mem.v                                                       //
//                                                                           //
// Description : This is a clock-based latency, pipelined memory with        //
//               3 buses (address in, data in, data out) and a limit         //
//               on the number of outstanding memory operations allowed      //
//               at any time.                                                //
//                                                                           // 
///////////////////////////////////////////////////////////////////////////////

`ifndef __MEM_V__
`define __MEM_V__

`timescale 1ns/100ps

module mem (
	input         clk,              // Memory clock
	input  [`XLEN-1:0] proc2mem_addr_0,    // address for current command
	input  [`XLEN-1:0] proc2mem_addr_1,    // address for current command
	input  [`XLEN-1:0] proc2mem_addr_2,    // address for current command
	//support for memory model with byte level addressing
	input  [63:0] proc2mem_data_0,    // address for current command
	input  [63:0] proc2mem_data_1,    // address for current command
	input  [63:0] proc2mem_data_2,    // address for current command

	input  MEM_SIZE proc2mem_size_0, //BYTE, HALF, WORD or DOUBLE
	input  MEM_SIZE proc2mem_size_1, //BYTE, HALF, WORD or DOUBLE
	input  MEM_SIZE proc2mem_size_2, //BYTE, HALF, WORD or DOUBLE
	input  [1:0]   proc2mem_command_0, // `BUS_NONE `BUS_LOAD or `BUS_STORE
	input  [1:0]   proc2mem_command_1, // `BUS_NONE `BUS_LOAD or `BUS_STORE
	input  [1:0]   proc2mem_command_2, // `BUS_NONE `BUS_LOAD or `BUS_STORE
	
	output logic  [3:0] mem2proc_response_0,// 0 = can't accept, other=tag of transaction
	output logic  [3:0] mem2proc_response_1,// 0 = can't accept, other=tag of transaction
	output logic  [3:0] mem2proc_response_2,// 0 = can't accept, other=tag of transaction
	output logic [63:0] mem2proc_data_0,    // data resulting from a load
	output logic [63:0] mem2proc_data_1,    // data resulting from a load
	output logic [63:0] mem2proc_data_2,    // data resulting from a load
	output logic  [3:0] mem2proc_tag_0,    // 0 = no value, other=tag of transaction
	output logic  [3:0] mem2proc_tag_1,    // 0 = no value, other=tag of transaction
	output logic  [3:0] mem2proc_tag_2     // 0 = no value, other=tag of transaction
  );


	logic [63:0] next_mem2proc_data_0;
	logic [63:0] next_mem2proc_data_1;
	logic [63:0] next_mem2proc_data_2;
	logic  [3:0] next_mem2proc_response_0, next_mem2proc_tag_0;
	logic  [3:0] next_mem2proc_response_1, next_mem2proc_tag_1;
	logic  [3:0] next_mem2proc_response_2, next_mem2proc_tag_2;
	
	logic [63:0]                    unified_memory  [`MEM_64BIT_LINES - 1:0];
	logic [63:0]                    loaded_data     [`NUM_MEM_TAGS:1];
	logic [`NUM_MEM_TAGS:1]  [15:0] cycles_left;
	logic [`NUM_MEM_TAGS:1]         waiting_for_bus;
	
	logic acquire_tag_0;
	logic acquire_tag_1;
	logic acquire_tag_2;
	logic bus_filled_0;
	logic bus_filled_1;
	logic bus_filled_2;
	

// Implement the Memory function

    wire valid_address_0 = (proc2mem_addr_0<`MEM_SIZE_IN_BYTES);
    wire valid_address_1 = (proc2mem_addr_1<`MEM_SIZE_IN_BYTES);
    wire valid_address_2 = (proc2mem_addr_2<`MEM_SIZE_IN_BYTES);
	EXAMPLE_CACHE_BLOCK c;

    // temporary wires for byte level selection because verilog does not support variable range selection
	always @(negedge clk) begin
		next_mem2proc_tag_0      = 4'b0;
		next_mem2proc_tag_1      = 4'b0;
		next_mem2proc_tag_2      = 4'b0;
		next_mem2proc_response_0 = 4'b0;
		next_mem2proc_response_1 = 4'b0;
		next_mem2proc_response_2 = 4'b0;
		next_mem2proc_data_0     = 64'bx;
		next_mem2proc_data_1     = 64'bx;
		next_mem2proc_data_2     = 64'bx;
		bus_filled_0             = 1'b0;
		bus_filled_1             = 1'b0;
		bus_filled_2             = 1'b0;
		acquire_tag_0            = ((proc2mem_command_0 == BUS_LOAD) ||
		                          (proc2mem_command_0 == BUS_STORE)) && valid_address_0;
		acquire_tag_1            = ((proc2mem_command_1 == BUS_LOAD) ||
		                          (proc2mem_command_1 == BUS_STORE)) && valid_address_1;
		acquire_tag_2            = ((proc2mem_command_2 == BUS_LOAD) ||
		                          (proc2mem_command_2 == BUS_STORE)) && valid_address_2;
		
		for(int i=1;i<=`NUM_MEM_TAGS;i=i+1) begin
			if(cycles_left[i]>16'd0) begin // Seems never executed since MEM_LATENCY_IN_CYCLES=0.
				cycles_left[i] = cycles_left[i]-16'd1;
			
			end else if(acquire_tag_0 && !waiting_for_bus[i]) begin // Deal with way0
				next_mem2proc_response_0 = i;
				acquire_tag_0            = 1'b0;
				cycles_left[i]         = `MEM_LATENCY_IN_CYCLES; 
				                          // must add support for random lantencies
				                          // though this could be done via a non-number
				                          // definition for this macro
				//filling up these temp variables
				c.byte_level = unified_memory[proc2mem_addr_0[`XLEN-1:3]];
				c.half_level = unified_memory[proc2mem_addr_0[`XLEN-1:3]];
				c.word_level = unified_memory[proc2mem_addr_0[`XLEN-1:3]];

				if(proc2mem_command_0 == BUS_LOAD) begin
					waiting_for_bus[i] = 1'b1;
					loaded_data[i]     = unified_memory[proc2mem_addr_0[`XLEN-1:3]];
                	case (proc2mem_size_0) 
                        BYTE: begin
							loaded_data[i] = {56'b0, c.byte_level[proc2mem_addr_0[2:0]]};
                        end
                        HALF: begin
							assert(proc2mem_addr_0[0] == 0);
							loaded_data[i] = {48'b0, c.half_level[proc2mem_addr_0[2:1]]};
                        end
                        WORD: begin
							assert(proc2mem_addr_0[1:0] == 0);
							loaded_data[i] = {32'b0, c.word_level[proc2mem_addr_0[2]]};
                        end
						DOUBLE:
							loaded_data[i] = unified_memory[proc2mem_addr_0[`XLEN-1:3]];
					endcase

				end else begin
					case (proc2mem_size_0) 
                        BYTE: begin
							c.byte_level[proc2mem_addr_0[2:0]] = proc2mem_data_0[7:0];
                            unified_memory[proc2mem_addr_0[`XLEN-1:3]] = c.byte_level;
                        end
                        HALF: begin
							assert(proc2mem_addr_0[0] == 0);
							c.half_level[proc2mem_addr_0[2:1]] = proc2mem_data_0[15:0];
                            unified_memory[proc2mem_addr_0[`XLEN-1:3]] = c.half_level;
                        end
                        WORD: begin
							assert(proc2mem_addr_0[1:0] == 0);
							c.word_level[proc2mem_addr_0[2]] = proc2mem_data_0[31:0];
                            unified_memory[proc2mem_addr_0[`XLEN-1:3]] = c.word_level;
                        end
                        default: begin
							assert(proc2mem_addr_0[1:0] == 0);
							c.byte_level[proc2mem_addr_0[2]] = proc2mem_data_0[31:0];
                            unified_memory[proc2mem_addr_0[`XLEN-1:3]] = c.word_level;
                        end
					endcase
				end
			end

			if((cycles_left[i]==16'd0) && waiting_for_bus[i] && !bus_filled_0) begin
					bus_filled_0         = 1'b1;
					next_mem2proc_tag_0  = i;
					next_mem2proc_data_0 = loaded_data[i];
					waiting_for_bus[i] = 1'b0;
			end
		end

		for(int i=1;i<=`NUM_MEM_TAGS;i=i+1) begin
			if(cycles_left[i]>16'd0) begin // Seems never executed since MEM_LATENCY_IN_CYCLES=0.
				cycles_left[i] = cycles_left[i]-16'd1;
			
			end else if(acquire_tag_1 && !waiting_for_bus[i]) begin // Deal with way1
				next_mem2proc_response_1 = i;
				acquire_tag_1            = 1'b0;
				cycles_left[i]         = `MEM_LATENCY_IN_CYCLES; 
				                          // must add support for random lantencies
				                          // though this could be done via a non-number
				                          // definition for this macro
				//filling up these temp variables
				c.byte_level = unified_memory[proc2mem_addr_1[`XLEN-1:3]];
				c.half_level = unified_memory[proc2mem_addr_1[`XLEN-1:3]];
				c.word_level = unified_memory[proc2mem_addr_1[`XLEN-1:3]];

				if(proc2mem_command_1 == BUS_LOAD) begin
					waiting_for_bus[i] = 1'b1;
					loaded_data[i]     = unified_memory[proc2mem_addr_1[`XLEN-1:3]];
                	case (proc2mem_size_1) 
                        BYTE: begin
							loaded_data[i] = {56'b0, c.byte_level[proc2mem_addr_1[2:0]]};
                        end
                        HALF: begin
							assert(proc2mem_addr_1[0] == 0);
							loaded_data[i] = {48'b0, c.half_level[proc2mem_addr_1[2:1]]};
                        end
                        WORD: begin
							assert(proc2mem_addr_1[1:0] == 0);
							loaded_data[i] = {32'b0, c.word_level[proc2mem_addr_1[2]]};
                        end
						DOUBLE:
							loaded_data[i] = unified_memory[proc2mem_addr_1[`XLEN-1:3]];
					endcase

				end else begin
					case (proc2mem_size_1) 
                        BYTE: begin
							c.byte_level[proc2mem_addr_1[2:0]] = proc2mem_data_1[7:0];
                            unified_memory[proc2mem_addr_1[`XLEN-1:3]] = c.byte_level;
                        end
                        HALF: begin
							assert(proc2mem_addr_1[0] == 0);
							c.half_level[proc2mem_addr_1[2:1]] = proc2mem_data_1[15:0];
                            unified_memory[proc2mem_addr_1[`XLEN-1:3]] = c.half_level;
                        end
                        WORD: begin
							assert(proc2mem_addr_1[1:0] == 0);
							c.word_level[proc2mem_addr_1[2]] = proc2mem_data_1[31:0];
                            unified_memory[proc2mem_addr_1[`XLEN-1:3]] = c.word_level;
                        end
                        default: begin
							assert(proc2mem_addr_1[1:0] == 0);
							c.byte_level[proc2mem_addr_1[2]] = proc2mem_data_1[31:0];
                            unified_memory[proc2mem_addr_1[`XLEN-1:3]] = c.word_level;
                        end
					endcase
				end
			end
			
			if((cycles_left[i]==16'd0) && waiting_for_bus[i] && !bus_filled_1) begin
					bus_filled_1         = 1'b1;
					next_mem2proc_tag_1  = i;
					next_mem2proc_data_1 = loaded_data[i];
					waiting_for_bus[i] = 1'b0;
			end
		end

		for(int i=1;i<=`NUM_MEM_TAGS;i=i+1) begin
			if(cycles_left[i]>16'd0) begin // Seems never executed since MEM_LATENCY_IN_CYCLES=0.
				cycles_left[i] = cycles_left[i]-16'd1;
			
			end else if(acquire_tag_2 && !waiting_for_bus[i]) begin // Deal with way2
				next_mem2proc_response_2 = i;
				acquire_tag_2            = 1'b0;
				cycles_left[i]         = `MEM_LATENCY_IN_CYCLES; 
				                          // must add support for random lantencies
				                          // though this could be done via a non-number
				                          // definition for this macro
				//filling up these temp variables
				c.byte_level = unified_memory[proc2mem_addr_2[`XLEN-1:3]];
				c.half_level = unified_memory[proc2mem_addr_2[`XLEN-1:3]];
				c.word_level = unified_memory[proc2mem_addr_2[`XLEN-1:3]];

				if(proc2mem_command_2 == BUS_LOAD) begin
					waiting_for_bus[i] = 1'b1;
					loaded_data[i]     = unified_memory[proc2mem_addr_2[`XLEN-1:3]];
                	case (proc2mem_size_2) 
                        BYTE: begin
							loaded_data[i] = {56'b0, c.byte_level[proc2mem_addr_2[2:0]]};
                        end
                        HALF: begin
							assert(proc2mem_addr_2[0] == 0);
							loaded_data[i] = {48'b0, c.half_level[proc2mem_addr_2[2:1]]};
                        end
                        WORD: begin
							assert(proc2mem_addr_2[1:0] == 0);
							loaded_data[i] = {32'b0, c.word_level[proc2mem_addr_2[2]]};
                        end
						DOUBLE:
							loaded_data[i] = unified_memory[proc2mem_addr_2[`XLEN-1:3]];
					endcase

				end else begin
					case (proc2mem_size_2) 
                        BYTE: begin
							c.byte_level[proc2mem_addr_2[2:0]] = proc2mem_data_2[7:0];
                            unified_memory[proc2mem_addr_2[`XLEN-1:3]] = c.byte_level;
                        end
                        HALF: begin
							assert(proc2mem_addr_2[0] == 0);
							c.half_level[proc2mem_addr_2[2:1]] = proc2mem_data_2[15:0];
                            unified_memory[proc2mem_addr_2[`XLEN-1:3]] = c.half_level;
                        end
                        WORD: begin
							assert(proc2mem_addr_2[1:0] == 0);
							c.word_level[proc2mem_addr_2[2]] = proc2mem_data_2[31:0];
                            unified_memory[proc2mem_addr_2[`XLEN-1:3]] = c.word_level;
                        end
                        default: begin
							assert(proc2mem_addr_2[1:0] == 0);
							c.byte_level[proc2mem_addr_2[2]] = proc2mem_data_2[31:0];
                            unified_memory[proc2mem_addr_2[`XLEN-1:3]] = c.word_level;
                        end
					endcase
				end
			end
			
			if((cycles_left[i]==16'd0) && waiting_for_bus[i] && !bus_filled_2) begin
					bus_filled_2         = 1'b1;
					next_mem2proc_tag_2  = i;
					next_mem2proc_data_2 = loaded_data[i];
					waiting_for_bus[i] = 1'b0;
			end 
		end
		mem2proc_response_0 <= `SD next_mem2proc_response_0;
		mem2proc_response_1 <= `SD next_mem2proc_response_1;
		mem2proc_response_2 <= `SD next_mem2proc_response_2;
		mem2proc_data_0     <= `SD next_mem2proc_data_0;
		mem2proc_data_1     <= `SD next_mem2proc_data_1;
		mem2proc_data_2     <= `SD next_mem2proc_data_2;
		mem2proc_tag_0      <= `SD next_mem2proc_tag_0;
		mem2proc_tag_1      <= `SD next_mem2proc_tag_1;
		mem2proc_tag_2      <= `SD next_mem2proc_tag_2;
	end
	// Initialise the entire memory
	initial begin
		for(int i=0; i<`MEM_64BIT_LINES; i=i+1) begin
			unified_memory[i] = 64'h0;
		end
		mem2proc_data_0=64'bx;
		mem2proc_data_1=64'bx;
		mem2proc_data_2=64'bx;
		mem2proc_tag_0=4'd0;
		mem2proc_tag_1=4'd0;
		mem2proc_tag_2=4'd0;
		mem2proc_response_0=4'd0;
		mem2proc_response_1=4'd0;
		mem2proc_response_2=4'd0;
		for(int i=1;i<=`NUM_MEM_TAGS;i=i+1) begin
			loaded_data[i]=64'bx;
			cycles_left[i]=16'd0;
			waiting_for_bus[i]=1'b0;
		end
	end

endmodule    // module mem
`endif //__MEM_V__