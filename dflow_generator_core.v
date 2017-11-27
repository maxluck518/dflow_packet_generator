 /*
 *
  *     dflow test
  *     5-tuple generator
  *     mjw
  *
  */

module dflow_generator
#(
  parameter C_S_AXI_DATA_WIDTH   = 32,
  parameter C_S_AXI_ADDR_WIDTH   = 32,
  parameter C_BASEADDR           = 32'hFFFFFFFF,
  parameter C_HIGHADDR           = 32'h00000000,
  parameter C_USE_WSTRB          = 0,
  parameter C_DPHASE_TIMEOUT     = 0,
  parameter C_S_AXI_ACLK_FREQ_HZ = 100,
  parameter C_M_AXIS_DATA_WIDTH  = 256,
  parameter C_S_AXIS_DATA_WIDTH  = 256,
  parameter C_M_AXIS_TUSER_WIDTH = 128,
  parameter C_S_AXIS_TUSER_WIDTH = 128,
  parameter C_NUM_QUEUES         = 4,
  parameter DST_PORT_POS         = 0,
  parameter QDR_NUM_CHIPS        = 2,
  parameter QDR_DATA_WIDTH       = 36,
  parameter QDR_ADDR_WIDTH       = 19,
  parameter QDR_BW_WIDTH         = 4,
  parameter QDR_CQ_WIDTH         = 1,
  parameter QDR_CLK_WIDTH        = 1,
  parameter QDR_BURST_LENGTH     = 4,
  parameter QDR_CLK_PERIOD       = 4000,
  parameter REPLAY_COUNT_WIDTH   = 32,
  parameter SIM_ONLY             = 0,
  parameter PKT_TUPLE_WIDTH      = 104
)

