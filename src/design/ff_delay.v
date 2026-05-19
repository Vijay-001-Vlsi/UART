`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.05.2026 14:49:37
// Design Name: 
// Module Name: two_ff_sync
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module two_ff(
input uart_REC_dataH,b_clk,sys_rst_l,
output reg temp1,temp2
    );
 always @(posedge b_clk,negedge sys_rst_l)begin
    if(!sys_rst_l)begin
        temp1<=1'b1;
        temp2<=1'b1;
        end
        else begin
        temp1<=uart_REC_dataH;
        temp2<=temp1;
        end 
        end
endmodule

