`timescale 1ns / 1ps

module top_stopwatch_watch (
    input clk,
    input reset,
    input [3:0] sw,  // sw[0] sel up/down, sw[1] sel watch, sw[2] sel display, sw[3] watch setting
    input btn_r,  // i_run_stop(stopwatch), time_rigth(watch)
    input btn_l,  // i_clear(stopwatch), time_left(watch)
    input btn_u,  // time_up(watch)
    input btn_d,  // time_down(watch)
    input rx,
    output tx,
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);

    wire w_mode, w_run_stop, w_clear;
    wire o_btn_run_stop, o_btn_clear;

    wire [1:0] w_setting;
    wire w_timeright, w_timeleft, w_timeup, w_timedown;
    wire o_btn_timeright, o_btn_timerleft, o_btn_timeup, o_btn_timedown;

    wire [23:0] w_watch_time, w_stopwatch_time;
    wire [23:0] w_mux;

    wire [7:0] w_rx_data;
    wire w_rx_done;

    wire [7:0] w_rx_ascii, w_tx_ascii;

    wire [7:0] w_control_data;

    wire [3:0] w_local_sw;

    wire w_read_time, w_tx_start, w_tx_busy;
    wire [7:0] w_tx_data;

    assign w_read_time = w_rx_ascii[7];

    assign w_control_data = {
        w_local_sw[3],  // [7] watch set sel (from sw_reg)
        w_local_sw[2],  // [6] display sel (from sw_reg)
        w_local_sw[1],  // [5] watch sel (from sw_reg)
        w_local_sw[0],  // [4] mode sel (from sw_reg)
        o_btn_timedown | w_rx_ascii[3],  // [3] btnD
        o_btn_timeup | w_rx_ascii[2],  // [2] btnU
        o_btn_clear | w_rx_ascii[1],  // [1] btnL
        o_btn_run_stop | w_rx_ascii[0]  // [0] btnR
    };

    uart_top U_UART_TOP (
        .clk     (clk),
        .rst     (reset),
        .uart_rx (rx),
        // .tx_data (w_tx_data),
        .tx_data (w_rx_data),
        // .tx_start(w_tx_start),
        .tx_start(w_rx_done),
        .rx_data (w_rx_data),
        .rx_done (w_rx_done),
        .tx_busy (),
        .uart_tx (tx)
    );

    ascii_decoder U_ASCII_DECODER (
        .clk      (clk),
        .rst      (reset),
        .i_rx_done(w_rx_done),
        .i_rx_data(w_rx_data),
        .o_rx_data(w_rx_ascii)
    );

    switch_register U_SW_REGISTER (
        .clk(clk),
        .reset(reset),
        .i_local_sw(sw[3:0]),  // {sw[3], sw[2], sw[1], sw[0]}
        .i_uart_pulse({
            w_rx_ascii[7], w_rx_ascii[6], w_rx_ascii[5], w_rx_ascii[4]
        }),  // {set('3'), Display('2'), Sel('1'), Mode('0')}
        .o_control_sw(w_local_sw)  // {set, Display, Sel, Mode}
    );

    ascii_sender U_ASCII_SENDER (
        .clk      (clk),
        .rst      (reset),
        .read_time(w_read_time),
        .time_data(w_mux),
        .tx_busy  (w_tx_busy),
        .tx_data  (w_tx_data),
        .tx_start (w_tx_start)
    );

    btn_debounce U_BD_RUNSTOP (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_r),
        .o_btn(o_btn_run_stop)
    );

    btn_debounce U_BD_CLEAR (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_l),
        .o_btn(o_btn_clear)
    );

    btn_debounce U_BD_TIMEUP (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_u),
        .o_btn(o_btn_timeup)
    );

    btn_debounce U_BD_TIMEDOWN (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_d),
        .o_btn(o_btn_timedown)
    );

    control_unit U_CONTROL_UNIT (
        .clk           (clk),
        .reset         (reset),
        // .i_mode        (sw[0]),
        // .i_sel_watch   (sw[1]),
        // .i_run_stop    (o_btn_run_stop),
        // .i_clear       (o_btn_clear),
        // .i_timeup      (o_btn_timeup),
        // .i_timedown    (o_btn_timedown),
        // .i_setting     (sw[3]),
        .i_setting     (w_local_sw[3]),
        .i_control_data(w_control_data),
        .o_mode        (w_mode),
        .o_run_stop    (w_run_stop),
        .o_clear       (w_clear),
        .o_timeright   (w_timeright),
        .o_timeleft    (w_timeleft),
        .o_timeup      (w_timeup),
        .o_timedown    (w_timedown)
    );

    watch_datapath U_WATCH_DATAPATH (
        .clk          (clk),
        .reset        (reset),
        .mode         (w_mode),
        .clear        (w_clear),
        .run_stop     (w_run_stop),
        // .watch_setting(sw[3]),
        .watch_setting(w_local_sw[3]),
        .sel_display  (w_local_sw[2]),
        .i_timeup     (w_timeup),
        .i_timedown   (w_timedown),
        .i_timeright  (w_timeright),
        .i_timeleft   (w_timeleft),
        .msec         (w_watch_time[6:0]),    // 7bit
        .sec          (w_watch_time[12:7]),   // 6bit
        .min          (w_watch_time[18:13]),  // 6bit
        .hour         (w_watch_time[23:19]),  // 5bit
        .o_set        (w_setting)
    );

    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk     (clk),
        .reset   (reset),
        .mode    (w_mode),
        .clear   (w_clear),
        .run_stop(w_run_stop),
        .msec    (w_stopwatch_time[6:0]),    // 7bit
        .sec     (w_stopwatch_time[12:7]),   // 6bit
        .min     (w_stopwatch_time[18:13]),  // 6bit
        .hour    (w_stopwatch_time[23:19])   // 5bit
    );

    mux_2x1_watch_stopwatch U_MUX_2x1_WATCH_STOPWATCH (
        .sel_watch(w_local_sw[1]),
        .i_sel0   (w_watch_time),
        .i_sel1   (w_stopwatch_time),
        .o_mux    (w_mux)
    );

    fnd_controller U_FND_CNTL (
        .clk          (clk),
        .reset        (reset),
        .sel_display  (w_local_sw[2]),
        .watch_setting(w_local_sw[3] && ~w_local_sw[1]),
        .fnd_in_data  (w_mux),
        .i_set        (w_setting),
        .fnd_digit    (fnd_digit),
        .fnd_data     (fnd_data)
    );

endmodule

module ascii_decoder (
    input            clk,
    input            rst,
    input      [7:0] i_rx_data,
    input            i_rx_done,
    output reg [7:0] o_rx_data
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            o_rx_data <= 8'b0;
        end else begin
            o_rx_data <= 8'b0;
            if (i_rx_done) begin
                case (i_rx_data)
                    "r": o_rx_data <= 8'b0000_0001;  // run_stop, timeright
                    "l": o_rx_data <= 8'b0000_0010;  // clear, timeleft
                    "u": o_rx_data <= 8'b0000_0100;  // timeup
                    "d": o_rx_data <= 8'b0000_1000;  // timedown
                    "0": o_rx_data <= 8'b0001_0000;  // sw[0] up/down mode sel
                    "1": o_rx_data <= 8'b0010_0000;  // sw[1] watch/stopwatch sel
                    "2": o_rx_data <= 8'b0100_0000;  // sw[2] display sel
                    "3": o_rx_data <= 8'b1000_0000;  // sw[3] watch setting sel
                    default: o_rx_data <= 8'b0000_0000;
                endcase
            end
        end
    end

endmodule

module ascii_sender (
    input             clk,
    input             rst,
    input             read_time,
    input      [23:0] time_data,
    input             tx_busy,
    output reg [ 7:0] tx_data,
    output reg        tx_start
);

    localparam IDLE = 2'b00, SEND = 2'b01, WAIT = 2'b10;

    reg [1:0] c_state, n_state;
    // reg [23:0] 

    // state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
        end else begin
            c_state <= n_state;
        end
    end

    // next state CL
    always @(*) begin
        n_state  = c_state;
        tx_data  = 0;
        tx_start = 0;
        case (c_state)
            IDLE: begin
                tx_data  = 0;
                tx_start = 0;
                if (read_time) begin
                    if (tx_busy == 0) begin
                        n_state  = SEND;
                        tx_start = 1;
                        tx_data  = time_data;
                    end else begin
                        n_state = WAIT;
                        tx_data = 0;
                    end
                end
            end
            SEND: begin
                if (read_time) begin
                    if (tx_busy == 1) begin
                        n_state  = WAIT;
                        tx_start = 0;
                        tx_data  = 0;
                    end
                end else begin
                    n_state = IDLE;
                end
            end
            WAIT: begin
                if (read_time) begin
                    if (tx_busy == 0) begin
                        n_state = SEND;
                        tx_data = time_data;
                    end
                end
            end
            default: c_state <= IDLE;
        endcase
    end

endmodule

module watch_datapath (
    input        clk,
    input        reset,
    input        mode,           // always up
    input        clear,
    input        run_stop,
    input        watch_setting,  // sw[3]
    input        sel_display,    // sw[2]
    input        i_timeright,
    input        i_timeleft,
    input        i_timeup,
    input        i_timedown,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour,
    output [1:0] o_set           // 0: sec, 1:min, 2:hour
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;

    reg [1:0] cursor;
    assign o_set = cursor;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            cursor <= 2'b10;
        end else if (watch_setting) begin
            if (sel_display) begin
                if (cursor == 2'b00) begin
                    cursor <= 2'b10;
                end else if (i_timeright || i_timeleft) begin
                    // hour(2'b10) <-> min(2'b01)
                    if (cursor == 2'b10) begin
                        cursor <= 2'b01;
                    end else begin
                        cursor <= 2'b10;
                    end
                end
            end else begin
                // sec mode
                cursor <= 2'b00;
            end
        end
    end

    // [Hour Control] (Cursor 2)
    wire hour_sel = (watch_setting && cursor == 2);
    wire hour_mode = hour_sel ? i_timedown : 1'b0;
    wire hour_tick_in = hour_sel ? (i_timeup | i_timedown) : (watch_setting ? 1'b0 : w_hour_tick);

    // [Min Control] (Cursor 1)
    wire min_sel = (watch_setting && cursor == 1);
    wire min_mode = min_sel ? i_timedown : 1'b0;
    wire min_tick_in = min_sel ? (i_timeup | i_timedown) : (watch_setting ? 1'b0 : w_min_tick);

    // [Sec Control] (Cursor 0)
    wire sec_sel = (watch_setting && cursor == 0);
    wire sec_mode = sec_sel ? i_timedown : 1'b0;
    wire sec_tick_in = sec_sel ? (i_timeup | i_timedown) : (watch_setting ? 1'b0 : w_sec_tick);

    // [Msec Control] (no edit)
    wire msec_tick_in = w_tick_100hz;

    tick_counter #(
        .BIT_WIDTH (5),
        .TIMES     (24),
        .TIME_VALUE(12)
    ) hour_counter (
        .clk     (clk),
        .reset   (reset),
        .i_tick  (hour_tick_in),
        .mode    (hour_mode),
        .clear   (1'b0),
        .run_stop(1'b1),
        .o_count (hour),
        .o_tick  ()
    );

    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES    (60)
    ) min_counter (
        .clk     (clk),
        .reset   (reset),
        .i_tick  (min_tick_in),
        .mode    (min_mode),
        .clear   (1'b0),
        .run_stop(1'b1),
        .o_count (min),
        .o_tick  (w_hour_tick)
    );

    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES    (60)
    ) sec_counter (
        .clk     (clk),
        .reset   (reset),
        .i_tick  (sec_tick_in),
        .mode    (sec_mode),
        .clear   (1'b0),
        .run_stop(1'b1),
        .o_count (sec),
        .o_tick  (w_min_tick)
    );

    tick_counter #(
        .BIT_WIDTH(7),
        .TIMES    (100)
    ) msec_counter (
        .clk     (clk),
        .reset   (reset),
        .i_tick  (msec_tick_in),
        .mode    (1'b0),
        .clear   (1'b0),
        .run_stop(1'b1),
        .o_count (msec),
        .o_tick  (w_sec_tick)
    );

    tick_gen_100hz U_TICK_GEN (
        .clk         (clk),
        .reset       (reset),
        .i_run_stop  (1'b1),         // always run
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

module stopwatch_datapath (
    input        clk,
    input        reset,
    input        mode,
    input        clear,
    input        run_stop,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;

    tick_counter #(
        .BIT_WIDTH(5),
        .TIMES    (24)
    ) hour_counter (
        .clk     (clk),
        .reset   (reset),
        .i_tick  (w_hour_tick),
        .mode    (mode),
        .clear   (clear),
        .run_stop(run_stop),
        .o_count (hour),
        .o_tick  ()
    );

    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES    (60)
    ) min_counter (
        .clk     (clk),
        .reset   (reset),
        .i_tick  (w_min_tick),
        .mode    (mode),
        .clear   (clear),
        .run_stop(run_stop),
        .o_count (min),
        .o_tick  (w_hour_tick)
    );

    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES    (60)
    ) sec_counter (
        .clk     (clk),
        .reset   (reset),
        .i_tick  (w_sec_tick),
        .mode    (mode),
        .clear   (clear),
        .run_stop(run_stop),
        .o_count (sec),
        .o_tick  (w_min_tick)
    );

    tick_counter #(
        .BIT_WIDTH(7),
        .TIMES    (100)
    ) msec_counter (
        .clk     (clk),
        .reset   (reset),
        .i_tick  (w_tick_100hz),
        .mode    (mode),
        .clear   (clear),
        .run_stop(run_stop),
        .o_count (msec),
        .o_tick  (w_sec_tick)
    );

    tick_gen_100hz U_TICK_GEN (
        .clk         (clk),
        .reset       (reset),
        .i_run_stop  (run_stop),
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

module mux_2x1_watch_stopwatch (
    input         sel_watch,
    input  [23:0] i_sel0,     // watch
    input  [23:0] i_sel1,     // stopwatch
    output [23:0] o_mux
);
    // sel 1: output i_sel1, 0: i_sel0
    assign o_mux = (sel_watch) ? i_sel1 : i_sel0;

endmodule

// msec, sec, min, hour
// tick_counter
module tick_counter #(
    parameter BIT_WIDTH = 7,
    TIMES = 100,
    TIME_VALUE = 0
) (
    input                      clk,
    input                      reset,
    input                      i_tick,
    input                      mode,
    input                      clear,
    input                      run_stop,
    output     [BIT_WIDTH-1:0] o_count,
    output reg                 o_tick
);

    // counter reg
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;

    assign o_count = counter_reg;

    // state reg SL
    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            counter_reg <= TIME_VALUE;
        end else begin
            counter_reg <= counter_next;
        end
    end

    // next CL
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (i_tick & run_stop) begin
            if (mode == 1'b1) begin
                //down
                if (counter_reg == 0) begin
                    counter_next = TIMES - 1;
                    o_tick = 1'b1;
                end else begin
                    counter_next = counter_reg - 1;
                    o_tick = 1'b0;
                end
            end else begin
                // up
                if (counter_reg == (TIMES - 1)) begin
                    counter_next = 0;
                    o_tick = 1'b1;
                end else begin
                    counter_next = counter_reg + 1;
                    o_tick = 1'b0;
                end
            end
        end
    end

endmodule

module tick_gen_100hz (
    input      clk,
    input      reset,
    input      i_run_stop,
    output reg o_tick_100hz
);
    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT)-1:0] r_counter;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_counter    <= 0;
            o_tick_100hz <= 1'b0;
        end else begin
            if (i_run_stop) begin
                r_counter    <= r_counter + 1;
                o_tick_100hz <= 1'b0;
                if (r_counter == (F_COUNT - 1)) begin
                    r_counter    <= 0;
                    o_tick_100hz <= 1'b1;
                end else begin
                    o_tick_100hz <= 1'b0;
                end
            end
        end
    end
endmodule
