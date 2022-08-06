`timescale 1ns/100ps

module detection_unit_test();

    logic clock;

    ID_EX_PACKET id_packet_0;
    ID_EX_PACKET id_packet_1;
    ID_EX_PACKET id_packet_2;

    ID_EX_PACKET ex_packet_0;
    ID_EX_PACKET ex_packet_1;
    ID_EX_PACKET ex_packet_2;

    EX_MEM_PACKET mem_packet_0;
    EX_MEM_PACKET mem_packet_1;
    EX_MEM_PACKET mem_packet_2;

    ID_EX_PACKET id_packet_out_0;
    ID_EX_PACKET id_packet_out_1;
    ID_EX_PACKET id_packet_out_2;

    logic [1:0] rollback;

    RS_SELECT [3:0] forwarding_A;
    RS_SELECT [3:0] forwarding_B;

    detection_unit detection_unit_0(
        .id_packet_0(id_packet_0),
        .id_packet_1(id_packet_1),
        .id_packet_2(id_packet_2),
        .ex_packet_0(ex_packet_0),
        .ex_packet_1(ex_packet_1),
        .ex_packet_2(ex_packet_2),
        .mem_packet_0(mem_packet_0),
        .mem_packet_1(mem_packet_1),
        .mem_packet_2(mem_packet_2),
        .id_packet_out_0(id_packet_out_0),
        .id_packet_out_1(id_packet_out_1),
        .id_packet_out_2(id_packet_out_2),
        .rollback(rollback),

        .forwarding_A(forwarding_A),
        .forwarding_B(forwarding_B)

    );

    always begin
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock;
	end

/*

   0:	00108093          	addi	x1,x1,1
   4:	00210113          	addi	x2,x2,2
   8:	00318193          	addi	x3,x3,3
   c:	0000a083          	lw	x1,0(x1)
  10:	0000a103          	lw	x2,0(x1)
  14:	0000a183          	lw	x3,0(x1)
  18:	00110093          	addi	x1,x2,1
  1c:	00108113          	addi	x2,x1,1
  20:	002081b3          	add	x3,x1,x2
  24:	001101b3          	add	x3,x2,x1
  28:	004081b3          	add	x3,x1,x4
  2c:	001201b3          	add	x3,x4,x1

*/

task update_packet;
    id_packet_0.dest_reg_idx = id_packet_0.inst.r.rd;
    id_packet_1.dest_reg_idx = id_packet_1.inst.r.rd;
    id_packet_2.dest_reg_idx = id_packet_2.inst.r.rd;

    ex_packet_0.dest_reg_idx = ex_packet_0.inst.r.rd;
    ex_packet_1.dest_reg_idx = ex_packet_1.inst.r.rd;
    ex_packet_2.dest_reg_idx = ex_packet_2.inst.r.rd;

    mem_packet_0.dest_reg_idx = mem_packet_0.inst.r.rd;
    mem_packet_1.dest_reg_idx = mem_packet_1.inst.r.rd;
    mem_packet_2.dest_reg_idx = mem_packet_2.inst.r.rd;
    
    casez(id_packet_0.inst)
        `RV32_LB, `RV32_LH, `RV32_LW, `RV32_LBU, `RV32_LHU: id_packet_0.rd_mem = 1;
        default: id_packet_0.rd_mem = 0;
    endcase
    casez(id_packet_1.inst)
        `RV32_LB, `RV32_LH, `RV32_LW, `RV32_LBU, `RV32_LHU: id_packet_1.rd_mem = 1;
        default: id_packet_1.rd_mem = 0;
    endcase
    casez(id_packet_2.inst)
        `RV32_LB, `RV32_LH, `RV32_LW, `RV32_LBU, `RV32_LHU: id_packet_2.rd_mem = 1;
        default: id_packet_2.rd_mem = 0;
    endcase
    casez(ex_packet_0.inst)
        `RV32_LB, `RV32_LH, `RV32_LW, `RV32_LBU, `RV32_LHU: ex_packet_0.rd_mem = 1;
        default: ex_packet_0.rd_mem = 0;
    endcase
    casez(ex_packet_1.inst)
        `RV32_LB, `RV32_LH, `RV32_LW, `RV32_LBU, `RV32_LHU: ex_packet_1.rd_mem = 1;
        default: ex_packet_1.rd_mem = 0;
    endcase
    casez(ex_packet_2.inst)
        `RV32_LB, `RV32_LH, `RV32_LW, `RV32_LBU, `RV32_LHU: ex_packet_2.rd_mem = 1;
        default: ex_packet_2.rd_mem = 0;
    endcase

endtask
/*
    assign id_packet_0.dest_reg_idx = id_packet_0.inst.r.rd;
    assign id_packet_1.dest_reg_idx = id_packet_1.inst.r.rd;
    assign id_packet_2.dest_reg_idx = id_packet_2.inst.r.rd;

    assign ex_packet_0.dest_reg_idx = ex_packet_0.inst.r.rd;
    assign ex_packet_1.dest_reg_idx = ex_packet_1.inst.r.rd;
    assign ex_packet_2.dest_reg_idx = ex_packet_2.inst.r.rd;

    assign mem_packet_0.dest_reg_idx = mem_packet_0.inst.r.rd;
    assign mem_packet_1.dest_reg_idx = mem_packet_1.inst.r.rd;
    assign mem_packet_2.dest_reg_idx = mem_packet_2.inst.r.rd;

    always begin
        #1;
		casez(id_packet_0.inst)
			`RV32_LB, `RV32_LH, `RV32_LW, `RV32_LBU, `RV32_LHU: id_packet_0.rd_mem = 1;
			default: id_packet_0.rd_mem = 0;
		endcase
        casez(id_packet_1.inst)
			`RV32_LB, `RV32_LH, `RV32_LW, `RV32_LBU, `RV32_LHU: id_packet_1.rd_mem = 1;
			default: id_packet_1.rd_mem = 0;
		endcase
        casez(id_packet_2.inst)
			`RV32_LB, `RV32_LH, `RV32_LW, `RV32_LBU, `RV32_LHU: id_packet_2.rd_mem = 1;
			default: id_packet_2.rd_mem = 0;
		endcase
        casez(ex_packet_0.inst)
			`RV32_LB, `RV32_LH, `RV32_LW, `RV32_LBU, `RV32_LHU: ex_packet_0.rd_mem = 1;
			default: ex_packet_0.rd_mem = 0;
		endcase
        casez(ex_packet_1.inst)
			`RV32_LB, `RV32_LH, `RV32_LW, `RV32_LBU, `RV32_LHU: ex_packet_1.rd_mem = 1;
			default: ex_packet_1.rd_mem = 0;
		endcase
        casez(ex_packet_2.inst)
			`RV32_LB, `RV32_LH, `RV32_LW, `RV32_LBU, `RV32_LHU: ex_packet_2.rd_mem = 1;
			default: ex_packet_2.rd_mem = 0;
		endcase
    end
*/

    initial begin	
		clock = 1'b0;

        id_packet_0 = 0;
        id_packet_1 = 0;
        id_packet_2 = 0;

        ex_packet_0 = 0;
        ex_packet_1 = 0;
        ex_packet_2 = 0;

        mem_packet_0 = 0;
        mem_packet_1 = 0;
        mem_packet_2 = 0;
        
        update_packet;

        // roll back test
        // internal
        @(posedge clock);
        id_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        id_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        id_packet_2.inst = 32'h00318193; //addi	x3,x3,3
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        id_packet_1.inst = 32'h00108113; //addi	x2,x1,1
        id_packet_2.inst = 32'h00318193; //addi	x3,x3,3
        update_packet;
        
        @(posedge clock);
        id_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        id_packet_1.inst = 32'h00318193; //addi	x3,x3,3
        id_packet_2.inst = 32'h00108113; //addi	x2,x1,1
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h00318193; //addi	x3,x3,3
        id_packet_1.inst = 32'h00108093; //addi	x1,x1,1
        id_packet_2.inst = 32'h00108113; //addi	x2,x1,1
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        id_packet_1.inst = 32'h00108113; //addi	x2,x1,1
        id_packet_2.inst = 32'h00210113; //addi	x2,x2,2
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        id_packet_1.inst = 32'h001201b3; //add x3,x4,x1
        id_packet_2.inst = 32'h00210113; //addi	x2,x2,2
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        id_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        id_packet_2.inst = 32'h001201b3; //add x3,x4,x1
        update_packet;

        //load
        @(posedge clock);
        id_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        id_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        id_packet_2.inst = 32'h00318193; //addi	x3,x3,3
        ex_packet_0.inst = 32'h0000a083; //lw x1,0(x1)
        ex_packet_1.inst = 32'h0;
        ex_packet_2.inst = 32'h0;
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        id_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        id_packet_2.inst = 32'h00318193; //addi	x3,x3,3
        ex_packet_0.inst = 32'h00318193; //addi	x3,x3,3
        ex_packet_1.inst = 32'h0000a083; //lw x1,0(x1)
        ex_packet_2.inst = 32'h0;
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        id_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        id_packet_2.inst = 32'h00318193; //addi	x3,x3,3
        ex_packet_0.inst = 32'h00210113; //addi	x2,x2,2
        ex_packet_1.inst = 32'h00108093; //addi	x1,x1,1
        ex_packet_2.inst = 32'h0000a083; //lw x1,0(x1)
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        id_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        id_packet_2.inst = 32'h00318193; //addi	x3,x3,3
        ex_packet_0.inst = 32'h0000a103; //lw	x2,0(x1)
        ex_packet_1.inst = 32'h0;
        ex_packet_2.inst = 32'h0;
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        id_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        id_packet_2.inst = 32'h00318193; //addi	x3,x3,3
        ex_packet_0.inst = 32'h00318193; //addi	x3,x3,3
        ex_packet_1.inst = 32'h0000a103; //lw	x2,0(x1)
        ex_packet_2.inst = 32'h0;
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        id_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        id_packet_2.inst = 32'h00318193; //addi	x3,x3,3
        ex_packet_0.inst = 32'h00210113; //addi	x2,x2,2
        ex_packet_1.inst = 32'h00108093; //addi	x1,x1,1
        ex_packet_2.inst = 32'h0000a103; //lw	x2,0(x1)
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        id_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        id_packet_2.inst = 32'h00318193; //addi	x3,x3,3
        ex_packet_0.inst = 32'h0000a183; //lw	x3,0(x1)
        ex_packet_1.inst = 32'h0;
        ex_packet_2.inst = 32'h0;
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        id_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        id_packet_2.inst = 32'h00318193; //addi	x3,x3,3
        ex_packet_0.inst = 32'h00318193; //addi	x3,x3,3
        ex_packet_1.inst = 32'h0000a183; //lw	x3,0(x1)
        ex_packet_2.inst = 32'h0;
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        id_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        id_packet_2.inst = 32'h00318193; //addi	x3,x3,3
        ex_packet_0.inst = 32'h00210113; //addi	x2,x2,2
        ex_packet_1.inst = 32'h00108093; //addi	x1,x1,1
        ex_packet_2.inst = 32'h0000a183; //lw	x3,0(x1)
        update_packet;

        //forwarding
        @(posedge clock);
        id_packet_0.inst = 32'h002081b3; //add	x3,x1,x2
        id_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        id_packet_2.inst = 32'h00108093; //addi	x1,x1,1
        ex_packet_0.inst = 32'h0;
        ex_packet_1.inst = 32'h0;
        ex_packet_2.inst = 32'h0;
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h002081b3; //add	x3,x1,x2
        id_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        id_packet_2.inst = 32'h00108093; //addi	x1,x1,1
        ex_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        ex_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        ex_packet_2.inst = 32'h0;
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h002081b3; //add	x3,x1,x2
        id_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        id_packet_2.inst = 32'h00108093; //addi	x1,x1,1
        ex_packet_0.inst = 32'h0;
        ex_packet_1.inst = 32'h00108093; //addi	x1,x1,1
        ex_packet_2.inst = 32'h00210113; //addi	x2,x2,2
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h002081b3; //add	x3,x1,x2
        id_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        id_packet_2.inst = 32'h00108093; //addi	x1,x1,1
        ex_packet_0.inst = 32'h0;
        ex_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        ex_packet_2.inst = 32'h00108093; //addi	x1,x1,1
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h002081b3; //add	x3,x1,x2
        id_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        id_packet_2.inst = 32'h00108093; //addi	x1,x1,1
        ex_packet_0.inst = 32'h0;
        ex_packet_1.inst = 32'h0;
        ex_packet_2.inst = 32'h0;
        mem_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        mem_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        mem_packet_2.inst = 32'h0;
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h002081b3; //add	x3,x1,x2
        id_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        id_packet_2.inst = 32'h00108093; //addi	x1,x1,1
        ex_packet_0.inst = 32'h0;
        ex_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        ex_packet_2.inst = 32'h0;
        mem_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        mem_packet_1.inst = 32'h0;
        mem_packet_2.inst = 32'h0;
        update_packet;

        @(posedge clock);
        id_packet_0.inst = 32'h002081b3; //add	x3,x1,x2
        id_packet_1.inst = 32'h00210113; //addi	x2,x2,2
        id_packet_2.inst = 32'h00108093; //addi	x1,x1,1
        ex_packet_0.inst = 32'h00210113; //addi	x2,x2,2
        ex_packet_1.inst = 32'h0;
        ex_packet_2.inst = 32'h0;
        mem_packet_0.inst = 32'h00108093; //addi	x1,x1,1
        mem_packet_1.inst = 32'h0;
        mem_packet_2.inst = 32'h0;
        update_packet;

    end

endmodule