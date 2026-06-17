`timescale 1ns / 1ps

module tb_decoder ();

    reg clk, rst, rx;
    wire [7:0] w_rx_data;
    wire w_rx_done;
    wire [7:0] rx_data;

    uart_top U_UART_TOP (
        .clk     (clk),
        .rst     (rst),
        .uart_rx (rx),
        .tx_data (),
        .tx_start(),
        .rx_data (w_rx_data),
        .rx_done (w_rx_done),
        .tx_busy (),
        .uart_tx ()
    );

    ascii_decoder U_ASCII_DECODER (
        .clk      (clk),
        .rst      (rst),
        .i_rx_data(w_rx_data),
        .i_rx_done(w_rx_done),
        .o_rx_data(rx_data)
    );
    
    always #5 clk = ~clk;

    integer i;

    initial begin
        clk = 0;
        rst = 1;
        rx = 0;
        @(negedge clk);
        @(negedge clk);
        rst = 0;

        for (i=0;i<256;i=i+1) begin
            // random test
            rx = $random % 256;
        end

    end
endmodule