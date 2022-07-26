//////////////////////////////////////////////////////////////////////////
//                                                                      //
//   Modulename :  ex_stage.v                                           //
//                                                                      //
//  Description :  instruction execute (EX) stage of the pipeline;      //
//                 given the instruction command code CMD, select the   //
//                 proper input A and B for the ALU, compute the result,// 
//                 and compute the condition for branches, and pass all //
//                 the results down the pipeline. MWB                   // 
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////
`ifndef __EX_STAGE_V__
`define __EX_STAGE_V__

`timescale 1ns/100ps

//
// The ALU
//
// given the command code CMD and proper operands A and B, compute the
// result of the instruction
//
// This module is purely combinational
//
module alu(
	input [`XLEN-1:0] opa,
	input [`XLEN-1:0] opb,
	ALU_FUNC     func,

	output logic [`XLEN-1:0] result
);
	wire signed [`XLEN-1:0] signed_opa, signed_opb;
	wire signed [2*`XLEN-1:0] signed_mul, mixed_mul;
	wire        [2*`XLEN-1:0] unsigned_mul;
	assign signed_opa = opa;
	assign signed_opb = opb;
	assign signed_mul = signed_opa * signed_opb;
	assign unsigned_mul = opa * opb;
	assign mixed_mul = signed_opa * opb;

	always_comb begin
		case (func)
			ALU_ADD:      result = opa + opb;
			ALU_SUB:      result = opa - opb;
			ALU_AND:      result = opa & opb;
			ALU_SLT:      result = signed_opa < signed_opb;
			ALU_SLTU:     result = opa < opb;
			ALU_OR:       result = opa | opb;
			ALU_XOR:      result = opa ^ opb;
			ALU_SRL:      result = opa >> opb[4:0];
			ALU_SLL:      result = opa << opb[4:0];
			ALU_SRA:      result = signed_opa >>> opb[4:0]; // arithmetic from logical shift
			ALU_MUL:      result = signed_mul[`XLEN-1:0];
			ALU_MULH:     result = signed_mul[2*`XLEN-1:`XLEN];
			ALU_MULHSU:   result = mixed_mul[2*`XLEN-1:`XLEN];
			ALU_MULHU:    result = unsigned_mul[2*`XLEN-1:`XLEN];

			default:      result = `XLEN'hfacebeec;  // here to prevent latches
		endcase
	end
endmodule // alu

//
// BrCond module
//
// Given the instruction code, compute the proper condition for the
// instruction; for branches this condition will indicate whether the
// target is taken.
//
// This module is purely combinational
//
module brcond(// Inputs
	input [`XLEN-1:0] rs1,    // Value to check against condition
	input [`XLEN-1:0] rs2,
	input  [2:0] func,  // Specifies which condition to check

	output logic cond    // 0/1 condition result (False/True)
);

	logic signed [`XLEN-1:0] signed_rs1, signed_rs2;
	assign signed_rs1 = rs1;
	assign signed_rs2 = rs2;
	always_comb begin
		cond = 0;
		case (func)
			3'b000: cond = signed_rs1 == signed_rs2;  // BEQ
			3'b001: cond = signed_rs1 != signed_rs2;  // BNE
			3'b100: cond = signed_rs1 < signed_rs2;   // BLT
			3'b101: cond = signed_rs1 >= signed_rs2;  // BGE
			3'b110: cond = rs1 < rs2;                 // BLTU
			3'b111: cond = rs1 >= rs2;                // BGEU
		endcase
	end
	
endmodule // brcond



