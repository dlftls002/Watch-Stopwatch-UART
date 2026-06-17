`timescale 1ns / 1ps

module control_unit (
    input            clk,
    input            reset,
    input            i_setting,
    input      [7:0] i_control_data,
    output           o_mode,
    output reg       o_run_stop,
    output reg       o_clear,
    output reg       o_timeright,
    output reg       o_timeleft,
    output reg       o_timeup,
    output reg       o_timedown
    // input            i_mode,
    // input            i_sel_watch,
    // input            i_run_stop,
    // input            i_clear,
    // input            i_timeup,
    // input            i_timedown,
);

    localparam STOP = 4'b0000, RUN = 4'b0001, CLEAR = 4'b0010;
    localparam TIMERIGHT = 4'b0011, TIMELEFT = 4'b0100, TIMEUP = 4'b0101, TIMEDOWN = 4'b0110;

    // reg variable
    reg [2:0] current_st, next_st;

    // mode: switch control
    assign o_mode = i_control_data[4];

    // state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_st <= STOP;
        end else begin
            current_st <= next_st;
        end
    end

    // next state CL
    always @(*) begin
        next_st     = current_st;
        o_run_stop  = 1'b0;
        o_clear     = 1'b0;
        o_timeright = 1'b0;
        o_timeleft  = 1'b0;
        o_timeup    = 1'b0;
        o_timedown  = 1'b0;
        case (current_st)
            STOP: begin
                // moore output -> decide output first
                o_run_stop  = 1'b0;
                o_clear     = 1'b0;
                o_timeright = 1'b0;
                o_timeleft  = 1'b0;
                o_timeup    = 1'b0;
                o_timedown  = 1'b0;
                if (i_setting) begin  
                    if (i_control_data[0]) begin    // btnR
                        next_st = TIMERIGHT;
                    end else if (i_control_data[1]) begin   // btnL
                        next_st = TIMELEFT;
                    end else if (i_control_data[2]) begin   // btnU
                        next_st = TIMEUP;
                    end else if (i_control_data[3]) begin   // btnD
                        next_st = TIMEDOWN;
                    end
                end else begin
                    if (i_control_data[5] == 1'b1) begin  // sel_watch
                        if (i_control_data[0]) begin    // btnR
                            next_st = RUN;
                        end else if (i_control_data[1]) begin   // btnL
                            next_st = CLEAR;
                        end
                    end
                end
            end
            RUN: begin
                o_run_stop = 1'b1;
                o_clear = 1'b0;
                if (i_control_data[5] == 1'b1) begin  // sel_watch
                    if (i_control_data[0]) begin    // btnR
                        next_st = STOP;
                    end
                end
            end
            CLEAR: begin
                o_run_stop = 1'b0;
                o_clear = 1'b1;
                next_st = STOP;
            end
            TIMERIGHT: begin
                o_timeright = 1'b1;
                next_st = STOP;
            end
            TIMELEFT: begin
                o_timeleft = 1'b1;
                next_st = STOP;
            end
            TIMEUP: begin
                o_timeup = 1'b1;
                next_st  = STOP;
            end
            TIMEDOWN: begin
                o_timedown = 1'b1;
                next_st = STOP;
            end
            default: next_st = STOP;
        endcase
    end

endmodule
