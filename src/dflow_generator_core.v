 /*
 *
  *     dflow test
  *     5-tuple generator
  *     mjw
  *
  */

module dflow_generator
#(

  parameter ACTION_TUPLE_WIDTH     = 128,
  parameter PKT_TUPLE_WIDTH        = 104,
  parameter PKT_LEN_WIDTH          = 16,
  parameter MEM_SIZE               = 16,

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
  parameter SIM_ONLY             = 0,
  parameter REPLAY_COUNT_WIDTH   = 32,
  parameter REPLAY_COUNT         = 2
)

(
    // system signals
    input             							        qdr_clk,
    input                                               resetn,

    // controll signals
	input                                               sw_rst,
    input                                               start_replay,
    output                                              compelete_replay,
    input                                               start_store,

    // addr signals
    input  [QDR_ADDR_WIDTH-1:0]                         mem_addr_low,
    input  [QDR_ADDR_WIDTH-1:0]                         mem_addr_high,
    
    // QDR Memory Interface  
    input             							        init_calib_complete,	  
    output            							        user_app_wr_cmd,
    output [QDR_ADDR_WIDTH-1:0]     				    user_app_wr_addr,
    output [QDR_DATA_WIDTH*QDR_BURST_LENGTH-1:0]        user_app_wr_data,
    output            							        user_app_rd_cmd,
	output [QDR_ADDR_WIDTH-1:0]                         user_app_rd_addr,
	input  [QDR_DATA_WIDTH*QDR_BURST_LENGTH-1:0]        user_app_rd_data,
    input             							        user_app_rd_valid,

    // dflow info input Interface
    input  [PKT_TUPLE_WIDTH-1:0]                        fivetuple_data_in,
    input  [PKT_LEN_WIDTH-1:0]                          pkt_len_in,
    input                                               tuple_in_vld,
    output                                              tuple_in_ready,

    // dflow info output Interface
    output   [ACTION_TUPLE_WIDTH-1:0]                   fivetuple_data_out,
    output   [PKT_LEN_WIDTH-1:0]                        pkt_len_out,
    output                                              tuple_out_vld,
    input                                               tuple_out_ready

);

    /* upstream plane */
    assign tuple_in_ready        = ~fifo_inqueue_nearly_full;

    // link to axi bus
