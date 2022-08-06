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
	input [3:0]   mem2proc_response [`WAYS-1:0],        // Tag from memory about current request

	
	input [63:0]  mem2proc_data [`WAYS-1:0],            // Data coming back from memory

	
	input [3:0]   mem2proc_tag [`WAYS-1:0],              // Tag from memory about current reply

	
	output logic [1:0]  proc2mem_command [`WAYS-1:0],    // command sent to memory

	
	output logic [`XLEN-1:0] proc2mem_addr [`WAYS-1:0],      // Address sent to memory

	
	output logic [63:0] proc2mem_data [`WAYS-1:0],      // Data sent to memory

	
	output MEM_SIZE proc2mem_size [`WAYS-1:0],          // data size sent to memory


	output EXCEPTION_CODE   pipeline_error_status,

    output logic [3:0] pipeline_completed_inst [`WAYS-1:0],
	output logic [4:0]  pipeline_commit_wr_idx [`WAYS-1:0],
	output logic [`XLEN-1:0] pipeline_commit_wr_data [`WAYS-1:0],
	output logic        pipeline_commit_wr_en [`WAYS-1:0],
	output logic [`XLEN-1:0] pipeline_commit_NPC [`WAYS-1:0],
	
	
	// testing hooks (these must be exported so we can test
	// the synthesized version) data is tested by looking at
	// the final values in memory
	
	
	// Outputs from IF-Stage 
	output logic [`XLEN-1:0] if_NPC_out [`WAYS-1:0],
	output logic [31:0] if_IR_out [`WAYS-1:0],
	output logic        if_valid_inst_out [`WAYS-1:0],
	
	// Outputs from IF/ID Pipeline Register
	output logic [`XLEN-1:0] if_id_NPC [`WAYS-1:0],
	output logic [31:0] if_id_IR [`WAYS-1:0],
	output logic        if_id_valid_inst [`WAYS-1:0],
	
	
	// Outputs from ID/EX Pipeline Register
	output logic [`XLEN-1:0] id_ex_NPC [`WAYS-1:0],
	output logic [31:0] id_ex_IR [`WAYS-1:0],
	output logic        id_ex_valid_inst [`WAYS-1:0],
	
	
	// Outputs from EX/MEM Pipeline Register
	output logic [`XLEN-1:0] ex_mem_NPC [`WAYS-1:0],
	output logic [31:0] ex_mem_IR [`WAYS-1:0],
	output logic        ex_mem_valid_inst [`WAYS-1:0],
	
	
	// Outputs from MEM/WB Pipeline Register
	output logic [`XLEN-1:0] mem_wb_NPC [`WAYS-1:0],
	output logic [31:0] mem_wb_IR [`WAYS-1:0],
	output logic        mem_wb_valid_inst [`WAYS-1:0]
	
    ,output logic [`ROLLBACK_WIDTH-1:0] rollback_out
    
    ,output logic [`ROLLBACK_WIDTH-1:0] invalid_way

    
    `ifdef DEBUG
    ,output logic [`XLEN-1:0] sorted_packet_0_PC
    ,output logic [`XLEN-1:0] wb_data
	,output logic [`XLEN-1:0] branch_penalty
	,output logic [`XLEN-1:0] dependency_penalty
    `endif
);

    assign rollback_out = rollback;
   `ifdef DEBUG
   assign wb_data = ex_packet[0].alu_result;
   `endif

	// Pipeline register enables
	logic   if_id_enable, id_ex_enable, ex_mem_enable, mem_wb_enable;
	
	// Outputs from IF-Stage
	logic [`XLEN-1:0] proc2Imem_addr [`WAYS-1:0];


	IF_ID_PACKET if_packet [`WAYS-1:0];


	// Outputs from IF/ID Pipeline Register
	IF_ID_PACKET if_id_packet [`WAYS-1:0];


	// Outputs from ID stage
	ID_EX_PACKET id_packet [`WAYS-1:0];


	// Outputs from ID/EX Pipeline Register
	ID_EX_PACKET id_ex_packet [`WAYS-1:0];

	
	// Outputs from EX-Stage
	EX_MEM_PACKET ex_packet [`WAYS-1:0];


	// Outputs from EX/MEM Pipeline Register
	EX_MEM_PACKET ex_mem_packet [`WAYS-1:0];

	logic ex_mem_take_branch;
	logic [`XLEN-1:0] ex_mem_target_pc;
	logic [`ROLLBACK_WIDTH-1:0] ex_mem_branch_way;
	logic [`WAYS-1:0] ex_mem_is_branch;
	
	
	// Outputs from MEM-Stage
	logic mem_take_branch;
	logic [`XLEN-1:0] mem_target_pc;
	logic [`ROLLBACK_WIDTH-1:0] mem_branch_way;


	logic [`XLEN-1:0] mem_result_out [`WAYS-1:0];


	logic [`XLEN-1:0] proc2Dmem_addr [`WAYS-1:0];


	logic [`XLEN-1:0] proc2Dmem_data [`WAYS-1:0];


	logic [1:0]  proc2Dmem_command [`WAYS-1:0];


	MEM_SIZE proc2Dmem_size [`WAYS-1:0];


	// Outputs from MEM/WB Pipeline Register
	logic        mem_wb_halt [`WAYS-1:0];


	logic        mem_wb_illegal [`WAYS-1:0];

	
	logic  [4:0] mem_wb_dest_reg_idx [`WAYS-1:0];


	logic [`XLEN-1:0] mem_wb_result [`WAYS-1:0];

	
	logic        mem_wb_take_branch [`WAYS-1:0];

	
	// Outputs from WB-Stage  (These loop back to the register file in ID)
	logic [`XLEN-1:0] wb_reg_wr_data_out [`WAYS-1:0];
	logic  [4:0] wb_reg_wr_idx_out [`WAYS-1:0];
	logic        wb_reg_wr_en_out [`WAYS-1:0];

	logic [`ROLLBACK_WIDTH-1:0] rollback;
	
	// assign pipeline_completed_insts = {3'b0, mem_wb_valid_inst};
	
	assign pipeline_completed_inst[0] = {3'b000, mem_wb_valid_inst[0]};
	assign pipeline_completed_inst[1] = {3'b000, mem_wb_valid_inst[1]};
	assign pipeline_completed_inst[2] = {3'b000, mem_wb_valid_inst[2]};
	
	assign pipeline_error_status =  (mem_wb_illegal[0] | !mem_wb_halt[0]&mem_wb_illegal[1] | !mem_wb_halt[0]&!mem_wb_halt[1]&mem_wb_illegal[2])          ? 		ILLEGAL_INST :
	                                (mem_wb_halt[0] | mem_wb_halt[1] | mem_wb_halt[2])                ? HALTED_ON_WFI :
	                                ((mem2proc_response[0]==4'h0) | (mem2proc_response[1]==4'h0) | (mem2proc_response[2]==4'h0))  ? LOAD_ACCESS_FAULT :
	                                NO_ERROR;
	
	assign pipeline_commit_wr_idx = wb_reg_wr_idx_out;
	assign pipeline_commit_wr_data = wb_reg_wr_data_out;
	assign pipeline_commit_wr_en = wb_reg_wr_en_out;
	assign pipeline_commit_NPC = mem_wb_NPC;

genvar i;
generate;
	for( i=0; i<`WAYS; i++) begin
		assign proc2mem_command[i] =
			(proc2Dmem_command[i] == BUS_NONE) ? BUS_LOAD : proc2Dmem_command[i];
		assign proc2mem_addr[i] =
			(proc2Dmem_command[i] == BUS_NONE) ? proc2Imem_addr[i] : proc2Dmem_addr[i];
		//if it's an instruction, then load a double word (64 bits)
		assign proc2mem_size[i] = (proc2Dmem_command[i] == BUS_NONE) ? DOUBLE : proc2Dmem_size[i];
		assign proc2mem_data[i] = {32'b0, proc2Dmem_data[i]};
	end
endgenerate


//////////////////////////////////////////////////
//                                              //
//                  IF-Stage                    //
//                                              //
//////////////////////////////////////////////////

	//these are debug signals that are now included in the packet,
	//breaking them out to support the legacy debug modes
	
	always_comb begin
	   integer i;
		for (i = 0; i < `WAYS; i++) begin
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
		.ex_mem_packet(ex_mem_packet),
		.Imem2proc_data(mem2proc_data),
		
		
		// Outputs
		.proc2Imem_addr(proc2Imem_addr),
		.if_packet_out(if_packet),
		
		.rollback(rollback),
		
		.invalid_way(invalid_way)
	);


//////////////////////////////////////////////////
//                                              //
//            IF/ID Pipeline Register           //
//                                              //
//////////////////////////////////////////////////

	always_comb begin
	   integer i;
		for (i = 0; i < `WAYS; i++) begin
			if_id_NPC[i]        = if_id_packet[i].NPC;
			if_id_IR[i]         = if_id_packet[i].inst;
			if_id_valid_inst[i] = if_id_packet[i].valid; // always enabled
		end
	end
	
	assign if_id_enable = 1;
	
	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if (reset || mem_take_branch) begin 
			for (int i = 0; i < `WAYS; i++)
				if_id_packet[i]<=`SD '{inst:`NOP,valid:`FALSE,NPC:0,PC:0};	
		end else begin// if (reset)
			if (if_id_enable) begin
				if_id_packet <= `SD if_packet; 
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

		.wb_reg_wr_en_out   (wb_reg_wr_en_out),
		.wb_reg_wr_idx_out  (wb_reg_wr_idx_out),
		.wb_reg_wr_data_out (wb_reg_wr_data_out),

		.if_id_packet_in(if_id_packet),
		.id_ex_packet_in(id_ex_packet),
		.ex_mem_packet_in(ex_mem_packet),
		
		.rollback(rollback),
		.ex_mem_take_branch(mem_take_branch),
		
		// Outputs
		.id_packet_out(id_packet)
		
		`ifdef DEBUG
		,.sorted_packet_0_PC(sorted_packet_0_PC)
		`endif
	);


//////////////////////////////////////////////////
//                                              //
//            ID/EX Pipeline Register           //
//                                              //
//////////////////////////////////////////////////

	always_comb begin
		for (int i = 0; i <= `WAYS-1; i++) begin
			id_ex_NPC[i]        = id_ex_packet[i].NPC;
			id_ex_IR[i]         = id_ex_packet[i].inst;
			id_ex_valid_inst[i] = id_ex_packet[i].valid;

			
		end
	end
	
	assign id_ex_enable = 1'b1; // always enabled
	// synopsys sync_set_reset "reset"

`define EMPTY_ID_PACKET '{\
					{`XLEN{1'b0}},\
					{`XLEN{1'b0}},\
					{`XLEN{1'b0}},\
					{`XLEN{1'b0}},\
					OPA_IS_RS1,\
					OPB_IS_RS2,\
					RS_IS_RS,\
					RS_IS_RS,\
					`NOP,\
					`ZERO_REG,\
					ALU_ADD,\
					1'b0,\
					1'b0,\
					1'b0,\
					1'b0,\
					1'b0,\
					1'b0,\
					1'b0,\
					1'b0\
				}
	always_ff @(posedge clock) begin
		if (reset || mem_take_branch || rollback == 3) begin
			id_ex_packet[0] <= `SD `EMPTY_ID_PACKET;
			id_ex_packet[1] <= `SD `EMPTY_ID_PACKET;
			id_ex_packet[2] <= `SD `EMPTY_ID_PACKET;
		end else if (rollback == 2) begin
			id_ex_packet[0] <= `SD id_packet[0];
			id_ex_packet[1] <= `SD `EMPTY_ID_PACKET;
			id_ex_packet[2] <= `SD `EMPTY_ID_PACKET;
		end else if (rollback == 1) begin
			id_ex_packet[0] <= `SD id_packet[0];
			id_ex_packet[1] <= `SD id_packet[1];
			id_ex_packet[2] <= `SD `EMPTY_ID_PACKET;
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
		.id_ex_packet_in(id_ex_packet),
		.ex_result('{ex_mem_packet[2].alu_result,ex_mem_packet[1].alu_result,ex_mem_packet[0].alu_result}),
		.mem_result(mem_wb_result),
		// Outputs
		.ex_packet_out(ex_packet),
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

	assign ex_mem_is_branch = {ex_packet[2].is_branch,ex_packet[1].is_branch,ex_packet[0].is_branch};
	
	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if (reset || mem_take_branch) begin
			ex_mem_IR     <= `SD {`NOP,`NOP,`NOP};

			ex_mem_packet <= `SD {0,0,0};

			mem_take_branch <= `SD 0;
			mem_target_pc 	<= `SD 0;
			mem_branch_way 	<= `SD 0;

		end else begin
			mem_take_branch <= `SD ex_mem_take_branch;
			mem_target_pc 	<= `SD ex_mem_target_pc;
			mem_branch_way 	<= `SD ex_mem_branch_way;
			//squash instrs after branch but in the same stage
			if (ex_mem_take_branch && ex_mem_branch_way==0) begin 
				ex_mem_packet[0] <= `SD ex_packet[0];
				ex_mem_IR[0]<=`SD id_ex_IR[0];
				ex_mem_packet[2:1] <= `SD {0,0};
				ex_mem_IR[2:1] <= `SD {`NOP,`NOP};
			end else if (ex_mem_take_branch && ex_mem_branch_way==1) begin
				ex_mem_packet[1:0] <= `SD ex_packet[1:0];
				ex_mem_IR[1:0]<=`SD id_ex_IR[1:0];
				ex_mem_packet[2] <= `SD {0};
				ex_mem_IR[2] <= `SD {`NOP};
			end else begin
				ex_mem_IR     <= `SD id_ex_IR;
				ex_mem_packet <= `SD ex_packet;
			end // else
		end
	end // always

   
//////////////////////////////////////////////////
//                                              //
//                 MEM-Stage                    //
//                                              //
//////////////////////////////////////////////////
	mem_stage mem_stage_0 (// Inputs
		.clock(clock),
		.reset(reset),
		.ex_mem_packet_in(ex_mem_packet),
		.Dmem2proc_data('{mem2proc_data[2][`XLEN-1:0],mem2proc_data[1][`XLEN-1:0],mem2proc_data[0][`XLEN-1:0]}),
		
		// Outputs
		.mem_result_out(mem_result_out),
		.proc2Dmem_command(proc2Dmem_command),
		.proc2Dmem_size(proc2Dmem_size),
		.proc2Dmem_addr(proc2Dmem_addr),
		.proc2Dmem_data(proc2Dmem_data)
	);


