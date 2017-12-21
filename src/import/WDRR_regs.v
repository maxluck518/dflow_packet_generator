`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:10:25 11/28/2012 
// Design Name: 
// Module Name:     
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//////////////////////////////////////////////////////////////////////////////////
`define WDRR_BLOCK_ADDR           17'h00020
`define WDRR_BLOCK_ADDR_WIDTH     17
`define WDRR_REG_ADDR_WIDTH       6

module WDRR_regs
	#(
	  parameter AXI_DATA_WIDTH = 32,
	  parameter AXI_ADDR_WIDTH = 23,
	  parameter NUM_REG_USED = 4,
	  parameter REG_ADDR_WIDTH = `WDRR_REG_ADDR_WIDTH,
	  parameter QUEUES_NUM = 64,
	  parameter QUEUES_NUM_BIT = 6
	  
    )
	(
	  input                               			reg_req_in,
	  input                               			reg_rd_wr_L_in,
	  input [AXI_ADDR_WIDTH-1:0]     	 			reg_addr_in,
	  input [AXI_DATA_WIDTH-1:0]    	 			reg_wr_data,
	  
	  output reg                            		reg_ack_out,
	  output reg [AXI_DATA_WIDTH-1:0]  				reg_rd_data,
	  
	  output [AXI_DATA_WIDTH *QUEUES_NUM*4 -1:0] 	wr_regs,
	  input [AXI_DATA_WIDTH *QUEUES_NUM*4*2 -1:0] 	rd_regs,	  
	  
	  input                            				clk,
	  input                            				reset
	);
	
	reg  [AXI_DATA_WIDTH-1:0]               		reg_wr_file[QUEUES_NUM*4-1:0];
	wire [AXI_DATA_WIDTH-1:0]               		reg_rd_file[QUEUES_NUM*4*2-1:0];
	
	reg  [QUEUES_NUM_BIT*2-1:0]					  	wr_addr;
	reg  [QUEUES_NUM_BIT*2-1:0]					  	rd_addr;
	
	wire [`WDRR_BLOCK_ADDR_WIDTH-1:0]             	tag_addr;
	wire[REG_ADDR_WIDTH-1:0]                      	reg_addr;
	wire                                          	addr_good;
	wire                                          	tag_hit;

	//tag_addr is the block address of WDRR module,and reg_addr is the address of register that sw want to access
	assign tag_addr = reg_addr_in[AXI_ADDR_WIDTH-1:`WDRR_REG_ADDR_WIDTH];
	assign reg_addr = reg_addr_in[`WDRR_REG_ADDR_WIDTH-1:0];
	
	assign tag_hit = tag_addr == `WDRR_BLOCK_ADDR;
	assign addr_good = (reg_addr < NUM_REG_USED);
	
	genvar i;
	generate
		for(i=0; i<QUEUES_NUM*4; i=i+1) begin : rwregs
			assign wr_regs[AXI_DATA_WIDTH*(i+1)-1 : AXI_DATA_WIDTH*i] = reg_wr_file[i];
			assign reg_rd_file[i] = rd_regs[AXI_DATA_WIDTH*(i+1)-1 : AXI_DATA_WIDTH*i];
			assign reg_rd_file[i+QUEUES_NUM*4] = rd_regs[AXI_DATA_WIDTH*(i+1+QUEUES_NUM*4)-1 : AXI_DATA_WIDTH*(QUEUES_NUM*4+i)];
		end
	endgenerate
	
	always @(posedge clk) begin
		if(reset) begin
			reg_rd_data <= 0;
			reg_ack_out <= 0;
			rd_addr <= 0;
		end
		else begin
			if(reg_req_in && tag_hit)begin
				reg_ack_out <= 1;
				if(addr_good) begin
					if(!reg_rd_wr_L_in) begin
						if(reg_addr == 0) wr_addr <= reg_wr_data;
						else if(reg_addr == 1) rd_addr <= reg_wr_data;
						else reg_wr_file[wr_addr] <= reg_wr_data;
					end
					else
						reg_rd_data <= reg_rd_file[rd_addr];
				end
				else 
				reg_rd_data <= 32'hdead_beef;
				
			end
			else begin
				reg_rd_data <= reg_wr_data;
				reg_ack_out <= 0;
			end
		end//end if(reset) else
	end//end always
endmodule
