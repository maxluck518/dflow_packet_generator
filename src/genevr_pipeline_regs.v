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
`define REPLAY_UENGINE_BLOCK_ADDR_WIDTH     17
`define REPLAY_UENGINE_REG_ADDR_WIDTH       6
module genevr_pipeline_regs
	#(
	  parameter AXI_DATA_WIDTH = 32,
	  parameter AXI_ADDR_WIDTH = 23,
	  parameter NUM_REG_USED = 4,
	  parameter REG_ADDR_WIDTH = `REPLAY_UENGINE_REG_ADDR_WIDTH,
	  parameter REPLAY_UENGINE_BLOCK_ADDR = 17'h10017
	  
    )
	(
	  input                               	 reg_req_in,
	  input                               	 reg_rd_wr_L_in,
	  input [AXI_ADDR_WIDTH -1:0]     	     reg_addr_in,
	  input [AXI_DATA_WIDTH-1:0]    	     reg_wr_data,
	  
	  output reg                             reg_ack_out,
	  output reg [AXI_DATA_WIDTH-1:0]        reg_rd_data,
	  
	  output [AXI_DATA_WIDTH *NUM_REG_USED -1:0] rw_regs,                  
	  
	  input                            clk,
	  input                            reset
	);
	
	reg  [AXI_DATA_WIDTH-1:0]                     reg_file[NUM_REG_USED-1:0];
	wire [`REPLAY_UENGINE_BLOCK_ADDR_WIDTH-1:0]   tag_addr;
	wire[REG_ADDR_WIDTH-1:0]                      reg_addr;
	wire                                          addr_good;
	wire                                          tag_hit;

	//tag_addr is the block address of CUTTER module,and reg_addr is the address of register that sw want to access
	assign tag_addr = reg_addr_in[AXI_ADDR_WIDTH-1:`REPLAY_UENGINE_REG_ADDR_WIDTH];
	assign reg_addr = reg_addr_in[`REPLAY_UENGINE_REG_ADDR_WIDTH-1:0];
	
	assign tag_hit = tag_addr == REPLAY_UENGINE_BLOCK_ADDR;
	assign addr_good = reg_addr <= NUM_REG_USED;
	
	genvar i;
	
	generate
		for(i=0; i<NUM_REG_USED; i=i+1) begin : rwregs
			assign rw_regs[AXI_DATA_WIDTH*(i+1)-1 : AXI_DATA_WIDTH*i] = reg_file[i];
		end
	endgenerate
	
	always @(posedge clk) begin
		if(reset) begin
			reg_rd_data <= 0;
			reg_ack_out <= 0;
		end
		else begin
			if(reg_req_in && tag_hit)begin
				reg_ack_out <= 1;
				if(addr_good) begin
					if(!reg_rd_wr_L_in)
						reg_file[reg_addr] <= reg_wr_data;
					else	
						reg_rd_data <= reg_file[reg_addr];
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
