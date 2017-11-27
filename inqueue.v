`timescale 1 ns / 1 ps

module inqueue
#(
  parameter ACTION_TUPLE_WIDTH     = 128,
  parameter PKT_TUPLE_WIDTH        = 104

)
(
    /* system clock */
    input                                               clk,
    input                                               resetn,

    /* pkt plane */
    input   [ACTION_TUPLE_WIDTH-1:0]                    tuple_in_transtuple_DATA,
    input                                               tuple_in_transtuple_VALID,
    input   [PKT_TUPLE_WIDTH-1:0]                       tuple_in_fivetuple_DATA,
    input                                               tuple_in_fivetuple_VALID,
    output                                              tuple_in_READY,

    /* fifo plane */
    output  [PKT_TUPLE_WIDTH+15:0]                      fifo_data_out,
    input                                               fifo_rd_en,
    input                                               fifo_wr_en,
    output                                              fifo_nearly_full,
    output                                              fifo_empty

);

    reg                                                 wr_en;
    wire [15:0]                                         fifo_in_pkt_len;
    wire [PKT_TUPLE_WIDTH-1:0]                          fifo_in_pkt_fivetuple;
    reg  [15:0]                                         fifo_in_pkt_len_next;
    reg  [PKT_TUPLE_WIDTH-1:0]                          fifo_in_pkt_fivetuple_next;

    wire [15:0]                                         fifo_out_pkt_len;
    wire [PKT_TUPLE_WIDTH-1:0]                          fifo_out_pkt_fivetuple;

    assign tuple_in_READY        = ~fifo_nearly_full;
    assign fifo_data_out         = {fifo_out_pkt_fivetuple,fifo_out_pkt_len};
    assign fifo_in_pkt_len       = fifo_in_pkt_len_next;
    assign fifo_in_pkt_fivetuple = fifo_in_pkt_fivetuple_next;
    assign fifo_wr_en            = ~fifo_nearly_full & wr_en;

    always @(posedge clk)
        if (~resetn) begin
            fifo_in_pkt_len_next <= 0;
            fifo_in_pkt_fivetuple_next <= 0;
            wr_en <=0;
        end
        else begin
            if(tuple_in_transtuple_VALID) begin
                fifo_in_pkt_fivetuple_next <= tuple_in_fivetuple_DATA;
                fifo_in_pkt_len_next <= tuple_in_transtuple_DATA[15:0];
                wr_en <=1;
            end
            else begin
                wr_en <=0;
            end
        end

    /* fifo plane  */
    fallthrough_small_fifo_v2 #
    (.WIDTH(PKT_TUPLE_WIDTH+16),
     .MAX_DEPTH_BITS(10))
      info_fifo
        (.din           ({fifo_in_pkt_fivetuple,fifo_in_pkt_len}),  // Data in
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
