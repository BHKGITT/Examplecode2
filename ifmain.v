

/*	module interface #
	(
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
		input sdout,
		output reg sen,
		output  sclk,
		output reg resetn,
		output reg sdin
		
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

	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 3;

	//ADC Configuration Registers 
	reg [C_S_AXI_DATA_WIDTH-1:0]	SW_RST_RW;               // 1-> Reset the registers (self clears back to zero)
	reg [C_S_AXI_DATA_WIDTH-1:0]	Die_select;              // Selects the die from which to read back to the registers:   0: Bottom Die, 1: Top Die
	reg [C_S_AXI_DATA_WIDTH-1:0]	Clk_speed_DF_KSPS;      // 00: 32 MHz, 01: 16 MHz, 10: 32 MHz,  11: 8 MHz.
	reg [C_S_AXI_DATA_WIDTH-1:0]	Data_Resolution_0x12;   // 0 indicates 24 bit and 1 indicates 20 bits 
	reg [C_S_AXI_DATA_WIDTH-1:0]	odd_ch_0x13;           // [7:0] for odd channels
	reg [C_S_AXI_DATA_WIDTH-1:0]	odd_ch_0x14;          // [15:0] for odd channels
	reg [C_S_AXI_DATA_WIDTH-1:0]	Default_0x15;        //[15:0] for 48 bit header
	reg [C_S_AXI_DATA_WIDTH-1:0]	Default_0x16;        //[15:0] for 48 bit header
	reg [C_S_AXI_DATA_WIDTH-1:0]	Default_0x17;       //[15:0] for 48 bit header
	reg [C_S_AXI_DATA_WIDTH-1:0]	Default_0x18;      //[7:0] for 24 bit trail
	reg [C_S_AXI_DATA_WIDTH-1:0]	Default_0x19;     //[15:0] for 24 bit trail
	reg [C_S_AXI_DATA_WIDTH-1:0]	test_patt_0x1A;   // To enable Tets_Patterns and customizing even channels
	reg [C_S_AXI_DATA_WIDTH-1:0]	test_patt_0x1B;  // To select even channels                                       
	reg [C_S_AXI_DATA_WIDTH-1:0]	LVDS_CMOS_0x3A;
	reg [C_S_AXI_DATA_WIDTH-1:0]	Start;
	
	
	
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [23:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;
    
    //Extra variables declaration 
    reg         Write_Reg , Read_Reg;
    reg         Write_Read;
    reg [23:0] shift_reg=24'd0;
   // wire        sclk,rst;
 
     // I/O Connections assignments
	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	
	//assign serial_datain = Serial_Data_hold;
	           
    
    reg[4:0]    ADC_SCLK_CNTR = 5'd0;
    reg[3:0]    ADC_RD_SCLK_CNTR = 4'd0;
    reg         ADC_WR_RD_MODE;
    reg[4:0]    ADC_STATE = 0; 
  

    localparam  ADDR_0 = 0;
    localparam  ADDR_1 = 1;
    localparam  ADDR_2 = 2;
    localparam  ADDR_3 = 3;
    localparam  ADDR_4 = 4;
    localparam  ADDR_5 = 5;
    localparam  ADDR_6 = 6;
    localparam  ADDR_7 = 7;
    localparam  ADDR_8 = 8;
    localparam  ADDR_9 = 9;
    localparam  ADDR_10 = 10;
    localparam  ADDR_11 = 11;
    localparam  ADDR_12 = 12;
    localparam  ADDR_13 = 13;
    localparam  ADDR_14 = 14;
    
 
    localparam  RD_ADDR_1   = 15;
    localparam  RD_ADDR_2   = 16;
    localparam  RD_ADDR_3   = 17;
    localparam  RD_ADDR_4   = 18;
    localparam  RD_ADDR_5   = 19;
    localparam  RD_ADDR_6   = 20;
    localparam  RD_ADDR_7   = 21;
    localparam  RD_ADDR_8   = 22;
    localparam  RD_ADDR_9  = 23;
    localparam  RD_ADDR_10  = 24;
    localparam  RD_ADDR_11  = 25;
    localparam  RD_ADDR_12  = 26;
        
//  assign serial_datain = sdin;
  
  

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
//	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID )
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

   
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	                      SW_RST_RW <= 0;
	                      Die_select <= 0;
	                      Clk_speed_DF_KSPS <= 0;
	                      Data_Resolution_0x12 <= 0;
	                      odd_ch_0x13 <= 0;
	                      odd_ch_0x14 <= 0;
	                      Default_0x15 <= 0;
	                      Default_0x16 <= 0;
	                      Default_0x17 <= 0;
	                      Default_0x18 <= 0;
	                      Default_0x19 <= 0;
	                      test_patt_0x1A <= 0;
	                      test_patt_0x1B <=0;
	                      LVDS_CMOS_0x3A <= 0;
	                      Start <= 0;
	   
	    end 
	  else begin
	    if(slv_reg_wren) 
	      begin
//	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        case ( axi_awaddr )
	          6'h0:begin
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                  $display("axi_awaddr : %b" ,axi_awaddr );
	                Write_Reg <= 1;
	                SW_RST_RW[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end 

	              end 
	               
	          6'h1:begin
	            for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Die_select[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end 

	              end 
	          6'h2:begin
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Clk_speed_DF_KSPS[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end 

	              end  
	          6'h3:begin
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Data_Resolution_0x12[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  

	              end
	          6'h4:begin
	            for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	               Write_Reg <= 1;
	                odd_ch_0x13[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end

	              end  
	          6'h5:begin
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                odd_ch_0x14[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  

	             end
	          6'h6:begin
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Default_0x15[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
 
	              end
	          6'h7:begin
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Default_0x16[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  

	             end
	          6'h8:begin
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Default_0x17[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end 

	             end
	          6'h9:begin
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Default_0x18[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end 

	             end 
	          6'hA:begin
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Default_0x19[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end

	             end
	          6'hB:begin
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                test_patt_0x1A[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end

	             end
	          6'hC:begin
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                test_patt_0x1B[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end

	             end  
	              
	           6'hD:begin
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                LVDS_CMOS_0x3A[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end 

	             end
	           6'hE:begin
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                Write_Reg <= 1;
	                Start[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	
	             end
	          default : begin
	                      SW_RST_RW <= SW_RST_RW;
	                      Die_select <= Die_select;
	                      Clk_speed_DF_KSPS <= Clk_speed_DF_KSPS;
	                      Data_Resolution_0x12 <= Data_Resolution_0x12;
	                      odd_ch_0x13 <= odd_ch_0x13;
	                      odd_ch_0x14 <= odd_ch_0x14;
	                      Default_0x15 <= Default_0x15;
	                      Default_0x16 <= Default_0x16;
	                      Default_0x17 <= Default_0x17;
	                      Default_0x18 <= Default_0x18;
	                      Default_0x19 <= Default_0x19;
	                      test_patt_0x1A <= test_patt_0x1A;
	                      test_patt_0x1B <=test_patt_0x1B;
	                      LVDS_CMOS_0x3A <= LVDS_CMOS_0x3A;
	                      Start <= Start;
	                    end
	        endcase
	      end
	  end
	end 
	//////////////////////////////////////////////
reg [3:0] new_count=4'd0;
	always @(posedge S_AXI_ACLK)
	begin
	new_count <= new_count + 1'b1;
	   if(S_AXI_ARESETN==0)
	   begin
	   sdin<=0;
	   end
	   
	   else if(new_count < 4'd3)
	   begin
	       sdin<=1'b1;
	   end
	   
	   else
	   begin
	       sdin<=0;
	   end
	 end      
//////////////////////////////////////////////////////////////////////////////////////
	
reg     new_sclk = 0;
assign sclk = new_sclk;
reg      sen_flag = 0;
reg[2:0] sen_cntr = 3'd0;

 always@(posedge  S_AXI_ACLK) 
    begin   
    new_sclk <= ~new_sclk;  
     if ( S_AXI_ARESETN == 1'b0 )
	  begin
	   resetn<=1'b0;
	   sdin<=0;
	 end	
	
	 else 
	  begin				
		resetn <= 1'b1; 
    if(Start[0]==1'b1)
    begin   
     
        case(ADC_STATE)
             
               ADDR_0 : begin
                        if(sen_flag)
                        begin
                            sen<=1'b1;
                                ADC_WR_RD_MODE <=1'b1;
                                ADC_SCLK_CNTR<=5'd0;
                                shift_reg <=SW_RST_RW[23:0];
                                ADC_STATE <=ADDR_1;
                        end 
                        
                        else  begin  
                            sen_cntr <= sen_cntr + 1;
                                if(sen_cntr == 4)
                                begin
                                    sen_flag    <= 1;
                                    ADC_STATE       <= ADDR_0 ;
                                end 
                            end 
	                     end
                       
                     
             ADDR_1 : begin
                      
                        
                       if(ADC_SCLK_CNTR<=24 && ADC_WR_RD_MODE==1'b1)
                        begin
                        
                         sen<=1'b0;
							if(sclk==1'b1)
							begin
                              sdin<=shift_reg[23];
                              shift_reg<={shift_reg[22:0],1'b0};
                             ADC_SCLK_CNTR<=ADC_SCLK_CNTR+1'b1;
							 end
							
							ADC_STATE<=ADDR_1;
						end	
					   
                           
						
                        else  begin
                            ADC_SCLK_CNTR   <= 5'd0;
                            sen<=1'b1;
                             shift_reg <=Die_select[23:0];
                            ADC_STATE       <= ADDR_2;
                         end
                        end
                     
                         
             ADDR_2 : begin
                   
                     
                       if(ADC_SCLK_CNTR<=24 && ADC_WR_RD_MODE==1'b1)
                        begin
                      
                         sen<=1'b0;
							if(sclk==1'b1)
							begin
                              sdin<=shift_reg[23];
                              shift_reg<={shift_reg[22:0],1'b0};
                              ADC_SCLK_CNTR<=ADC_SCLK_CNTR+1'b1;
							 end
							ADC_STATE<=ADDR_2;
									end	
					 
                        else begin
                        
                            ADC_SCLK_CNTR   <= 5'd0;
                            sen<=1'b1;
                                shift_reg <=Clk_speed_DF_KSPS[23:0];
                            ADC_STATE       <= ADDR_3;
                        end
                     end
                               
            ADDR_3 : begin
                        if(ADC_SCLK_CNTR<=24 && ADC_WR_RD_MODE==1'b1)
                        begin
                     
                         sen<=1'b0;
							if(sclk==1'b1)
							begin
                              sdin<=shift_reg[23];
                              shift_reg<={shift_reg[22:0],1'b0};
                              ADC_SCLK_CNTR<=ADC_SCLK_CNTR+1'b1;
							 end
							ADC_STATE<=ADDR_3;
									end	
					 
                        else begin
                        
                            ADC_SCLK_CNTR   <= 5'd0;
                            sen<=1'b1;
                             shift_reg <=Data_Resolution_0x12[23:0];
                            ADC_STATE       <= ADDR_4;
                        end
                     end
                              
            ADDR_4 : begin
                         if(ADC_SCLK_CNTR<=24 && ADC_WR_RD_MODE==1'b1)
                        begin
                     
                         sen<=1'b0;
							if(sclk==1'b1)
							begin
                              sdin<=shift_reg[23];
                              shift_reg<={shift_reg[22:0],1'b0};
                              ADC_SCLK_CNTR<=ADC_SCLK_CNTR+1'b1;
							 end
							ADC_STATE<=ADDR_4;
									end	
					 
                        else begin
                        
                            ADC_SCLK_CNTR   <= 5'd0;
                            sen<=1'b1;
                             shift_reg <=odd_ch_0x13[23:0];
                            ADC_STATE       <= ADDR_5;
                        end
                     end
              
            ADDR_5 : begin
                       if(ADC_SCLK_CNTR<=24 && ADC_WR_RD_MODE==1'b1)
                        begin
                     
                         sen<=1'b0;
							if(sclk==1'b1)
							begin
                              sdin<=shift_reg[23];
                              shift_reg<={shift_reg[22:0],1'b0};
                              ADC_SCLK_CNTR<=ADC_SCLK_CNTR+1'b1;
							 end
							ADC_STATE<=ADDR_5;
									end	
					 
                        else begin
                        
                            ADC_SCLK_CNTR   <= 5'd0;
                            sen<=1'b1;
                             shift_reg <=odd_ch_0x14[23:0];
                            ADC_STATE       <= ADDR_6;
                        end
                     end

            ADDR_6 : begin
                         if(ADC_SCLK_CNTR<=24 && ADC_WR_RD_MODE==1'b1)
                        begin
                     
                         sen<=1'b0;
							if(sclk==1'b1)
							begin
                              sdin<=shift_reg[23];
                              shift_reg<={shift_reg[22:0],1'b0};
                              ADC_SCLK_CNTR<=ADC_SCLK_CNTR+1'b1;
							 end
							ADC_STATE<=ADDR_6;
									end	
					 
                        else begin
                        
                            ADC_SCLK_CNTR   <= 5'd0;
                            sen<=1'b1;
                             shift_reg <=Default_0x15[23:0];
                            ADC_STATE       <= ADDR_7;
                        end
                     end
                                                      
            ADDR_7 : begin
                        if(ADC_SCLK_CNTR<=24 && ADC_WR_RD_MODE==1'b1)
                        begin
                     
                         sen<=1'b0;
							if(sclk==1'b1)
							begin
                              sdin<=shift_reg[23];
                              shift_reg<={shift_reg[22:0],1'b0};
                              ADC_SCLK_CNTR<=ADC_SCLK_CNTR+1'b1;
							 end
							ADC_STATE<=ADDR_7;
									end	
					 
                        else begin
                        
                            ADC_SCLK_CNTR   <= 5'd0;
                            sen<=1'b1;
                             shift_reg <=Default_0x16[23:0];
                            ADC_STATE       <= ADDR_8;
                        end
                     end

            ADDR_8 : begin
                         if(ADC_SCLK_CNTR<=24 && ADC_WR_RD_MODE==1'b1)
                        begin
                     
                         sen<=1'b0;
							if(sclk==1'b1)
							begin
                              sdin<=shift_reg[23];
                              shift_reg<={shift_reg[22:0],1'b0};
                              ADC_SCLK_CNTR<=ADC_SCLK_CNTR+1'b1;
							 end
							ADC_STATE<=ADDR_8;
									end	
					 
                        else begin
                        
                            ADC_SCLK_CNTR   <= 5'd0;
                            sen<=1'b1;
                             shift_reg <=Default_0x17[23:0];
                            ADC_STATE       <= ADDR_9;
                        end
                     end

            ADDR_9 : begin
                         if(ADC_SCLK_CNTR<=24 && ADC_WR_RD_MODE==1'b1)
                        begin
                     
                         sen<=1'b0;
							if(sclk==1'b1)
							begin
                              sdin<=shift_reg[23];
                              shift_reg<={shift_reg[22:0],1'b0};
                              ADC_SCLK_CNTR<=ADC_SCLK_CNTR+1'b1;
							 end
							ADC_STATE<=ADDR_9;
									end	
					 
                        else begin
                        
                            ADC_SCLK_CNTR   <= 5'd0;
                            sen<=1'b1;
                             shift_reg <=Default_0x18[23:0];
                            ADC_STATE       <= ADDR_10;
                        end
                     end

            ADDR_10 : begin
                        if(ADC_SCLK_CNTR<=24 && ADC_WR_RD_MODE==1'b1)
                        begin
                     
                         sen<=1'b0;
							if(sclk==1'b1)
							begin
                              sdin<=shift_reg[23];
                              shift_reg<={shift_reg[22:0],1'b0};
                              ADC_SCLK_CNTR<=ADC_SCLK_CNTR+1'b1;
							 end
							ADC_STATE<=ADDR_10;
									end	
					 
                        else begin
                        
                            ADC_SCLK_CNTR   <= 5'd0;
                            sen<=1'b1;
                             shift_reg <=Default_0x19[23:0];
                            ADC_STATE       <= ADDR_11;
                        end
                     end

            ADDR_11 : begin
                       if(ADC_SCLK_CNTR<=24 && ADC_WR_RD_MODE==1'b1)
                        begin
                     
                         sen<=1'b0;
							if(sclk==1'b1)
							begin
                              sdin<=shift_reg[23];
                              shift_reg<={shift_reg[22:0],1'b0};
                              ADC_SCLK_CNTR<=ADC_SCLK_CNTR+1'b1;
							 end
							ADC_STATE<=ADDR_11;
									end	
					 
                        else begin
                        
                            ADC_SCLK_CNTR   <= 5'd0;
                            sen<=1'b1;
                             shift_reg <=test_patt_0x1A[23:0];
                            ADC_STATE       <= ADDR_12;
                        end
                     end
                     
            ADDR_12 : begin
                         if(ADC_SCLK_CNTR<=24 && ADC_WR_RD_MODE==1'b1)
                        begin
                     
                         sen<=1'b0;
							if(sclk==1'b1)
							begin
                              sdin<=shift_reg[23];
                              shift_reg<={shift_reg[22:0],1'b0};
                              ADC_SCLK_CNTR<=ADC_SCLK_CNTR+1'b1;
							 end
							ADC_STATE<=ADDR_12;
									end	
					 
                        else begin
                        
                            ADC_SCLK_CNTR   <= 5'd0;
                            sen<=1'b1;
                             shift_reg <=test_patt_0x1B[23:0];
                            ADC_STATE       <= ADDR_13;
                        end
                     end
                     
             ADDR_13 : begin
                         if(ADC_SCLK_CNTR<=24 && ADC_WR_RD_MODE==1'b1)
                        begin
                     
                         sen<=1'b0;
							if(sclk==1'b1)
							begin
                              sdin<=shift_reg[23];
                              shift_reg<={shift_reg[22:0],1'b0};
                              ADC_SCLK_CNTR<=ADC_SCLK_CNTR+1'b1;
							 end
							ADC_STATE<=ADDR_13;
									end	
					 
                        else begin
                        
                            ADC_SCLK_CNTR   <= 5'd0;
                            sen<=1'b1;
                             shift_reg <=Start[23:0];
                            ADC_STATE       <= ADDR_14;
                        end
                     end
                     
              ADDR_14 : begin
                         if(ADC_SCLK_CNTR<=24 && ADC_WR_RD_MODE==1'b1)
                        begin
                     
                         sen<=1'b0;
							if(sclk==1'b1)
							begin
                              sdin<=shift_reg[23];
                              shift_reg<={shift_reg[22:0],1'b0};
                              ADC_SCLK_CNTR<=ADC_SCLK_CNTR+1'b1;
							 end
							ADC_STATE<=ADDR_14;
									end	
					 
                        else begin
                        
                            ADC_SCLK_CNTR   <= 5'd0;
                            sen<=1'b1;
                            ADC_STATE       <= ADDR_0;
                        end
                     end


            default : ; 
        endcase 
       end 
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

	// Performing Read Operation on ADC Registers
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
//	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	      case ( axi_araddr )
	        6'h0   : begin
	                       Read_Reg <= 0;
	                       reg_data_out <= SW_RST_RW[23:0];
	                 end
	        6'h1   : begin 
	                       Read_Reg <= 0;
	                       reg_data_out <= Die_select[23:0];
	                 end
	        6'h2   : begin 
	                       Read_Reg <= 0;
	                       reg_data_out <= Clk_speed_DF_KSPS[23:0];
	                 end
	        6'h3   : begin 
	                       Read_Reg <= 0;
	                       reg_data_out <= Data_Resolution_0x12[23:0];
	                 end
	        6'h4   : begin 
	                       Read_Reg <= 0;
	                       reg_data_out <= odd_ch_0x13[23:0];
	                 end
	        6'h5   : begin 
	                       Read_Reg <= 0;
	                       reg_data_out <= odd_ch_0x14[23:0];
	                 end
	        6'h6   : begin 
	                       Read_Reg <= 0;
	                       reg_data_out <= Default_0x15[23:0];
	                 end
	        6'h7   : begin 
	                       Read_Reg <= 0;
	                       reg_data_out <= Default_0x16[23:0];
	                 end
	        6'h8   : begin 
	                       Read_Reg <= 0;
	                       reg_data_out <= Default_0x17[23:0];
	                 end
	        6'h9   : begin 
	                       Read_Reg <= 0;
	                       reg_data_out <= Default_0x18[23:0];
	                 end
	        6'hA   : begin 
	                       Read_Reg <= 0;
	                       reg_data_out <= Default_0x19[23:0];
	                 end
	        6'hB   : begin 
	                       Read_Reg <= 0;
	                       reg_data_out <= test_patt_0x1A[23:0];
	                 end
	        6'hC   : begin 
	                       Read_Reg <= 0;
	                       reg_data_out <= test_patt_0x1B[23:0];
	                 end
	        6'hD  : begin 
	                       Read_Reg <= 0;
	                       reg_data_out <= LVDS_CMOS_0x3A[23:0];
	                 end
	                 
	        6'hE   : begin 
	                       Read_Reg <= 0;
	                       reg_data_out <= Start[23:0];
	                 end
	        default : reg_data_out <= 0;
	      endcase
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
	
	
	
	
	endmodule*/
