 /*
 *
  *     dflow test
  *     5-tuple generator
  *     mjw
  *
  */

module dflow_generator
#(
    parameter ACTION_TUPLE_WIDTH = 128,
    parameter PKT_TUPLE_WIDTH    = 104,
    parameter PKT_LEN_WIDTH      = 16,
    parameter MEM_SIZE           = 16,
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 32,
    parameter QDR_NUM_CHIPS      = 2,
    parameter QDR_DATA_WIDTH     = 36,
    parameter QDR_ADDR_WIDTH     = 19,
    parameter QDR_BW_WIDTH       = 4,
    parameter QDR_CQ_WIDTH       = 1,
    parameter QDR_CLK_WIDTH      = 1,
    parameter QDR_BURST_LENGTH   = 4,
    parameter QDR_CLK_PERIOD     = 4000
)
(
    /* system clk */
    input                               clk,
    input                               resetn,
    
    //AXI-lite Slave interface
    input                               s_axi_aclk,
    input                               s_axi_aresetn,
    // Write address channel
    input [31:0]                        s_axi_awaddr,
    input [2:0]                         s_axi_awprot,
    input                               s_axi_awvalid,
    output                              s_axi_awready,
    // Write Data Channel
    input [31:0]                        s_axi_wdata, 
    input [3:0]                         s_axi_wstrb,
    input                               s_axi_wvalid,
    output                              s_axi_wready,
    // Write Response Channel
    output [1:0]                        s_axi_bresp,
    output                              s_axi_bvalid,
    input                               s_axi_bready,
    // Read Address channel
    input [31:0]                        s_axi_araddr,
    input [2:0]                         s_axi_arprot,
    input                               s_axi_arvalid,
    output                              s_axi_arready,
    // Read Data Channel
    output [31:0]                       s_axi_rdata,
    output [1:0]                        s_axi_rresp,
    output                              s_axi_rvalid,
    input                               s_axi_rready,

    // QDR Memory Interface  
    input             				    init_calib_complete,	  
    output            				    user_app_wr_cmd0,
    output [18:0]     				    user_app_wr_addr0,
    output            				    user_app_rd_cmd0,
    output [18:0]     				    user_app_rd_addr0,
    output [143:0] 					    user_app_wr_data0,
    input             				    user_app_rd_valid0,
    input [143:0]                       user_app_rd_data0,
    input             				    qdr_clk,

    // dflow info input Interface
    input   [ACTION_TUPLE_WIDTH-1:0]    tuple_in_transtuple_DATA,
    input                               tuple_in_transtuple_VALID,
    input   [PKT_TUPLE_WIDTH-1:0]       tuple_in_fivetuple_DATA,
    output                              tuple_in_ready,

    // dflow info output Interface
    output   [ACTION_TUPLE_WIDTH-1:0]   tuple_out_transtuple_DATA,
    output                              tuple_out_transtuple_VALID,
    output   [PKT_TUPLE_WIDTH-1:0]      tuple_out_fivetuple_DATA,
    input                               tuple_out_ready

);
    // modify interface 
    (*MARK_DEBUG="true"*)wire  [PKT_TUPLE_WIDTH-1:0]         fivetuple_data_in;
    (*MARK_DEBUG="true"*)wire  [PKT_LEN_WIDTH-1:0]           pkt_len_in;
    (*MARK_DEBUG="true"*)wire                                tuple_in_vld;
    (*MARK_DEBUG="true"*)wire   [ACTION_TUPLE_WIDTH-1:0]     fivetuple_data_out;
    (*MARK_DEBUG="true"*)wire   [PKT_LEN_WIDTH-1:0]          pkt_len_out;
    (*MARK_DEBUG="true"*)reg                                 tuple_out_vld;

    assign  fivetuple_data_in        = tuple_in_fivetuple_DATA;
    assign  pkt_len_in               = tuple_in_transtuple_DATA[15:0];
    assign  tuple_in_vld             = tuple_in_transtuple_VALID;
    assign  tuple_out_fivetuple_DATA = fivetuple_data_out;
    assign  tuple_out_transtuple_DATA[PKT_LEN_WIDTH-1:0]                  = pkt_len_out;
    assign  tuple_out_transtuple_DATA[ACTION_TUPLE_WIDTH-1:PKT_LEN_WIDTH] = 0;
    assign  tuple_out_transtuple_VALID = tuple_out_vld;

   // register bus decode
    wire              					reg_req;
	wire              					reg_rd_wr_L;
	wire [31:0]       					reg_addr;
	wire [31:0]       					reg_wr_data;
	wire              					reg_ack;
	wire [31:0]       					reg_rd_data;

 //------------------------------------------------------------
   //register access
   //------------------------------------------------------------
    axi_to_reg_bus axi_to_reg_bus (
		.s_axi_awaddr     (s_axi_awaddr), 
		.s_axi_awprot     (s_axi_awprot), 
		.s_axi_awvalid    (s_axi_awvalid), 
		.s_axi_awready    (s_axi_awready), 
      
		.s_axi_wdata      (s_axi_wdata), 
		.s_axi_wstrb      (s_axi_wstrb), 
		.s_axi_wvalid     (s_axi_wvalid), 
		.s_axi_wready     (s_axi_wready), 
      
		.s_axi_bresp      (s_axi_bresp), 
		.s_axi_bvalid     (s_axi_bvalid), 
		.s_axi_bready     (s_axi_bready), 
      
		.s_axi_araddr     (s_axi_araddr), 
		.s_axi_arprot     (s_axi_arprot), 
		.s_axi_arvalid    (s_axi_arvalid), 
		.s_axi_arready    (s_axi_arready),
      
		.s_axi_rdata      (s_axi_rdata), 
		.s_axi_rresp      (s_axi_rresp), 
		.s_axi_rvalid     (s_axi_rvalid), 
		.s_axi_rready     (s_axi_rready), 
      
		.reg_req          (reg_req), 
		.reg_rd_wr_L      (reg_rd_wr_L), 
		.reg_addr         (reg_addr), 
		.reg_wr_data      (reg_wr_data), 
		.reg_ack          (reg_ack), 
		.reg_rd_data      (reg_rd_data),  
      
		.s_axi_aclk       (s_axi_aclk),
		.s_axi_aresetn    (s_axi_aresetn),
		.reset            (~resetn), 
		.clk              (clk)
	);

    localparam NUM_RW_REGS = 6;

	wire [NUM_RW_REGS*C_S_AXI_DATA_WIDTH-1:0]               rw_regs;
	(*MARK_DEBUG="true"*)wire                                                    sw_rst;
    (*MARK_DEBUG="true"*)wire                                                    start_replay;
    (*MARK_DEBUG="true"*)wire                                                    compelete_replay;
    (*MARK_DEBUG="true"*)wire                                                    start_store;
    (*MARK_DEBUG="true"*)wire [QDR_ADDR_WIDTH-1:0]                               mem_addr_low;
    (*MARK_DEBUG="true"*)wire [QDR_ADDR_WIDTH-1:0]                               mem_addr_high;

    assign  sw_rst           = rw_regs[(C_S_AXI_DATA_WIDTH*0)+1-1:(C_S_AXI_DATA_WIDTH*0)];
    assign  start_store      = rw_regs[(C_S_AXI_DATA_WIDTH*1)+1-1:(C_S_AXI_DATA_WIDTH*1)];
    assign  start_replay     = rw_regs[(C_S_AXI_DATA_WIDTH*2)+1-1:(C_S_AXI_DATA_WIDTH*2)];
   // assign  compelete_replay = rw_regs[(C_S_AXI_DATA_WIDTH*3)+1-1:(C_S_AXI_DATA_WIDTH*3)];
    assign  mem_addr_low     = rw_regs[(C_S_AXI_DATA_WIDTH*4)+QDR_ADDR_WIDTH-1:(C_S_AXI_DATA_WIDTH*4)];
    assign  mem_addr_high    = rw_regs[(C_S_AXI_DATA_WIDTH*5)+QDR_ADDR_WIDTH-1:(C_S_AXI_DATA_WIDTH*5)];
	//--------------------------------------------------
    //
    // --- cutter disabled
    //--------------------------------------------------  
	 genevr_pipeline_regs #  
	(
		.NUM_REG_USED(NUM_RW_REGS)
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

    // dflow info input Sync signals
    wire                                sync_five_tuple_data_in;
    wire                                sync_pkt_len_in;
    reg                                 sync_tuple_in_vld;
    wire                                sync_tuple_in_ready;
    // dflow info output Sync signals
    wire                                sync_five_tuple_data_out;
    wire                                sync_pkt_len_out;
    wire                                sync_tuple_out_vld;
    wire                                sync_tuple_out_ready;

    wire                                sync_in_fifo_wr_en;
    wire                                sync_in_fifo_rd_en;
    wire                                sync_in_fifo_prog_full;
    wire                                sync_in_fifo_empty;

    assign tuple_in_ready = ~sync_in_fifo_prog_full;
    assign sync_in_fifo_wr_en = tuple_in_ready & tuple_in_vld;
    assign sync_in_fifo_rd_en = sync_tuple_in_ready & ~sync_in_fifo_empty;

    always @(posedge qdr_clk)
        if (~resetn) begin
            sync_tuple_in_vld <= 0;
        end
        else begin
            if(sync_in_fifo_rd_en)
                sync_tuple_in_vld <= 1;
            else
                sync_tuple_in_vld <= 0;
        end

    wire                                sync_out_fifo_wr_en;
    wire                                sync_out_fifo_rd_en;
    wire                                sync_out_fifo_prog_full;
    wire                                sync_out_fifo_empty;

    assign sync_out_fifo_wr_en = sync_tuple_out_ready & sync_tuple_out_vld;
    assign sync_out_fifo_rd_en = ~sync_out_fifo_empty & tuple_out_ready;

    always @(posedge clk)
        if (~resetn) begin
            tuple_out_vld <= 0;
        end
        else begin
            if(sync_out_fifo_rd_en)
                tuple_out_vld <= 1;
            else
                tuple_out_vld <= 0;
        end


    xil_async_fifo #(
        .DOUT_WIDTH(PKT_LEN_WIDTH+PKT_TUPLE_WIDTH), 
        .DIN_WIDTH(PKT_LEN_WIDTH+PKT_TUPLE_WIDTH)
    )
    async_fifo_input
      ( .din          ({fivetuple_data_in,pkt_len_in}),
        .wr_en        (sync_in_fifo_wr_en),
        .rd_en        (sync_in_fifo_rd_en),
        .dout         ({sync_fivetuple_data_in,sync_pkt_len_in}),
		.prog_full	  (sync_in_fifo_prog_full),
        .empty        (sync_in_fifo_empty),
        .rst          (~resetn),
        .wr_clk       (clk),
        .rd_clk       (qdr_clk)
      );

   dflow_generator_core # (
    )
    dflow_generator_inst 
    (
        // system signals
        .qdr_clk                                (qdr_clk),
        .resetn                                 (resetn),

        // controll signals
	    .sw_rst                                 (sw_rst),
        .start_replay                           (start_replay),
        .compelete_replay                       (compelete_replay),
        .start_store                            (start_store),

        // addr signals
        // .mem_addr_low                           (0),
        // .mem_addr_high                          (16'h0fff),
        .mem_addr_low                           (mem_addr_low),
        .mem_addr_high                          (mem_addr_high),
                                                
        // QDR Memory Interface                 
        .init_calib_complete	                (init_calib_complete),
        .user_app_wr_cmd                        (user_app_wr_cmd),
        .user_app_wr_addr                       (user_app_wr_addr),
        .user_app_wr_data                       (user_app_wr_data),
        .user_app_rd_cmd                        (user_app_rd_cmd),
        .user_app_rd_addr                       (user_app_rd_addr),
        .user_app_rd_valid                      (user_app_rd_valid),
        .user_app_rd_data                       (user_app_rd_data),
                                                
        // dflow info input Interface           
        .fivetuple_data_in                      (sync_fivetuple_data_in),
        .pkt_len_in                             (sync_pkt_len_in),
        .tuple_in_vld                           (sync_tuple_in_vld),
        .tuple_in_ready                         (sync_tuple_in_ready),
                                                
        // dflow info output Interface          
        .fivetuple_data_out                     (sync_fivetuple_data_out),
        .pkt_len_out                            (sync_pkt_len_out),
        .tuple_out_vld                          (sync_tuple_out_vld),
        .tuple_out_ready                        (sync_tuple_out_ready)
    );


    xil_async_fifo #(
        .DOUT_WIDTH(PKT_LEN_WIDTH+PKT_TUPLE_WIDTH), 
        .DIN_WIDTH(PKT_LEN_WIDTH+PKT_TUPLE_WIDTH)
    )
    async_fifo_output
      ( 
        .din          ({sync_fivetuple_data_out,sync_pkt_len_out}),
        .wr_en        (sync_out_fifo_wr_en),
        .rd_en        (sync_out_fifo_rd_en),
        .dout         ({fivetuple_data_out,pkt_len_out}),
		.prog_full	  (sync_out_fifo_prog_full),
        .empty        (sync_out_fifo_empty),
        .rst          (~resetn),
        .wr_clk       (clk),
        .rd_clk       (qdr_clk)
      );

    endmodule
