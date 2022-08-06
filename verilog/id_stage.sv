/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  id_stage.v                                          //
//                                                                     //
//  Description :  instruction decode (ID) stage of the pipeline;      // 
//                 decode the instruction fetch register operands, and // 
//                 compute immediate operand (if applicable)           // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////


`timescale 1ns/100ps
`define USE_DETECTION


  // Decode an instruction: given instruction bits IR produce the
  // appropriate datapath control signals.
  //
  // This is a *combinational* module (basically a PLA).
  //

module decoder(

	//input [31:0] inst,
	//input valid_inst_in,  // ignore inst when low, outputs will
	                      // reflect noop (except valid_inst)
	//see sys_defs.svh for definition
	input IF_ID_PACKET if_packet,
	
	output ALU_OPA_SELECT opa_select,
	output ALU_OPB_SELECT opb_select,
	output DEST_REG_SEL   dest_reg, // mux selects
	output ALU_FUNC       alu_func,
	output logic rd_mem, wr_mem, cond_branch, uncond_branch,
	output logic csr_op,    // used for CSR operations, we only used this as 
	                        //a cheap way to get the return code out
	output logic halt,      // non-zero on a halt
	output logic illegal,    // non-zero on an illegal instruction
	output logic valid_inst  // for counting valid instructions executed
	                        // and for making the fetch stage die on halts/
	                        // keeping track of when to allow the next
	                        // instruction out of fetch
	                        // 0 for HALT and illegal instructions (die on halt)

);

	INST inst;
	logic valid_inst_in;
	
	assign inst          = if_packet.inst;
	assign valid_inst_in = if_packet.valid;
	assign valid_inst    = valid_inst_in & ~illegal;
	
	always_comb begin
		// default control values:
		// - valid instructions must override these defaults as necessary.
		//	 opa_select, opb_select, and alu_func should be set explicitly.
		// - invalid instructions should clear valid_inst.
		// - These defaults are equivalent to a noop
		// * see sys_defs.vh for the constants used here
		opa_select = OPA_IS_RS1;
		opb_select = OPB_IS_RS2;
		alu_func = ALU_ADD;
		dest_reg = DEST_NONE;
		csr_op = `FALSE;
		rd_mem = `FALSE;
		wr_mem = `FALSE;
		cond_branch = `FALSE;
		uncond_branch = `FALSE;
		halt = `FALSE;
		illegal = `FALSE;
		if(valid_inst_in) begin
			casez (inst) 
				`RV32_LUI: begin
					dest_reg   = DEST_RD;
					opa_select = OPA_IS_ZERO;
					opb_select = OPB_IS_U_IMM;
				end
				`RV32_AUIPC: begin
					dest_reg   = DEST_RD;
					opa_select = OPA_IS_PC;
					opb_select = OPB_IS_U_IMM;
				end
				`RV32_JAL: begin
					dest_reg      = DEST_RD;
					opa_select    = OPA_IS_PC;
					opb_select    = OPB_IS_J_IMM;
					uncond_branch = `TRUE;
				end
				`RV32_JALR: begin
					dest_reg      = DEST_RD;
					opa_select    = OPA_IS_RS1;
					opb_select    = OPB_IS_I_IMM;
					uncond_branch = `TRUE;
				end
				`RV32_BEQ, `RV32_BNE, `RV32_BLT, `RV32_BGE,
				`RV32_BLTU, `RV32_BGEU: begin
					opa_select  = OPA_IS_PC;
					opb_select  = OPB_IS_B_IMM;
					cond_branch = `TRUE;
				end
				`RV32_LB, `RV32_LH, `RV32_LW,
				`RV32_LBU, `RV32_LHU: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
					rd_mem     = `TRUE;
				end
				`RV32_SB, `RV32_SH, `RV32_SW: begin
					opb_select = OPB_IS_S_IMM;
					wr_mem     = `TRUE;
				end
				`RV32_ADDI: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
				end
				`RV32_SLTI: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
					alu_func   = ALU_SLT;
				end
				`RV32_SLTIU: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
					alu_func   = ALU_SLTU;
				end
				`RV32_ANDI: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
					alu_func   = ALU_AND;
				end
				`RV32_ORI: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
					alu_func   = ALU_OR;
				end
				`RV32_XORI: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
					alu_func   = ALU_XOR;
				end
				`RV32_SLLI: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
					alu_func   = ALU_SLL;
				end
				`RV32_SRLI: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
					alu_func   = ALU_SRL;
				end
				`RV32_SRAI: begin
					dest_reg   = DEST_RD;
					opb_select = OPB_IS_I_IMM;
					alu_func   = ALU_SRA;
				end
				`RV32_ADD: begin
					dest_reg   = DEST_RD;
				end
				`RV32_SUB: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_SUB;
				end
				`RV32_SLT: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_SLT;
				end
				`RV32_SLTU: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_SLTU;
				end
				`RV32_AND: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_AND;
				end
				`RV32_OR: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_OR;
				end
				`RV32_XOR: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_XOR;
				end
				`RV32_SLL: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_SLL;
				end
				`RV32_SRL: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_SRL;
				end
				`RV32_SRA: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_SRA;
				end
				`RV32_MUL: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_MUL;
				end
				`RV32_MULH: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_MULH;
				end
				`RV32_MULHSU: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_MULHSU;
				end
				`RV32_MULHU: begin
					dest_reg   = DEST_RD;
					alu_func   = ALU_MULHU;
				end
				`RV32_CSRRW, `RV32_CSRRS, `RV32_CSRRC: begin
					csr_op = `TRUE;
				end
				`WFI: begin
					halt = `TRUE;
				end
				default: illegal = `TRUE;

		endcase // casez (inst)
		end // if(valid_inst_in)
	end // always
