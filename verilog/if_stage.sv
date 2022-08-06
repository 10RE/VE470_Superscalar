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
    // IF_ID_PACKET prefetch_queue[16];
    // logic [3:0] tail, next_tail, increment;
    // logic [`XLEN-1:0] prefetch_PC;
    // always_comb begin
    //     next_tail=tail;
    //     increment=0;
    //     if (!structural_haz[0]&&next_tail<14) begin
    //         proc2Imem_addr[0] = {prefetch_PC[`XLEN-1:3]+increment, 3'b0};
    //         prefetch_queue[next_tail] = Imem2proc_data[0][31:0];
    //         prefetch_queue[next_tail+1] = Imem2proc_data[0][63:32];
    //         next_tail=next_tail+2;
    //         increment=increment+8;
    //     end
    //     if (!structural_haz[1]&&next_tail<14) begin
    //         proc2Imem_addr[1] = {prefetch_PC[`XLEN-1:3]+increment, 3'b0};
    //         prefetch_queue[next_tail] = Imem2proc_data[1][31:0];
    //         prefetch_queue[next_tail+1] = Imem2proc_data[1][63:32];
    //         next_tail=next_tail+2;
    //         increment=increment+8;
    //     end
    //     if (!structural_haz[2]&&next_tail<14) begin
    //         proc2Imem_addr[2] = {prefetch_PC[`XLEN-1:3]+increment, 3'b0};
    //         prefetch_queue[next_tail] = Imem2proc_data[2][31:0];
    //         prefetch_queue[next_tail+1] = Imem2proc_data[2][63:32];
    //         next_tail=next_tail+2;
    //         increment=increment+8;
    //     end
    // end
   
	logic [1:0] mem_count;
	assign mem_count = {1'b0,structural_haz[0]} + {1'b0,structural_haz[1]} + {1'b0,structural_haz[2]};
	assign invalid_way = mem_count > rollback? mem_count: rollback;
	
    assign if_packet_out[0].valid = invalid_way<3;
    assign if_packet_out[1].valid = invalid_way<2;
    assign if_packet_out[2].valid = invalid_way<1;
    //assign if_valid = if_packet_out[0].valid;

    

	//reorder
	always_comb begin
        case(structural_haz)
            3'b010: begin
                proc2Imem_addr[0] = {PC_reg[`XLEN-1:3], 3'b0};
                proc2Imem_addr[1] = {`XLEN'b0}; //invalid 
                proc2Imem_addr[2] = {PC_plus_4[`XLEN-1:3], 3'b0};
                //
                if_packet_out[0].inst = PC_reg[2] ? Imem2proc_data[0][63:32] : Imem2proc_data[0][31:0];
                if_packet_out[1].inst = PC_plus_4[2] ? Imem2proc_data[2][63:32] : Imem2proc_data[2][31:0];
                if_packet_out[2].inst = `NOP;
                if_packet_out[0].PC = PC_reg;
                if_packet_out[1].PC = PC_plus_4;
                if_packet_out[2].PC = 0;
            end
            3'b001: begin
                proc2Imem_addr[0] = {`XLEN'b0}; //invalid 
                proc2Imem_addr[1] = {PC_reg[`XLEN-1:3], 3'b0};
                proc2Imem_addr[2] = {PC_plus_4[`XLEN-1:3], 3'b0};
                //
                if_packet_out[0].inst = PC_reg[2] ? Imem2proc_data[1][63:32] : Imem2proc_data[1][31:0];
                if_packet_out[1].inst = PC_plus_4[2] ? Imem2proc_data[2][63:32] : Imem2proc_data[2][31:0];
                if_packet_out[2].inst = `NOP;
                if_packet_out[0].PC = PC_reg;
                if_packet_out[1].PC = PC_plus_4;
                if_packet_out[2].PC = 0;
            end
            3'b011: begin
                proc2Imem_addr[0] = {`XLEN'b0}; //invalid 
                proc2Imem_addr[1] = {`XLEN'b0}; //invalid 
                proc2Imem_addr[2] = {PC_reg[`XLEN-1:3], 3'b0};
                //
                if_packet_out[0].inst = PC_reg[2] ? Imem2proc_data[2][63:32] : Imem2proc_data[2][31:0];
                if_packet_out[1].inst = `NOP;
                if_packet_out[2].inst = `NOP;
                if_packet_out[0].PC = PC_reg;
                if_packet_out[1].PC = 0;
                if_packet_out[2].PC = 0;
            end
            3'b101: begin
                proc2Imem_addr[0] = {`XLEN'b0}; //invalid 
                proc2Imem_addr[1] = {PC_reg[`XLEN-1:3], 3'b0};
                proc2Imem_addr[2] = {`XLEN'b0}; //invalid 
                //
                if_packet_out[0].inst = PC_reg[2] ? Imem2proc_data[1][63:32] : Imem2proc_data[1][31:0];
                if_packet_out[1].inst = `NOP;
                if_packet_out[2].inst = `NOP;
                if_packet_out[0].PC = PC_reg;
                if_packet_out[1].PC = 0;
                if_packet_out[2].PC = 0;
            end
            default: begin
                proc2Imem_addr[0] = {PC_reg[`XLEN-1:3], 3'b0};
                proc2Imem_addr[1] = {PC_plus_4[`XLEN-1:3], 3'b0};
                proc2Imem_addr[2] = {PC_plus_8[`XLEN-1:3], 3'b0};
                //
                if_packet_out[0].inst = structural_haz[0]? `NOP: PC_reg[2] ? Imem2proc_data[0][63:32] : Imem2proc_data[0][31:0];
                if_packet_out[1].inst = structural_haz[1]? `NOP: PC_plus_4[2] ? Imem2proc_data[1][63:32] : Imem2proc_data[1][31:0];
                if_packet_out[2].inst = structural_haz[2]? `NOP: PC_plus_8[2] ? Imem2proc_data[2][63:32] : Imem2proc_data[2][31:0];
                if_packet_out[0].PC = structural_haz[0]? 0: PC_reg;
                if_packet_out[1].PC = structural_haz[1]? 0: PC_plus_4;
                if_packet_out[2].PC = structural_haz[2]? 0: PC_plus_8;
            end
        endcase
    end
    always_comb begin
        //next PC
        if (ex_mem_take_branch) next_PC=ex_mem_target_pc;
        else begin
            case(invalid_way)
                1:       next_PC = PC_plus_8;
                2:       next_PC = PC_plus_4;
                3:       next_PC = PC_reg;
                default: next_PC = PC_plus_12;
            endcase
        end
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
	assign PC_enable = if_packet_out[0].valid | if_packet_out[1].valid | if_packet_out[2].valid | ex_mem_take_branch;
	
	// Pass PC+4 down pipeline w/instruction
	//*******???????
	//assign if_packet_out.NPC = PC_plus_4;
	//assign if_packet_out.PC  = PC_reg;
	assign if_packet_out[0].NPC = if_packet_out[0].PC + 4;
	assign if_packet_out[1].NPC = if_packet_out[1].PC + 4;
	assign if_packet_out[2].NPC = if_packet_out[2].PC + 4;
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
