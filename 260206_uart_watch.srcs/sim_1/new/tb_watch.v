`timescale 1ns / 1ps

module tb_top_stopwatch_watch;

    reg        clk;
    reg        reset;
    reg  [3:0] sw;  // sw[3]:Set, sw[2]:Disp, sw[1]:Mode, sw[0]:Up/Dn
    reg        btn_r;  // Run/Stop or Right
    reg        btn_l;  // Clear or Left
    reg        btn_u;  // Time Up
    reg        btn_d;  // Time Down
    reg        rx;
    wire       tx;
    wire [3:0] fnd_digit;
    wire [7:0] fnd_data;

    top_stopwatch_watch dut (
        .clk      (clk),
        .reset    (reset),
        .sw       (sw),
        .btn_r    (btn_r),
        .btn_l    (btn_l),
        .btn_u    (btn_u),
        .btn_d    (btn_d),
        .rx       (rx),
        .tx       (tx),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data)
    );

    parameter BAUD = 9600;
    parameter BAUD_PERIOD = (100_000_000 / BAUD) * 10;  // 104_160

    // clock
    always #5 clk = ~clk;

    task UART_SENDER;
        input [7:0] test_data;
        integer i;
        begin
            // uart test pattern
            // start
            rx = 0;
            #(BAUD_PERIOD);
            // data
            for (i = 0; i < 8; i = i + 1) begin
                rx = test_data[i];
                #(BAUD_PERIOD);
            end
            // stop
            rx = 1'b1;
            #(BAUD_PERIOD);
        end
    endtask

    initial begin
        #0;
        clk = 0;
        reset = 1;
        sw = 4'b0000;
        btn_r = 0;
        btn_l = 0;
        btn_u = 0;
        btn_d = 0;
        rx = 1;

        #100;
        reset = 0;

        // // Case 1: stopwatch
        // UART_SENDER("1");
        // #100000;

        // // Run
        // UART_SENDER("r");
        // #100000000;

        // // Stop
        // UART_SENDER("r");
        // #100000000;

        // // Clear
        // UART_SENDER("l");
        // #100000000;


        // Case 2: watch time setting
        // sel display
        UART_SENDER("2");
        sw[3] = 1;
        #100000;

        // 2 hour up
        UART_SENDER("u");
        #10000000;

        UART_SENDER("u");
        #10000000;

        // hour -> min
        UART_SENDER("r");
        #10000000;

        // 2min down
        UART_SENDER("d");
        #10000000;

        UART_SENDER("d");
        #10000000;

        $stop;
    end

endmodule



