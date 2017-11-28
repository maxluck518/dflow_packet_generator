 /*
 *
  *     dflow test
  *     5-tuple generator
  *     mjw
  *
  */

module mem_to_fifo
#(
	parameter NUM_QUEUES       		= 4,
	parameter NUM_QUEUES_BITS 		= 2,
    parameter FIFO_DATA_WIDTH      = 144,
	parameter MEM_ADDR_WIDTH       = 19,
	parameter MEM_DATA_WIDTH       = 144,
	parameter MEM_BW_WIDTH         = 4,
	parameter MEM_BURST_LENGTH	   = 4,
	parameter MEM_ADDR_LOW         = 0,
	parameter REPLAY_COUNT_WIDTH   = 32,
	parameter SIM_ONLY			   = 0
)
(
    // Global Ports
    input                             		clk,
	input							  		rst,

	// Memory Ports
	output reg                            	app_rd_cmd,
	output reg [MEM_ADDR_WIDTH-1:0]         app_rd_addr,
	input      [MEM_DATA_WIDTH-1:0] 		app_rd_data,
	input									app_rd_valid,
	input                                   mem_addr_high,
	
	//*****************************wrl rewrite**************************
	output reg                              q0_fifo_wr_en,
    output reg [FIFO_DATA_WIDTH-1:0]        q0_fifo_data,
    input                           		q0_fifo_full,
	input                           		q0_fifo_prog_full,

    // Misc
	input									start_replay,
	input                             		sw_rst,

	//******************************************************************
	
	input [MEM_ADDR_WIDTH-1:0]  			q0_mem_high,
		
	input									cal_done
);

