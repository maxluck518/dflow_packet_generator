 /*
 *
  *     dflow test
  *     5-tuple generator
  *     mjw
  *
  */

module dflow_generator
#(
)
(
      input          clk,                       //system clk
      input          reset,                     //system reset

      //AXI-lite Slave interface
      input          s_axi_aclk,
      input          s_axi_aresetn,
      // Write address channel
      input [31:0]   s_axi_awaddr,
      input [2:0]    s_axi_awprot,
      input          s_axi_awvalid,
      output         s_axi_awready,
      // Write Data Channel
      input [31:0]   s_axi_wdata, 
      input [3:0]    s_axi_wstrb,
      input          s_axi_wvalid,
      output         s_axi_wready,
      // Write Response Channel
      output [1:0]   s_axi_bresp,
      output         s_axi_bvalid,
      input          s_axi_bready,
      // Read Address channel
      input [31:0]   s_axi_araddr,
      input [2:0]    s_axi_arprot,
      input          s_axi_arvalid,
      output         s_axi_arready,
      // Read Data Channel
      output [31:0]  s_axi_rdata,
      output [1:0]   s_axi_rresp,
      output         s_axi_rvalid,
      input          s_axi_rready,

      // QDR Memory Interface  
      input             							  init_calib_complete,	  
      output            							  user_app_wr_cmd0,
      output [18:0]     							  user_app_wr_addr0,
      output            							  user_app_rd_cmd0,
      output [18:0]     							  user_app_rd_addr0,
      output [143:0] 								  user_app_wr_data0,
      input             							  user_app_rd_valid0,
      input [143:0]									  user_app_rd_data0,
      input             							  qdr_clk,

    // dflow info input Interface
    input                                           five_tuple_data_in,
    input                                           pkt_len_in,
    input                                           tuple_in_vld,
    output                                          tuple_in_ready,

    // dflow info output Interface
    output                                           five_tuple_data_out,
    output                                           pkt_len_out,
    output                                           tuple_out_vld,
    input                                            tuple_out_ready

  );
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
		.reset            (reset), 
		.clk              (clk)
	);

