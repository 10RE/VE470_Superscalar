`ifndef __DETECTION_UNIT__
`define __DETECTION_UNIT__

`timescale 1ns/100ps

//`define DETECTION_UNIT_TEST

module detection_unit(
    input ID_EX_PACKET id_packet_0,
    input ID_EX_PACKET id_packet_1,
    input ID_EX_PACKET id_packet_2,

    input ID_EX_PACKET ex_packet_0,
    input ID_EX_PACKET ex_packet_1,
    input ID_EX_PACKET ex_packet_2,

    input EX_MEM_PACKET mem_packet_0,
    input EX_MEM_PACKET mem_packet_1,
    input EX_MEM_PACKET mem_packet_2,

    output ID_EX_PACKET id_packet_out_0,
    output ID_EX_PACKET id_packet_out_1,
    output ID_EX_PACKET id_packet_out_2,

    output logic [1:0] rollback

`ifdef DETECTION_UNIT_TEST
    ,
    output RS_SELECT [2:0] forwarding_A,
    output RS_SELECT [2:0] forwarding_B
`endif

);

`ifdef DETECTION_UNIT_TEST
    assign forwarding_A = {
        id_packet_out_0.forwarding_A,
        id_packet_out_1.forwarding_A,
        id_packet_out_2.forwarding_A
    };

    assign forwarding_B = {
        id_packet_out_0.forwarding_B,
        id_packet_out_1.forwarding_B,
        id_packet_out_2.forwarding_B
    };
`endif

    logic [4:0] id_reg_A_0;
    assign id_reg_A_0 = id_packet_0.inst.r.rs1;

    logic [4:0] id_reg_B_0;
    assign id_reg_B_0 = id_packet_0.inst.r.rs2;

    logic [4:0] id_reg_A_1;
    assign id_reg_A_1 = id_packet_1.inst.r.rs1;

    logic [4:0] id_reg_B_1;
    assign id_reg_B_1 = id_packet_1.inst.r.rs2;

    logic [4:0] id_reg_A_2;
    assign id_reg_A_2 = id_packet_2.inst.r.rs1;

    logic [4:0] id_reg_B_2;
    assign id_reg_B_2 = id_packet_2.inst.r.rs2;

    logic [4:0] id_dest_reg_0;
    assign id_dest_reg_0 = id_packet_0.dest_reg_idx;

    logic [4:0] id_dest_reg_1;
    assign id_dest_reg_1 = id_packet_1.dest_reg_idx;

    logic [4:0] id_dest_reg_2;
    assign id_dest_reg_2 = id_packet_2.dest_reg_idx;

    logic [4:0] ex_dest_reg_0;
    assign ex_dest_reg_0 = ex_packet_0.dest_reg_idx;

    logic [4:0] ex_dest_reg_1;
    assign ex_dest_reg_1 = ex_packet_1.dest_reg_idx;

    logic [4:0] ex_dest_reg_2;
    assign ex_dest_reg_2 = ex_packet_2.dest_reg_idx;

    logic [4:0] mem_dest_reg_0;
    assign mem_dest_reg_0 = mem_packet_0.dest_reg_idx;

    logic [4:0] mem_dest_reg_1;
    assign mem_dest_reg_1 = mem_packet_1.dest_reg_idx;

    logic [4:0] mem_dest_reg_2;
    assign mem_dest_reg_2 = mem_packet_2.dest_reg_idx;

    logic id_reg_A_ZERO_0;
    assign id_reg_A_ZERO_0 = (id_packet_0.inst.r.rs1 == `ZERO_REG);

    logic id_reg_B_ZERO_0;
    assign id_reg_B_ZERO_0 = (id_packet_0.inst.r.rs2 == `ZERO_REG);

    logic id_reg_A_ZERO_1;
    assign id_reg_A_ZERO_1 = (id_packet_1.inst.r.rs1 == `ZERO_REG);

    logic id_reg_B_ZERO_1;
    assign id_reg_B_ZERO_1 = (id_packet_1.inst.r.rs2 == `ZERO_REG);

    logic id_reg_A_ZERO_2;
    assign id_reg_A_ZERO_2 = (id_packet_2.inst.r.rs1 == `ZERO_REG);

    logic id_reg_B_ZERO_2;
    assign id_reg_B_ZERO_2 = (id_packet_2.inst.r.rs2 == `ZERO_REG);

    always_comb begin
        id_packet_out_0 = id_packet_0;
        id_packet_out_0.rs1_select = RS_IS_RS;
        id_packet_out_0.rs2_select = RS_IS_RS;

        if (id_reg_A_0 == ex_dest_reg_2 && !id_reg_A_ZERO_0) begin
            id_packet_out_0.rs1_select = RS_IS_EX_2;
        end
        else if (id_reg_A_0 == ex_dest_reg_1 && !id_reg_A_ZERO_0) begin
            id_packet_out_0.rs1_select = RS_IS_EX_1;
        end
        else if (id_reg_A_0 == ex_dest_reg_0 && !id_reg_A_ZERO_0) begin
            id_packet_out_0.rs1_select = RS_IS_EX_0;
        end
        
        if (id_reg_B_0 == ex_dest_reg_2 && !id_reg_B_ZERO_0) begin
            id_packet_out_0.rs2_select = RS_IS_EX_2;
        end
        else if (id_reg_B_0 == ex_dest_reg_1 && !id_reg_B_ZERO_0) begin
            id_packet_out_0.rs2_select = RS_IS_EX_1;
        end
        else if (id_reg_B_0 == ex_dest_reg_0 && !id_reg_B_ZERO_0) begin
            id_packet_out_0.rs2_select = RS_IS_EX_0;
        end

        if (id_reg_A_0 == mem_dest_reg_2 && !id_reg_A_ZERO_0) begin
            id_packet_out_0.rs1_select = RS_IS_MEM_2;
        end
        else if (id_reg_A_0 == mem_dest_reg_1 && !id_reg_A_ZERO_0) begin
            id_packet_out_0.rs1_select = RS_IS_MEM_1;
        end
        else if (id_reg_A_0 == mem_dest_reg_0 && !id_reg_A_ZERO_0) begin
            id_packet_out_0.rs1_select = RS_IS_MEM_0;
        end

        if (id_reg_B_0 == mem_dest_reg_2 && !id_reg_B_ZERO_0) begin
            id_packet_out_0.rs2_select = RS_IS_MEM_2;
        end
        else if (id_reg_B_0 == mem_dest_reg_1 && !id_reg_B_ZERO_0) begin
            id_packet_out_0.rs2_select = RS_IS_MEM_1;
        end
        else if (id_reg_B_0 == mem_dest_reg_0 && !id_reg_B_ZERO_0) begin
            id_packet_out_0.rs2_select = RS_IS_MEM_0;
        end

        id_packet_out_1 = id_packet_1;
        id_packet_out_1.rs1_select = RS_IS_RS;
        id_packet_out_1.rs2_select = RS_IS_RS;

        if (id_reg_A_1 == ex_dest_reg_2 && !id_reg_A_ZERO_1) begin
            id_packet_out_1.rs1_select = RS_IS_EX_2;
        end
        else if (id_reg_A_1 == ex_dest_reg_1 && !id_reg_A_ZERO_1) begin
            id_packet_out_1.rs1_select = RS_IS_EX_1;
        end
        else if (id_reg_A_1 == ex_dest_reg_0 && !id_reg_A_ZERO_1) begin
            id_packet_out_1.rs1_select = RS_IS_EX_0;
        end

        if (id_reg_B_1 == ex_dest_reg_2 && !id_reg_B_ZERO_1) begin
            id_packet_out_1.rs2_select = RS_IS_EX_2;
        end
        else if (id_reg_B_1 == ex_dest_reg_1 && !id_reg_B_ZERO_1) begin
            id_packet_out_1.rs2_select = RS_IS_EX_1;
        end
        else if (id_reg_B_1 == ex_dest_reg_0 && !id_reg_B_ZERO_1) begin
            id_packet_out_1.rs2_select = RS_IS_EX_0;
        end

        if (id_reg_A_1 == mem_dest_reg_2 && !id_reg_A_ZERO_1) begin
            id_packet_out_1.rs1_select = RS_IS_MEM_2;
        end
        else if (id_reg_A_1 == mem_dest_reg_1 && !id_reg_A_ZERO_1) begin
            id_packet_out_1.rs1_select = RS_IS_MEM_1;
        end
        else if (id_reg_A_1 == mem_dest_reg_0 && !id_reg_A_ZERO_1) begin
            id_packet_out_1.rs1_select = RS_IS_MEM_0;
        end

        if (id_reg_B_1 == mem_dest_reg_2 && !id_reg_B_ZERO_1) begin
            id_packet_out_1.rs2_select = RS_IS_MEM_2;
        end
        else if (id_reg_B_1 == mem_dest_reg_1 && !id_reg_B_ZERO_1) begin
            id_packet_out_1.rs2_select = RS_IS_MEM_1;
        end
        else if (id_reg_B_1 == mem_dest_reg_0 && !id_reg_B_ZERO_1) begin
            id_packet_out_1.rs2_select = RS_IS_MEM_0;
        end

        id_packet_out_2 = id_packet_2;
        id_packet_out_2.rs1_select = RS_IS_RS;
        id_packet_out_2.rs2_select = RS_IS_RS;

        if (id_reg_A_2 == ex_dest_reg_2 && !id_reg_A_ZERO_2) begin
            id_packet_out_2.rs1_select = RS_IS_EX_2;
        end
        else if (id_reg_A_2 == ex_dest_reg_1 && !id_reg_A_ZERO_2) begin
            id_packet_out_2.rs1_select = RS_IS_EX_1;
        end
        else if (id_reg_A_2 == ex_dest_reg_0 && !id_reg_A_ZERO_2) begin
            id_packet_out_2.rs1_select = RS_IS_EX_0;
        end

        if (id_reg_B_2 == ex_dest_reg_2 && !id_reg_B_ZERO_2) begin
            id_packet_out_2.rs2_select = RS_IS_EX_2;
        end
        else if (id_reg_B_2 == ex_dest_reg_1 && !id_reg_B_ZERO_2) begin
            id_packet_out_2.rs2_select = RS_IS_EX_1;
        end
        else if (id_reg_B_2 == ex_dest_reg_0 && !id_reg_B_ZERO_2) begin
            id_packet_out_2.rs2_select = RS_IS_EX_0;
        end

        if (id_reg_A_2 == mem_dest_reg_2 && !id_reg_A_ZERO_2) begin
            id_packet_out_2.rs1_select = RS_IS_MEM_2;
        end
        else if (id_reg_A_2 == mem_dest_reg_1 && !id_reg_A_ZERO_2) begin
            id_packet_out_2.rs1_select = RS_IS_MEM_1;
        end
        else if (id_reg_A_2 == mem_dest_reg_0 && !id_reg_A_ZERO_2) begin
            id_packet_out_2.rs1_select = RS_IS_MEM_0;
        end

        if (id_reg_B_2 == mem_dest_reg_2 && !id_reg_B_ZERO_2) begin
            id_packet_out_2.rs2_select = RS_IS_MEM_2;
        end
        else if (id_reg_B_2 == mem_dest_reg_1 && !id_reg_B_ZERO_2) begin
            id_packet_out_2.rs2_select = RS_IS_MEM_1;
        end
        else if (id_reg_B_2 == mem_dest_reg_0 && !id_reg_B_ZERO_2) begin
            id_packet_out_2.rs2_select = RS_IS_MEM_0;
        end

    end
    
    logic [1:0] mem_count;
    
    logic ex_load_0;
    logic ex_load_1;
    logic ex_load_2;

    assign ex_load_0 = ex_packet_0.rd_mem;
    assign ex_load_1 = ex_packet_1.rd_mem;
    assign ex_load_2 = ex_packet_2.rd_mem;

    always_comb begin
        rollback = 0;
        // hazards between stages
        if (
            (id_reg_A_0 == ex_dest_reg_0 && !id_reg_A_ZERO_0 && ex_load_0) ||
            (id_reg_B_0 == ex_dest_reg_0 && !id_reg_B_ZERO_0 && ex_load_0) ||
            (id_reg_A_0 == ex_dest_reg_1 && !id_reg_A_ZERO_0 && ex_load_1) ||
            (id_reg_B_0 == ex_dest_reg_1 && !id_reg_B_ZERO_0 && ex_load_1) ||
            (id_reg_A_0 == ex_dest_reg_2 && !id_reg_A_ZERO_0 && ex_load_2) ||
            (id_reg_B_0 == ex_dest_reg_2 && !id_reg_B_ZERO_0 && ex_load_2)
        ) begin
            rollback = 3;
        end
        // hazards between ways in single cycle
        else if ((id_dest_reg_0 == id_reg_A_1 && !id_reg_A_ZERO_1) || (id_dest_reg_0 == id_reg_B_1 && !id_reg_B_ZERO_1)) begin
            rollback = 2;
        end
        // hazards between stages
        else if (
            (id_reg_A_1 == ex_dest_reg_0 && !id_reg_A_ZERO_1 && ex_load_0) ||
            (id_reg_B_1 == ex_dest_reg_0 && !id_reg_B_ZERO_1 && ex_load_0) ||
            (id_reg_A_1 == ex_dest_reg_1 && !id_reg_A_ZERO_1 && ex_load_1) ||
            (id_reg_B_1 == ex_dest_reg_1 && !id_reg_B_ZERO_1 && ex_load_1) ||
            (id_reg_A_1 == ex_dest_reg_2 && !id_reg_A_ZERO_1 && ex_load_2) ||
            (id_reg_B_1 == ex_dest_reg_2 && !id_reg_B_ZERO_1 && ex_load_2)
        ) begin
            rollback = 2;
        end
        // hazards between ways in single cycle
        else if ((id_dest_reg_0 == id_reg_A_2 && !id_reg_A_ZERO_2) || (id_dest_reg_0 == id_reg_B_2 && !id_reg_B_ZERO_2)) begin
            rollback = 1;
        end
        // hazards between ways in single cycle
        else if ((id_dest_reg_1 == id_reg_A_2 && !id_reg_A_ZERO_2) || (id_dest_reg_1 == id_reg_B_2 && !id_reg_B_ZERO_2)) begin
            rollback = 1;
        end
        // hazards between stages
        else if (
            (id_reg_A_2 == ex_dest_reg_0 && !id_reg_A_ZERO_2 && ex_load_0) ||
            (id_reg_B_2 == ex_dest_reg_0 && !id_reg_B_ZERO_2 && ex_load_0) ||
            (id_reg_A_2 == ex_dest_reg_1 && !id_reg_A_ZERO_2 && ex_load_1) ||
            (id_reg_B_2 == ex_dest_reg_1 && !id_reg_B_ZERO_2 && ex_load_1) ||
            (id_reg_A_2 == ex_dest_reg_2 && !id_reg_A_ZERO_2 && ex_load_2) ||
            (id_reg_B_2 == ex_dest_reg_2 && !id_reg_B_ZERO_2 && ex_load_2)
        ) begin
            rollback = 1;
        end
    end

endmodule
<<<<<<< HEAD
`endif
=======
`endif
>>>>>>> origin/wzh_id