//    assign  sw_rst           = rw_regs[(C_S_AXI_DATA_WIDTH*0)+1-1:(C_S_AXI_DATA_WIDTH*0)];
//    assign  start_store      = rw_regs[(C_S_AXI_DATA_WIDTH*1)+1-1:(C_S_AXI_DATA_WIDTH*1)];
//    assign  start_replay     = rw_regs[(C_S_AXI_DATA_WIDTH*2)+1-1:(C_S_AXI_DATA_WIDTH*2)];
//    assign  compelete_replay = rw_regs[(C_S_AXI_DATA_WIDTH*3)+1-1:(C_S_AXI_DATA_WIDTH*3)];
    
    /* inqueue */
    wire  [PKT_TUPLE_WIDTH+PKT_LEN_WIDTH-1:0]          fifo_inqueue_data;
    wire                                               fifo_inqueue_rd_en;
    wire                                               fifo_inqueue_nearly_full;
    wire                                               fifo_inqueue_empty;
    /* outqueue */
    wire  [PKT_TUPLE_WIDTH+PKT_LEN_WIDTH-1:0]          fifo_outqueue_data;
    wire                                               fifo_outqueue_wr_en;
    wire                                               fifo_outqueue_nearly_full;

    inqueue # (
        .ACTION_TUPLE_WIDTH(128),
        .PKT_TUPLE_WIDTH(104),
        .PKT_LEN_WIDTH(16)           
    )
    inqueue_inst
    (

        /* system clock */
        .clk                     (qdr_clk),
        .resetn                  (resetn),
                                
        /* pkt plane */          
        .fivetuple_data_in       (fivetuple_data_in),
        .pkt_len_in              (pkt_len_in),
        .tuple_in_vld            (tuple_in_vld),
        .tuple_in_ready          (tuple_in_ready),
                                 
        /* fifo plane */         
        .fifo_data_out           (fifo_inqueue_data),
        .fifo_rd_en              (fifo_inqueue_rd_en),
        // .fifo_wr_en              (),
        .fifo_nearly_full        (fifo_inqueue_nearly_full),
        .fifo_empty              (fifo_inqueue_empty)
    );

    wire  [QDR_ADDR_WIDTH-1:0]               dflow_mem_high_store; 

	fifo_to_mem #(
		.FIFO_DATA_WIDTH      		(PKT_LEN_WIDTH+PKT_TUPLE_WIDTH),
		.MEM_ADDR_WIDTH       		(QDR_ADDR_WIDTH),
		.MEM_DATA_WIDTH       		(QDR_DATA_WIDTH*QDR_BURST_LENGTH)
	)
	  fifo_to_mem_inst
	(
	    .clk								(qdr_clk),
		.rst								(~resetn),
                          		
	    .fifo_rd_en							(fifo_inqueue_rd_en),
	    .fifo_data							(fifo_inqueue_data),
	    .fifo_empty							(fifo_inqueue_empty),
		                      		
	    .app_wr_cmd                     	(user_app_wr_cmd),
		.app_wr_data                    	(user_app_wr_data),
		.app_wr_addr                    	(user_app_wr_addr),
		.cal_done							(init_calib_complete),
         //****************************wrl  rewrite******************** 
		.start_store                        (start_store),
	    .sw_rst								(sync_sw_rst),	
         //********************************************************************		
	    .dflow_addr_low                     (mem_addr_low),
	    .dflow_addr_high                    (mem_addr_high),
	    .dflow_mem_high                     (dflow_mem_high_store)
	);

	mem_to_fifo #(
		.FIFO_DATA_WIDTH      (PKT_LEN_WIDTH+PKT_TUPLE_WIDTH),
		.MEM_ADDR_WIDTH       (QDR_ADDR_WIDTH),
		.MEM_DATA_WIDTH       (QDR_DATA_WIDTH*QDR_BURST_LENGTH),
		.REPLAY_COUNT_WIDTH   (REPLAY_COUNT_WIDTH),
        .REPLAY_COUNT         (REPLAY_COUNT)
	)
		mem_to_fifo_inst
	(
		.clk							(qdr_clk),
		.rst							(~resetn),
	                      	
		.app_rd_cmd                     (user_app_rd_cmd),
		.app_rd_addr                    (user_app_rd_addr),
		.app_rd_data                    (user_app_rd_data),
		.app_rd_valid                   (user_app_rd_valid),
		
        .fifo_wr_en					    (fifo_outqueue_wr_en),
        .fifo_data					    (fifo_outqueue_data),
        .fifo_nearly_full               (fifo_outqueue_nearly_full),
		
		//**************************wrl  rewrite********************
		.start_replay                   (start_replay),
		.compelete_replay               (compelete_replay),
			                  	
	    .sw_rst							(sync_sw_rst),
		//**********************************************************
		
		.cal_done						(init_calib_complete),
	    .dflow_mem_low                  (mem_addr_low),
	    .dflow_mem_high                 (dflow_mem_high_store)
	);


    outqueue # (
        .ACTION_TUPLE_WIDTH(128),
        .PKT_TUPLE_WIDTH(104),
        .PKT_LEN_WIDTH(16)           
    )
    outqueue_inst
    (
        /* system clock */
        .clk                     (qdr_clk), 
        .resetn                  (resetn), 
                             
        /* fifo plane */         
        .fifo_data_in            (fifo_outqueue_data),
        .fifo_wr_en              (fifo_outqueue_wr_en),
        .fifo_nearly_full        (fifo_outqueue_nearly_full),

        /* pkt plane */          
        .fivetuple_data_out      (fivetuple_data_out),
        .pkt_len_out             (pkt_len_out),
        .tuple_out_vld           (tuple_out_vld),
        .tuple_out_ready         (tuple_out_ready)
    );

    endmodule
