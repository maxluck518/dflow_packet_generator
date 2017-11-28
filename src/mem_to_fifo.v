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
	parameter REPLAY_COUNT         = 2
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
	
	//*****************************wrl rewrite**************************
	output reg                              fifo_wr_en,
    output reg [FIFO_DATA_WIDTH-1:0]        fifo_data,
	input                           		fifo_neadly_full,

    // Misc
	input									start_replay,
	output                                  compelete_replay,
	input                             		sw_rst,

	//******************************************************************
	
	input [MEM_ADDR_WIDTH-1:0]  			dflow_mem_low,
	input [MEM_ADDR_WIDTH-1:0]  			dflow_mem_high,
	input									cal_done
);

    reg									    replay_count;
    wire                                    wr_en;

    assign  wr_en = fifo_nearly_full && cal_done; 
    assign  compelete_replay = if(replay_count == 0) 1:0;

    always @ (posedge clk) begin
        if(rst || sw_rst) begin
            mem_ad_rd_r      <= q0_addr_low;
            replay_count_r   <= q0_replay_count;
            compelete_replay <= 0;
            replay_count     <= REPLAY_COUNT;
        end
        else if(start_replay) begin
            if (replay_count >0) begin
                if (mem_ad_rd_r >= dflow_mem_high) begin
                    mem_ad_rd_r  <= dflow_mem_low;
                    replay_count <= replay_count-1;
                end
                else	begin
                    if(wr_en) begin
                        mem_ad_rd_r  <= mem_ad_rd_r+1;
                        app_rd_addr  <= mem_ad_rd_r;
                        app_rd_cmd   <= 1;
                    end
                    else
                        app_rd_cmd   <= 0;
                end													
            end
        end
        else begin
            app_rd_cmd   <= 0;
        end
    end

    /* fifo plane */
    always @ (posedge clk) begin
        if(rst || sw_rst) begin
            fifo_wr_en      <= 0;
            fifo_data       <= 0;
        end
        else begin
            if(app_rd_valid) begin
                fifo_wr_en  <= wr_en;
                fifo_data   <= app_rd_data;
            end
            else begin
                fifo_wr_en  <= 0;
                fifo_data   <= 0;
            end
        end
    end

    endmodule
