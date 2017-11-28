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
    reg                                                clk;
    reg                                                qdr_clk;
    reg                                                resetn;

    /* pkt plane */
    wire  [PKT_TUPLE_WIDTH-1:0]                        fivetuple_data_in;
    wire  [PKT_LEN_WIDTH-1:0]                          pkt_len_in;
    wire                                               tuple_in_vld;
    wire                                               tuple_in_ready; 

    /* fifo plane */
    wire  [PKT_TUPLE_WIDTH+PKT_LEN_WIDTH-1:0]          fifo_data_out;
    wire                                               fifo_rd_en;
    // wire                                               fifo_wr_en;
    wire                                               fifo_nearly_full;
    wire                                               fifo_empty;
    assign  fifo_rd_en = 0;

    // -- Local Functions
    function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
    endfunction

    /*testbench signals*/
    wire  [31:0]                                        cnt;
    reg   [31:0]                                        cnt_next;
    wire  [MEM_SIZE-1:0]                                id;
    reg   [PKT_TUPLE_WIDTH-1:0]                         fivetuple_mem[MEM_SIZE-1:0];
    reg   [PKT_LEN_WIDTH-1:0]                           pkt_len_mem[MEM_SIZE-1:0];

    reg   [PKT_TUPLE_WIDTH-1:0]                         fivetuple_data_in_next;
    reg   [PKT_LEN_WIDTH-1:0]                           pkt_len_in_next;
    reg                                                 tuple_in_vld_next;


    assign  id = cnt % MEM_SIZE;   

    assign  fivetuple_data_in = fivetuple_data_in_next;
    assign  pkt_len_in        = pkt_len_in_next;
    assign  tuple_in_vld      = tuple_in_vld_next;
    assign  cnt               = cnt_next;

    integer i;
    initial begin
        clk   = 1'b0;
        qdr_clk = 1'b0;
        cnt_next = 0;
        $display("[%t] : System Reset Asserted...", $realtime);
        resetn = 1'b0;
        for (i = 0; i < MEM_SIZE; i = i + 1) begin
                   @(posedge clk);
                   fivetuple_mem[i] = i;
                   pkt_len_mem[i] = i;
        end
        $display("[%t] : System Reset De-asserted...", $realtime);
        resetn = 1'b1;
    end

    always #2.5  clk = ~clk;
    always #2.5  qdr_clk = ~qdr_clk;

    inqueue # (
        .ACTION_TUPLE_WIDTH(128),
        .PKT_TUPLE_WIDTH(104),
        .PKT_LEN_WIDTH(16)           
    )
    inqueue_inst
    (

        /* system clock */
        .clk                     (clk),
        .resetn                  (resetn),
                                
        /* pkt plane */          
        .fivetuple_data_in       (fivetuple_data_in),
        .pkt_len_in              (pkt_len_in),
        .tuple_in_vld            (tuple_in_vld),
        .tuple_in_ready          (tuple_in_ready),
                                 
        /* fifo plane */         
        .fifo_data_out           (fifo_data_out),
        .fifo_rd_en              (fifo_rd_en),
        // .fifo_wr_en              (),
        // .fifo_nearly_full        (),
        .fifo_empty              (fifo_empty)
    );

    always  @(posedge clk) begin
        if(~resetn)
            tuple_in_vld_next <= 0;
        else begin
            if(tuple_in_ready) begin
                fivetuple_data_in_next <= fivetuple_mem[id];
                pkt_len_in_next <= pkt_len_mem[id];
                tuple_in_vld_next <= 1;
                cnt_next <= cnt + 1;
            end
        end
    end

    endmodule
