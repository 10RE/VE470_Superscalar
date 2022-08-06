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
        input   [4:0] rda_idx[`WAYS-1:0], rdb_idx[`WAYS-1:0], wr_idx[`WAYS-1:0],    // read/write index
        input  [`XLEN-1:0] wr_data[`WAYS-1:0],            // write data
        input         wr_en[2:0], wr_clk,

        output logic [`XLEN-1:0] rda_out[`WAYS-1:0], rdb_out[`WAYS-1:0]    // read data
          
      );
  
  logic    [31:0] [`XLEN-1:0] registers;   // 32, 64-bit Registers

  wire [`XLEN-1:0] rda_reg[`WAYS-1:0],rdb_reg[`WAYS-1:0];

  assign rda_reg[0] = registers[rda_idx[0]];
  assign rdb_reg[0] = registers[rdb_idx[0]];
  assign rda_reg[1] = registers[rda_idx[1]];
  assign rdb_reg[1] = registers[rdb_idx[1]];
  assign rda_reg[2] = registers[rda_idx[2]];
  assign rdb_reg[2] = registers[rdb_idx[2]];

  //
  // Read port A[0]
  //
  always_comb
    if (rda_idx[0] == `ZERO_REG)
      rda_out[0] = 0;
    else if (wr_en[2] && (wr_idx[2] == rda_idx[0]))
      rda_out[0] = wr_data[2];  // internal forwarding
    else if (wr_en[1] && (wr_idx[1] == rda_idx[0]))
      rda_out[0] = wr_data[1];
    else if (wr_en[0] && (wr_idx[0] == rda_idx[0]))
      rda_out[0] = wr_data[0];
    else
      rda_out[0] = rda_reg[0];

  //
  // Read port B[0]
  //
  always_comb
    if (rdb_idx[0] == `ZERO_REG)
      rdb_out[0] = 0;
    else if (wr_en[2] && (wr_idx[2] == rdb_idx[0]))
      rdb_out[0] = wr_data[2];  // internal forwarding
    else if (wr_en[1] && (wr_idx[1] == rdb_idx[0]))
      rdb_out[0] = wr_data[1];
    else if (wr_en[0] && (wr_idx[0] == rdb_idx[0]))
      rdb_out[0] = wr_data[0];
    else
      rdb_out[0] = rdb_reg[0];
      
  //
  // Read port A[1]
  //
  always_comb
    if (rda_idx[1] == `ZERO_REG)
      rda_out[1] = 0;
    else if (wr_en[2] && (wr_idx[2] == rda_idx[1]))
      rda_out[1] = wr_data[2];  // internal forwarding
    else if (wr_en[1] && (wr_idx[1] == rda_idx[1]))
      rda_out[1] = wr_data[1];
    else if (wr_en[0] && (wr_idx[0] == rda_idx[1]))
      rda_out[1] = wr_data[0];
    else
      rda_out[1] = rda_reg[1];

  //
  // Read port B[1]
  //
  always_comb
    if (rdb_idx[1] == `ZERO_REG)
      rdb_out[1] = 0;
    else if (wr_en[2] && (wr_idx[2] == rdb_idx[1]))
      rdb_out[1] = wr_data[2];  // internal forwarding
    else if (wr_en[1] && (wr_idx[1] == rdb_idx[1]))
      rdb_out[1] = wr_data[1];
    else if (wr_en[0] && (wr_idx[0] == rdb_idx[1]))
      rdb_out[1] = wr_data[0];
    else
      rdb_out[1] = rdb_reg[1];
      
  //
  // Read port A[2]
  //
  always_comb
    if (rda_idx[2] == `ZERO_REG)
      rda_out[2] = 0;
    else if (wr_en[2] && (wr_idx[2] == rda_idx[2]))
      rda_out[2] = wr_data[2];  // internal forwarding
    else if (wr_en[1] && (wr_idx[1] == rda_idx[2]))
      rda_out[2] = wr_data[1];
    else if (wr_en[0] && (wr_idx[0] == rda_idx[2]))
      rda_out[2] = wr_data[0];
    else
      rda_out[2] = rda_reg[2];

  //
  // Read port B[2]
  //
  always_comb
    if (rdb_idx[2] == `ZERO_REG)
      rdb_out[2] = 0;
    else if (wr_en[2] && (wr_idx[2] == rda_idx[2]))
      rdb_out[2] = wr_data[2];  // internal forwarding
    else if (wr_en[1] && (wr_idx[1] == rdb_idx[2]))
      rdb_out[2] = wr_data[1];
    else if (wr_en[0] && (wr_idx[0] == rdb_idx[2]))
      rdb_out[2] = wr_data[0];
    else
      rdb_out[2] = rdb_reg[2];

  //
  // Write port
  //
  always_ff @(posedge wr_clk) begin
    if (wr_en[0]) begin
      registers[wr_idx[0]] <= `SD wr_data[0];
    end
    if (wr_en[1]) begin
      registers[wr_idx[1]] <= `SD wr_data[1];
    end
    if (wr_en[2]) begin
      registers[wr_idx[2]] <= `SD wr_data[2];
    end
  end

endmodule // regfile
`endif //__REGFILE_V__
