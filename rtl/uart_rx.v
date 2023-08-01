`timescale 1ns / 1ps

module uart_rx #
(
     integer G_DATAWIDTH = 8
    ,integer G_PRESCALE = 1302 // 9600 @ 100 Mhz
)
(
     input                    clk
    ,input                    rst
    ,output [G_DATAWIDTH-1:0]  uart_rxdata
    ,output                   uart_rxvalid
    ,input                    rxd
    ,output                   busy
    ,output                   overrun_error
    ,output                   frame_error
);

logic [G_DATAWIDTH-1:0] f_tdata = 0;
logic f_valid = 0;

logic f_rxd = 1;

logic f_busy = 0;
logic f_overrun_error = 0;
logic f_frame_error = 0;

logic [G_DATAWIDTH-1:0] f_data = 0;
logic [18:0] f_prescale = 0;
logic [3:0] f_bit_cnt = 0;

assign uart_rxdata = f_tdata;
assign uart_rxvalid = f_valid;

assign busy = f_busy;
assign overrun_error = f_overrun_error;
assign frame_error = f_frame_error;

always @(posedge clk) begin : p_uart_rx
    if (~rst) begin
        f_tdata <= 0;
        f_valid <= 0;
        f_rxd <= 1;
        f_prescale <= 0;
        f_bit_cnt <= 0;
        f_busy <= 0;
        f_overrun_error <= 0;
        f_frame_error <= 0;
    end else begin
        f_rxd <= rxd;
        f_overrun_error <= 0;
        f_frame_error <= 0;
        f_valid <= 0;

        if (f_prescale > 0) begin
            f_prescale <= f_prescale - 1;
        end else if (f_bit_cnt > 0) begin
            if (f_bit_cnt > G_DATAWIDTH+1) begin
                if (!f_rxd) begin
                    f_bit_cnt <= f_bit_cnt - 1;
                    f_prescale <= (G_PRESCALE << 3)-1;
                end else begin
                    f_bit_cnt <= 0;
                    f_prescale <= 0;
                end
            end else if (f_bit_cnt > 1) begin
                f_bit_cnt <= f_bit_cnt - 1;
                f_prescale <= (G_PRESCALE << 3)-1;
                f_data <= {f_rxd, f_data[G_DATAWIDTH-1:1]};
            end else if (f_bit_cnt == 1) begin
                f_bit_cnt <= f_bit_cnt - 1;
                if (f_rxd) begin
                    f_tdata <= f_data;
                    f_valid <= 1;
                    f_overrun_error <= f_valid;
                end else begin
                    f_frame_error <= 1;
                end
            end
        end else begin
            f_busy <= 0;
            if (!f_rxd) begin
                f_prescale <= (G_PRESCALE << 2)-2;
                f_bit_cnt <= G_DATAWIDTH+2;
                f_data <= 0;
                f_busy <= 1;
            end
        end
    end
end

endmodule
