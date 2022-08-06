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
    input EX_MEM_PACKET ex_mem_packet[2:0],
    output [2:0] structural_haz
);
    assign structural_haz[0] = ex_mem_packet[0].valid &(ex_mem_packet[0].wr_mem | ex_mem_packet[0].rd_mem);
    assign structural_haz[1] = ex_mem_packet[1].valid &(ex_mem_packet[1].wr_mem | ex_mem_packet[1].rd_mem);
    assign structural_haz[2] = ex_mem_packet[2].valid &(ex_mem_packet[2].wr_mem | ex_mem_packet[2].rd_mem);
endmodule

module if_stage(
	input         clock,                  // system clock
	input         reset,                  // system reset
	input         mem_wb_valid_inst,      // only go to next instruction when true
	                                      // makes pipeline behave as single-cycle
	input         ex_mem_take_branch,      // taken-branch signal
	input  [`XLEN-1:0] ex_mem_target_pc,        // target pc: use if take_branch is TRUE
	//***************************
	input EX_MEM_PACKET ex_mem_packet[2:0],
	output logic [`XLEN-1:0] proc2Imem_addr[2:0],    // Address sent to Instruction memory
	input  [63:0] Imem2proc_data[2:0]   // Data coming back from instruction-memory
	
	,output IF_ID_PACKET if_packet_out[2:0]         // Output data packet from IF going to ID, see sys_defs for signal information 
    
    ,input [1:0] rollback
    
    ,output logic [1:0] invalid_way
);

	logic    [`XLEN-1:0] PC_reg;             // PC we are currently fetching
	
	logic    [`XLEN-1:0] PC_plus_4, PC_plus_8, PC_plus_12;
	logic    [`XLEN-1:0] next_PC;
	logic           PC_enable;
	
    wire [2:0] structural_haz;

	detect_structural_hazard ds_unit(
		.ex_mem_packet(ex_mem_packet),
		.structural_haz(structural_haz)
	);
	//********************* set the fetch address to be sent to the I_memory
    IF_ID_PACKET prefetch_queue[15:0];
    logic [3:0] tail, next_tail;
    logic [`XLEN-1:0] prefetch_PC, next_prefetch_PC;

	// assign if_packet_out=prefetch_queue;
	always_comb
		foreach(if_packet_out[i])begin
			if_packet_out[i].inst=prefetch_queue[i].inst;
			if_packet_out[i].PC=prefetch_queue[i].PC;
			if_packet_out[i].NPC=prefetch_queue[i].PC+4;
		end


    always_comb begin
		proc2Imem_addr='{3{`XLEN'b0}};
		next_prefetch_PC=prefetch_PC;
		next_tail=tail;
		foreach(proc2Imem_addr[i])
			if (!structural_haz[i]&&next_tail<14) begin
				if(next_prefetch_PC[2]) begin
					proc2Imem_addr[i] = {next_prefetch_PC[`XLEN-1:3], 3'b0};
					prefetch_queue[next_tail].inst = Imem2proc_data[i][63:32];
					prefetch_queue[next_tail].PC = next_prefetch_PC;
					next_tail=next_tail+1;
					next_prefetch_PC=next_prefetch_PC+4;
				end else begin
					proc2Imem_addr[i] = next_prefetch_PC;
					prefetch_queue[next_tail].inst = Imem2proc_data[i][31:0];
					prefetch_queue[next_tail].PC = next_prefetch_PC;
					prefetch_queue[next_tail+1].inst = Imem2proc_data[i][63:32];
					prefetch_queue[next_tail+1].PC = next_prefetch_PC+4;
					next_tail=next_tail+2;
					next_prefetch_PC=next_prefetch_PC+8;
				end
			end
    end

   
	logic [1:0] mem_count;
	assign mem_count = {1'b0,structural_haz[0]} + {1'b0,structural_haz[1]} + {1'b0,structural_haz[2]};
	logic [1:0] valid_way;
	assign invalid_way = 3-valid_way;
	assign valid_way=3-rollback>next_tail?next_tail:3-rollback;
	
    assign if_packet_out[0].valid = valid_way>0;
    assign if_packet_out[1].valid = valid_way>1;
    assign if_packet_out[2].valid = valid_way>2;
	
    always_ff @(posedge clock) begin
		if(reset) begin
			prefetch_PC <= `SD 0;       // initial PC value is 0
			tail <= `SD 0;
		end
		else if(PC_enable) begin
			if (ex_mem_take_branch) begin
				prefetch_PC <= `SD ex_mem_target_pc; // transition to next PC
				tail <= `SD 0;
			end else begin 
				prefetch_PC <= `SD next_prefetch_PC; // transition to next PC
				tail <= `SD next_tail-valid_way;
			end
			case(valid_way)
				0:prefetch_queue <= prefetch_queue;
				1:prefetch_queue <= prefetch_queue[15:1];
				2:prefetch_queue <= prefetch_queue[15:2];
				3:prefetch_queue <= prefetch_queue[15:3];
			endcase
		end
	end  // always
	
	// this mux is because the Imem gives us 64 bits not 32 bits
	//assign if_packet_out.inst = PC_reg[2] ? Imem2proc_data[63:32] : Imem2proc_data[31:0];
	
	//********????
	assign PC_enable = if_packet_out[0].valid | if_packet_out[1].valid | if_packet_out[2].valid | ex_mem_take_branch;
	
endmodule  // module if_stage
