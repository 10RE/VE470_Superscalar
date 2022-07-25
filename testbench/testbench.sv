/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  testbench.v                                         //
//                                                                     //
//  Description :  Testbench module for the verisimple pipeline;       //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

import "DPI-C" function void print_header(string str);
import "DPI-C" function void print_cycles();
import "DPI-C" function void print_stage(string div, int inst, int npc, int valid_inst);
import "DPI-C" function void print_reg(int wb_reg_wr_data_out_hi, int wb_reg_wr_data_out_lo,
                                       int wb_reg_wr_idx_out, int wb_reg_wr_en_out);
import "DPI-C" function void print_membus(int proc2mem_command, int mem2proc_response,
                                          int proc2mem_addr_hi, int proc2mem_addr_lo,
						 			     int proc2mem_data_hi, int proc2mem_data_lo);
import "DPI-C" function void print_close();


module testbench;

	// variables used in the testbench
	logic        clock;
	logic        reset;
	logic [31:0] clock_count;
	logic [31:0] instr_count;
	int          wb_fileno;
	
	logic [1:0]  proc2mem_command [`WAYS:0];
	logic [`XLEN-1:0] proc2mem_addr [`WAYS:0];
	logic [63:0] proc2mem_data [`WAYS:0];

	logic  [3:0] mem2proc_response [`WAYS:0];
	logic [63:0] mem2proc_data [`WAYS:0];
	logic  [3:0] mem2proc_tag [`WAYS:0];

	MEM_SIZE     proc2mem_size [`WAYS:0];

	logic  [3:0] pipeline_completed_insts;
	EXCEPTION_CODE   pipeline_error_status;

	logic  [4:0] pipeline_commit_wr_idx [`WAYS:0];
	logic [`XLEN-1:0] pipeline_commit_wr_data [`WAYS:0];
	logic        pipeline_commit_wr_en [`WAYS:0];
	logic [`XLEN-1:0] pipeline_commit_NPC [`WAYS:0];

	logic [`XLEN-1:0] if_NPC_out [`WAYS:0];
	logic [31:0] if_IR_out [`WAYS:0];
	logic        if_valid_inst_out [`WAYS:0];
	logic [`XLEN-1:0] if_id_NPC [`WAYS:0];
	logic [31:0] if_id_IR [`WAYS:0];
	logic        if_id_valid_inst [`WAYS:0];
	logic [`XLEN-1:0] id_ex_NPC [`WAYS:0];
	logic [31:0] id_ex_IR [`WAYS:0];
	logic        id_ex_valid_inst [`WAYS:0];
	logic [`XLEN-1:0] ex_mem_NPC [`WAYS:0];
	logic [31:0] ex_mem_IR [`WAYS:0];
	logic        ex_mem_valid_inst [`WAYS:0];
	logic [`XLEN-1:0] mem_wb_NPC [`WAYS:0];
	logic [31:0] mem_wb_IR [`WAYS:0];
	logic        mem_wb_valid_inst [`WAYS:0];


    //counter used for when pipeline infinite loops, forces termination
    logic [63:0] debug_counter;
	// Instantiate the Pipeline
	
	wire [2:0] detect_structural_hazards;
	wire [1:0]invalid_way;
	wire if_valid;
	
	pipeline core(
		// Inputs
		.clock             (clock),
		.reset             (reset),
		.mem2proc_response (mem2proc_response),
		.mem2proc_data     (mem2proc_data),
		.mem2proc_tag      (mem2proc_tag),
		
		
		// Outputs
		.proc2mem_command  (proc2mem_command),
		.proc2mem_addr     (proc2mem_addr),
		.proc2mem_data     (proc2mem_data),
		.proc2mem_size     (proc2mem_size),
		
		.pipeline_completed_insts(pipeline_completed_insts),
		.pipeline_error_status(pipeline_error_status),

		.pipeline_commit_wr_data(pipeline_commit_wr_data),
		.pipeline_commit_wr_idx(pipeline_commit_wr_idx),
		.pipeline_commit_wr_en(pipeline_commit_wr_en),
		.pipeline_commit_NPC(pipeline_commit_NPC),

		.if_NPC_out(if_NPC_out),
		.if_IR_out(if_IR_out),
		.if_valid_inst_out(if_valid_inst_out),
		.if_id_NPC(if_id_NPC),
		.if_id_IR(if_id_IR),
		.if_id_valid_inst(if_id_valid_inst),
		.id_ex_NPC(id_ex_NPC),
		.id_ex_IR(id_ex_IR),
		.id_ex_valid_inst(id_ex_valid_inst),
		.ex_mem_NPC(ex_mem_NPC),
		.ex_mem_IR(ex_mem_IR),
		.ex_mem_valid_inst(ex_mem_valid_inst),
		.mem_wb_NPC(mem_wb_NPC),
		.mem_wb_IR(mem_wb_IR),
		.mem_wb_valid_inst(mem_wb_valid_inst),
		/////////
		.detect_structural_hazards(detect_structural_hazards),
		.if_valid(if_valid)
	);


	mem memory(
	.clk(clock),              // Memory clock
	.proc2mem_addr_0(proc2mem_addr[0]),    // address for current command
	.proc2mem_addr_1(proc2mem_addr[1]),    // address for current command
	.proc2mem_addr_2(proc2mem_addr[2]),    // address for current command
	//support for memory model with byte level addressing
	.proc2mem_data_0(proc2mem_data[0]),    // address for current command
	.proc2mem_data_1(proc2mem_data[1]),    // address for current command
	.proc2mem_data_2(proc2mem_data[2]),    // address for current command

	.proc2mem_size_0(proc2mem_size[0]), //BYTE, HALF, WORD or DOUBLE
	.proc2mem_size_1(proc2mem_size[1]), //BYTE, HALF, WORD or DOUBLE
	.proc2mem_size_2(proc2mem_size[2]), //BYTE, HALF, WORD or DOUBLE
	.proc2mem_command_0(proc2mem_command[0]), // `BUS_NONE `BUS_LOAD or `BUS_STORE
	.proc2mem_command_1(proc2mem_command[1]), // `BUS_NONE `BUS_LOAD or `BUS_STORE
	.proc2mem_command_2(proc2mem_command[2]), // `BUS_NONE `BUS_LOAD or `BUS_STORE
	
	.mem2proc_response_0(mem2proc_response[0]),// 0 = can't accept, other=tag of transaction
	.mem2proc_response_1(mem2proc_response[1]),// 0 = can't accept, other=tag of transaction
	.mem2proc_response_2(mem2proc_response[2]),// 0 = can't accept, other=tag of transaction
	.mem2proc_data_0(mem2proc_data[0]),    // data resulting from a load
	.mem2proc_data_1(mem2proc_data[1]),    // data resulting from a load
	.mem2proc_data_2(mem2proc_data[2]),    // data resulting from a load
	.mem2proc_tag_0(mem2proc_tag[0]),    // 0 = no value, other=tag of transaction
	.mem2proc_tag_1(mem2proc_tag[1]),    // 0 = no value, other=tag of transaction
	.mem2proc_tag_2(mem2proc_tag[2])     // 0 = no value, other=tag of transaction
);	
	// Generate System Clock
	always begin
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock;
	end
	
	// Task to display # of elapsed clock edges
	task show_clk_count;
		real cpi;
		
		begin
			cpi = (clock_count + 1.0) / instr_count;
			$display("@@  %0d cycles / %0d instrs = %f CPI\n@@",
			          clock_count+1, instr_count, cpi);
			$display("@@  %4.2f ns total time to execute\n@@\n",
			          clock_count*`VERILOG_CLOCK_PERIOD);
		end
	endtask  // task show_clk_count 
	
	// Show contents of a range of Unified Memory, in both hex and decimal
	task show_mem_with_decimal;
		input [31:0] start_addr;
		input [31:0] end_addr;
		int showing_data;
		begin
			$display("@@@");
			showing_data=0;
			for(int k=start_addr;k<=end_addr; k=k+1)
				if (memory.unified_memory[k] != 0) begin
					$display("@@@ mem[%5d] = %x : %0d", k*8, memory.unified_memory[k], 
				                                            memory.unified_memory[k]);
					showing_data=1;
				end else if(showing_data!=0) begin
					$display("@@@");
					showing_data=0;
				end
			$display("@@@");
		end
	endtask  // task show_mem_with_decimal
	
	initial begin
		$dumpvars;
	
		clock = 1'b0;
		reset = 1'b0;
		
		// Pulse the reset signal
		$display("@@\n@@\n@@  %t  Asserting System reset......", $realtime);
		reset = 1'b1;
		@(posedge clock);
		@(posedge clock);
		
		$readmemh("program.mem", memory.unified_memory);
		
		@(posedge clock);
		@(posedge clock);
		`SD;
		// This reset is at an odd time to avoid the pos & neg clock edges
		
		reset = 1'b0;
		$display("@@  %t  Deasserting System reset......\n@@\n@@", $realtime);
		
		wb_fileno = $fopen("writeback.out");
		
		//Open header AFTER throwing the reset otherwise the reset state is displayed
		print_header("                                                                            D-MEM Bus &\n");
		print_header("Cycle:      IF1     |     IF2     |     IF3     |     ID1     |     ID2     |     ID3     |     EX1     |     EX2     |     EX3     |     MEM1    |     MEM2    |     MEM3    |     WB1     |     WB2     |     WB3     ");
	end


	// Count the number of posedges and number of instructions completed
	// till simulation ends
	always @(posedge clock) begin
		if(reset) begin
			clock_count <= `SD 0;
			instr_count <= `SD 0;
		end else begin
			clock_count <= `SD (clock_count + 1);
			instr_count <= `SD (instr_count + pipeline_completed_insts);
		end
	end  
	
	
	always @(negedge clock) begin
        if(reset) begin
			$display("@@\n@@  %t : System STILL at reset, can't show anything\n@@",
			         $realtime);
            debug_counter <= 0;
        end else begin
			`SD;
			`SD;
			
			 // print the piepline stuff via c code to the pipeline.out
			 print_cycles();
			 print_stage(" ", if_IR_out[0], if_NPC_out[0][31:0], {31'b0,if_valid_inst_out[0]});
			 print_stage("|", if_IR_out[1], if_NPC_out[1][31:0], {31'b0,if_valid_inst_out[1]});
			 print_stage("|", if_IR_out[2], if_NPC_out[2][31:0], {31'b0,if_valid_inst_out[2]});

			 print_stage("|", if_id_IR[0], if_id_NPC[0][31:0], {31'b0,if_id_valid_inst[0]});
			 print_stage("|", if_id_IR[1], if_id_NPC[1][31:0], {31'b0,if_id_valid_inst[1]});
			 print_stage("|", if_id_IR[2], if_id_NPC[2][31:0], {31'b0,if_id_valid_inst[2]});

			 print_stage("|", id_ex_IR[0], id_ex_NPC[0][31:0], {31'b0,id_ex_valid_inst[0]});
			 print_stage("|", id_ex_IR[1], id_ex_NPC[1][31:0], {31'b0,id_ex_valid_inst[1]});
			 print_stage("|", id_ex_IR[2], id_ex_NPC[2][31:0], {31'b0,id_ex_valid_inst[2]});

			 print_stage("|", ex_mem_IR[0], ex_mem_NPC[0][31:0], {31'b0,ex_mem_valid_inst[0]});
			 print_stage("|", ex_mem_IR[1], ex_mem_NPC[1][31:0], {31'b0,ex_mem_valid_inst[1]});
			 print_stage("|", ex_mem_IR[2], ex_mem_NPC[2][31:0], {31'b0,ex_mem_valid_inst[2]});

			 print_stage("|", mem_wb_IR[0], mem_wb_NPC[0][31:0], {31'b0,mem_wb_valid_inst[0]});
			 print_stage("|", mem_wb_IR[1], mem_wb_NPC[1][31:0], {31'b0,mem_wb_valid_inst[1]});
			 print_stage("|", mem_wb_IR[2], mem_wb_NPC[2][31:0], {31'b0,mem_wb_valid_inst[2]});

			 /*
			 print_reg(32'b0, pipeline_commit_wr_data[31:0],
				{27'b0,pipeline_commit_wr_idx}, {31'b0,pipeline_commit_wr_en});
			 print_membus({30'b0,proc2mem_command}, {28'b0,mem2proc_response},
				32'b0, proc2mem_addr[31:0],
				proc2mem_data[63:32], proc2mem_data[31:0]);
			*/
			
			 // print the writeback information to writeback.out
			if(pipeline_completed_insts>0) begin
				if(pipeline_commit_wr_en[0])
					$fdisplay(wb_fileno, "PC=%x, REG[%d]=%x",
						pipeline_commit_NPC[0]-4,
						pipeline_commit_wr_idx[0],
						pipeline_commit_wr_data[0]);
				else
					$fdisplay(wb_fileno, "PC=%x, ---",pipeline_commit_NPC[1]-4);
				if(pipeline_commit_wr_en[1])
					$fdisplay(wb_fileno, "PC=%x, REG[%d]=%x",
						pipeline_commit_NPC[1]-4,
						pipeline_commit_wr_idx[1],
						pipeline_commit_wr_data[1]);
				else
					$fdisplay(wb_fileno, "PC=%x, ---",pipeline_commit_NPC[1]-4);
				if(pipeline_commit_wr_en[2])
					$fdisplay(wb_fileno, "PC=%x, REG[%d]=%x",
						pipeline_commit_NPC[2]-4,
						pipeline_commit_wr_idx[2],
						pipeline_commit_wr_data[2]);
				else
					$fdisplay(wb_fileno, "PC=%x, ---",pipeline_commit_NPC[2]-4);
			end
			
			// deal with any halting conditions
			if(pipeline_error_status != NO_ERROR || debug_counter > 50000000) begin
				$display("@@@ Unified Memory contents hex on left, decimal on right: ");
				show_mem_with_decimal(0,`MEM_64BIT_LINES - 1); 
				// 8Bytes per line, 16kB total
				
				$display("@@  %t : System halted\n@@", $realtime);
				
				case(pipeline_error_status)
					LOAD_ACCESS_FAULT:  
						$display("@@@ System halted on memory error");
					HALTED_ON_WFI:          
						$display("@@@ System halted on WFI instruction");
					ILLEGAL_INST:
						$display("@@@ System halted on illegal instruction");
					default: 
						$display("@@@ System halted on unknown error code %x", 
							pipeline_error_status);
				endcase
				$display("@@@\n@@");
				show_clk_count;
				print_close(); // close the pipe_print output file
				$fclose(wb_fileno);
				#100 $finish;
			end
            debug_counter <= debug_counter + 1;
		end  // if(reset)   
	end 

endmodule  // module testbench
