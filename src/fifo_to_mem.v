 /*
 *
  *     dflow test
  *     5-tuple generator
  *     mjw
  *
  */

module fifo_to_mem
#(
    parameter FIFO_DATA_WIDTH      = 144,
	parameter MEM_ADDR_WIDTH       = 19,
	parameter MEM_DATA_WIDTH       = 144,
	parameter MEM_BW_WIDTH         = 4,
	parameter MEM_BURST_LENGTH	   = 4,
	parameter MEM_ADDR_LOW         = 0
)
(
    // Global Ports
    input                             		clk,
	input							  		rst,
		
    // FIFO Ports
    output 	                        		fifo_rd_en,
    input [FIFO_DATA_WIDTH-1:0]       		fifo_data,
    input                             		fifo_empty,
	
	// Memory Ports
	output reg                            	app_wr_cmd,
	output reg [MEM_ADDR_WIDTH-1:0]         app_wr_addr,
	output reg [MEM_DATA_WIDTH-1:0] 		app_wr_data,

	// Misc
	input [MEM_ADDR_WIDTH-1:0]  			dflow_addr_low,
	input [MEM_ADDR_WIDTH-1:0]  			dflow_addr_high,
	output [MEM_ADDR_WIDTH-1:0]  			dflow_mem_high,
    
    // control signals
    input                                   start_store,
	input									cal_done,
	input                                   sw_rst
);

	reg [MEM_ADDR_WIDTH-1:0] 			    mem_ad_wr_r;
	reg                                     mem_wr_cmd; 

	assign  fifo_rd_en     = !fifo_empty && cal_done;
    assign  dflow_mem_high = mem_addr_wr;

    always @ (posedge clk) begin
      if(rst || sw_rst) begin
      		app_wr_data  <= {MEM_DATA_WIDTH{1'b0}};
      		app_wr_addr  <= MEM_ADDR_LOW;
			mem_addr_wr  <= dflow_addr_low;
      end
      else if(start_store) begin
		    app_wr_data <= fifo_data;
		    app_wr_cmd  <= fifo_rd_en;
            app_wr_addr <= mem_addr_wr;
            if (!fifo_empty && cal_done) begin
                if (mem_addr_wr == (dflow_addr_high-1)) 
                    mem_wr_cmd  <= 0;
                else	begin
                    mem_addr_wr <= mem_addr_wr + 1;
                end
            end
        end
        else begin
      		app_wr_data  <= {MEM_DATA_WIDTH{1'b0}};
      		app_wr_addr  <= MEM_ADDR_LOW;
		    app_wr_cmd  <= 0;
        end
    end

    endmodule
