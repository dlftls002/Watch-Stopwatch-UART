`timescale 1ns / 1ps

module switch_register (
    input            clk,
    input            reset,
    input      [3:0] i_local_sw,      // {sw[3], sw[2], sw[1], sw[0]}
    input      [3:0] i_uart_pulse,    // {setting('3'), Display('2'), Sel('1'), Mode('0')}
    output reg [3:0] o_control_sw     // {setting, Display, Sel, Mode}
);

    reg [3:0] r_sw_change;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            o_control_sw <= 4'b0000;
            r_sw_change  <= 4'b0000;
        end else begin
            // 1) local switch change
            if (i_local_sw != r_sw_change) begin
                o_control_sw <= i_local_sw;
                r_sw_change  <= i_local_sw;
            end
            // 2) uart pulse toggle
            else begin
                // bit 0: mode (sw[0])
                if (i_uart_pulse[0]) 
                    o_control_sw[0] <= ~o_control_sw[0]; 
                // bit 1: watch/stopwatch sel (sw[1])
                if (i_uart_pulse[1]) 
                    o_control_sw[1] <= ~o_control_sw[1];

                // bit 2: display sel (sw[2])
                if (i_uart_pulse[2]) 
                    o_control_sw[2] <= ~o_control_sw[2];
                // bit 3: watch setting (sw[3])
                if (i_uart_pulse[3]) 
                    o_control_sw[3] <= ~o_control_sw[3];
            end
        end
    end
endmodule

