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
/*
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
*/

module proj_id_stage(         
	input         clock,              // system clock
	input         reset,              // system reset
	input         wb_reg_wr_en_out_0,    // Reg write enable from WB Stage
	input  [4:0] wb_reg_wr_idx_out_0,  // Reg write index from WB Stage
	input  [`XLEN-1:0] wb_reg_wr_data_out_0,  // Reg write data from WB Stage
	input         wb_reg_wr_en_out_1,    // Reg write enable from WB Stage
	input  [4:0] wb_reg_wr_idx_out_1,  // Reg write index from WB Stage
	input  [`XLEN-1:0] wb_reg_wr_data_out_1,  // Reg write data from WB Stage
	input         wb_reg_wr_en_out_2,    // Reg write enable from WB Stage
	input  [4:0] wb_reg_wr_idx_out_2,  // Reg write index from WB Stage
	input  [`XLEN-1:0] wb_reg_wr_data_out_2,  // Reg write data from WB Stage
	
	input  IF_ID_PACKET if_id_packet_in_0,
	input  IF_ID_PACKET if_id_packet_in_1,
	input  IF_ID_PACKET if_id_packet_in_2,
	
	input ID_EX_PACKET id_ex_packet_in_0, // forwarding data
	input ID_EX_PACKET id_ex_packet_in_1,
	input ID_EX_PACKET id_ex_packet_in_2,
	
	input EX_MEM_PACKET ex_mem_packet_in_0,
	input EX_MEM_PACKET ex_mem_packet_in_1,
	input EX_MEM_PACKET ex_mem_packet_in_2,
	
	output [1:0] rollback,
	
	output ID_EX_PACKET id_packet_out_0,
	output ID_EX_PACKET id_packet_out_1,
	output ID_EX_PACKET id_packet_out_2
);
    
    logic [1:0] pre_rollback;

    IF_ID_PACKET hold_reg_0;
    IF_ID_PACKET hold_reg_1;
    IF_ID_PACKET hold_reg_2;
    
    IF_ID_PACKET packet_select_0;
    IF_ID_PACKET packet_select_1;
    IF_ID_PACKET packet_select_2;
    
    IF_ID_PACKET sorted_packet_0;
    IF_ID_PACKET sorted_packet_1;
    IF_ID_PACKET sorted_packet_2;

	ID_EX_PACKET id_packet_internal_0;
	ID_EX_PACKET id_packet_internal_1;
	ID_EX_PACKET id_packet_internal_2;
    
    assign packet_select_0 = pre_rollback == 3 ? hold_reg_0 : if_id_packet_in_0;
    assign packet_select_1 = pre_rollback >= 2 ? hold_reg_1 : if_id_packet_in_1;
    assign packet_select_2 = pre_rollback >= 1 ? hold_reg_2 : if_id_packet_in_2;

    id_sorter sorter (
        .packet_in_0(packet_select_0),
        .packet_in_1(packet_select_1),
        .packet_in_2(packet_select_2),
        
        .packet_out_0(sorted_packet_0),
        .packet_out_1(sorted_packet_1),
        .packet_out_2(sorted_packet_2)
    );
    
    assign id_packet_internal_0.inst = sorted_packet_0.inst;
    assign id_packet_internal_0.NPC  = sorted_packet_0.NPC;
    assign id_packet_internal_0.PC   = sorted_packet_0.PC;
    assign id_packet_internal_1.inst = sorted_packet_1.inst;
    assign id_packet_internal_1.NPC  = sorted_packet_1.NPC;
    assign id_packet_internal_1.PC   = sorted_packet_1.PC;
    assign id_packet_internal_2.inst = sorted_packet_2.inst;
    assign id_packet_internal_2.NPC  = sorted_packet_2.NPC;
    assign id_packet_internal_2.PC   = sorted_packet_2.PC;
    
    
    
    
    
	DEST_REG_SEL dest_reg_select_0; 
	DEST_REG_SEL dest_reg_select_1; 
	DEST_REG_SEL dest_reg_select_2; 
	
	ALU_OPA_SELECT temp_opa_select_0;
	ALU_OPB_SELECT temp_opb_select_0;
	ALU_OPA_SELECT temp_opa_select_1;
	ALU_OPB_SELECT temp_opb_select_1;
	ALU_OPA_SELECT temp_opa_select_2;
	ALU_OPB_SELECT temp_opb_select_2;

	// Instantiate the register file used by this pipeline
	superregfile regf_0 (
		.rda_idx_0(sorted_packet_0.inst.r.rs1),
		.rda_out_0(id_packet_internal_0.rs1_value), 

		.rdb_idx_0(sorted_packet_0.inst.r.rs2),
		.rdb_out_0(id_packet_internal_0.rs2_value),
		
		.rda_idx_1(sorted_packet_1.inst.r.rs1),
		.rda_out_1(id_packet_internal_1.rs1_value), 

		.rdb_idx_1(sorted_packet_1.inst.r.rs2),
		.rdb_out_1(id_packet_internal_1.rs2_value),
		
		.rda_idx_2(sorted_packet_2.inst.r.rs1),
		.rda_out_2(id_packet_internal_2.rs1_value), 

		.rdb_idx_2(sorted_packet_2.inst.r.rs2),
		.rdb_out_2(id_packet_internal_2.rs2_value),

		.wr_clk(clock),
		.wr_en_0(wb_reg_wr_en_out_0),
		.wr_idx_0(wb_reg_wr_idx_out_0),
		.wr_data_0(wb_reg_wr_data_out_0),
		
		.wr_en_1(wb_reg_wr_en_out_1),
		.wr_idx_1(wb_reg_wr_idx_out_1),
		.wr_data_1(wb_reg_wr_data_out_1),
		
		.wr_en_2(wb_reg_wr_en_out_2),
		.wr_idx_2(wb_reg_wr_idx_out_2),
		.wr_data_2(wb_reg_wr_data_out_2)
	);

	// instantiate the instruction decoder
	decoder decoder_0 (
		.if_packet(sorted_packet_0),	 
		// Outputs
		.opa_select(temp_opa_select_0),
		.opb_select(temp_opb_select_0),
		.alu_func(id_packet_internal_0.alu_func),
		.dest_reg(dest_reg_select_0),
		.rd_mem(id_packet_internal_0.rd_mem),
		.wr_mem(id_packet_internal_0.wr_mem),
		.cond_branch(id_packet_internal_0.cond_branch),
		.uncond_branch(id_packet_internal_0.uncond_branch),
		.csr_op(id_packet_internal_0.csr_op),
		.halt(id_packet_internal_0.halt),
		.illegal(id_packet_internal_0.illegal),
		.valid_inst(id_packet_internal_0.valid)
	);
	
	decoder decoder_1 (
		.if_packet(sorted_packet_1),	 
		// Outputs
		.opa_select(temp_opa_select_1),
		.opb_select(temp_opb_select_1),
		.alu_func(id_packet_internal_1.alu_func),
		.dest_reg(dest_reg_select_1),
		.rd_mem(id_packet_internal_1.rd_mem),
		.wr_mem(id_packet_internal_1.wr_mem),
		.cond_branch(id_packet_internal_1.cond_branch),
		.uncond_branch(id_packet_internal_1.uncond_branch),
		.csr_op(id_packet_internal_1.csr_op),
		.halt(id_packet_internal_1.halt),
		.illegal(id_packet_internal_1.illegal),
		.valid_inst(id_packet_internal_1.valid)
	);
	
	decoder decoder_2 (
		.if_packet(sorted_packet_2),	 
		// Outputs
		.opa_select(temp_opa_select_2),
		.opb_select(temp_opb_select_2),
		.alu_func(id_packet_internal_2.alu_func),
		.dest_reg(dest_reg_select_2),
		.rd_mem(id_packet_internal_2.rd_mem),
		.wr_mem(id_packet_internal_2.wr_mem),
		.cond_branch(id_packet_internal_2.cond_branch),
		.uncond_branch(id_packet_internal_2.uncond_branch),
		.csr_op(id_packet_internal_2.csr_op),
		.halt(id_packet_internal_2.halt),
		.illegal(id_packet_internal_2.illegal),
		.valid_inst(id_packet_internal_2.valid)
	);

	// mux to generate dest_reg_idx based on
	// the dest_reg_select output from decoder
	always_comb begin
		case (dest_reg_select_0)
			DEST_RD:    id_packet_internal_0.dest_reg_idx = sorted_packet_0.inst.r.rd;
			DEST_NONE:  id_packet_internal_0.dest_reg_idx = `ZERO_REG;
			default:    id_packet_internal_0.dest_reg_idx = `ZERO_REG; 
		endcase
		
		case (dest_reg_select_1)
			DEST_RD:    id_packet_internal_1.dest_reg_idx = sorted_packet_1.inst.r.rd;
			DEST_NONE:  id_packet_internal_1.dest_reg_idx = `ZERO_REG;
			default:    id_packet_internal_1.dest_reg_idx = `ZERO_REG; 
		endcase
		
		case (dest_reg_select_2)
			DEST_RD:    id_packet_internal_2.dest_reg_idx = sorted_packet_2.inst.r.rd;
			DEST_NONE:  id_packet_internal_2.dest_reg_idx = `ZERO_REG;
			default:    id_packet_internal_2.dest_reg_idx = `ZERO_REG; 
		endcase
	end
	
	/*
	// hazzard detection and control unit
	wire ld_detection;
	
	assign ld_detection = id_ex_packet_in.rd_mem &&  id_packet_out.valid && id_ex_packet_in.valid;
	
	always_comb begin
	   id_packet_out.stall = 1'b0;
	   id_packet_out.opa_select = temp_opa_select;
	   id_packet_out.opb_select = temp_opb_select;
	   id_packet_out.brcond_opa_select = BRCOND_OPA_IS_RS1;
	   id_packet_out.brcond_opb_select = BRCOND_OPB_IS_RS2;
	   id_packet_out.store_opb_select  = STORE_OPB_IS_RS2;
	   
	   if (id_packet_out.opa_select == OPA_IS_RS1 && id_packet_out.inst.r.rs1 != `ZERO_REG) begin
	       if (id_packet_out.inst.r.rs1 == id_ex_packet_in.dest_reg_idx && id_ex_packet_in.valid) begin
	           id_packet_out.opa_select = OPA_IS_FROM_EX_MEM;
	           id_packet_out.stall = ld_detection;
	       end
	       else if (id_packet_out.inst.r.rs1 == ex_mem_packet_in.dest_reg_idx && ex_mem_packet_in.valid) begin
	           id_packet_out.opa_select = OPA_IS_FROM_MEM_WB;
	       end
	   end
	   
	   if (id_packet_out.opb_select == OPB_IS_RS2 && id_packet_out.inst.r.rs2 != `ZERO_REG) begin
	       if (id_packet_out.inst.r.rs2 == id_ex_packet_in.dest_reg_idx && id_ex_packet_in.valid) begin
	           id_packet_out.opb_select = OPB_IS_FROM_EX_MEM;
	           id_packet_out.stall = ld_detection;
	       end
	       else if (id_packet_out.inst.r.rs2 == ex_mem_packet_in.dest_reg_idx && ex_mem_packet_in.valid) begin
	           id_packet_out.opb_select = OPB_IS_FROM_MEM_WB;
	       end
	   end
	   
	   
	   if (id_packet_out.cond_branch && id_packet_out.inst.r.rs1 != `ZERO_REG) begin
	       if (id_packet_out.inst.r.rs1 == id_ex_packet_in.dest_reg_idx && id_ex_packet_in.valid) begin
	           id_packet_out.brcond_opa_select = BRCOND_OPA_IS_FROM_EX_MEM;
	           id_packet_out.stall = ld_detection;
	       end
	       else if (id_packet_out.inst.r.rs1 == ex_mem_packet_in.dest_reg_idx && ex_mem_packet_in.valid) begin
	           id_packet_out.brcond_opa_select = BRCOND_OPA_IS_FROM_MEM_WB;
	       end
	   end
	   
	   if (id_packet_out.cond_branch && id_packet_out.inst.r.rs2 != `ZERO_REG) begin
	       if (id_packet_out.inst.r.rs2 == id_ex_packet_in.dest_reg_idx && id_ex_packet_in.valid) begin
	           id_packet_out.brcond_opb_select = BRCOND_OPB_IS_FROM_EX_MEM;
	           id_packet_out.stall = ld_detection;
	       end
	       else if (id_packet_out.inst.r.rs2 == ex_mem_packet_in.dest_reg_idx && ex_mem_packet_in.valid) begin
	           id_packet_out.brcond_opb_select = BRCOND_OPB_IS_FROM_MEM_WB;
	       end
	   end
	   
	   
	   // Special condition for store
	   if (id_packet_out.wr_mem && id_packet_out.inst.r.rs2 != `ZERO_REG) begin
	       if (id_packet_out.inst.r.rs2 == id_ex_packet_in.dest_reg_idx && id_ex_packet_in.valid) begin
	           id_packet_out.store_opb_select = STORE_OPB_IS_FROM_EX_MEM;
	           id_packet_out.stall = ld_detection;
	       end
	       else if (id_packet_out.inst.r.rs2 == ex_mem_packet_in.dest_reg_idx && ex_mem_packet_in.valid) begin
	           id_packet_out.store_opb_select = STORE_OPB_IS_FROM_MEM_WB;
	       end
	   end
	   
	end
	*/
`ifdef USE_DETECTION
	detection_unit detection_unit_0(
        .id_packet_0(id_packet_internal_0),
        .id_packet_1(id_packet_internal_1),
        .id_packet_2(id_packet_internal_2),
        .ex_packet_0(id_ex_packet_in_0),
        .ex_packet_1(id_ex_packet_in_1),
        .ex_packet_2(id_ex_packet_in_2),
        .mem_packet_0(ex_mem_packet_in_0),
        .mem_packet_1(ex_mem_packet_in_1),
        .mem_packet_2(ex_mem_packet_in_2),
        .id_packet_out_0(id_packet_out_0),
        .id_packet_out_1(id_packet_out_1),
        .id_packet_out_2(id_packet_out_2),
        .rollback(rollback),
    );
`else
	assign id_packet_out_0 = id_packet_internal_0;
	assign id_packet_out_1 = id_packet_internal_1;
	assign id_packet_out_2 = id_packet_internal_2;
`endif

	/*
	always_ff @(posedge clock) begin
	   pre_rollback <= `SD rollback;
	   hold_reg_0 <= `SD if_id_packet_in_0;
	   hold_reg_1 <= `SD if_id_packet_in_1;
	   hold_reg_2 <= `SD if_id_packet_in_2;
	end
	*/
	
   
endmodule // module id_stage
