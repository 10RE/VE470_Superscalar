/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  pipeline.v                                          //
//                                                                     //
//  Description :  Top-level module of the verisimple pipeline;        //
//                 This instantiates and connects the 5 stages of the  //
//                 Verisimple pipeline togeather.                      //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __PIPELINE_V__
`define __PIPELINE_V__

`timescale 1ns/100ps

module pipeline (

	input         clock,                    // System clock
	input         reset,                    // System reset
	input [3:0]   mem2proc_response [`WAYS:0],        // Tag from memory about current request

	
	input [63:0]  mem2proc_data [`WAYS:0],            // Data coming back from memory

	
	input [3:0]   mem2proc_tag [`WAYS:0],              // Tag from memory about current reply

	
	output logic [1:0]  proc2mem_command [`WAYS:0],    // command sent to memory

	
	output logic [`XLEN-1:0] proc2mem_addr [`WAYS:0],      // Address sent to memory

	
	output logic [63:0] proc2mem_data [`WAYS:0],      // Data sent to memory

	
	output MEM_SIZE proc2mem_size [`WAYS:0],          // data size sent to memory


	output logic [3:0]  pipeline_completed_insts,
	output EXCEPTION_CODE   pipeline_error_status,

	output logic [4:0]  pipeline_commit_wr_idx [`WAYS:0],
	output logic [`XLEN-1:0] pipeline_commit_wr_data [`WAYS:0],
	output logic        pipeline_commit_wr_en [`WAYS:0],
	output logic [`XLEN-1:0] pipeline_commit_NPC [`WAYS:0],
	
	
	// testing hooks (these must be exported so we can test
	// the synthesized version) data is tested by looking at
	// the final values in memory
	
	
	// Outputs from IF-Stage 
	output logic [`XLEN-1:0] if_NPC_out [`WAYS:0],
	output logic [31:0] if_IR_out [`WAYS:0],
	output logic        if_valid_inst_out [`WAYS:0],
	
	// Outputs from IF/ID Pipeline Register
	output logic [`XLEN-1:0] if_id_NPC [`WAYS:0],
	output logic [31:0] if_id_IR [`WAYS:0],
	output logic        if_id_valid_inst [`WAYS:0],
	
	
	// Outputs from ID/EX Pipeline Register
	output logic [`XLEN-1:0] id_ex_NPC [`WAYS:0],
	output logic [31:0] id_ex_IR [`WAYS:0],
	output logic        id_ex_valid_inst [`WAYS:0],
	
	
	// Outputs from EX/MEM Pipeline Register
	output logic [`XLEN-1:0] ex_mem_NPC [`WAYS:0],
	output logic [31:0] ex_mem_IR [`WAYS:0],
	output logic        ex_mem_valid_inst [`WAYS:0],
	
	
	// Outputs from MEM/WB Pipeline Register
	output logic [`XLEN-1:0] mem_wb_NPC [`WAYS:0],
	output logic [31:0] mem_wb_IR [`WAYS:0],
	output logic        mem_wb_valid_inst [`WAYS:0],
	
	logic [1:0] rollback

);

	// Pipeline register enables
	logic   if_id_enable, id_ex_enable, ex_mem_enable, mem_wb_enable;
	
	// Outputs from IF-Stage
	logic [`XLEN-1:0] proc2Imem_addr [`WAYS:0];


	IF_ID_PACKET if_packet [`WAYS:0];


	// Outputs from IF/ID Pipeline Register
	IF_ID_PACKET if_id_packet [`WAYS:0];


	// Outputs from ID stage
	ID_EX_PACKET id_packet [`WAYS:0];


	// Outputs from ID/EX Pipeline Register
	ID_EX_PACKET id_ex_packet [`WAYS:0];

	
	// Outputs from EX-Stage
	EX_MEM_PACKET ex_packet [`WAYS:0];


	// Outputs from EX/MEM Pipeline Register
	EX_MEM_PACKET ex_mem_packet [`WAYS:0];

	logic ex_mem_take_branch;
	logic [`XLEN-1:0] ex_mem_target_pc;
	logic [1:0] ex_mem_branch_way;
	
	
	// Outputs from MEM-Stage
	logic mem_take_branch;
	logic [`XLEN-1:0] mem_target_pc;
	logic [1:0] mem_branch_way;


	logic [`XLEN-1:0] mem_result_out [`WAYS:0];


	logic [`XLEN-1:0] proc2Dmem_addr [`WAYS:0];


	logic [`XLEN-1:0] proc2Dmem_data [`WAYS:0];


	logic [1:0]  proc2Dmem_command [`WAYS:0];


	MEM_SIZE proc2Dmem_size [`WAYS:0];


	// Outputs from MEM/WB Pipeline Register
	logic        mem_wb_halt [`WAYS:0];


	logic        mem_wb_illegal [`WAYS:0];

	
	logic  [4:0] mem_wb_dest_reg_idx [`WAYS:0];


	logic [`XLEN-1:0] mem_wb_result [`WAYS:0];

	
	logic        mem_wb_take_branch [`WAYS:0];

	
	// Outputs from WB-Stage  (These loop back to the register file in ID)
	logic [`XLEN-1:0] wb_reg_wr_data_out [`WAYS:0];
	logic  [4:0] wb_reg_wr_idx_out [`WAYS:0];
	logic        wb_reg_wr_en_out [`WAYS:0];

	//logic [1:0] rollback;
	
	always_comb begin
		pipeline_completed_insts = {3'b000, mem_wb_valid_inst[0]} + 
								   {3'b000, mem_wb_valid_inst[2]} + 
								   {3'b000, mem_wb_valid_inst[2]};
	end
	// assign pipeline_completed_insts = {3'b0, mem_wb_valid_inst};
	
	assign pipeline_error_status =  (mem_wb_illegal[0] | mem_wb_illegal[1] | mem_wb_illegal[2])          ? 		ILLEGAL_INST :
	                                (mem_wb_halt[0] | mem_wb_halt[1] | mem_wb_halt[2])                ? HALTED_ON_WFI :
	                                ((mem2proc_response[0]==4'h0) | (mem2proc_response[1]==4'h0) | (mem2proc_response[2]==4'h0))  ? LOAD_ACCESS_FAULT :
	                                NO_ERROR;
	
	assign pipeline_commit_wr_idx[0] = wb_reg_wr_idx_out[0];
	assign pipeline_commit_wr_idx[1] = wb_reg_wr_idx_out[1];
	assign pipeline_commit_wr_idx[2] = wb_reg_wr_idx_out[2];

	assign pipeline_commit_wr_data[0] = wb_reg_wr_data_out[0];
	assign pipeline_commit_wr_data[1] = wb_reg_wr_data_out[1];
	assign pipeline_commit_wr_data[2] = wb_reg_wr_data_out[2];

	assign pipeline_commit_wr_en[0] = wb_reg_wr_en_out[0];
	assign pipeline_commit_wr_en[1] = wb_reg_wr_en_out[1];
	assign pipeline_commit_wr_en[2] = wb_reg_wr_en_out[2];

	assign pipeline_commit_NPC[0] = mem_wb_NPC[0];
	assign pipeline_commit_NPC[1] = mem_wb_NPC[1];
	assign pipeline_commit_NPC[2] = mem_wb_NPC[2];
	
	assign proc2mem_command[0] =
	     (proc2Dmem_command[0] == BUS_NONE) ? BUS_LOAD : proc2Dmem_command[0];
	assign proc2mem_command[1] =
	     (proc2Dmem_command[1] == BUS_NONE) ? BUS_LOAD : proc2Dmem_command[1];
	assign proc2mem_command[2] =
	     (proc2Dmem_command[2] == BUS_NONE) ? BUS_LOAD : proc2Dmem_command[2];

	assign proc2mem_addr[0] =
	     (proc2Dmem_command[0] == BUS_NONE) ? proc2Imem_addr[0] : proc2Dmem_addr[0];
	assign proc2mem_addr[1] =
	     (proc2Dmem_command[1] == BUS_NONE) ? proc2Imem_addr[1] : proc2Dmem_addr[1];
	assign proc2mem_addr[2] =
	     (proc2Dmem_command[2] == BUS_NONE) ? proc2Imem_addr[2] : proc2Dmem_addr[2];

	//if it's an instruction, then load a double word (64 bits)
	assign proc2mem_size[0] = (proc2Dmem_command[0] == BUS_NONE) ? DOUBLE : proc2Dmem_size[0];
	assign proc2mem_size[1] = (proc2Dmem_command[1] == BUS_NONE) ? DOUBLE : proc2Dmem_size[1];
	assign proc2mem_size[2] = (proc2Dmem_command[2] == BUS_NONE) ? DOUBLE : proc2Dmem_size[2];
		 
		 
	assign proc2mem_data[0] = {32'b0, proc2Dmem_data[0]};
	assign proc2mem_data[1] = {32'b0, proc2Dmem_data[1]};
	assign proc2mem_data[2] = {32'b0, proc2Dmem_data[2]};

//////////////////////////////////////////////////
//                                              //
//                  IF-Stage                    //
//                                              //
//////////////////////////////////////////////////

	//these are debug signals that are now included in the packet,
	//breaking them out to support the legacy debug modes
	always_comb begin
		for (int i = 0; i < `WAYS; i++) begin
			if_NPC_out[i]        = if_packet[i].NPC;
			if_IR_out[i]         = if_packet[i].inst;
			if_valid_inst_out[i] = if_packet[i].valid;
		end
	end

	if_stage if_stage_0 (
		// Inputs
		.clock (clock),
		.reset (reset),
		.mem_wb_valid_inst(mem_wb_valid_inst[0]),
		.ex_mem_take_branch(mem_take_branch),
		.ex_mem_target_pc(mem_target_pc),
		.Imem2proc_data_0(mem2proc_data[0]),
		.Imem2proc_data_1(mem2proc_data[1]),
		.Imem2proc_data_2(mem2proc_data[2]),
		
		.ex_mem_packet_0(ex_mem_packet[0]),
		.ex_mem_packet_1(ex_mem_packet[1]),
		.ex_mem_packet_2(ex_mem_packet[2]),

		.rollback(rollback),
		
		// Outputs
		.proc2Imem_addr_0(proc2Imem_addr[0]),
		.proc2Imem_addr_1(proc2Imem_addr[1]),
		.proc2Imem_addr_2(proc2Imem_addr[2]),
		.if_packet_out_0(if_packet[0]),
		.if_packet_out_1(if_packet[1]),
		.if_packet_out_2(if_packet[2])
	);


//////////////////////////////////////////////////
//                                              //
//            IF/ID Pipeline Register           //
//                                              //
//////////////////////////////////////////////////

	always_comb begin
		for (int i = 0; i < `WAYS; i++) begin
			if_id_NPC[i]        = if_id_packet[i].NPC;
			if_id_IR[i]         = if_id_packet[i].inst;
			if_id_valid_inst[i] = if_id_packet[i].valid;
			if_id_enable
			
			 = 1'b1; // always enabled
		end
	end
	
	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if (reset || mem_take_branch) begin 
			if_id_packet[0].inst  <= `SD `NOP;
			if_id_packet[0].valid <= `SD `FALSE;
            if_id_packet[0].NPC   <= `SD 0;
            if_id_packet[0].PC    <= `SD 0;
			
			if_id_packet[1].inst  <= `SD `NOP;
			if_id_packet[1].valid <= `SD `FALSE;
            if_id_packet[1].NPC   <= `SD 0;
            if_id_packet[1].PC    <= `SD 0;

			if_id_packet[2].inst  <= `SD `NOP;
			if_id_packet[2].valid <= `SD `FALSE;
            if_id_packet[2].NPC   <= `SD 0;
            if_id_packet[2].PC    <= `SD 0;
		end else begin// if (reset)
			if (if_id_enable) begin
				if_id_packet[0] <= `SD if_packet[0]; 
				if_id_packet[1] <= `SD if_packet[1]; 
				if_id_packet[2] <= `SD if_packet[2]; 
			end // if (if_id_enable)	
		end
	end // always

   
//////////////////////////////////////////////////
//                                              //
//                  ID-Stage                    //
//                                              //
//////////////////////////////////////////////////
	
	id_stage id_stage_0 (// Inputs
		.clock(clock),
		.reset(reset),

		.wb_reg_wr_en_out_0   (wb_reg_wr_en_out[0]),
		.wb_reg_wr_idx_out_0  (wb_reg_wr_idx_out[0]),
		.wb_reg_wr_data_out_0 (wb_reg_wr_data_out[0]),
		.wb_reg_wr_en_out_1   (wb_reg_wr_en_out[1]),
		.wb_reg_wr_idx_out_1  (wb_reg_wr_idx_out[1]),
		.wb_reg_wr_data_out_1 (wb_reg_wr_data_out[1]),
		.wb_reg_wr_en_out_2   (wb_reg_wr_en_out[2]),
		.wb_reg_wr_idx_out_2  (wb_reg_wr_idx_out[2]),
		.wb_reg_wr_data_out_2 (wb_reg_wr_data_out[2]),

		.if_id_packet_in_0(if_id_packet[0]),
		.if_id_packet_in_1(if_id_packet[1]),
		.if_id_packet_in_2(if_id_packet[2]),

		.id_ex_packet_in_0(id_ex_packet[0]),
		.id_ex_packet_in_1(id_ex_packet[1]),
		.id_ex_packet_in_2(id_ex_packet[2]),

		.ex_mem_packet_in_0(ex_mem_packet[0]),
		.ex_mem_packet_in_1(ex_mem_packet[1]),
		.ex_mem_packet_in_2(ex_mem_packet[2]),
		
		.rollback(rollback),
		
		// Outputs
		.id_packet_out_0(id_packet[0]),
		.id_packet_out_1(id_packet[1]),
		.id_packet_out_2(id_packet[2])
	);


//////////////////////////////////////////////////
//                                              //
//            ID/EX Pipeline Register           //
//                                              //
//////////////////////////////////////////////////

	always_comb begin
		for (int i = 0; i < `WAYS; i++) begin
			id_ex_NPC[i]        = id_ex_packet[i].NPC;
			id_ex_IR[i]         = id_ex_packet[i].inst;
			id_ex_valid_inst[i] = id_ex_packet[i].valid;

			id_ex_enable = 1'b1; // always enabled
		end
	end
	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if (reset || mem_take_branch || rollback == 3) begin
			id_ex_packet[0] <= `SD '{
					{`XLEN{1'b0}},
					{`XLEN{1'b0}}, 
					{`XLEN{1'b0}}, 
					{`XLEN{1'b0}}, 
					OPA_IS_RS1, 
					OPB_IS_RS2, 
					RS_IS_RS,
					RS_IS_RS,
					`NOP,
					`ZERO_REG,
					ALU_ADD, 
					1'b0, //rd_mem
					1'b0, //wr_mem
					1'b0, //cond
					1'b0, //uncond
					1'b0, //halt
					1'b0, //illegal
					1'b0, //csr_op
					1'b0 //valid
				};
			id_ex_packet[1] <= `SD '{
					{`XLEN{1'b0}},
					{`XLEN{1'b0}}, 
					{`XLEN{1'b0}}, 
					{`XLEN{1'b0}}, 
					OPA_IS_RS1, 
					OPB_IS_RS2, 
					RS_IS_RS,
					RS_IS_RS,
					`NOP,
					`ZERO_REG,
					ALU_ADD, 
					1'b0, //rd_mem
					1'b0, //wr_mem
					1'b0, //cond
					1'b0, //uncond
					1'b0, //halt
					1'b0, //illegal
					1'b0, //csr_op
					1'b0 //valid
				};
			id_ex_packet[2] <= `SD '{
					{`XLEN{1'b0}},
					{`XLEN{1'b0}}, 
					{`XLEN{1'b0}}, 
					{`XLEN{1'b0}}, 
					OPA_IS_RS1, 
					OPB_IS_RS2, 
					RS_IS_RS,
					RS_IS_RS,
					`NOP,
					`ZERO_REG,
					ALU_ADD, 
					1'b0, //rd_mem
					1'b0, //wr_mem
					1'b0, //cond
					1'b0, //uncond
					1'b0, //halt
					1'b0, //illegal
					1'b0, //csr_op
					1'b0 //valid
				};
		end else if (rollback == 2) begin
			id_ex_packet[0] <= `SD id_packet[0];
			id_ex_packet[1] <= `SD '{
					{`XLEN{1'b0}},
					{`XLEN{1'b0}}, 
					{`XLEN{1'b0}}, 
					{`XLEN{1'b0}}, 
					OPA_IS_RS1, 
					OPB_IS_RS2, 
					RS_IS_RS,
					RS_IS_RS,
					`NOP,
					`ZERO_REG,
					ALU_ADD, 
					1'b0, //rd_mem
					1'b0, //wr_mem
					1'b0, //cond
					1'b0, //uncond
					1'b0, //halt
					1'b0, //illegal
					1'b0, //csr_op
					1'b0 //valid
				};
			id_ex_packet[2] <= `SD '{
					{`XLEN{1'b0}},
					{`XLEN{1'b0}}, 
					{`XLEN{1'b0}}, 
					{`XLEN{1'b0}}, 
					OPA_IS_RS1, 
					OPB_IS_RS2, 
					RS_IS_RS,
					RS_IS_RS,
					`NOP,
					`ZERO_REG,
					ALU_ADD, 
					1'b0, //rd_mem
					1'b0, //wr_mem
					1'b0, //cond
					1'b0, //uncond
					1'b0, //halt
					1'b0, //illegal
					1'b0, //csr_op
					1'b0 //valid
				};
		end else if (rollback == 1) begin
			id_ex_packet[0] <= `SD id_packet[0];
			id_ex_packet[1] <= `SD id_packet[1];
			id_ex_packet[2] <= `SD '{
					{`XLEN{1'b0}},
					{`XLEN{1'b0}}, 
					{`XLEN{1'b0}}, 
					{`XLEN{1'b0}}, 
					OPA_IS_RS1, 
					OPB_IS_RS2, 
					RS_IS_RS,
					RS_IS_RS,
					`NOP,
					`ZERO_REG,
					ALU_ADD, 
					1'b0, //rd_mem
					1'b0, //wr_mem
					1'b0, //cond
					1'b0, //uncond
					1'b0, //halt
					1'b0, //illegal
					1'b0, //csr_op
					1'b0 //valid
				};
		end else begin 
			id_ex_packet[0] <= `SD id_packet[0];
			id_ex_packet[1] <= `SD id_packet[1];
			id_ex_packet[2] <= `SD id_packet[2];
		end // else: !if(reset)
	end // always


//////////////////////////////////////////////////
//                                              //
//                  EX-Stage                    //
//                                              //
//////////////////////////////////////////////////
	ex_stage ex_stage_0 (
		// Inputs
		.clock(clock),
		.reset(reset),
		.id_ex_packet_in_0(id_ex_packet[0]),
		.id_ex_packet_in_1(id_ex_packet[1]),
		.id_ex_packet_in_2(id_ex_packet[2]),
		.ex_0_result(ex_mem_packet[0].alu_result),
		.ex_1_result(ex_mem_packet[1].alu_result),
		.ex_2_result(ex_mem_packet[2].alu_result),
		.mem_0_result(mem_wb_result[0]),
		.mem_1_result(mem_wb_result[1]),
		.mem_2_result(mem_wb_result[2]),
		// Outputs
		.ex_packet_out_0(ex_packet[0]),
		.ex_packet_out_1(ex_packet[1]),
		.ex_packet_out_2(ex_packet[2]),
		.ex_mem_take_branch(ex_mem_take_branch),
		.ex_mem_target_pc(ex_mem_target_pc),
		.ex_mem_branch_way(ex_mem_branch_way)
	);


//////////////////////////////////////////////////
//                                              //
//           EX/MEM Pipeline Register           //
//                                              //
//////////////////////////////////////////////////
	
	assign ex_mem_NPC[0]        = ex_mem_packet[0].NPC;
	assign ex_mem_NPC[1]        = ex_mem_packet[1].NPC;
	assign ex_mem_NPC[2]        = ex_mem_packet[2].NPC;
	
	assign ex_mem_valid_inst[0] = ex_mem_packet[0].valid;
	assign ex_mem_valid_inst[1] = ex_mem_packet[1].valid;
	assign ex_mem_valid_inst[2] = ex_mem_packet[2].valid;
	
	assign ex_mem_enable = 1'b1;
	
	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if (reset || mem_take_branch) begin
			ex_mem_IR[0]     <= `SD `NOP;
			ex_mem_IR[1]     <= `SD `NOP;
			ex_mem_IR[2]     <= `SD `NOP;

			ex_mem_packet[0] <= `SD 0;
			ex_mem_packet[1] <= `SD 0;
			ex_mem_packet[2] <= `SD 0;

			mem_take_branch <= `SD 0;
			mem_target_pc 	<= `SD 0;
			mem_branch_way 	<= `SD 0;

		end else begin
			// if (ex_mem_enable)   begin
			// 	// these are forwarded directly from ID/EX registers, only for debugging purposes
			// 	ex_mem_IR     <= `SD id_ex_IR;
			// 	// EX outputs
			// 	ex_mem_packet <= `SD ex_packet;
			// end // if
			ex_mem_IR[0]     <= `SD id_ex_IR[0];
			ex_mem_IR[1]     <= `SD id_ex_IR[1];
			ex_mem_IR[2]     <= `SD id_ex_IR[2];

			ex_mem_packet[0] <= `SD ex_packet[0];
			ex_mem_packet[1] <= `SD ex_packet[1];
			ex_mem_packet[2] <= `SD ex_packet[2];

			mem_take_branch <= `SD ex_mem_take_branch;
			mem_target_pc 	<= `SD ex_mem_target_pc;
			mem_branch_way 	<= `SD ex_mem_branch_way;
		end // else: !if(reset)
	end // always

   
//////////////////////////////////////////////////
//                                              //
//                 MEM-Stage                    //
//                                              //
//////////////////////////////////////////////////
	mem_stage mem_stage_0 (// Inputs
		.clock(clock),
		.reset(reset),

		.ex_mem_packet_in_0(ex_mem_packet[0]),
		.ex_mem_packet_in_1(ex_mem_packet[1]),
		.ex_mem_packet_in_2(ex_mem_packet[2]),

		.Dmem2proc_data_0(mem2proc_data[0]),
		.Dmem2proc_data_1(mem2proc_data[1]),
		.Dmem2proc_data_2(mem2proc_data[2]),
		
		// Outputs
		.mem_result_out_0(mem_result_out[0]),
		.mem_result_out_1(mem_result_out[1]),
		.mem_result_out_2(mem_result_out[2]),
		
		.proc2Dmem_command_0(proc2Dmem_command[0]),
		.proc2Dmem_command_1(proc2Dmem_command[1]),
		.proc2Dmem_command_2(proc2Dmem_command[2]),

		.proc2Dmem_size_0(proc2Dmem_size[0]),
		.proc2Dmem_size_1(proc2Dmem_size[1]),
		.proc2Dmem_size_2(proc2Dmem_size[2]),
		
		.proc2Dmem_addr_0(proc2Dmem_addr[0]),
		.proc2Dmem_addr_1(proc2Dmem_addr[1]),
		.proc2Dmem_addr_2(proc2Dmem_addr[2]),

		.proc2Dmem_data_0(proc2Dmem_data[0]),
		.proc2Dmem_data_1(proc2Dmem_data[1]),
		.proc2Dmem_data_2(proc2Dmem_data[2])
	);


//////////////////////////////////////////////////
//                                              //
//           MEM/WB Pipeline Register           //
//                                              //
//////////////////////////////////////////////////
	assign mem_wb_enable = 1'b1; // always enabled
	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		mem_wb_NPC[0]          <= `SD 0;
		mem_wb_IR[0]           <= `SD `NOP;
		mem_wb_halt[0]         <= `SD 0;
		mem_wb_illegal[0]      <= `SD 0;
		mem_wb_dest_reg_idx[0] <= `SD `ZERO_REG;
		mem_wb_take_branch[0]  <= `SD 0;
		mem_wb_result[0]       <= `SD 0;
		mem_wb_valid_inst[0]   <= `SD 0;

		mem_wb_NPC[1]          <= `SD 0;
		mem_wb_IR[1]           <= `SD `NOP;
		mem_wb_halt[1]         <= `SD 0;
		mem_wb_illegal[1]      <= `SD 0;
		mem_wb_dest_reg_idx[1] <= `SD `ZERO_REG;
		mem_wb_take_branch[1]  <= `SD 0;
		mem_wb_result[1]       <= `SD 0;
		mem_wb_valid_inst[1]   <= `SD 0;
		
		mem_wb_NPC[2]          <= `SD 0;
		mem_wb_IR[2]           <= `SD `NOP;
		mem_wb_halt[2]         <= `SD 0;
		mem_wb_illegal[2]      <= `SD 0;
		mem_wb_dest_reg_idx[2] <= `SD `ZERO_REG;
		mem_wb_take_branch[2]  <= `SD 0;
		mem_wb_result[2]       <= `SD 0;
		mem_wb_valid_inst[2]   <= `SD 0;

		if (!reset && mem_take_branch && mem_branch_way == 0) begin

			mem_wb_NPC[0]          <= `SD ex_mem_packet[0].NPC;
			mem_wb_IR[0]           <= `SD ex_mem_IR[0];
			mem_wb_halt[0]         <= `SD ex_mem_packet[0].halt;
			mem_wb_illegal[0]      <= `SD ex_mem_packet[0].illegal;
			mem_wb_dest_reg_idx[0] <= `SD ex_mem_packet[0].dest_reg_idx;
			mem_wb_take_branch[0]  <= `SD ex_mem_packet[0].take_branch;
			mem_wb_result[0]       <= `SD mem_result_out[0];
			mem_wb_valid_inst[0]   <= `SD ex_mem_packet[0].valid;

			mem_wb_NPC[1]          <= `SD 0;
			mem_wb_IR[1]           <= `SD `NOP;
			mem_wb_halt[1]         <= `SD 0;
			mem_wb_illegal[1]      <= `SD 0;
			mem_wb_dest_reg_idx[1] <= `SD `ZERO_REG;
			mem_wb_take_branch[1]  <= `SD 0;
			mem_wb_result[1]       <= `SD 0;
			mem_wb_valid_inst[1]   <= `SD 0;
			
			mem_wb_NPC[2]          <= `SD 0;
			mem_wb_IR[2]           <= `SD `NOP;
			mem_wb_halt[2]         <= `SD 0;
			mem_wb_illegal[2]      <= `SD 0;
			mem_wb_dest_reg_idx[2] <= `SD `ZERO_REG;
			mem_wb_take_branch[2]  <= `SD 0;
			mem_wb_result[2]       <= `SD 0;
			mem_wb_valid_inst[2]   <= `SD 0;

		end else if (!reset && mem_take_branch && mem_branch_way == 1) begin

			mem_wb_NPC[0]          <= `SD ex_mem_packet[0].NPC;
			mem_wb_IR[0]           <= `SD ex_mem_IR[0];
			mem_wb_halt[0]         <= `SD ex_mem_packet[0].halt;
			mem_wb_illegal[0]      <= `SD ex_mem_packet[0].illegal;
			mem_wb_dest_reg_idx[0] <= `SD ex_mem_packet[0].dest_reg_idx;
			mem_wb_take_branch[0]  <= `SD ex_mem_packet[0].take_branch;
			mem_wb_result[0]       <= `SD mem_result_out[0];
			mem_wb_valid_inst[0]   <= `SD ex_mem_packet[0].valid;

			mem_wb_NPC[1]          <= `SD ex_mem_packet[1].NPC;
			mem_wb_IR[1]           <= `SD ex_mem_IR[1];
			mem_wb_halt[1]         <= `SD ex_mem_packet[1].halt;
			mem_wb_illegal[1]      <= `SD ex_mem_packet[1].illegal;
			mem_wb_dest_reg_idx[1] <= `SD ex_mem_packet[1].dest_reg_idx;
			mem_wb_take_branch[1]  <= `SD ex_mem_packet[1].take_branch;
			mem_wb_result[1]       <= `SD mem_result_out[1];
			mem_wb_valid_inst[1]   <= `SD ex_mem_packet[1].valid;
			
			mem_wb_NPC[2]          <= `SD 0;
			mem_wb_IR[2]           <= `SD `NOP;
			mem_wb_halt[2]         <= `SD 0;
			mem_wb_illegal[2]      <= `SD 0;
			mem_wb_dest_reg_idx[2] <= `SD `ZERO_REG;
			mem_wb_take_branch[2]  <= `SD 0;
			mem_wb_result[2]       <= `SD 0;
			mem_wb_valid_inst[2]   <= `SD 0;
		
		end else if (!reset) begin
			
			mem_wb_NPC[0]          <= `SD ex_mem_packet[0].NPC;
			mem_wb_IR[0]           <= `SD ex_mem_IR[0];
			mem_wb_halt[0]         <= `SD ex_mem_packet[0].halt;
			mem_wb_illegal[0]      <= `SD ex_mem_packet[0].illegal;
			mem_wb_dest_reg_idx[0] <= `SD ex_mem_packet[0].dest_reg_idx;
			mem_wb_take_branch[0]  <= `SD ex_mem_packet[0].take_branch;
			mem_wb_result[0]       <= `SD mem_result_out[0];
			mem_wb_valid_inst[0]   <= `SD ex_mem_packet[0].valid;

			mem_wb_NPC[1]          <= `SD ex_mem_packet[1].NPC;
			mem_wb_IR[1]           <= `SD ex_mem_IR[1];
			mem_wb_halt[1]         <= `SD ex_mem_packet[1].halt;
			mem_wb_illegal[1]      <= `SD ex_mem_packet[1].illegal;
			mem_wb_dest_reg_idx[1] <= `SD ex_mem_packet[1].dest_reg_idx;
			mem_wb_take_branch[1]  <= `SD ex_mem_packet[1].take_branch;
			mem_wb_result[1]       <= `SD mem_result_out[1];
			mem_wb_valid_inst[1]   <= `SD ex_mem_packet[1].valid;

			mem_wb_NPC[2]          <= `SD ex_mem_packet[2].NPC;
			mem_wb_IR[2]           <= `SD ex_mem_IR[2];
			mem_wb_halt[2]         <= `SD ex_mem_packet[2].halt;
			mem_wb_illegal[2]      <= `SD ex_mem_packet[2].illegal;
			mem_wb_dest_reg_idx[2] <= `SD ex_mem_packet[2].dest_reg_idx;
			mem_wb_take_branch[2]  <= `SD ex_mem_packet[2].take_branch;
			mem_wb_result[2]       <= `SD mem_result_out[2];
			mem_wb_valid_inst[2]   <= `SD ex_mem_packet[2].valid;

		end
	end // always


//////////////////////////////////////////////////
//                                              //
//                  WB-Stage                    //
//                                              //
//////////////////////////////////////////////////
	wb_stage wb_stage_0 (
		// Inputs
		.clock(clock),
		.reset(reset),
		.mem_wb_NPC(mem_wb_NPC[0]),
		.mem_wb_result(mem_wb_result[0]),
		.mem_wb_dest_reg_idx(mem_wb_dest_reg_idx[0]),
		.mem_wb_take_branch(mem_wb_take_branch[0]),
		.mem_wb_valid_inst(mem_wb_valid_inst[0]),
		
		// Outputs
		.reg_wr_data_out(wb_reg_wr_data_out[0]),
		.reg_wr_idx_out(wb_reg_wr_idx_out[0]),
		.reg_wr_en_out(wb_reg_wr_en_out[0])
	);

	wb_stage wb_stage_1 (
		// Inputs
		.clock(clock),
		.reset(reset),
		.mem_wb_NPC(mem_wb_NPC[1]),
		.mem_wb_result(mem_wb_result[1]),
		.mem_wb_dest_reg_idx(mem_wb_dest_reg_idx[1]),
		.mem_wb_take_branch(mem_wb_take_branch[1]),
		.mem_wb_valid_inst(mem_wb_valid_inst[1]),
		
		// Outputs
		.reg_wr_data_out(wb_reg_wr_data_out[1]),
		.reg_wr_idx_out(wb_reg_wr_idx_out[1]),
		.reg_wr_en_out(wb_reg_wr_en_out[1])
	);

	wb_stage wb_stage_2 (
		// Inputs
		.clock(clock),
		.reset(reset),
		.mem_wb_NPC(mem_wb_NPC[2]),
		.mem_wb_result(mem_wb_result[2]),
		.mem_wb_dest_reg_idx(mem_wb_dest_reg_idx[2]),
		.mem_wb_take_branch(mem_wb_take_branch[2]),
		.mem_wb_valid_inst(mem_wb_valid_inst[2]),
		
		// Outputs
		.reg_wr_data_out(wb_reg_wr_data_out[2]),
		.reg_wr_idx_out(wb_reg_wr_idx_out[2]),
		.reg_wr_en_out(wb_reg_wr_en_out[2])
	);

endmodule  // module verisimple
`endif // __PIPELINE_V__
