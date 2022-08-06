`ifndef __DETECTION_UNIT__
`define __DETECTION_UNIT__

`timescale 1ns/100ps

//`define DETECTION_UNIT_TEST



module detection_unit(
    input ID_EX_PACKET id_packet[2:0],

    input ID_EX_PACKET ex_packet[2:0],

    input EX_MEM_PACKET mem_packet[2:0],

    output ID_EX_PACKET id_packet_out[2:0],

    output logic [1:0] rollback

`ifdef DETECTION_UNIT_TEST
    ,
    output RS_SELECT [2:0] forwarding_A,
    output RS_SELECT [2:0] forwarding_B
`endif

);
    logic [4:0] mem_dest_reg [2:0];
    assign mem_dest_reg={
        mem_packet[2].dest_reg_idx,
        mem_packet[1].dest_reg_idx,
        mem_packet[0].dest_reg_idx
    };

    logic [4:0] ex_dest_reg [2:0];
    assign ex_dest_reg={
        ex_packet[2].dest_reg_idx,
        ex_packet[1].dest_reg_idx,
        ex_packet[0].dest_reg_idx
    };

    logic ex_load [2:0];
    assign ex_load={
        ex_packet[2].rd_mem,
        ex_packet[1].rd_mem,
        ex_packet[0].rd_mem
    };

module single_rs_select(
    input logic [4:0] id_reg,
    output RS_SELECT rs_select,
    output logic ex_load_depend
);
    RS_SELECT rs_select_ex;
    always_comb begin
        ex_load_depend=0;
        rs_select = RS_IS_RS;
        if (id_reg!=`ZERO_REG) begin
            rs_select = (id_reg==ex_dest_reg[2])?RS_IS_EX_2:
                        (id_reg==ex_dest_reg[1])?RS_IS_EX_1:
                        (id_reg==ex_dest_reg[0])?RS_IS_EX_0:
                        (id_reg==mem_dest_reg[2])?RS_IS_MEM_2:
                        (id_reg==mem_dest_reg[1])?RS_IS_MEM_1:
                        (id_reg==mem_dest_reg[0])?RS_IS_MEM_0:
                        RS_IS_RS;
            ex_load_depend =    (id_reg==ex_dest_reg[2]&&ex_load[2])||
                                (id_reg==ex_dest_reg[1]&&ex_load[1])||
                                (id_reg==ex_dest_reg[0]&&ex_load[0]);
        end
    end
endmodule

module single_way_select(
    input ID_EX_PACKET id_packet,
    output ID_EX_PACKET id_packet_out,
    output logic ex_load_depend
);
    RS_SELECT rs1_select,rs2_select;
    logic rs1_ex_load_depend,rs2_ex_load_depend;

    single_rs_select rs1(
        .id_reg(id_packet.inst.r.rs1),
        .rs_select(rs1_select),
        .ex_load_depend(rs1_ex_load_depend)
    );
    single_rs_select rs2(
        .id_reg(id_packet.inst.r.rs2),
        .rs_select(rs2_select),
        .ex_load_depend(rs2_ex_load_depend)
    );
    assign ex_load_depend = rs1_ex_load_depend || rs2_ex_load_depend;

    always_comb begin
        id_packet_out = id_packet;
        id_packet_out.rs1_select = rs1_select;
        id_packet_out.rs2_select = rs2_select;
    end
endmodule



`ifdef DETECTION_UNIT_TEST
    assign forwarding_A = {
        id_packet_out[0].rs1_select,
        id_packet_out[1].rs1_select,
        id_packet_out[2].rs1_select
    };

    assign forwarding_B = {
        id_packet_out[0].rs2_select,
        id_packet_out[1].rs2_select,
        id_packet_out[2].rs2_select
    };
`endif
    logic ex_load_depend[3];

    single_way_select way_0(
        .id_packet(id_packet[0]),
        .id_packet_out(id_packet_out[0]),
        .ex_load_depend(ex_load_depend[0])
    );
    single_way_select way_1(
        .id_packet(id_packet[1]),
        .id_packet_out(id_packet_out[1]),
        .ex_load_depend(ex_load_depend[1])
    );
    single_way_select way_2(
        .id_packet(id_packet[2]),
        .id_packet_out(id_packet_out[2]),
        .ex_load_depend(ex_load_depend[2])
    );

module depend_helper(
    input ID_EX_PACKET id_packet,
    input ID_EX_PACKET id_packet_later,
    output logic depend
);
    assign depend = (id_packet.dest_reg_idx == id_packet_later.inst.r.rs1 && id_packet_later.inst.r.rs1!=`ZERO_REG) || 
                    (id_packet.dest_reg_idx == id_packet_later.inst.r.rs2 && id_packet_later.inst.r.rs2!=`ZERO_REG);
endmodule

    logic way_0_depend_by_1, way_0_depend_by_2, way_1_depend_by_2;

    depend_helper way0vs1(
        .id_packet(id_packet[0]),
        .id_packet_later(id_packet[1]),
        .depend(way_0_depend_by_1)
    );
    depend_helper way0vs2(
        .id_packet(id_packet[0]),
        .id_packet_later(id_packet[2]),
        .depend(way_0_depend_by_2)
    );
    depend_helper way1vs2(
        .id_packet(id_packet[1]),
        .id_packet_later(id_packet[2]),
        .depend(way_1_depend_by_2)
    );

    
    always_comb begin
        logic [1:0] rollback_same_cycle, rollback_across_cycle;
        rollback_across_cycle = 0;
        rollback_same_cycle = 0;
        // hazards between stages
        if (ex_load_depend[0])
            rollback_across_cycle = 3;
        else if (ex_load_depend[1])
            rollback_across_cycle = 2;
        else if (ex_load_depend[2])
            rollback_across_cycle = 1;
        
        // hazards between ways in single cycle
        if (way_0_depend_by_1)
            rollback_same_cycle = 2;
        else if (way_0_depend_by_2 || way_1_depend_by_2)
            rollback_same_cycle = 1;
        
        // the greater one
        rollback=   (rollback_across_cycle > rollback_same_cycle) ? rollback_across_cycle :
                    rollback_same_cycle;
    end

endmodule

`endif
