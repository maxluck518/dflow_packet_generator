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
	  parameter AXI_ADDR_WIDTH = 26,
	  parameter NUM_REQ_REG_USED = 8,
	  parameter NUM_RESP_REG_USED = 2,
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
	  
	  output [AXI_DATA_WIDTH *NUM_REQ_REG_USED -1:0] rw_regs,                  
      input                                  compelete_store,
      input                                  compelete_replay,
	  
	  input                                  clk,
	  input                                  reset
	);
	
	function integer log2;
      	input integer number;
      	begin
        	log2=0;
         	while(2**log2<number) begin
            		log2=log2+1;
         	end
      	end
   	endfunction // log2

	(*MARK_DEBUG="true"*)reg  [AXI_DATA_WIDTH-1:0]                     req_reg_file[log2(NUM_REQ_REG_USED*4)-1:0];
	(*MARK_DEBUG="true"*)reg  [AXI_DATA_WIDTH-1:0]                     resp_reg_file[log2(NUM_RESP_REG_USED*4)-1:0];
	(*MARK_DEBUG="true"*)wire [`REPLAY_UENGINE_BLOCK_ADDR_WIDTH-1:0]   tag_addr;
	(*MARK_DEBUG="true"*)wire[REG_ADDR_WIDTH-1:0]                      reg_addr;
	(*MARK_DEBUG="true"*)wire                                          addr_req_good;
	(*MARK_DEBUG="true"*)wire                                          addr_resp_good;
	(*MARK_DEBUG="true"*)wire                                          tag_hit;
    (*MARK_DEBUG="true"*)wire                                          addr_req_hit; 
    (*MARK_DEBUG="true"*)wire                                          addr_resp_hit;
    (*MARK_DEBUG="true"*)wire [1:0]                                    resp_op;

	//tag_addr is the block address of CUTTER module,and reg_addr is the address of register that sw want to access
	assign tag_addr = reg_addr_in[AXI_ADDR_WIDTH-1:`REPLAY_UENGINE_REG_ADDR_WIDTH];
	assign reg_addr = reg_addr_in[`REPLAY_UENGINE_REG_ADDR_WIDTH-1:0];
	
	assign tag_hit = tag_addr == REPLAY_UENGINE_BLOCK_ADDR;
	assign addr_req_good = reg_addr <= NUM_REQ_REG_USED;
	assign addr_resp_good = reg_addr <= NUM_RESP_REG_USED;
    assign addr_req_hit = tag_hit && (reg_addr_in[25:23] == 3'b000);
    assign addr_resp_hit = tag_hit && (reg_addr_in[25:23] == 3'b001);
    assign resp_op = {compelete_replay,compelete_store};
	
	genvar i;
	
	generate
		for(i=0; i<NUM_REQ_REG_USED; i=i+1) begin : reqregs
			assign rw_regs[AXI_DATA_WIDTH*(i+1)-1 : AXI_DATA_WIDTH*i] = req_reg_file[i*4+3];
		end
    endgenerate

	always @(*) begin
        case(resp_op) 
                2'b00: begin
                    resp_reg_file[0] = 32'h00000000;
                    resp_reg_file[1] = 32'h00000000;
                end
                2'b01: begin
                    resp_reg_file[0] = 32'h00000001;
                    resp_reg_file[1] = 32'h00000000;
                end
                2'b10: begin
                    resp_reg_file[0] = 32'h00000000;
                    resp_reg_file[1] = 32'h00000001;
                end
                2'b11: begin
                    resp_reg_file[0] = 32'h00000001;
                    resp_reg_file[1] = 32'h00000001;
                end
        endcase
    end
	
	always @(posedge clk) begin
		if(reset) begin
			reg_rd_data <= 0;
			reg_ack_out <= 0;
		end
		else begin
			if(reg_req_in && addr_req_hit)begin
				reg_ack_out <= 1;
				if(addr_req_good) begin
					if(!reg_rd_wr_L_in)
						req_reg_file[reg_addr] <= reg_wr_data;
					else	
						reg_rd_data <= req_reg_file[reg_addr];
				end
				else 
				reg_rd_data <= 32'hdead_beef;
				
			end
			else if(reg_req_in && addr_resp_hit)begin
				reg_ack_out <= 1;
				if(addr_resp_good) begin
					if(reg_rd_wr_L_in)
						reg_rd_data <= resp_reg_file[reg_addr];
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