//////////////////////////////////////////////////
//                                              //
//           MEM/WB Pipeline Register           //
//                                              //
//////////////////////////////////////////////////
	assign mem_wb_enable = 1'b1; // always enabled
	// synopsys sync_set_reset "reset"
`define MEM_WB_SQUASH_WAY(I) 	mem_wb_NPC[I]          <= `SD 0;\
						mem_wb_IR[I]           <= `SD `NOP;\
						mem_wb_halt[I]         <= `SD 0;\
						mem_wb_illegal[I]      <= `SD 0;\
						mem_wb_dest_reg_idx[I] <= `SD `ZERO_REG;\
						mem_wb_take_branch[I]  <= `SD 0;\
						mem_wb_result[I]       <= `SD 0;\
						mem_wb_valid_inst[I]   <= `SD 0
`define MEM_WB_TAKE_WAY(I) 	mem_wb_NPC[I]          <= `SD ex_mem_packet[I].NPC;\
						mem_wb_IR[I]           <= `SD ex_mem_IR[I];\
						mem_wb_halt[I]         <= `SD ex_mem_packet[I].halt;\
						mem_wb_illegal[I]      <= `SD ex_mem_packet[I].illegal;\
						mem_wb_dest_reg_idx[I] <= `SD ex_mem_packet[I].dest_reg_idx;\
						mem_wb_take_branch[I]  <= `SD ex_mem_packet[I].take_branch;\
						mem_wb_result[I]       <= `SD mem_result_out[I];\
						mem_wb_valid_inst[I]   <= `SD ex_mem_packet[I].valid
	always_ff @(posedge clock) begin
		if (reset) begin
			`MEM_WB_SQUASH_WAY(0);
			`MEM_WB_SQUASH_WAY(1);
			`MEM_WB_SQUASH_WAY(2);
		end else begin
			`MEM_WB_TAKE_WAY(0);
			`MEM_WB_TAKE_WAY(1);
			`MEM_WB_TAKE_WAY(2);
		end
	end // always


//////////////////////////////////////////////////
//                                              //
//                  WB-Stage                    //
//                                              //
//////////////////////////////////////////////////
	wb_stage wb_stage [`WAYS-1:0] (
		// Inputs
		.clock(clock),
		.reset(reset),
		.mem_wb_NPC(mem_wb_NPC),
		.mem_wb_result(mem_wb_result),
		.mem_wb_dest_reg_idx(mem_wb_dest_reg_idx),
		.mem_wb_take_branch(mem_wb_take_branch),
		.mem_wb_valid_inst(mem_wb_valid_inst),
		
		// Outputs
		.reg_wr_data_out(wb_reg_wr_data_out),
		.reg_wr_idx_out(wb_reg_wr_idx_out),
		.reg_wr_en_out(wb_reg_wr_en_out)
	);

endmodule  // module verisimple
`endif // __PIPELINE_V__
