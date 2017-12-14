`timescale 1 ns / 1 ps

module outqueue
#(
  parameter QDR_DATA_WIDTH       = 36,
  parameter ACTION_TUPLE_WIDTH     = 128,
  parameter PKT_TUPLE_WIDTH        = 104,
  parameter PKT_LEN_WIDTH          = 16

)
(
    input                                               clk,
    input                                               resetn,

    /* fifo plane */
    input   [PKT_TUPLE_WIDTH+PKT_LEN_WIDTH-1:0]         fifo_data_in,
    // input                                               fifo_rd_en,
    input                                               fifo_wr_en,
    output                                              fifo_nearly_full,
    output                                              fifo_empty,

    /* pkt plane */
    output   [PKT_TUPLE_WIDTH-1:0]                   fivetuple_data_out,
    output   [PKT_LEN_WIDTH-1:0]                        pkt_len_out,
    output reg                                          tuple_out_vld,
    input                                               tuple_out_ready

);

    wire [PKT_LEN_WIDTH-1:0]                            fifo_out_pkt_len;
    wire [PKT_TUPLE_WIDTH-1:0]                          fifo_out_pkt_fivetuple;
    wire                                                fifo_rd_en;

    assign  fifo_rd_en         = ~fifo_empty && tuple_out_ready;
    assign  fivetuple_data_out = fifo_out_pkt_fivetuple;
    assign  pkt_len_out        = fifo_out_pkt_len;

    always @(posedge clk)
        if (~resetn) begin
            tuple_out_vld <= 0;
        end
        else begin
            if(fifo_rd_en)
                tuple_out_vld <= 1;
            else
                tuple_out_vld <= 0;
        end

    /* fifo plane  */
    fallthrough_small_fifo_v2 #
    (.WIDTH(PKT_TUPLE_WIDTH+PKT_LEN_WIDTH),
     .MAX_DEPTH_BITS(10))
      info_fifo
        (.din           (fifo_data_in),  // Data in
         .wr_en         (fifo_wr_en),             // Write enable
         .rd_en         (fifo_rd_en),    // Read the next word
         .dout          ({fifo_out_pkt_fivetuple,fifo_out_pkt_len}),
         .full          (),
         .nearly_full   (fifo_nearly_full),
         .prog_full     (),
         .empty         (fifo_empty),
         .reset         (~resetn),
         .clk           (clk)
         );

endmodule
