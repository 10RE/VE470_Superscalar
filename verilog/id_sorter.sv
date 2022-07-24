`ifndef __ID_SORTER__
`define __IDSORTER__

`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/21 15:14:43
// Design Name: 
// Module Name: id_sorter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module id_sorter(
        input IF_ID_PACKET packet_in_0, packet_in_1, packet_in_2,
        
        output IF_ID_PACKET packet_out_0, packet_out_1, packet_out_2
    );
    
    wire [2:0] compare;
    
    assign compare[2] = packet_in_0.PC < packet_in_1.PC ? 1 : 0;
    assign compare[1] = packet_in_0.PC < packet_in_2.PC ? 1 : 0;
    assign compare[0] = packet_in_1.PC < packet_in_2.PC ? 1 : 0;
    
    always_comb begin
        case (compare)
            3'b000: begin
                packet_out_0 = packet_in_2;
                packet_out_1 = packet_in_1;
                packet_out_2 = packet_in_0;
            end
            3'b001: begin
                packet_out_0 = packet_in_1;
                packet_out_1 = packet_in_2;
                packet_out_2 = packet_in_0;
            end
            3'b010: begin // not exist
                packet_out_0 = packet_in_0;
                packet_out_1 = packet_in_1;
                packet_out_2 = packet_in_2;
            end
            3'b011: begin
                packet_out_0 = packet_in_1;
                packet_out_1 = packet_in_0;
                packet_out_2 = packet_in_2;
            end
            3'b100: begin
                packet_out_0 = packet_in_2;
                packet_out_1 = packet_in_0;
                packet_out_2 = packet_in_1;
            end
            3'b101: begin // not exist
                packet_out_0 = packet_in_0;
                packet_out_1 = packet_in_1;
                packet_out_2 = packet_in_2;
            end
            3'b110: begin
                packet_out_0 = packet_in_0;
                packet_out_1 = packet_in_2;
                packet_out_2 = packet_in_1;
            end
            3'b111: begin
                packet_out_0 = packet_in_0;
                packet_out_1 = packet_in_1;
                packet_out_2 = packet_in_2;
            end
        endcase
    end
    
    
endmodule


`endif