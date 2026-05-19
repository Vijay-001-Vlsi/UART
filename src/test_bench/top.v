`timescale 1ns / 1ps
module top_module #(
    parameter freq   = 100,
    parameter b_rate = 2
)(
    input        sys_clk,
    input        sys_rst_l,
    // TX
    input        xmitH,
    input  [7:0] xmit_dataH,
    output       uart_XMIT_dataH,
    output       xmit_doneH,
    output       xmit_active,
    // RX
    input        uart_REC_dataH,
    output [7:0] rec_dataH,
    output       rec_readyH,
    output       rec_busy
);

    wire b_clk;
    wire temp1, temp2;

    // Baud generator (shared clock for TX and RX)
    baud_gen #(.freq(freq), .b_rate(b_rate)) u_baud (
        .sys_clk   (sys_clk),
        .b_clk  (b_clk)
    );

    // TX
    tx u_tx (
        .b_clk          (b_clk),
        .sys_rst_l      (sys_rst_l),
        .xmitH          (xmitH),
        .xmit_dataH     (xmit_dataH),
        .uart_XMIT_dataH(uart_XMIT_dataH),
        .xmit_doneH     (xmit_doneH),
        .xmit_active    (xmit_active)
    );

    // Two-FF synchroniser on RX input
    two_ff u_sync (
        .uart_REC_dataH (uart_REC_dataH),
        .b_clk          (b_clk),
        .sys_rst_l      (sys_rst_l),
        .temp1          (temp1),
        .temp2          (temp2)
    );

    // RX - feed synchronised signal
    rx u_rx (
        .b_clk          (b_clk),
        .sys_rst_l      (sys_rst_l),
        .uart_REC_dataH (temp2),
        .rec_dataH      (rec_dataH),
        .rec_readyH     (rec_readyH),
        .rec_busy       (rec_busy)
    );

endmodule
