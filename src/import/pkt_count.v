
`timescale 1 ns / 1 ps

module pkt_count
#(
    parameter QDR_ADDR_WIDTH     = 19,
    parameter TIMESTAMP_WIDTH    = 64

)
(
    input                                               clk,
    input                                               resetn,

    /* pkt plane */
    input                                               tuple_out_vld,
    input                                               tuple_out_ready,
    /* control signals */
    input                                               sw_rst,
    input [QDR_ADDR_WIDTH-1:0]                          mem_high_store,
    input                                               start_replay,
    output reg                                          compelete_transform
);

    (*MARK_DEBUG="true"*) reg [QDR_ADDR_WIDTH-1:0] pkt_count_reg;
    (*MARK_DEBUG="true"*) reg [TIMESTAMP_WIDTH-1:0] timestamp_reg;
    (*MARK_DEBUG="true"*)wire  transform_vld;
    assign transform_vld = tuple_out_ready && tuple_out_vld;

    always @ (posedge clk) begin
      if(~resetn|| sw_rst) begin
          timestamp_reg <= 0;
      end
      else if(start_replay) begin
          if(~compelete_transform) begin
              timestamp_reg <= timestamp_reg + 1;
          end
      end
  end
    always @ (posedge clk) begin
      if(~resetn|| sw_rst) begin
          pkt_count_reg = 0;
          compelete_transform <= 0;
      end
      else if(start_replay && transform_vld) begin
          if(pkt_count_reg != mem_high_store-2) begin
              pkt_count_reg <= pkt_count_reg + 1;
              compelete_transform <= 0;
          end
          else begin
              compelete_transform <= 1;
          end
      end
    end


endmodule