// Single Ex Stage module
module signle_ex_stage(
	input clock,               // system clock
	input reset,               // system reset
	input ID_EX_PACKET   id_ex_packet_in,
	input [`XLEN-1:0] ex_0_result, ex_1_result, ex_2_result,
	input [`XLEN-1:0] mem_0_result, mem_1_result, mem_2_result,
	output EX_MEM_PACKET ex_packet_out
);

	// Pass-throughs
	assign ex_packet_out.NPC 				= id_ex_packet_in.NPC;
	assign ex_packet_out.rs2_value 			= forward_rs2_value;
	assign ex_packet_out.rd_mem 			= id_ex_packet_in.rd_mem;
	assign ex_packet_out.wr_mem 			= id_ex_packet_in.wr_mem;
	assign ex_packet_out.dest_reg_idx 		= id_ex_packet_in.dest_reg_idx;
	assign ex_packet_out.halt 				= id_ex_packet_in.halt;
	assign ex_packet_out.illegal 			= id_ex_packet_in.illegal;
	assign ex_packet_out.csr_op 			= id_ex_packet_in.csr_op;
	assign ex_packet_out.valid 				= id_ex_packet_in.valid;
	assign ex_packet_out.mem_size 			= id_ex_packet_in.inst.r.funct3;

	logic [`XLEN-1:0] opa_mux_out, opb_mux_out;
	logic brcond_result;
	logic [`XLEN-1:0] forward_rs1_value, forward_rs2_value;

	//
	// forward
	//
	always_comb begin
		forward_rs1_value=0;
		case (id_ex_packet_in.rs1_select)
			RS_IS_RS: 		forward_rs1_value	=	id_ex_packet_in.rs1_value;
			RS_IS_EX_0: 	forward_rs1_value	=	ex_0_result;
			RS_IS_MEM_0:	forward_rs1_value	=	mem_0_result;
			RS_IS_EX_1: 	forward_rs1_value	=	ex_1_result;
			RS_IS_MEM_1:	forward_rs1_value	=	mem_1_result;
			RS_IS_EX_2: 	forward_rs1_value	=	ex_2_result;
			RS_IS_MEM_2:	forward_rs1_value	=	mem_2_result;
		endcase

		forward_rs2_value=0;
		case (id_ex_packet_in.rs2_select)
			RS_IS_RS: 		forward_rs2_value	=	id_ex_packet_in.rs2_value;
			RS_IS_EX_0: 	forward_rs2_value	=	ex_0_result;
			RS_IS_MEM_0:	forward_rs2_value	=	mem_0_result;
			RS_IS_EX_1: 	forward_rs2_value	=	ex_1_result;
			RS_IS_MEM_1:	forward_rs2_value	=	mem_1_result;
			RS_IS_EX_2: 	forward_rs2_value	=	ex_2_result;
			RS_IS_MEM_2:	forward_rs2_value	=	mem_2_result;
		endcase
	end

	//
	// ALU opA mux
	//
	always_comb begin
		opa_mux_out = `XLEN'hdeadfbac;
		case (id_ex_packet_in.opa_select)
			OPA_IS_RS1:  opa_mux_out = forward_rs1_value;
			OPA_IS_NPC:  opa_mux_out = id_ex_packet_in.NPC;
			OPA_IS_PC:   opa_mux_out = id_ex_packet_in.PC;
			OPA_IS_ZERO: opa_mux_out = 0;
		endcase
	end

	 //
	 // ALU opB mux
	 //
	always_comb begin
		opb_mux_out = `XLEN'hfacefeed;
		case (id_ex_packet_in.opb_select)
			OPB_IS_RS2:   opb_mux_out = forward_rs2_value;
			OPB_IS_I_IMM: opb_mux_out = `RV32_signext_Iimm(id_ex_packet_in.inst);
			OPB_IS_S_IMM: opb_mux_out = `RV32_signext_Simm(id_ex_packet_in.inst);
			OPB_IS_B_IMM: opb_mux_out = `RV32_signext_Bimm(id_ex_packet_in.inst);
			OPB_IS_U_IMM: opb_mux_out = `RV32_signext_Uimm(id_ex_packet_in.inst);
			OPB_IS_J_IMM: opb_mux_out = `RV32_signext_Jimm(id_ex_packet_in.inst);
		endcase 
	end

	alu alu_0 (// Inputs
		.opa(opa_mux_out),
		.opb(opb_mux_out),
		.func(id_ex_packet_in.alu_func),

		// Output
		.result(ex_packet_out.alu_result)
	);

	brcond brcond_0 (// Inputs
		.rs1(id_ex_packet_in.rs1_value), 
		.rs2(id_ex_packet_in.rs2_value),
		.func(id_ex_packet_in.inst.b.funct3), // inst bits to determine check

		// Output
		.cond(brcond_result)
	);

	// ultimate "take branch" signal:
	 //	unconditional, or conditional and the condition is true
	assign ex_packet_out.take_branch = id_ex_packet_in.uncond_branch
		                          | (id_ex_packet_in.cond_branch & brcond_result);
endmodule // single_ex_stage


module ex_stage(
	input clock,               // system clock
	input reset,               // system reset
	input ID_EX_PACKET   id_ex_packet_in_0,
	input ID_EX_PACKET   id_ex_packet_in_1,
	input ID_EX_PACKET   id_ex_packet_in_2,
	input [`XLEN-1:0] ex_0_result, ex_1_result, ex_2_result,
	input [`XLEN-1:0] mem_0_result, mem_1_result, mem_2_result,
	output EX_MEM_PACKET ex_packet_out_0,
	output EX_MEM_PACKET ex_packet_out_1,
	output EX_MEM_PACKET ex_packet_out_2,
	output logic ex_mem_take_branch,
	output logic [`XLEN-1:0] ex_mem_target_pc,
	output logic [1:0] ex_mem_branch_way
);
	
	signle_ex_stage ex_stage_0 (
		.clock(clock),               
		.reset(reset),               
		.id_ex_packet_in(id_ex_packet_in_0),
		.ex_0_result(ex_0_result), 
		.ex_1_result(ex_1_result), 
		.ex_2_result(ex_2_result),
		.mem_0_result(mem_0_result), 
		.mem_1_result(mem_1_result), 
		.mem_2_result(mem_2_result),
		.ex_packet_out(ex_packet_out_0)
	);

	signle_ex_stage ex_stage_1 (
		.clock(clock),               
		.reset(reset),               
		.id_ex_packet_in(id_ex_packet_in_1),
		.ex_0_result(ex_0_result), 
		.ex_1_result(ex_1_result), 
		.ex_2_result(ex_2_result),
		.mem_0_result(mem_0_result), 
		.mem_1_result(mem_1_result), 
		.mem_2_result(mem_2_result),
		.ex_packet_out(ex_packet_out_1)
	);

	signle_ex_stage ex_stage_2 (
		.clock(clock),               
		.reset(reset),               
		.id_ex_packet_in(id_ex_packet_in_2),
		.ex_0_result(ex_0_result), 
		.ex_1_result(ex_1_result), 
		.ex_2_result(ex_2_result),
		.mem_0_result(mem_0_result), 
		.mem_1_result(mem_1_result), 
		.mem_2_result(mem_2_result),
		.ex_packet_out(ex_packet_out_2)
	);

	// brcond
	always_comb begin
		ex_mem_take_branch = 0;
		ex_mem_target_pc = 0;
		ex_mem_branch_way = 0;
		if (ex_packet_out_0.take_branch || ex_packet_out_0.halt) begin
			ex_mem_take_branch = 1;
			ex_mem_target_pc = ex_packet_out_0.alu_result;
			ex_mem_branch_way = 0;
		end
		else if (ex_packet_out_1.take_branch || ex_packet_out_1.halt) begin
			ex_mem_take_branch = 1;
			ex_mem_target_pc = ex_packet_out_1.alu_result;
			ex_mem_branch_way = 1;
		end
		else if (ex_packet_out_2.take_branch || ex_packet_out_2.halt) begin
			ex_mem_take_branch = 1;
			ex_mem_target_pc = ex_packet_out_2.alu_result;
			ex_mem_branch_way = 2;
		end
	end

endmodule // module ex_stage
`endif // __EX_STAGE_V__
