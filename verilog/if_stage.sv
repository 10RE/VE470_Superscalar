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
    input EX_MEM_PACKET ex_mem_packet[`WAYS-1:0],
    output [`WAYS-1:0] structural_haz
);
genvar i;
generate
	for (i=0;i<`WAYS;i++)
    	assign structural_haz[i] = ex_mem_packet[i].valid &(ex_mem_packet[i].wr_mem | ex_mem_packet[i].rd_mem);
endgenerate
endmodule

module simple_branch_predictor(
	input clock,
	input reset,
	input [`ROLLBACK_WIDTH-1:0] ex_mem_branch_way,
	input [`WAYS-1:0] ex_mem_is_branch,
	output prediction //0 for not take, 1 for take
);
	logic state, next_state; 
	assign prediction = (state==1);
	always_comb begin
		next_state=state;
		foreach(ex_mem_is_branch[i]) begin
			if(ex_mem_is_branch[i])
				case (next_state)
					1'b0:if(ex_mem_branch_way==i)next_state=1;
					1'b1:if(!ex_mem_branch_way==i)next_state=0;
				endcase
		end
	end
	always_ff @(posedge clock) begin
		if (reset) state <= `SD 0;
		else state <=`SD next_state;
	end  // always
endmodule

module if_stage(
	input         clock,                  // system clock
	input         reset,                  // system reset
	input         mem_wb_valid_inst,      // only go to next instruction when true
	                                      // makes pipeline behave as single-cycle
	input         ex_mem_take_branch,      // taken-branch signal
	input  [`XLEN-1:0] ex_mem_target_pc,        // target pc: use if take_branch is TRUE
	input         predict_take_branch,      // taken-branch signal
	input  [`XLEN-1:0] predict_target_pc,        // target pc: use if take_branch is TRUE
	input EX_MEM_PACKET ex_mem_packet[`WAYS-1:0],
	//***************************
	input  [63:0] Imem2proc_data[`WAYS-1:0] ,  // Data coming back from instruction-memory
	output logic [`XLEN-1:0] proc2Imem_addr[`WAYS-1:0],    // Address sent to Instruction memory
	
	output IF_ID_PACKET if_packet_out[`WAYS-1:0],         // Output data packet from IF going to ID, see sys_defs for signal information 
    
    input [`ROLLBACK_WIDTH-1:0] rollback,
    
    output logic [`ROLLBACK_WIDTH:0] invalid_way
);

	logic           PC_enable;
	
    wire [`WAYS-1:0]structural_haz;

	detect_structural_hazard ds_unit(
		.ex_mem_packet(ex_mem_packet),
		.structural_haz(structural_haz)
	);

	logic 			prediction;
	simple_branch_predictor sbp(
		.clock(clock),
		.reset(reset),
		.ex_mem_is_branch(ex_mem_is_branch),
		.ex_mem_branch_way(ex_mem_branch_way),
		.prediction(prediction)
	);
	//********************* set the fetch address to be sent to the I_memory

`define PREFETCH_SIZE 16
`define PREFETCH_WIDTH 8
    IF_ID_PACKET prefetch_queue[`PREFETCH_SIZE-1:0];
    IF_ID_PACKET next_prefetch_queue[`PREFETCH_SIZE-1:0];
    logic [`PREFETCH_WIDTH-1:0] tail, next_tail;
    logic [`XLEN-1:0] prefetch_PC, next_prefetch_PC;

	// assign if_packet_out=prefetch_queue;
	always_comb
		foreach(if_packet_out[i])begin
			if_packet_out[i].inst=next_prefetch_queue[i].inst;
			if_packet_out[i].PC=next_prefetch_queue[i].PC;
			if_packet_out[i].NPC=next_prefetch_queue[i].PC+4;
		end


    always_comb begin
		proc2Imem_addr='{`WAYS{`XLEN'b0}};
		next_prefetch_queue=prefetch_queue;
		next_prefetch_PC=prefetch_PC;
		next_tail=tail;
		foreach(proc2Imem_addr[i])
			if (!structural_haz[i]&&next_tail<`PREFETCH_SIZE-2) begin
				if(next_prefetch_PC[2]) begin
					proc2Imem_addr[i] = {next_prefetch_PC[`XLEN-1:3], 3'b0};
					next_prefetch_queue[next_tail].inst = Imem2proc_data[i][63:32];
					next_prefetch_queue[next_tail].PC = next_prefetch_PC;
					next_tail=next_tail+1;
					next_prefetch_PC=next_prefetch_PC+4;
				end else begin
					proc2Imem_addr[i] = next_prefetch_PC;
					next_prefetch_queue[next_tail].inst = Imem2proc_data[i][31:0];
					next_prefetch_queue[next_tail].PC = next_prefetch_PC;
					next_prefetch_queue[next_tail+1].inst = Imem2proc_data[i][63:32];
					next_prefetch_queue[next_tail+1].PC = next_prefetch_PC+4;
					next_tail=next_tail+2;
					next_prefetch_PC=next_prefetch_PC+8;
				end
			end
    end

   
	logic [`ROLLBACK_WIDTH-1:0] mem_count;
	assign mem_count = {2'b0,structural_haz[0]} + {2'b0,structural_haz[1]} + {2'b0,structural_haz[2]}+ {2'b0,structural_haz[3]};
	logic [`ROLLBACK_WIDTH-1:0] valid_way;
	assign invalid_way = `WAYS-valid_way;
	assign valid_way=`WAYS-rollback>next_tail?next_tail:`WAYS-rollback;
	
    assign if_packet_out[0].valid = valid_way>0;
    assign if_packet_out[1].valid = valid_way>1;
    assign if_packet_out[2].valid = valid_way>2;
    assign if_packet_out[3].valid = valid_way>3;
	
    always_ff @(posedge clock) begin
		if(reset) begin
			prefetch_PC <= `SD 0;       // initial PC value is 0
			tail <= `SD 0;
		end
		else if(PC_enable) begin
			if (ex_mem_take_branch) begin
				prefetch_PC <= `SD ex_mem_target_pc; // transition to next PC
				tail <= `SD 0;
			end else if (predict_take_branch) begin
				prefetch_PC <= `SD predict_target_pc; // transition to next PC
				tail <= `SD 0;
			end else begin 
				prefetch_PC <= `SD next_prefetch_PC; // transition to next PC
				tail <= `SD next_tail-valid_way;
			end
`define CASEI(I) I:prefetch_queue[`PREFETCH_SIZE-1-I:0] <= next_prefetch_queue[`PREFETCH_SIZE-1:I]
			case(valid_way)
				0:prefetch_queue <= next_prefetch_queue;
				`CASEI(1);
				`CASEI(2);
				`CASEI(3);
				`CASEI(4);
			endcase
		end
	end  // always
	
	// this mux is because the Imem gives us 64 bits not 32 bits
	//assign if_packet_out.inst = PC_reg[2] ? Imem2proc_data[63:32] : Imem2proc_data[31:0];
	
	//********????
	assign PC_enable = if_packet_out[0].valid | if_packet_out[1].valid | if_packet_out[2].valid | if_packet_out[3].valid | ex_mem_take_branch;
	
endmodule  // module if_stage
