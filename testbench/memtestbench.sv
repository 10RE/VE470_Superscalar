`timescale 1ns/100ps
//`include "sys_defs.svh"
import "DPI-C" function void print_header(string str);
import "DPI-C" function void print_cycles();
import "DPI-C" function void print_stage(string div, int inst, int npc, int valid_inst);
import "DPI-C" function void print_reg(int wb_reg_wr_data_out_hi, int wb_reg_wr_data_out_lo,
                                       int wb_reg_wr_idx_out, int wb_reg_wr_en_out);
import "DPI-C" function void print_membus(int proc2mem_command, int mem2proc_response,
                                          int proc2mem_addr_hi, int proc2mem_addr_lo,
						 			     int proc2mem_data_hi, int proc2mem_data_lo);
import "DPI-C" function void print_close();


module memtestbench;

	// variables used in the testbench
	logic        clock;
	logic        reset;
	
	logic [1:0]  proc2mem_command_0;
	logic [1:0]  proc2mem_command_1;
	logic [1:0]  proc2mem_command_2;
	logic [`XLEN-1:0] proc2mem_addr_0;
	logic [`XLEN-1:0] proc2mem_addr_1;
	logic [`XLEN-1:0] proc2mem_addr_2;
	logic [63:0] proc2mem_data_0;
	logic [63:0] proc2mem_data_1;
	logic [63:0] proc2mem_data_2;
	logic  [3:0] mem2proc_response_0;
	logic  [3:0] mem2proc_response_1;
	logic  [3:0] mem2proc_response_2;
	logic [63:0] mem2proc_data_0;
	logic [63:0] mem2proc_data_1;
	logic [63:0] mem2proc_data_2;
	logic  [3:0] mem2proc_tag_0;
	logic  [3:0] mem2proc_tag_1;
	logic  [3:0] mem2proc_tag_2;
	MEM_SIZE     proc2mem_size_0;
	MEM_SIZE     proc2mem_size_1;
	MEM_SIZE     proc2mem_size_2;


    //counter used for when pipeline infinite loops, forces termination
    logic [63:0] debug_counter;
    logic correct;

	// Instantiate the Data Memory
	mem memory (
		// Inputs
		.clk               (clock),
		.proc2mem_command_0  (proc2mem_command_0),
		.proc2mem_command_1  (proc2mem_command_1),
		.proc2mem_command_2  (proc2mem_command_2),
		.proc2mem_addr_0     (proc2mem_addr_0),
		.proc2mem_addr_1     (proc2mem_addr_1),
		.proc2mem_addr_2     (proc2mem_addr_2),
		.proc2mem_data_0     (proc2mem_data_0),
		.proc2mem_data_1     (proc2mem_data_1),
		.proc2mem_data_2     (proc2mem_data_2),
		.proc2mem_size_0     (proc2mem_size_0),
		.proc2mem_size_1     (proc2mem_size_1),
		.proc2mem_size_2     (proc2mem_size_2),

		// Outputs

		.mem2proc_response_0 (mem2proc_response_0),
		.mem2proc_response_1 (mem2proc_response_1),
		.mem2proc_response_2 (mem2proc_response_2),
		.mem2proc_data_0     (mem2proc_data_0),
		.mem2proc_data_1     (mem2proc_data_1),
		.mem2proc_data_2     (mem2proc_data_2),
		.mem2proc_tag_0      (mem2proc_tag_0),
		.mem2proc_tag_1      (mem2proc_tag_1),
		.mem2proc_tag_2      (mem2proc_tag_2)
	);
	
	// Generate System Clock
	always begin
		#(`VERILOG_CLOCK_PERIOD/2.0);
		clock = ~clock;
	end
	task show_mem_with_decimal;
		input [31:0] start_addr;
		input [31:0] end_addr;
		int showing_data;
		begin
			$display("@@@");
			showing_data=0;
			for(int k=start_addr;k<=end_addr; k=k+1)
				if (memory.unified_memory[k] != 0) begin
					$display("@@@ mem[%5d] = %x : %0d", k*8, memory.unified_memory[k], 
				                                            memory.unified_memory[k]);
					showing_data=1;
				end else if(showing_data!=0) begin
					$display("@@@");
					showing_data=0;
				end
			$display("@@@");
		end
	endtask  // task show_mem_with_decimal
    
    task exit_on_error;
		begin
					$display("@@@ Incorrect at time %4.0f", $time);
					$display("ENDING TESTBENCH : ERROR !");
					$finish;
		end
	endtask
    always_ff @(negedge clock) begin
		if( !correct ) begin //CORRECT CASE
			exit_on_error( );
		end
	end
    task CHECK_MEM;
		input logic [`XLEN-1:0] addr;
		input logic [63:0] data;
        input MEM_SIZE size;
		begin
		    for(int way=0;way<3;way++) begin
                proc2mem_command_0=BUS_NONE;
                proc2mem_command_1=BUS_NONE;
                proc2mem_command_2=BUS_NONE;
                if(way==0) begin
                    proc2mem_addr_0=addr;
                    proc2mem_command_0=BUS_LOAD;
                    proc2mem_size_0=size;
                    @(negedge clock);
                    if(mem2proc_data_0!=data) correct=0;
                end else if (way==1)begin
                    proc2mem_addr_1=addr;
                    proc2mem_command_1=BUS_LOAD;
                    proc2mem_size_1=size;
                    @(negedge clock);
                    if(mem2proc_data_1!=data) correct=0;
                end else if (way==2)begin
                    proc2mem_addr_2=addr;
                    proc2mem_command_2=BUS_LOAD;
                    proc2mem_size_2=size;
                    @(negedge clock);
                    if(mem2proc_data_2!=data) correct=0;
                end
            end
		end
	endtask
    task CHECK_DATA;
		input logic [63:0] mem2proc_data;
		input logic [63:0] data;
		begin
            if(mem2proc_data!=data) correct=0;
		end
	endtask
	initial begin
	    clock=0;
        reset=1;
        correct=1;
        $display("STARTING MEM_TESTBENCH!\n");
        proc2mem_addr_0=0;
        proc2mem_addr_1=0;
        proc2mem_addr_2=0;
        proc2mem_command_0=BUS_STORE;
        proc2mem_command_1=BUS_STORE;
        proc2mem_command_2=BUS_STORE;
        proc2mem_data_0=0;
        proc2mem_data_1=0;
        proc2mem_data_2=0;
        proc2mem_size_0=WORD;
        proc2mem_size_1=WORD;
        proc2mem_size_2=WORD;
        @(negedge clock);
        //BASIC TEST (WORD)
        for(int k=0;k<16; k=k+1) begin
            proc2mem_addr_0=0;
            proc2mem_addr_1=4;
            proc2mem_addr_2=8;
            proc2mem_command_0=BUS_STORE;
            proc2mem_command_1=BUS_STORE;
            proc2mem_command_2=BUS_STORE;
            proc2mem_data_0=k;
            proc2mem_data_1=k+1;
            proc2mem_data_2=k+2;
            proc2mem_size_0=WORD;
            proc2mem_size_1=WORD;
            proc2mem_size_2=WORD;
            @(negedge clock);
            CHECK_MEM(0,k,WORD);
            CHECK_MEM(4,k+1,WORD);
            CHECK_MEM(8,k+2,WORD);
        end
        //OVERWRITE TEST
        for(int k=0;k<16; k=k+1) begin
            proc2mem_addr_0=12;
            proc2mem_addr_1=12;
            proc2mem_addr_2=12;
            proc2mem_command_0=BUS_STORE;
            proc2mem_command_1=BUS_STORE;
            proc2mem_command_2=BUS_STORE;
            proc2mem_data_0=k;
            proc2mem_data_1=k+1;
            proc2mem_data_2=k+2;
            proc2mem_size_0=WORD;
            proc2mem_size_1=WORD;
            proc2mem_size_2=WORD;
            @(negedge clock);
            CHECK_MEM(12,k+2,WORD);
        end
        for(int k=0;k<16; k=k+1) begin
            proc2mem_addr_0=16;
            proc2mem_addr_1=16;
            proc2mem_addr_2=20;
            proc2mem_command_0=BUS_STORE;
            proc2mem_command_1=BUS_STORE;
            proc2mem_command_2=BUS_STORE;
            proc2mem_data_0=k;
            proc2mem_data_1=k+1;
            proc2mem_data_2=k+2;
            proc2mem_size_0=WORD;
            proc2mem_size_1=WORD;
            proc2mem_size_2=WORD;
            @(negedge clock);
            CHECK_MEM(16,k+1,WORD);
            CHECK_MEM(20,k+2,WORD);
        end
        for(int k=0;k<16; k=k+1) begin
            proc2mem_addr_0=24;
            proc2mem_addr_1=28;
            proc2mem_addr_2=28;
            proc2mem_command_0=BUS_STORE;
            proc2mem_command_1=BUS_STORE;
            proc2mem_command_2=BUS_STORE;
            proc2mem_data_0=k;
            proc2mem_data_1=k+1;
            proc2mem_data_2=k+2;
            proc2mem_size_0=WORD;
            proc2mem_size_1=WORD;
            proc2mem_size_2=WORD;
            @(negedge clock);
            CHECK_MEM(24,k,WORD);
            CHECK_MEM(28,k+2,WORD);
        end
        for(int k=0;k<16; k=k+1) begin
            proc2mem_addr_0=32;
            proc2mem_addr_1=36;
            proc2mem_addr_2=32;
            proc2mem_command_0=BUS_STORE;
            proc2mem_command_1=BUS_STORE;
            proc2mem_command_2=BUS_STORE;
            proc2mem_data_0=k;
            proc2mem_data_1=k+1;
            proc2mem_data_2=k+2;
            proc2mem_size_0=WORD;
            proc2mem_size_1=WORD;
            proc2mem_size_2=WORD;
            @(negedge clock);
            CHECK_MEM(36,k+1,WORD);
            CHECK_MEM(32,k+2,WORD);
        end

        //BYTE-ADDRESSING TEST
        for(int k=0;k<16; k=k+1) begin
            proc2mem_addr_0=40;
            proc2mem_addr_1=41;
            proc2mem_addr_2=42;
            proc2mem_command_0=BUS_STORE;
            proc2mem_command_1=BUS_STORE;
            proc2mem_command_2=BUS_STORE;
            proc2mem_data_0=k;
            proc2mem_data_1=k+1;
            proc2mem_data_2=k+2;
            proc2mem_size_0=BYTE;
            proc2mem_size_1=BYTE;
            proc2mem_size_2=BYTE;
            @(negedge clock);
            CHECK_MEM(40,k,BYTE);
            CHECK_MEM(41,k+1,BYTE);
            CHECK_MEM(42,k+2,BYTE);
        end
        for(int k=0;k<16; k=k+1) begin
            proc2mem_addr_0=40;
            proc2mem_addr_1=41;
            proc2mem_addr_2=42;
            proc2mem_command_0=BUS_STORE;
            proc2mem_command_1=BUS_STORE;
            proc2mem_command_2=BUS_STORE;
            proc2mem_data_0=k;
            proc2mem_data_1=k^15;
            proc2mem_data_2=k^7;
            proc2mem_size_0=BYTE;
            proc2mem_size_1=BYTE;
            proc2mem_size_2=BYTE;
            @(negedge clock);
            CHECK_MEM(40,k,BYTE);
            CHECK_MEM(41,k^15,BYTE);
            CHECK_MEM(42,k^7,BYTE);
        end
        //HALF-ADDRESSING TEST
        for(int k=0;k<16; k=k+1) begin
            proc2mem_addr_0=44;
            proc2mem_addr_1=46;
            proc2mem_addr_2=48;
            proc2mem_command_0=BUS_STORE;
            proc2mem_command_1=BUS_STORE;
            proc2mem_command_2=BUS_STORE;
            proc2mem_data_0=k;
            proc2mem_data_1=k^15;
            proc2mem_data_2=k^7;
            proc2mem_size_0=HALF;
            proc2mem_size_1=HALF;
            proc2mem_size_2=HALF;
            @(negedge clock);
            CHECK_MEM(44,k,HALF);
            CHECK_MEM(46,k^15,HALF);
            CHECK_MEM(48,k^7,HALF);
        end
        //DOUBLE-ADDRESSING TEST
        for(int k=0;k<16; k=k+1) begin
            proc2mem_addr_0=56;
            proc2mem_addr_1=64;
            proc2mem_addr_2=72;
            proc2mem_command_0=BUS_STORE;
            proc2mem_command_1=BUS_STORE;
            proc2mem_command_2=BUS_STORE;
            proc2mem_data_0=k;
            proc2mem_data_1=k^15;
            proc2mem_data_2=k^7;
            proc2mem_size_0=DOUBLE;
            proc2mem_size_1=DOUBLE;
            proc2mem_size_2=DOUBLE;
            @(negedge clock);
            CHECK_MEM(56,k,DOUBLE);
            CHECK_MEM(64,k^15,DOUBLE);
            CHECK_MEM(72,k^7,DOUBLE);
        end
        //FUZZING


	    show_mem_with_decimal(0,`MEM_64BIT_LINES - 1); 
        $finish;
	end

endmodule  // module testbench
