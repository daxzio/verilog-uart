`timescale 1ns / 1ps
module uart_tx #
(
     integer G_DATAWIDTH = 8
    ,integer G_PRESCALE = 1302 // 9600 @ 100 Mhz
)
(
    input                    clk
    ,input                    rst
    ,input  [G_DATAWIDTH-1:0] uart_txdata
    ,input                    uart_txvalid
    ,output                   uart_txready
    ,output                   txd
    ,output                   busy
);

logic f_axis_tready = 0;
logic f_txd = 1;
logic f_busy = 0;
logic [G_DATAWIDTH:0] f_data = 0;
logic [18:0] f_prescale = 0;
logic [3:0] f_bit_cnt = 0;

assign txd = f_txd;

assign busy = f_busy;

always @(posedge clk) begin
    if (~rst) begin
        f_axis_tready <= 0;
        f_txd <= 1;
        f_prescale <= 0;
        f_bit_cnt <= 0;
        f_busy <= 0;
    end else begin
        if (f_prescale > 0) begin
            f_axis_tready <= 0;
            f_prescale <= f_prescale - 1;
        end else if (f_bit_cnt == 0) begin
            f_axis_tready <= 1;
            f_busy <= 0;

            if (uart_txvalid) begin
                f_axis_tready <= !f_axis_tready;
                f_prescale <= (G_PRESCALE << 3)-1;
                f_bit_cnt <= G_DATAWIDTH+1;
                f_data <= {1'b1, uart_txdata};
                f_txd <= 0;
                f_busy <= 1;
            end
        end else begin
            if (f_bit_cnt > 1) begin
                f_bit_cnt <= f_bit_cnt - 1;
                f_prescale <= (G_PRESCALE << 3)-1;
                {f_data, f_txd} <= {1'b0, f_data};
            end else if (f_bit_cnt == 1) begin
                f_bit_cnt <= f_bit_cnt - 1;
                f_prescale <= (G_PRESCALE << 3);
                f_txd <= 1;
            end
        end
    end
end

endmodule