endmodule // decoder


module id_stage(         
	input         clock,              // system clock
	input         reset,              // system reset
	input         wb_reg_wr_en_out[`WAYS-1:0],    // Reg write enable from WB Stage
	input  [4:0] wb_reg_wr_idx_out[`WAYS-1:0],  // Reg write index from WB Stage
	input  [`XLEN-1:0] wb_reg_wr_data_out[`WAYS-1:0],  // Reg write data from WB Stage

	input  IF_ID_PACKET if_id_packet_in[`WAYS-1:0],
	
	input ID_EX_PACKET id_ex_packet_in[`WAYS-1:0],
	
	input EX_MEM_PACKET ex_mem_packet_in[`WAYS-1:0],
	
	input ex_mem_take_branch,
	
	output [`ROLLBACK_WIDTH-1:0] rollback,
	
	output ID_EX_PACKET id_packet_out[`WAYS-1:0]
	
	`ifdef DEBUG
	,output [`XLEN-1:0] sorted_packet_0_PC
	`endif
);
    
    logic [`ROLLBACK_WIDTH-1:0] pre_rollback;
    
    
    IF_ID_PACKET hold_reg[`WAYS-1:0];
    
    IF_ID_PACKET sorted_packet[`WAYS-1:0];

	ID_EX_PACKET id_packet_internal[`WAYS-1:0];
    

	always_comb begin
		case (pre_rollback)
			0:{sorted_packet[0],sorted_packet[1],sorted_packet[2]}={if_id_packet_in[0],	if_id_packet_in[1],	if_id_packet_in[2]};
			1:{sorted_packet[0],sorted_packet[1],sorted_packet[2]}={hold_reg[2],		if_id_packet_in[0],	if_id_packet_in[1]};
			2:{sorted_packet[0],sorted_packet[1],sorted_packet[2]}={hold_reg[1],		hold_reg[2],			if_id_packet_in[0]};
			3:{sorted_packet[0],sorted_packet[1],sorted_packet[2]}={hold_reg[0],		hold_reg[1],			hold_reg[2]};
		endcase
		
	end
    
    assign id_packet_internal[0].inst = sorted_packet[0].inst;
    assign id_packet_internal[0].NPC  = sorted_packet[0].NPC;
    assign id_packet_internal[0].PC   = sorted_packet[0].PC;
    assign id_packet_internal[1].inst = sorted_packet[1].inst;
    assign id_packet_internal[1].NPC  = sorted_packet[1].NPC;
    assign id_packet_internal[1].PC   = sorted_packet[1].PC;
    assign id_packet_internal[2].inst = sorted_packet[2].inst;
    assign id_packet_internal[2].NPC  = sorted_packet[2].NPC;
    assign id_packet_internal[2].PC   = sorted_packet[2].PC;
    
	DEST_REG_SEL dest_reg_select[`WAYS-1:0]; 

	wire [4:0] rda_idx[`WAYS-1:0], rdb_idx[`WAYS-1:0];
	wire [`XLEN-1:0] rda_out[`WAYS-1:0], rdb_out[`WAYS-1:0];
	genvar i;
    generate
		for (i=0;i<`WAYS;i++) begin
			assign rda_idx[i]=sorted_packet[i].inst.r.rs1;
			assign id_packet_internal[i].rs1_value=rda_out[i];
			assign rdb_idx[i]=sorted_packet[i].inst.r.rs2;
			assign id_packet_internal[i].rs2_value=rdb_out[i];
		end
	endgenerate
	
	// Instantiate the register file used by this pipeline
	superregfile regf_0 (
		.rda_idx(rda_idx),
		.rda_out(rda_out), 

		.rdb_idx(rdb_idx),
		.rdb_out(rdb_out),

		.wr_clk(clock),
		.wr_en(wb_reg_wr_en_out),
		.wr_idx(wb_reg_wr_idx_out),
		.wr_data(wb_reg_wr_data_out)
	);

	// instantiate the instruction decoder
	
	generate
		for (i=0;i<`WAYS;i++)
			decoder decoder (
				.if_packet(sorted_packet[i]),	 
				// Outputs
				.opa_select(id_packet_internal[i].opa_select),
				.opb_select(id_packet_internal[i].opb_select),
				.alu_func(id_packet_internal[i].alu_func),
				.dest_reg(dest_reg_select[i]),
				.rd_mem(id_packet_internal[i].rd_mem),
				.wr_mem(id_packet_internal[i].wr_mem),
				.cond_branch(id_packet_internal[i].cond_branch),
				.uncond_branch(id_packet_internal[i].uncond_branch),
				.csr_op(id_packet_internal[i].csr_op),
				.halt(id_packet_internal[i].halt),
				.illegal(id_packet_internal[i].illegal),
				.valid_inst(id_packet_internal[i].valid)
			);
	endgenerate

	// mux to generate dest_reg_idx based on
	// the dest_reg_select output from decoder
	always_comb begin
		foreach(dest_reg_select[i])
			case (dest_reg_select[i])
				DEST_RD:    id_packet_internal[i].dest_reg_idx = sorted_packet[i].inst.r.rd;
				DEST_NONE:  id_packet_internal[i].dest_reg_idx = `ZERO_REG;
				default:    id_packet_internal[i].dest_reg_idx = `ZERO_REG; 
			endcase
	end
	
	
	
`ifdef USE_DETECTION
	detection_unit detection_unit_0(
        .id_packet(id_packet_internal),
        .ex_packet(id_ex_packet_in),
        .mem_packet(ex_mem_packet_in),
        .id_packet_out(id_packet_out),
        .rollback(rollback)
    );
`else
	assign id_packet_out[0] = id_packet_internal[0];
	assign id_packet_out[1] = id_packet_internal[1];
	assign id_packet_out[2] = id_packet_internal[2];
`endif

	
	always_ff @(posedge clock) begin
	   if (ex_mem_take_branch) 
	       pre_rollback <= `SD 0;
	   else
	       pre_rollback <= `SD rollback;
	       
	   hold_reg[0].valid <= `SD id_packet_out[0].valid;
	   hold_reg[0].inst  <= `SD id_packet_out[0].inst;
	   hold_reg[0].NPC   <= `SD id_packet_out[0].NPC;
	   hold_reg[0].PC    <= `SD id_packet_out[0].PC;
	   
	   hold_reg[1].valid <= `SD id_packet_out[1].valid;
	   hold_reg[1].inst  <= `SD id_packet_out[1].inst;
	   hold_reg[1].NPC   <= `SD id_packet_out[1].NPC;
	   hold_reg[1].PC    <= `SD id_packet_out[1].PC;
	   
	   hold_reg[2].valid <= `SD id_packet_out[2].valid;
	   hold_reg[2].inst  <= `SD id_packet_out[2].inst;
	   hold_reg[2].NPC   <= `SD id_packet_out[2].NPC;
	   hold_reg[2].PC    <= `SD id_packet_out[2].PC;
	end
	
	
   
endmodule // module id_stage
