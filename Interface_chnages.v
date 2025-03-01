`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.03.2025 11:10:52
// Design Name: 
// Module Name: AXI4_INTERFACE
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


module AXI4_INTERFACE#(
		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 6
	)
	(
		input                             S_AXI_ACLK,
		input                             S_AXI_ARESETN,
		input [C_S_AXI_ADDR_WIDTH-1 : 0]  S_AXI_AWADDR,
		input [2 : 0]                     S_AXI_AWPROT,
		input                             S_AXI_AWVALID,
		output                            S_AXI_AWREADY,   // This signal indicates that the slave is ready to accept an address		
		input [C_S_AXI_DATA_WIDTH-1 : 0]  S_AXI_WDATA,     // Write data sent by Master     
		input[(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
		input                             S_AXI_WVALID,    //This signal indicates that valid write data and stobes are available
		output                            S_AXI_WREADY,    //This signal indicates that the slave can accept data
		output[1 : 0]                     S_AXI_BRESP,     //Status of the write transaction.
		output                            S_AXI_BVALID,    // Write response valid.
		input                             S_AXI_BREADY,    //This signal indicates that the master can accept a write response.
		input[C_S_AXI_ADDR_WIDTH-1 : 0]   S_AXI_ARADDR,    // Read address issued by Master
		input[2 : 0]                      S_AXI_ARPROT,
		input                             S_AXI_ARVALID,   //Indicates that valid Read address and information
		output                            S_AXI_ARREADY,   //This signal indicates that the slave is ready to accept an address
		output[C_S_AXI_DATA_WIDTH-1 : 0]  S_AXI_RDATA,     // Read data (issued by slave)
		output[1 : 0]                     S_AXI_RRESP,     //Status of Read transfer
		output                            S_AXI_RVALID,
		input                             S_AXI_RREADY,     //Indicates that Master can accept data
		
		//Extra ports 
		output sdata_out,
		output serial_datain ,
		output[4:0] SDOUT_CNTR_1
	);
	
		// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;
	
    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 3;
	
		//ADC Configuration Registers 
	reg [C_S_AXI_DATA_WIDTH-1:0]	SW_RST_RW;
	reg [C_S_AXI_DATA_WIDTH-1:0]	Die_select;
	reg [C_S_AXI_DATA_WIDTH-1:0]	Clk_speed_DF_KSPS;
	reg [C_S_AXI_DATA_WIDTH-1:0]	DCLK_Edge_divide_rate;
	reg [C_S_AXI_DATA_WIDTH-1:0]	Data_Resolution;
	reg [C_S_AXI_DATA_WIDTH-1:0]	Sdout_En;
	reg [C_S_AXI_DATA_WIDTH-1:0]	Test_Sel_En;
	reg [C_S_AXI_DATA_WIDTH-1:0]	Default_0x15;
	reg [C_S_AXI_DATA_WIDTH-1:0]	Default_0x16;
	reg [C_S_AXI_DATA_WIDTH-1:0]	Default_0x17;
	reg [C_S_AXI_DATA_WIDTH-1:0]	Default_0x18;
	reg [C_S_AXI_DATA_WIDTH-1:0]	Default_0x19;
	reg [C_S_AXI_DATA_WIDTH-1:0]	Start;
	
    wire        slv_reg_rden;
	wire	    slv_reg_wren;
	reg [23:0]	reg_data_out;
	integer	    byte_index;
	reg	        aw_en;
	
    //Extra variables declaration 
    reg         Write_Reg , Read_Reg;
    reg         Write_Read;             //WR or RD mode selection
    wire        sen,sclk,sdin,rst;
    
    //Serial Data  Generation Related  internal signals 
    reg[4:0] Serial_Counter = 5'd0;
    reg Serial_Data_hold ;
    reg Disable_Write_Flag_0 = 0 , Disable_Write_Flag_1 = 0 , Disable_Write_Flag_2 = 0 , Disable_Write_Flag_3 = 0 , Disable_Write_Flag_4 = 0 , Disable_Write_Flag_5 = 0 , Disable_Write_Flag_6 = 0 ,
        Disable_Write_Flag_7 = 0 , Disable_Write_Flag_8 = 0 , Disable_Write_Flag_9 = 0 , Disable_Write_Flag_10 = 0 , Disable_Write_Flag_11 = 0 , Disable_Write_Flag_12 = 0 ;
    reg[3:0] Serial_State = 4'd0;
    reg      Serial_DelayFlag = 0; 
    localparam  Serial_0 = 0 , Serial_1 = 1 , Serial_2 = 2 , Serial_3 = 3 , Serial_4 = 4 , Serial_5 = 5 , Serial_6 = 6 , Serial_7 = 7 ,
                Serial_8 = 8 , Serial_9 = 9 , Serial_10 = 10 , Serial_11 = 11 , Serial_12 = 12;
    
    	// I/O Connections assignments
	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	
	assign serial_datain = Serial_Data_hold;
	
	
    reg[7:0]    ADC_ADDR;
    reg[15:0]   ADC_DATA;
    reg[4:0]    ADC_SCLK_CNTR = 5'd0;
    reg[3:0]    ADC_RD_SCLK_CNTR = 4'd0;
    reg         ADC_WR_RD_MODE;
    reg[4:0]    ADC_STATE = 0;
	
	//REGISTER CONFIG module Instantiation 
   Spi_Controller DUT(
            .clk(S_AXI_ACLK),
            .addr(ADC_ADDR),
            .data(ADC_DATA),
            .wr_mode(1'b1),
            .reset(1'b0),
            .sdout(adc_sdata_out),
            .sen(sen),
            .sclk(sclk),
            .resetn(rst),
            .sdin(sdin)
            );
    
    localparam  ADDR_0 = 0 , ADDR_1 = 1, ADDR_2 = 2, ADDR_3 = 3 , ADDR_4 = 4, ADDR_5 = 5, ADDR_6 = 6, ADDR_7 = 7, ADDR_8 = 8, ADDR_9 = 9,
                ADDR_10 = 10, ADDR_11 = 11, ADDR_12 = 12;
   
    localparam  RD_ADDR_0   = 13, RD_ADDR_1   = 14, RD_ADDR_2   = 15, RD_ADDR_3   = 16, RD_ADDR_4   = 17, RD_ADDR_5   = 18, RD_ADDR_6   = 19, 
                RD_ADDR_7   = 20, RD_ADDR_8   = 21, RD_ADDR_9   = 22, RD_ADDR_10  = 23, RD_ADDR_11  = 24, RD_ADDR_12  = 25;            
            
    
	// axi_awready generation logic
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// axi_awaddr latching Logic
	// This process is used to latch the address  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) 
//	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID )
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// axi_wready generation Logic
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
//	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID  )
	        begin
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Performing Write Operation on ADC Registers
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    //Write_Read control 	
    always @(posedge S_AXI_ACLK )
    begin 
        if(slv_reg_wren)
            Write_Read <= Write_Reg;
         else
            Write_Read <= Read_Reg;
    end 	
// -------------------------------------------- Write Operation -------------------------------------------  
// Receiving all Register's data from PS at a time , later storing in PL ADC's Reg's 

    reg SerialFlag_0   = 0 , SerialFlag_1 = 0 , SerialFlag_2 = 0 , SerialFlag_3 = 0 , SerialFlag_4 = 0 , SerialFlag_5 = 0 , SerialFlag_6 = 0 , SerialFlag_7 = 0 ,
        SerialFlag_8 = 0 , SerialFlag_9 = 0 , SerialFlag_10 = 0 , SerialFlag_11 = 0 , SerialFlag_12 = 0;
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      SW_RST_RW             <= 0;
	      Die_select            <= 0;
	      Clk_speed_DF_KSPS     <= 0;
	      DCLK_Edge_divide_rate <= 0;
	      Data_Resolution       <= 0;
	      Sdout_En              <= 0;
	      Test_Sel_En           <= 0;
	      Default_0x15          <= 0;
	      Default_0x16          <= 0;
	      Default_0x17          <= 0;
	      Default_0x18          <= 0;
	      Default_0x19          <= 0;
	      Start                 <= 0;
	    end 
	  else begin
	    if(slv_reg_wren) 
	      begin
	        case ( axi_awaddr )
	          6'h0:
	            for ( byte_index = 1; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    $display("axi_awaddr : %b" ,axi_awaddr );
	                Write_Reg <= 1;
	                SW_RST_RW[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                SerialFlag_0 <= 1'b1 ;
	              end  
	          6'h1:
	               
	            for ( byte_index = 1; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Die_select[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                SerialFlag_1 <= 1'b1 ;
	              end  
	          6'h2:
	            for ( byte_index = 1; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Clk_speed_DF_KSPS[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                SerialFlag_2 <= 1'b1 ;
	              end  
	          6'h3:
	            for ( byte_index = 1; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                DCLK_Edge_divide_rate[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                 SerialFlag_3 <= 1'b1 ;
	              end  
	          6'h4:
	            for ( byte_index = 1; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Data_Resolution[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                SerialFlag_4 <= 1'b1 ;
	              end  
	          6'h5:
	            for ( byte_index = 1; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Sdout_En[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                 SerialFlag_5 <= 1'b1 ;
	              end  
	          6'h6:
	            for ( byte_index = 1; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Test_Sel_En[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                SerialFlag_6 <= 1'b1 ;
	              end  
	          6'h7:
	            for ( byte_index = 1; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Default_0x15[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                 SerialFlag_7 <= 1'b1 ;
	              end  
	          6'h8:
	            for ( byte_index = 1; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Default_0x16[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                SerialFlag_8 <= 1'b1 ;
	              end  
	          6'h9:
	            for ( byte_index = 1; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Default_0x17[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                SerialFlag_9 <= 1'b1 ;
	              end  
	          6'hA:
	            for ( byte_index = 1; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Default_0x18[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                SerialFlag_10 <= 1'b1 ;
	              end  
	          6'hB:
	            for ( byte_index = 1; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Default_0x19[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                SerialFlag_11 <= 1'b1 ;
	              end  
	          6'hC:
	            for ( byte_index = 1; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Start[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                SerialFlag_12 <= 1'b1 ;
	              end  
	          default : begin
	                      SW_RST_RW <= SW_RST_RW;
	                      Die_select <= Die_select;
	                      Clk_speed_DF_KSPS <= Clk_speed_DF_KSPS;
	                      DCLK_Edge_divide_rate <= DCLK_Edge_divide_rate;
	                      Data_Resolution <= Data_Resolution;
	                      Sdout_En <= Sdout_En;
	                      Test_Sel_En <= Test_Sel_En;
	                      Default_0x15 <= Default_0x15;
	                      Default_0x16 <= Default_0x16;
	                      Default_0x17 <= Default_0x17;
	                      Default_0x18 <= Default_0x18;
	                      Default_0x19 <= Default_0x19;
	                      Start <= Start;
	                    end
	        endcase
	      end
	  end
	end    
   //------------------------------------------- Spi_Controller ADDR , DATA -------------------------------------     
    always@(posedge  sclk) 
    begin         
        case(ADC_STATE)
               ADDR_0 : begin
                           ADC_SCLK_CNTR    <= ADC_SCLK_CNTR + 1'b1;  
                           if(ADC_SCLK_CNTR <= 5'd24 ) 
                           begin
                                ADC_WR_RD_MODE  <= 1;
                                ADC_ADDR        <= SW_RST_RW[23:16];
                                ADC_DATA        <= SW_RST_RW[15:0];
                                ADC_STATE       <= ADDR_0;                           
                            end
                            else begin 
                                ADC_WR_RD_MODE  <= 0;
                                ADC_SCLK_CNTR   <= 5'd0;
                                ADC_STATE       <= ADDR_1;
                            end 
                        end                     
             ADDR_1 : begin
                        ADC_SCLK_CNTR    <= ADC_SCLK_CNTR + 1'b1;
                        if(ADC_SCLK_CNTR <= 5'd24 ) 
                        begin
                            ADC_WR_RD_MODE  <= 1; 
                            ADC_ADDR        <= Die_select[23:16];
                            ADC_DATA        <= Die_select[15:0];
                            ADC_STATE       <= ADDR_1;                           
                        end
                        else begin 
                            ADC_WR_RD_MODE  <= 0;
                            ADC_SCLK_CNTR   <= 5'd0;
                            ADC_STATE       <= ADDR_2;
                        end 
                     end             
             ADDR_2 : begin
                        ADC_SCLK_CNTR    <= ADC_SCLK_CNTR + 1'b1;
                        if(ADC_SCLK_CNTR <= 5'd24 )
                        begin
                            ADC_WR_RD_MODE  <= 1;
                            ADC_ADDR        <= Clk_speed_DF_KSPS[23:16];
                            ADC_DATA        <= Clk_speed_DF_KSPS[15:0];
                            ADC_STATE       <= ADDR_2;
                        end
                        else begin
                            ADC_WR_RD_MODE  <= 0;
                            ADC_SCLK_CNTR   <= 5'd0;
                            ADC_STATE       <= ADDR_3;
                        end 
                     end                   
            ADDR_3 : begin
                        ADC_SCLK_CNTR    <= ADC_SCLK_CNTR + 1'b1;
                        if(ADC_SCLK_CNTR <= 5'd24 )
                        begin
                            ADC_WR_RD_MODE  <= 1;
                            ADC_ADDR        <= DCLK_Edge_divide_rate[23:16];
                            ADC_DATA        <= DCLK_Edge_divide_rate[15:0];
                            ADC_STATE       <= ADDR_3;
                        end
                        else begin
                             ADC_WR_RD_MODE  <= 0;
                             ADC_SCLK_CNTR   <= 5'd0;                         
                             ADC_STATE       <= ADDR_4;                           
                        end 
                     end
                               
            ADDR_4 : begin
                        ADC_SCLK_CNTR    <= ADC_SCLK_CNTR + 1'b1;
                        if(ADC_SCLK_CNTR <= 5'd24 )
                        begin
                            ADC_WR_RD_MODE  <= 1; 
                            ADC_ADDR        <= Data_Resolution[23:16];
                            ADC_DATA        <= Data_Resolution[15:0];
                            ADC_STATE       <= ADDR_4;
                        end
                        else begin
                            ADC_WR_RD_MODE  <= 0;
                            ADC_SCLK_CNTR   <= 5'd0;
                            ADC_STATE       <= ADDR_5;
                        end
                     end                 
            ADDR_5 : begin
                        ADC_SCLK_CNTR    <= ADC_SCLK_CNTR + 1'b1;
                        if(ADC_SCLK_CNTR <= 5'd24 )
                        begin 
                            ADC_WR_RD_MODE  <= 1;
                            ADC_ADDR        <= Sdout_En[23:16];
                            ADC_DATA        <= Sdout_En[15:0];
                            ADC_STATE       <= ADDR_5;
                        end 
                        else begin 
                            ADC_WR_RD_MODE  <= 0;
                            ADC_SCLK_CNTR   <= 5'd0;
                            ADC_STATE       <= ADDR_6;                      
                        end 
                     end
                  
            ADDR_6 : begin
                        ADC_SCLK_CNTR    <= ADC_SCLK_CNTR + 1'b1;
                        if(ADC_SCLK_CNTR <= 5'd24 )
                        begin 
                            ADC_WR_RD_MODE  <= 1;
                            ADC_ADDR        <= Test_Sel_En[23:16];
                            ADC_DATA        <= Test_Sel_En[15:0];
                            ADC_STATE       <= ADDR_6;
                        end 
                        else begin 
                            ADC_WR_RD_MODE  <= 0;
                            ADC_SCLK_CNTR   <= 5'd0;
                            ADC_STATE       <= ADDR_7;                      
                        end 
                     end

            ADDR_7 : begin
                        ADC_SCLK_CNTR    <= ADC_SCLK_CNTR + 1'b1;
                        if(ADC_SCLK_CNTR <= 5'd24 )
                        begin 
                            ADC_WR_RD_MODE  <= 1;
                            ADC_ADDR        <= Default_0x15[23:16];
                            ADC_DATA        <= Default_0x15[15:0];
                            ADC_STATE       <= ADDR_7;
                        end 
                        else begin 
                            ADC_WR_RD_MODE  <= 0;
                            ADC_SCLK_CNTR   <= 5'd0;
                            ADC_STATE       <= ADDR_8;                      
                        end 
                     end
                                           
            ADDR_8 : begin
                        ADC_SCLK_CNTR    <= ADC_SCLK_CNTR + 1'b1;
                        if(ADC_SCLK_CNTR <= 5'd24 )
                        begin 
                            ADC_WR_RD_MODE  <= 1;
                            ADC_ADDR        <= Default_0x16[23:16];
                            ADC_DATA        <= Default_0x16[15:0];
                            ADC_STATE       <= ADDR_8;
                        end 
                        else begin 
                            ADC_WR_RD_MODE  <= 0;
                            ADC_SCLK_CNTR   <= 5'd0;
                            ADC_STATE       <= ADDR_9;                      
                        end 
                     end

            ADDR_9 : begin
                        ADC_SCLK_CNTR    <= ADC_SCLK_CNTR + 1'b1;
                        if(ADC_SCLK_CNTR <= 5'd24 )
                        begin 
                            ADC_WR_RD_MODE  <= 1;
                            ADC_ADDR        <= Default_0x17[23:16];
                            ADC_DATA        <= Default_0x17[15:0];
                            ADC_STATE       <= ADDR_9;
                        end 
                        else begin 
                            ADC_WR_RD_MODE  <= 0;
                            ADC_SCLK_CNTR   <= 5'd0;
                            ADC_STATE       <= ADDR_10;                      
                        end 
                     end

            ADDR_10 : begin
                        ADC_SCLK_CNTR    <= ADC_SCLK_CNTR + 1'b1;
                        if(ADC_SCLK_CNTR <= 5'd24 )
                        begin 
                            ADC_WR_RD_MODE  <= 1;
                            ADC_ADDR        <= Default_0x18[23:16];
                            ADC_DATA        <= Default_0x18[15:0];
                            ADC_STATE       <= ADDR_10;
                        end 
                        else begin 
                            ADC_WR_RD_MODE  <= 0;
                            ADC_SCLK_CNTR   <= 5'd0;
                            ADC_STATE       <= ADDR_11;                      
                        end 
                     end

            ADDR_11 : begin
                        ADC_SCLK_CNTR    <= ADC_SCLK_CNTR + 1'b1;
                        if(ADC_SCLK_CNTR <= 5'd24 )
                        begin 
                            ADC_WR_RD_MODE  <= 1;
                            ADC_ADDR        <= Default_0x19[23:16];
                            ADC_DATA        <= Default_0x19[15:0];
                            ADC_STATE       <= ADDR_11;
                        end 
                        else begin 
                            ADC_WR_RD_MODE  <= 0;
                            ADC_SCLK_CNTR   <= 5'd0;
                            ADC_STATE       <= ADDR_12;                      
                        end 
                     end

            ADDR_12 : begin
                        ADC_SCLK_CNTR    <= ADC_SCLK_CNTR + 1'b1;
                        if(ADC_SCLK_CNTR <= 5'd25 )
                        begin 
                            ADC_WR_RD_MODE  <= 1;
                            ADC_ADDR        <= Start[23:16];
                            ADC_DATA        <= Start[15:0];
                            ADC_STATE       <= ADDR_12;
                        end 
                        else begin 
                            ADC_WR_RD_MODE  <= 0;
                            ADC_SCLK_CNTR   <= 5'd0;                       
                        end 
                     end
            default : ; 
        endcase
    end      
    
    //------------------------------------------ Sdin Generation --------------------------------------
    
    always@(posedge sclk)
    begin
        if(Serial_Counter < 5'd1 && Serial_DelayFlag == 1'b0 ) begin
            Serial_Counter <= Serial_Counter + 1'b1 ;
        end 
        else if(Serial_Counter == 5'd1 && Serial_DelayFlag == 1'b0)
        begin
            Serial_Counter <= 5'd0 ;
            Serial_DelayFlag   <= 1'b1 ;
        end
        else begin
        case(Serial_State)
            Serial_0 : begin
                            if(SerialFlag_0 == 1'b1 && Disable_Write_Flag_0 == 1'b0) 
                            begin
                                Serial_Counter <= Serial_Counter + 1'b1 ;
                                if(Serial_Counter < 5'd24)
                                begin
                                    Serial_Data_hold <= SW_RST_RW[Serial_Counter];
                                end
                                else begin
                                    Disable_Write_Flag_0 <= 1'b1 ;
                                    Serial_Counter        <= 5'd0 ;                              
                                end
                             end  
                             else  begin
                                Serial_State          <= Serial_1 ;
                             end
                        end 
            Serial_1 : begin
                            if(SerialFlag_1 == 1'b1 && Disable_Write_Flag_1 == 1'b0) 
                            begin
                                Serial_Counter <= Serial_Counter + 1'b1 ;
                                if(Serial_Counter < 5'd24)
                                begin
                                    Serial_Data_hold <= Die_select[Serial_Counter];
                                end
                                else begin
                                    Disable_Write_Flag_1 <= 1'b1 ;
                                    Serial_Counter        <= 5'd0 ;                              
                                end
                             end  
                             else  begin
                                Serial_State          <= Serial_2 ;
                             end
                        end   
            Serial_2 : begin
                            if(SerialFlag_2 == 1'b1 && Disable_Write_Flag_2 == 1'b0) 
                            begin
                                Serial_Counter <= Serial_Counter + 1'b1 ;
                                if(Serial_Counter < 5'd24)
                                begin
                                    Serial_Data_hold <= Clk_speed_DF_KSPS[Serial_Counter];
                                end
                                else begin
                                    Disable_Write_Flag_2 <= 1'b1 ;
                                    Serial_Counter        <= 5'd0 ;                              
                                end
                             end  
                             else  begin
                                Serial_State          <= Serial_3 ;
                             end
                        end    
            Serial_3 : begin
                            if(SerialFlag_3 == 1'b1 && Disable_Write_Flag_3 == 1'b0) 
                            begin
                                Serial_Counter <= Serial_Counter + 1'b1 ;
                                if(Serial_Counter < 5'd24)
                                begin
                                    Serial_Data_hold <= DCLK_Edge_divide_rate[Serial_Counter];
                                end
                                else begin
                                    Disable_Write_Flag_3  <= 1'b1 ;
                                    Serial_Counter        <= 5'd0 ;                              
                                end
                             end  
                             else  begin
                                Serial_State          <= Serial_4 ;
                             end
                        end     
            Serial_4 : begin
                            if(SerialFlag_4 == 1'b1 && Disable_Write_Flag_4 == 1'b0) 
                            begin
                                Serial_Counter <= Serial_Counter + 1'b1 ;
                                if(Serial_Counter < 5'd24)
                                begin
                                    Serial_Data_hold <= Data_Resolution[Serial_Counter];
                                end
                                else begin
                                    Disable_Write_Flag_4 <= 1'b1 ;
                                    Serial_Counter        <= 5'd0 ;                              
                                end
                             end  
                             else  begin
                                Serial_State          <= Serial_5 ;
                             end
                        end      
            Serial_5 : begin
                            if(SerialFlag_5 == 1'b1 && Disable_Write_Flag_5 == 1'b0) 
                            begin
                                Serial_Counter <= Serial_Counter + 1'b1 ;
                                if(Serial_Counter < 5'd24)
                                begin
                                    Serial_Data_hold <= Sdout_En[Serial_Counter];
                                end
                                else begin
                                    Disable_Write_Flag_5 <= 1'b1 ;
                                    Serial_Counter        <= 5'd0 ;                              
                                end
                             end  
                             else  begin
                                Serial_State          <= Serial_6 ;
                             end
                        end 
            Serial_6 : begin
                            if(SerialFlag_6 == 1'b1 && Disable_Write_Flag_6 == 1'b0) 
                            begin
                                Serial_Counter <= Serial_Counter + 1'b1 ;
                                if(Serial_Counter < 5'd24)
                                begin
                                    Serial_Data_hold <= Test_Sel_En[Serial_Counter];
                                end
                                else begin
                                    Disable_Write_Flag_6 <= 1'b1 ;
                                    Serial_Counter        <= 5'd0 ;                              
                                end
                             end  
                             else  begin
                                Serial_State          <= Serial_7 ;
                             end
                        end
            Serial_7 : begin
                            if(SerialFlag_7 == 1'b1 && Disable_Write_Flag_7 == 1'b0) 
                            begin
                                Serial_Counter <= Serial_Counter + 1'b1 ;
                                if(Serial_Counter < 5'd24)
                                begin
                                    Serial_Data_hold <= Default_0x15[Serial_Counter];
                                end
                                else begin
                                    Disable_Write_Flag_7 <= 1'b1 ;
                                    Serial_Counter        <= 5'd0 ;                              
                                end
                             end  
                             else  begin
                                Serial_State          <= Serial_8 ;
                             end
                      end 
            Serial_8 : begin
                            if(SerialFlag_8 == 1'b1 && Disable_Write_Flag_8 == 1'b0) 
                            begin
                                Serial_Counter <= Serial_Counter + 1'b1 ;
                                if(Serial_Counter < 5'd24)
                                begin
                                    Serial_Data_hold <= Default_0x16[Serial_Counter];
                                end
                                else begin
                                    Disable_Write_Flag_8 <= 1'b1 ;
                                    Serial_Counter        <= 5'd0 ;                              
                                end
                             end  
                             else  begin
                                Serial_State          <= Serial_9 ;
                             end
                      end
            Serial_9 : begin
                            if(SerialFlag_9 == 1'b1 && Disable_Write_Flag_9 == 1'b0) 
                            begin
                                Serial_Counter <= Serial_Counter + 1'b1 ;
                                if(Serial_Counter < 5'd24)
                                begin
                                    Serial_Data_hold <= Default_0x17[Serial_Counter];
                                end
                                else begin
                                    Disable_Write_Flag_9 <= 1'b1 ;
                                    Serial_Counter        <= 5'd0 ;                              
                                end
                             end  
                             else  begin
                                Serial_State          <= Serial_10 ;
                             end
                      end   
           Serial_10 : begin
                            if(SerialFlag_10 == 1'b1 && Disable_Write_Flag_10 == 1'b0) 
                            begin
                                Serial_Counter <= Serial_Counter + 1'b1 ;
                                if(Serial_Counter < 5'd24)
                                begin
                                    Serial_Data_hold <= Default_0x18[Serial_Counter];
                                end
                                else begin
                                    Disable_Write_Flag_10 <= 1'b1 ;
                                    Serial_Counter        <= 5'd0 ;                              
                                end
                             end  
                             else  begin
                                Serial_State          <= Serial_10 ;
                             end
                      end    
           Serial_11 : begin
                            if(SerialFlag_11 == 1'b1 && Disable_Write_Flag_11 == 1'b0) 
                            begin
                                Serial_Counter <= Serial_Counter + 1'b1 ;
                                if(Serial_Counter < 5'd24)
                                begin
                                    Serial_Data_hold <= Default_0x19[Serial_Counter];
                                end
                                else begin
                                    Disable_Write_Flag_11 <= 1'b1 ;
                                    Serial_Counter        <= 5'd0 ;                              
                                end
                             end  
                             else  begin
                                Serial_State          <= Serial_12 ;
                             end
                      end
           Serial_12 : begin
                            if(SerialFlag_12 == 1'b1 && Disable_Write_Flag_12 == 1'b0) 
                            begin
                                Serial_Counter <= Serial_Counter + 1'b1 ;
                                if(Serial_Counter < 5'd24)
                                begin
                                    Serial_Data_hold <= Start[Serial_Counter];
                                end
                                else begin
                                    Disable_Write_Flag_12 <= 1'b1 ;
                                    Serial_Counter        <= 5'd0 ;                              
                                end
                             end  
                             else  begin
//                                Serial_State          <= Serial_9 ;
                             end
                      end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
                    default ;
        endcase 
        end
    end      
    
	// Write response Logic 
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// axi_arready Logic 
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          axi_arready <= 1'b1;             // indicates that the slave has acceped the valid read address
	          axi_araddr  <= S_AXI_ARADDR;     // Read address latching
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// axi_arvalid Logic
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          
	          axi_rvalid <= 1'b1;              // Valid read data is available at the read data bus
	          axi_rresp  <= 2'b0;              // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
                  axi_rvalid <= 1'b0;       // Read data is accepted by the master
	        end                
	    end
	end    
	
	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address 
	      if (slv_reg_rden)
	        begin
	          axi_rdata[23:0] <= reg_data_out;     // register read data
	        end   
	    end
	end    
endmodule
