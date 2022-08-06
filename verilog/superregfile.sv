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
        input         wr_en[`WAYS-1:0], wr_clk,

        output logic [`XLEN-1:0] rda_out[`WAYS-1:0], rdb_out[`WAYS-1:0]    // read data
          
      );
  
  logic    [31:0] [`XLEN-1:0] registers;   // 32, 64-bit Registers

  wire [`XLEN-1:0] rda_reg[`WAYS-1:0],rdb_reg[`WAYS-1:0];
genvar i;
generate 
  for (i=0;i<`WAYS;i++) begin
    assign rda_reg[i] = registers[rda_idx[i]];
    assign rdb_reg[i] = registers[rdb_idx[i]];
  end
endgenerate

generate 
  //
  // Read port A[0]
  //
  for (i=0;i<`WAYS;i++) begin
    always_comb
      if (rda_idx[i] == `ZERO_REG)
        rda_out[i] = 0;
      else if (wr_en[3] && (wr_idx[3] == rda_idx[i]))
        rda_out[i] = wr_data[3];  // internal forwarding
      else if (wr_en[2] && (wr_idx[2] == rda_idx[i]))
        rda_out[i] = wr_data[2];  // internal forwarding
      else if (wr_en[1] && (wr_idx[1] == rda_idx[i]))
        rda_out[i] = wr_data[1];
      else if (wr_en[0] && (wr_idx[0] == rda_idx[i]))
        rda_out[i] = wr_data[0];
      else
        rda_out[i] = rda_reg[i];

    //
    // Read port B[0]
    //
    always_comb
      if (rdb_idx[i] == `ZERO_REG)
        rdb_out[i] = 0;
      else if (wr_en[3] && (wr_idx[3] == rdb_idx[i]))
        rdb_out[i] = wr_data[3];  // internal forwarding
      else if (wr_en[2] && (wr_idx[2] == rdb_idx[i]))
        rdb_out[i] = wr_data[2];  // internal forwarding
      else if (wr_en[1] && (wr_idx[1] == rdb_idx[i]))
        rdb_out[i] = wr_data[1];
      else if (wr_en[0] && (wr_idx[0] == rdb_idx[i]))
        rdb_out[i] = wr_data[0];
      else
        rdb_out[i] = rdb_reg[i];
  end
endgenerate
  

  //
  // Write port
  //
  always_ff @(posedge wr_clk) begin
    foreach(wr_en[i]) 
      if (wr_en[i]) begin
        registers[wr_idx[i]] <= `SD wr_data[i];
      end
  end

endmodule // regfile
`endif //__REGFILE_V__
