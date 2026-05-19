`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.05.2026 15:18:28
// Design Name: 
// Module Name: tx
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


module tx #(parameter width=8)(
input b_clk,sys_rst_l,
input xmitH,
input [width-1:0]xmit_dataH,
output reg uart_XMIT_dataH,xmit_doneH,xmit_active
);
integer i;
reg [1:0]ps,ns;
localparam idle=0,start=1,data_trans=2,stop=3;
reg [3:0]count;

always @(posedge b_clk,negedge sys_rst_l)begin
    if(!sys_rst_l)
        count<=4'd0;
    else begin
        if(ps==idle)
            count<=4'd0;
        else begin
            if(count==4'd15)
                 count<=4'd0;
            else
                 count<=count+1;
         end
         end
         end
        
always @(posedge b_clk or negedge sys_rst_l) begin
    if(!sys_rst_l) begin
        ps <= idle;
        i <= 0;

    end
    else begin
        ps <= ns;
        if(ps == data_trans && count == 15) begin
            if(i != 7)
                i <= i + 1;
            else
                i <= 0;
        end
    end
end
 
 always @(*)begin
//    uart_XMIT_dataH = 1'b1;
//    xmit_active = 1'b0;
//    xmit_doneH = 1'b0;
    case(ps)
        idle:begin 
            ns=(xmitH)?start:idle; 
            uart_XMIT_dataH = 1'b1;
            xmit_active = 1'b0;
            if(!sys_rst_l)
             xmit_doneH = 1'b0;
            else
                 xmit_doneH = 1'b1;    
                         end
        start:begin 
           xmit_doneH=(xmitH)?1'b0:1'b1;
             xmit_doneH = 1'b0;
                uart_XMIT_dataH=0;
                xmit_active=1'b1; 
               
                if(count==15)
                    ns=data_trans;
                else
                    ns=start;
                end
        data_trans: begin
        uart_XMIT_dataH = xmit_dataH[i];
        xmit_active=1'b1;
        xmit_doneH = 1'b0;
        if(count == 15 && i==7) 
            ns=stop;
            end
  stop: begin
    uart_XMIT_dataH = 1'b1;
    if (count == 15) begin
        xmit_doneH  = 1'b1;
        xmit_active = 1'b0;
        ns = idle;
    end else
        ns = stop;   // ← add this
end
         default:ns=idle;
        
endcase
end                
endmodule

