`timescale 1 ns / 1 ps

module inqueue_test
#(
  parameter ACTION_TUPLE_WIDTH     = 128,
  parameter PKT_TUPLE_WIDTH        = 104,
  parameter PKT_LEN_WIDTH          = 16,
  parameter MEM_SIZE               = 16

)
(
);

    /* system clock */
    wire                                               clk,
    wire                                               resetn,

    /* pkt plane */
    wire  [ACTION_TUPLE_WIDTH-1:0]                     fivetuple_data_in,
    wire  [PKT_LEN_WIDTH]                              pkt_len_in,
    wire                                               tuple_in_vld,
    wire                                               tuple_in_ready, 

    /* fifo plane */
    wire  [PKT_TUPLE_WIDTH+15:0]                       fifo_data_out,
    wire                                               fifo_rd_en,
    // wire                                               fifo_wr_en,
    wire                                               fifo_nearly_full,
    wire                                               fifo_empty

    /*testbench signals*/
    reg   [31:0]                                        cnt,cnt_next;
    wire  [3:0]                                         id;
    reg   [PKT_TUPLE_WIDTH-1:0]                         fivetuple_mem[3:0];
    reg   [PKT_LEN_WIDTH-1:0]                           pkt_len_mem[3:0];

    reg   [ACTION_TUPLE_WIDTH-1:0]                      fivetuple_data_in_next;
    reg   [PKT_LEN_WIDTH]                               pkt_len_in_next;
    reg                                                 tuple_in_vld_next;

    assign  id = cnt % 16;   

    assign  fivetuple_data_in = fivetuple_data_in_next;
    assign  pkt_len_in        = pkt_len_in_next;
    assign  tuple_in_vld      = tuple_in_vld_next;

    inqueue # (
        .ACTION_TUPLE_WIDTH(128),
        .PKT_TUPLE_WIDTH(104),
        .PKT_LEN_WIDTH(16)           
    )
    inqueue_inst
    (

        /* system clock */
        .clk                     (),
        .resetn                  (),
                                
        /* pkt plane */          
        .fivetuple_data_in       (fivetuple_data_in),
        .pkt_len_in              (pkt_len_in),
        .tuple_in_vld            (tuple_in_vld),
        .tuple_in_ready          (tuple_in_ready),
                                 
        /* fifo plane */         
        .fifo_data_out           (fifo_wr_data),
        .fifo_rd_en              (fifo_wr_rd_en),
        // .fifo_wr_en              (),
        // .fifo_nearly_full        (),
        .fifo_empty              (fifo_wr_empty)
    );

    always  @(posedge clk) begin
        if(~resetn)
            tuple_in_vld_next <= 0;
        else begin
            if(tuple_in_ready)
                fivetuple_data_in_next <= fivetuple_mem[id];
                pkt_len_in_next <= pkt_len_mem[id];
                tuple_in_vld_next <= 1;
                cnt_next <= cnt + 1;
        end
    end

    endmodule
