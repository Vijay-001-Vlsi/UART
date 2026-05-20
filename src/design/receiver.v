`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.05.2026 13:55:13
// Design Name: 
// Module Name: rx
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


module rx#(parameter width=8)(
input b_clk,sys_rst_l,uart_REC_dataH,
output reg[width-1:0]rec_dataH,
output reg rec_readyH,rec_busy
    );
 reg [1:0]ps,ns;
 reg [3:0]count;
 reg [7:0]store;
 reg[2:0]bit_count;
 localparam idle=0,start_r=1,data_r=2,stop_r=3;
 always @(posedge b_clk,negedge sys_rst_l)begin
    if(!sys_rst_l)begin
        ps <= idle;
      end
        else
            ps<=ns;
        end
    always @(posedge b_clk or negedge sys_rst_l) begin
        if(!sys_rst_l)
            count <= 4'd0;
        else begin
            if(ps != ns)
                count <= 4'd0;
            else if(count == 4'd15)
                count <= 4'd0;

            else
                count <= count + 1'b1;
        end
    end

always @(posedge b_clk or negedge sys_rst_l) begin
        if(!sys_rst_l)
            bit_count <= 3'd0;

        else begin
            if(ps!=data_r)
                bit_count <= 3'd0;

            else if(count==4'd15)
                bit_count <=bit_count+1 ;
        end
    end
    always @(posedge b_clk or negedge sys_rst_l) begin
        if (!sys_rst_l)
            store <= 8'd0;
        else if (ps == data_r && count == 4'd5)
            store[bit_count] <= uart_REC_dataH;
    end
        
     always @(*) begin
        case (ps)
            idle:    ns = (~uart_REC_dataH)           ? start_r : idle;
            start_r: ns = (count == 4'd15)            ? data_r  : start_r;
            data_r:  ns = (bit_count == 3'd7 && count == 4'd15) ? stop_r  : data_r;
            stop_r:  ns = (uart_REC_dataH && count == 4'd15)   ? idle    : stop_r;
            default: ns = idle;
        endcase
    end

        always @(*) begin
        if (!sys_rst_l) begin
            rec_dataH  = 8'd0;
            rec_readyH = 1'b0;
            rec_busy   = 1'b0;
        end else begin
            case (ps)
                idle: begin
                    rec_readyH = 1'b1;
                    rec_busy   = 1'b0;
                end
                start_r: begin
                    rec_readyH = 1'b0;
                    rec_busy   = 1'b1;
                end
                data_r: begin
                    rec_readyH = 1'b0;
                    rec_busy   = 1'b1;
                end
                stop_r: begin
                    if(count==5)
                         rec_dataH  = store;   // latch full byte now
                    if(uart_REC_dataH && count==13)begin
                        rec_readyH = 1'b1;   
                        rec_busy   = 1'b0;
                        ns=idle;
                    end
                    
                end
            endcase
        end
    end
                       
endmodule

