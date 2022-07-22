/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  regfile.v                                           //
//                                                                     //
//  Description :  This module creates the Regfile used by the ID and  // 
//                 WB Stages of the Pipeline.                          //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __SUPERREGFILE_V__
`define __SUPERREGFILE_V__

`timescale 1ns/100ps

module superregfile(
        input   [4:0] rda_idx_0, rdb_idx_0, wr_idx_0, rda_idx_1, rdb_idx_1, wr_idx_1, rda_idx_2, rdb_idx_2, wr_idx_2,    // read/write index
        input  [`XLEN-1:0] wr_data_0, wr_data_1, wr_data_2,            // write data
        input         wr_en_0, wr_en_1, wr_en_2, wr_clk,

        output logic [`XLEN-1:0] rda_out_0, rdb_out_0, rda_out_1, rdb_out_1, rda_out_2, rdb_out_2    // read data
          
      );
  
  logic    [31:0] [`XLEN-1:0] registers;   // 32, 64-bit Registers

  wire   [`XLEN-1:0] rda_reg_0 = registers[rda_idx_0];
  wire   [`XLEN-1:0] rdb_reg_0 = registers[rdb_idx_0];
  wire   [`XLEN-1:0] rda_reg_1 = registers[rda_idx_1];
  wire   [`XLEN-1:0] rdb_reg_1 = registers[rdb_idx_1];
  wire   [`XLEN-1:0] rda_reg_2 = registers[rda_idx_2];
  wire   [`XLEN-1:0] rdb_reg_2 = registers[rdb_idx_2];

  //
  // Read port A_0
  //
  always_comb
    if (rda_idx_0 == `ZERO_REG)
      rda_out_0 = 0;
    else if (wr_en_0 && (wr_idx_0 == rda_idx_0))
      rda_out_0 = wr_data_0;  // internal forwarding
    else if (wr_en_1 && (wr_idx_1 == rda_idx_0))
      rda_out_0 = wr_data_1;
    else if (wr_en_2 && (wr_idx_2 == rda_idx_0))
      rda_out_0 = wr_data_2;
    else
      rda_out_0 = rda_reg_0;

  //
  // Read port B_0
  //
  always_comb
    if (rdb_idx_0 == `ZERO_REG)
      rdb_out_0 = 0;
    else if (wr_en_0 && (wr_idx_0 == rdb_idx_0))
      rdb_out_0 = wr_data_0;  // internal forwarding
    else if (wr_en_1 && (wr_idx_1 == rdb_idx_0))
      rdb_out_0 = wr_data_1;
    else if (wr_en_2 && (wr_idx_2 == rdb_idx_0))
      rdb_out_0 = wr_data_2;
    else
      rdb_out_0 = rdb_reg_0;
      
  //
  // Read port A_1
  //
  always_comb
    if (rda_idx_1 == `ZERO_REG)
      rda_out_1 = 0;
    else if (wr_en_0 && (wr_idx_0 == rda_idx_1))
      rda_out_1 = wr_data_0;  // internal forwarding
    else if (wr_en_1 && (wr_idx_1 == rda_idx_1))
      rda_out_1 = wr_data_1;
    else if (wr_en_2 && (wr_idx_2 == rda_idx_1))
      rda_out_1 = wr_data_2;
    else
      rda_out_1 = rda_reg_1;

  //
  // Read port B_1
  //
  always_comb
    if (rdb_idx_1 == `ZERO_REG)
      rdb_out_1 = 0;
    else if (wr_en_0 && (wr_idx_0 == rdb_idx_1))
      rdb_out_1 = wr_data_0;  // internal forwarding
    else if (wr_en_1 && (wr_idx_1 == rdb_idx_1))
      rdb_out_1 = wr_data_1;
    else if (wr_en_2 && (wr_idx_2 == rdb_idx_1))
      rdb_out_1 = wr_data_2;
    else
      rdb_out_1 = rdb_reg_1;
      
  //
  // Read port A_2
  //
  always_comb
    if (rda_idx_2 == `ZERO_REG)
      rda_out_2 = 0;
    else if (wr_en_0 && (wr_idx_0 == rda_idx_2))
      rda_out_2 = wr_data_0;  // internal forwarding
    else if (wr_en_1 && (wr_idx_1 == rda_idx_2))
      rda_out_2 = wr_data_1;
    else if (wr_en_2 && (wr_idx_2 == rda_idx_2))
      rda_out_2 = wr_data_2;
    else
      rda_out_2 = rda_reg_2;

  //
  // Read port B_2
  //
  always_comb
    if (rdb_idx_2 == `ZERO_REG)
      rdb_out_2 = 0;
    else if (wr_en_0 && (wr_idx_0 == rda_idx_2))
      rdb_out_2 = wr_data_0;  // internal forwarding
    else if (wr_en_1 && (wr_idx_1 == rdb_idx_2))
      rdb_out_2 = wr_data_1;
    else if (wr_en_2 && (wr_idx_2 == rdb_idx_2))
      rdb_out_2 = wr_data_2;
    else
      rdb_out_2 = rdb_reg_2;

  //
  // Write port
  //
  always_ff @(posedge wr_clk) begin
    if (wr_en_0) begin
      registers[wr_idx_0] <= `SD wr_data_0;
    end
    if (wr_en_1) begin
      registers[wr_idx_1] <= `SD wr_data_1;
    end
    if (wr_en_2) begin
      registers[wr_idx_2] <= `SD wr_data_2;
    end
  end

endmodule // regfile
`endif //__REGFILE_V__