(
    // register bus decode
    input             							 reg_req,
    input             							 reg_rd_wr_L,
    input [31:0]      							 reg_addr,
    input [31:0]      							 reg_wr_data,
    output            							 reg_ack,
    output [31:0]								 reg_rd_data,
    
    // QDR Memory Interface  
    input             							  init_calib_complete,	  
    output            							  user_app_wr_cmd0,
    output [18:0]     							  user_app_wr_addr0,
    output            							  user_app_rd_cmd0,
    output [18:0]     							  user_app_rd_addr0,
    output [143:0] 								  user_app_wr_data0,
    input             							  user_app_rd_valid0,
    input [143:0]							      user_app_rd_data0,
    input             							  qdr_clk,

    // dflow info input Interface
    input                                           fivetuple_data_in,
    input                                           pkt_len_in,
    input                                           tuple_in_vld,
    output                                          tuple_in_ready,

    // dflow info output Interface
    output                                          fivetuple_data_out,
    output                                          pkt_len_out,
    output                                          tuple_out_vld,
    input                                           tuple_out_ready
);

    /* upstream plane */
    assign tuple_in_READY        = ~inqueue_fifo_nearly_full;

    /* inqueue */
    fallthrough_small_fifo_v2 #
    (.WIDTH(PKT_TUPLE_WIDTH+16),
     .MAX_DEPTH_BITS(10))
      inqueue_fifo
        (.din           ({inqueue_fifo_in_pkt_fivetuple,inqueue_fifo_in_pkt_len}),  // Data in
         .wr_en         (inqueue_fifo_wr_en),             // Write enable
         .rd_en         (inqueue_fifo_rd_en),    // Read the next word
         .dout          ({inqueue_fifo_out_pkt_fivetuple,inqueue_fifo_out_pkt_len}),
         .full          (),
         .nearly_full   (inqueue_fifo_nearly_full),
         .prog_full     (),
         .empty         (inqueue_fifo_empty),
         .reset         (~resetn),
         .clk           (clk)
         );

    localparam  NUM_RW_REGS = 4;

	wire [NUM_RW_REGS*C_S_AXI_DATA_WIDTH-1:0]   	rw_regs;
	wire                                            sw_rst;
    wire                                            start_reply;
    wire                                            compelete_reply;
    wire                                            start_store;

    assign  sw_rst           = rw_regs[(C_S_AXI_DATA_WIDTH*0)+1-1:(C_S_AXI_DATA_WIDTH*0)];
    assign  start_store      = rw_regs[(C_S_AXI_DATA_WIDTH*1)+1-1:(C_S_AXI_DATA_WIDTH*1)];
    assign  start_replay     = rw_regs[(C_S_AXI_DATA_WIDTH*2)+1-1:(C_S_AXI_DATA_WIDTH*2)];
    assign  compelete_replay = rw_regs[(C_S_AXI_DATA_WIDTH*3)+1-1:(C_S_AXI_DATA_WIDTH*3)];

	//--------------------------------------------------
    //
    // --- cutter disabled
    //--------------------------------------------------  
	 genevr_pipeline_regs #  
	(
		.NUM_REG_USED(4)
	)
	pipeline_regs_inst
	(
	  .reg_req_in            (reg_req),
	  .reg_rd_wr_L_in        (reg_rd_wr_L),
	  .reg_addr_in           (reg_addr),
	  .reg_wr_data           (reg_wr_data),
	  
	  .reg_ack_out           (reg_ack),
	  .reg_rd_data           (reg_rd_data),
	  
	  .rw_regs               (rw_regs),
		  
	  .clk                   (s_axi_aclk), 
      .reset                 (~axi_aresetn)
    );

	fifo_to_mem #(
		.FIFO_DATA_WIDTH      		(QDR_DATA_WIDTH*QDR_BURST_LENGTH),
		.NUM_QUEUES                 (C_NUM_QUEUES),
		.MEM_ADDR_WIDTH       		(QDR_ADDR_WIDTH),
		.MEM_DATA_WIDTH       		(QDR_DATA_WIDTH*QDR_BURST_LENGTH),
		.MEM_BW_WIDTH         		(QDR_BW_WIDTH),
		.MEM_BURST_LENGTH			(QDR_BURST_LENGTH)    
	)
	  fifo_to_mem_inst
	(
	    .clk								(qdr_clk),
		.rst								(~axi_aresetn),
                          		
	    .fifo_rd_en							(fifo_wr_rd_en),
	    .fifo_data							(fifo_wr_data),
	    .fifo_empty							(fifo_wr_empty),
		                      		
	    .app_wr_cmd                     	(user_app_wr_cmd),
		.app_wr_data                    	(user_app_wr_data),
		.app_wr_addr                    	(user_app_wr_addr),
		.mem_addr_high						(mem_addr_high),
         //****************************wrl  rewrite******************** 
		.start_store                        (start_store),
                          		
	    .sw_rst								(sync_sw_rst),	
         //********************************************************************		
		.cal_done							(init_calib_complete)
	);

	mem_to_fifo #(
		.NUM_QUEUES     	  (C_NUM_QUEUES),
		.FIFO_DATA_WIDTH      (QDR_DATA_WIDTH*QDR_BURST_LENGTH),
		.MEM_ADDR_WIDTH       (QDR_ADDR_WIDTH),
		.MEM_DATA_WIDTH       (QDR_DATA_WIDTH*QDR_BURST_LENGTH),
		.MEM_BW_WIDTH         (QDR_BW_WIDTH),
		.MEM_BURST_LENGTH	  (QDR_BURST_LENGTH),
		.REPLAY_COUNT_WIDTH   (REPLAY_COUNT_WIDTH),
		.SIM_ONLY			  (SIM_ONLY)
	)
		mem_to_fifo_inst
	(
		.clk							(qdr_clk),
		.rst							(~axi_aresetn),
	                      	
		.app_rd_cmd                     (user_app_rd_cmd),
		.app_rd_addr                    (user_app_rd_addr),
		.app_rd_data                    (user_app_rd_data),
		.app_rd_valid                   (user_app_rd_valid),
		.mem_addr_high					(mem_addr_high),
		
        .fifo_wr_en					    (fifo_rd_wr_en),
        .fifo_data					    (fifo_rd_data),
        .fifo_full					    (fifo_rd_full),
		
		//**************************wrl  rewrite********************
		.start_replay                   (start_replay),
		.compelete_replay               (compelete_replay),
			                  	
	    .sw_rst							(sync_sw_rst),
		//**********************************************************
		
		.cal_done						(init_calib_complete)
	);

    endmodule
