`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.03.2025 11:10:52
// Design Name: 
// Module Name: Spi_Controller
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


module Spi_Controller(	
		input clk,
		input [7:0]addr,
		input [15:0]data,
		input wr_mode,
		input reset,
		input sdout,
		output reg sen,
		output  sclk,
		output reg resetn,
		output reg sdin
		);		
//---------internal register----------

	reg[5:0]count = 6'd0;
	reg [23:0] shift_reg;
	
	reg [15:0] rdshift_reg;
	reg[2:0] state = 3'b0;
	reg [7:0]rd_add ; 
		
	localparam idle=3'b000;
	localparam start=3'b001;
	localparam transmit=3'b010;
	localparam read=3'b011;
	localparam	done=3'b100;

//Sclk Generation
reg     new_sclk = 0;
assign sclk = new_sclk;

//sen control signals 
reg      sen_flag = 0;
reg[2:0] sen_cntr = 3'd0;

always@(posedge clk)
	begin
	   new_sclk <= ~new_sclk;
		if(reset)
			begin
				resetn<=1'b0;
				rdshift_reg<=23'b0;
				state<= idle;
			end			
		else 
			begin				
				resetn <= 1'b1;
				case(state)					
					idle:	begin
					       if(sen_flag) 
					       begin
                                sen<=1'b1;                             					
                                if(wr_mode==1'b1)
                                begin
                                    shift_reg<={addr,data};	
                                    state<=start;
                                end
                                else if(wr_mode==1'b0)
                                    begin
                                        rd_add<={addr}; 
                                        state<=read;
                                    end
                            end
                            else begin
                                sen_cntr <= sen_cntr + 1;
                                if(sen_cntr == 4)
                                begin
                                    sen_flag    <= 1;
                                    state       <= idle ;
                                end 
                            end 
	                        end
		
					start:  begin
								count<=5'd0;
								sen<=1'b0;
								state<=transmit;
							end
							 
				 transmit:  begin
                                if(count<24 && wr_mode==1'b1)
                                   begin
                                        sen<=1'b0;
										if(sclk==1'b1)
											begin
                                                sdin<=shift_reg[23];
                                                shift_reg<={shift_reg[22:0],1'b0};
                                                count<=count+1'b1;
											end
										state<=transmit;
									end	
											
								else
                                    begin
                                        state <= done;
                                    end
                            end					
                      read: begin
                                if(count<24  && wr_mode==1'b0)
                                    begin
                                        sen<=1'b0;
                                        if(sclk==1'b1)
                                            begin
                                                sdin<=rd_add[7]; 
                                                rd_add<={rd_add[6:0],1'b0};
                                                count<=count+1'b1;
										    end
										else if(count > 8)
										  begin
                                                rdshift_reg<={rdshift_reg[15:0],sdout};
									      end
										  state<=read;
                                    end
								else
                                    begin
                                        state<=done;
                                    end
                            end		
                      done: begin
                                count <= 5'd0;
                                sen<=1'b1;
                                state<=idle;
							end
				endcase
          end
    end	
endmodule

