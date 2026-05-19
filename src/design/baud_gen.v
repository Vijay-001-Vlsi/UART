module baudclk_gen#(parameter freq=100,b_rate=2)(sys_clk,b_clk);

  input sys_clk;

  output reg b_clk=0;

  reg [12:0] cnt=0;

   localparam b_cnt=freq/b_rate; 

  always@(posedge sys_clk)

      begin

        if(cnt==(b_cnt/16*2)-1)

          begin

            b_clk<=~b_clk;

            cnt<=0;

           end

          else cnt<=cnt+1;

      end
 


endmodule
 
