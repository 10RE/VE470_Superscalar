/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  if_stage.v                                          //
//                                                                     //
//  Description :  instruction fetch (IF) stage of the pipeline;       // 
//                 fetch instruction, compute next PC location, and    //
//                 send them down the pipeline.                        //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module detect_structural_hazard(
    input EX_MEM_PACKET ex_mem_packet_0, ex_mem_packet_1, ex_mem_packet_2,
    output [2:0] structural_haz
);
    assign structural_haz[0] = ex_mem_packet_0.valid &(ex_mem_packet_0.wr_mem | ex_mem_packet_0.rd_mem);
    assign structural_haz[1] = ex_mem_packet_1.valid &(ex_mem_packet_1.wr_mem | ex_mem_packet_1.rd_mem);
    assign structural_haz[2] = ex_mem_packet_2.valid &(ex_mem_packet_2.wr_mem | ex_mem_packet_2.rd_mem);
endmodule


module if_stage(
	input         clock,                  // system clock
	input         reset,                  // system reset
	input         mem_wb_valid_inst,      // only go to next instruction when true
	                                      // makes pipeline behave as single-cycle
	input         ex_mem_take_branch,      // taken-branch signal
	input  [`XLEN-1:0] ex_mem_target_pc,        // target pc: use if take_branch is TRUE
	//***************************
	input EX_MEM_PACKET ex_mem_packet_0, ex_mem_packet_1, ex_mem_packet_2,
	output logic [`XLEN-1:0] proc2Imem_addr_0, proc2Imem_addr_1, proc2Imem_addr_2,    // Address sent to Instruction memory
	input  [63:0] Imem2proc_data_0, Imem2proc_data_1,Imem2proc_data_2   // Data coming back from instruction-memory
	
	,output IF_ID_PACKET if_packet_out_0         // Output data packet from IF going to ID, see sys_defs for signal information 
    ,output IF_ID_PACKET if_packet_out_1
    ,output IF_ID_PACKET if_packet_out_2
    
    ,input [1:0] rollback
    
    ,output logic [1:0] invalid_way
);

	logic    [`XLEN-1:0] PC_reg;             // PC we are currently fetching
	
	logic    [`XLEN-1:0] PC_plus_4, PC_plus_8, PC_plus_12;
	logic    [`XLEN-1:0] next_PC;
	logic           PC_enable;
	
    wire [2:0] structural_haz;

	detect_structural_hazard ds_unit(
		.ex_mem_packet_0(ex_mem_packet_0),
		.ex_mem_packet_1(ex_mem_packet_1),
		.ex_mem_packet_2(ex_mem_packet_2),
		.structural_haz(structural_haz)
	);
	//********************* set the fetch address to be sent to the I_memory

   
	logic [1:0] mem_count;
	assign mem_count = {1'b0,structural_haz[0]} + {1'b0,structural_haz[1]} + {1'b0,structural_haz[2]};
	assign invalid_way = mem_count > rollback? mem_count: rollback;
	
    assign if_packet_out_0.valid = invalid_way<3;
    assign if_packet_out_1.valid = invalid_way<2;
    assign if_packet_out_2.valid = invalid_way == 0;
    //assign if_valid = if_packet_out_0.valid;

	//reorder
	always_comb begin
	   case(structural_haz)
	       3'b010: begin
	           proc2Imem_addr_0 = {PC_reg[`XLEN-1:3], 3'b0};
	           proc2Imem_addr_1 = {`XLEN'b0}; //invalid 
	           proc2Imem_addr_2 = {PC_plus_4[`XLEN-1:3], 3'b0};
	           //
	           if_packet_out_0.inst = PC_reg[2] ? Imem2proc_data_0[63:32] : Imem2proc_data_0[31:0];
	           if_packet_out_1.inst  = PC_plus_4[2] ? Imem2proc_data_2[63:32] : Imem2proc_data_2[31:0];
			   if_packet_out_2.inst = `NOP;
			   if_packet_out_0.PC = PC_reg;
			   if_packet_out_1.PC = PC_plus_4;
			   if_packet_out_2.PC = 0;
	       end
	       3'b100: begin
	           proc2Imem_addr_0 = {`XLEN'b0}; //invalid 
	           proc2Imem_addr_1 = {PC_reg[`XLEN-1:3], 3'b0};
	           proc2Imem_addr_2 = {PC_plus_4[`XLEN-1:3], 3'b0};
	           //
	           if_packet_out_0.inst = PC_reg[2] ? Imem2proc_data_1[63:32] : Imem2proc_data_1[31:0];
	           if_packet_out_1.inst = PC_plus_4[2] ? Imem2proc_data_2[63:32] : Imem2proc_data_2[31:0];
			   if_packet_out_2.inst = `NOP;
			   if_packet_out_0.PC = PC_reg;
			   if_packet_out_1.PC = PC_plus_4;
			   if_packet_out_2.PC = 0;
	       end
	       3'b110: begin
	           proc2Imem_addr_0 = {`XLEN'b0}; //invalid 
	           proc2Imem_addr_1 = {`XLEN'b0}; //invalid 
	           proc2Imem_addr_2 = {PC_reg[`XLEN-1:3], 3'b0};
	           //
	           if_packet_out_0.inst = PC_reg[2] ? Imem2proc_data_2[63:32] : Imem2proc_data_2[31:0];
	           if_packet_out_1.inst = `NOP;
			   if_packet_out_2.inst = `NOP;
			   if_packet_out_0.PC = PC_reg;
			   if_packet_out_1.PC = 0;
			   if_packet_out_2.PC = 0;
	       end
	       3'b101: begin
	           proc2Imem_addr_0 = {`XLEN'b0}; //invalid 
	           proc2Imem_addr_1 = {PC_reg[`XLEN-1:3], 3'b0};
	           proc2Imem_addr_2 = {`XLEN'b0}; //invalid 
	           //
	           if_packet_out_0.inst = PC_reg[2] ? Imem2proc_data_1[63:32] : Imem2proc_data_1[31:0];
	           if_packet_out_1.inst  = `NOP;
			   if_packet_out_2.inst = `NOP;
			   if_packet_out_0.PC = PC_reg;
			   if_packet_out_1.PC = 0;
			   if_packet_out_2.PC = 0;
	       end
	       default: begin
	           proc2Imem_addr_0 = {PC_reg[`XLEN-1:3], 3'b0};
	           proc2Imem_addr_1 = {PC_plus_4[`XLEN-1:3], 3'b0};
	           proc2Imem_addr_2 = {PC_plus_8[`XLEN-1:3], 3'b0};
	           //
	           if_packet_out_0.inst = structural_haz[0]? `NOP: PC_reg[2] ? Imem2proc_data_0[63:32] : Imem2proc_data_0[31:0];
	           if_packet_out_1.inst = structural_haz[1]? `NOP: PC_plus_4[2] ? Imem2proc_data_1[63:32] : Imem2proc_data_1[31:0];
	           if_packet_out_2.inst = structural_haz[2]? `NOP: PC_plus_8[2] ? Imem2proc_data_2[63:32] : Imem2proc_data_2[31:0];
	           if_packet_out_0.PC = structural_haz[0]? 0: PC_reg;
			   if_packet_out_1.PC = structural_haz[1]? 0: PC_plus_4;
			   if_packet_out_2.PC = structural_haz[2]? 0: PC_plus_8;
	       end
	   endcase
	   //next PC
	   case(invalid_way)
	       1:       next_PC = ex_mem_take_branch ? ex_mem_target_pc : PC_plus_8;
	       2:       next_PC = ex_mem_take_branch ? ex_mem_target_pc : PC_plus_4;
	       3:       next_PC = ex_mem_take_branch ? ex_mem_target_pc : PC_reg;
	       default: next_PC = ex_mem_take_branch ? ex_mem_target_pc : PC_plus_12;
	   endcase
	   //
	   
	end 
	
	// this mux is because the Imem gives us 64 bits not 32 bits
	//assign if_packet_out.inst = PC_reg[2] ? Imem2proc_data[63:32] : Imem2proc_data[31:0];
	
	// default next PC value
	assign PC_plus_4 = PC_reg + 4;
	//**********************************
	assign PC_plus_8 = PC_reg + 8;
	assign PC_plus_12 = PC_reg + 12;
	
	// next PC is target_pc if there is a taken branch or
	// the next sequential PC (PC+4) if no branch
	// (halting is handled with the enable PC_enable;
	//assign next_PC = ex_mem_take_branch ? ex_mem_target_pc : PC_plus_4;
	
	// The take-branch signal must override stalling (otherwise it may be lost)
	//********????
	assign PC_enable = if_packet_out_0.valid | if_packet_out_1.valid| if_packet_out_2.valid| ex_mem_take_branch;
	
	// Pass PC+4 down pipeline w/instruction
	//*******???????
	//assign if_packet_out.NPC = PC_plus_4;
	//assign if_packet_out.PC  = PC_reg;
	assign if_packet_out_0.NPC = if_packet_out_0.PC + 4;
	assign if_packet_out_1.NPC = if_packet_out_1.PC + 4;
	assign if_packet_out_2.NPC = if_packet_out_2.PC + 4;
	// This register holds the PC value
	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if(reset)
			PC_reg <= `SD 0;       // initial PC value is 0
		else if(PC_enable)
			PC_reg <= `SD next_PC; // transition to next PC
	end  // always
	//******************
	//assign if_packet_out.valid = reset? 1: (structural_haz != 0? 0: 1);
	// This FF controls the stall signal that artificially forces
	// fetch to stall until the previous instruction has completed
	// This must be removed for Project 3
	// synopsys sync_set_reset "reset"
	/*
	always_ff @(posedge clock) begin
		if (reset)
			if_packet_out.valid <= `SD 1;  // must start with something
		else
			if_packet_out.valid <= `SD mem_wb_valid_inst;
	end*/
endmodule  // module if_stage
