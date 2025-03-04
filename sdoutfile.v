
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.12.2024 11:02:10
// Design Name: 
// Module Name: adc_comp
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


`timescale 1ns / 1ps

module axi_adc #(
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 8
)(
    input                              S_AXI_ACLK,
    input                              S_AXI_RESETN,
    input [C_S_AXI_ADDR_WIDTH-1:0]     S_AXI_AWADDR,
    input                              S_AXI_AWVALID,
    output                             S_AXI_AWREADY,
    input [C_S_AXI_DATA_WIDTH-1:0]     S_AXI_WDATA,
    input [C_S_AXI_DATA_WIDTH/8-1:0]   S_AXI_WSTRB,
    input                              S_AXI_WVALID,
    output                             S_AXI_WREADY,
    output [1:0]                       S_AXI_BRESP,
    output                             S_AXI_BVALID,
    input                              S_AXI_BREADY,
    input [C_S_AXI_ADDR_WIDTH-1:0]     S_AXI_ARADDR,
    input                              S_AXI_ARVALID,
    output                             S_AXI_ARREADY,
    output [C_S_AXI_DATA_WIDTH-1:0]    S_AXI_RDATA,
    output [1:0]                       S_AXI_RRESP,
    output                             S_AXI_RVALID,
    input                              S_AXI_RREADY,   
    
  
    
    output reg sdata_out     
);


    
    //--------user defined signals-----
    wire[7:0] WR_RD_ADDR ;
    wire[C_S_AXI_DATA_WIDTH-1:0] WR_RD_DATA;
    reg[4:0] cntr = 5'd0;
    wire sen,sclk,sdin,rst;
    wire[23:0] shift_data ;
    reg w_en =1'b0;
    
 //   assign WR_RD_DATA[15:0] = S_AXI_AWVALID ? S_AXI_WDATA[15:0] : S_AXI_RDATA[15:0];  //For write and read DATA based on wr_mode 
   assign WR_RD_DATA[23:0] = S_AXI_WDATA[23:0] ;
   assign WR_RD_ADDR = S_AXI_AWVALID ? S_AXI_AWADDR : S_AXI_ARADDR;        //For write and read address based on wr_mode    
 //  assign WR_RD_DATA[15:0] = S_AXI_WDATA[15:0];
  // assign WR_RD_ADDR = S_AXI_AWADDR;       //For write and read address based on wr_mode

   assign shift_data = S_AXI_AWVALID ? WR_RD_DATA[23:0] :{8'b0,WR_RD_DATA[23:16]}  ;
    
    main main_intstance(
          		.clk(S_AXI_ACLK),
		        .addr(WR_RD_DATA[23:16]),
		        .data(WR_RD_DATA[15:0]),
		        .wr_mode(w_en),
		        .reset(1'b0),
		        .sdout(sdata_out),
		        .sen(sen),
		        .sclk(sclk),
		        .resetn(rst),
		        .sdin(sdin)
                );
    // Registers for data
    reg [C_S_AXI_DATA_WIDTH-1:0] reg1, reg2, reg3, reg4;
    
    // Signals for AXI interface
    reg awready, wready, arready, bvalid, rvalid;
    reg [C_S_AXI_DATA_WIDTH-1:0] rdata;
   
    
    
    // Assign AXI interface outputs
    assign S_AXI_AWREADY = awready;
    assign S_AXI_WREADY  = wready;
    assign S_AXI_BRESP   = 2'b00;  // OKAY response
    assign S_AXI_BVALID  = bvalid;
    assign S_AXI_ARREADY = arready;
    assign S_AXI_RDATA   = rdata;
    assign S_AXI_RRESP   = 2'b00;  // OKAY response
    assign S_AXI_RVALID  = rvalid;
   
  
    
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_RESETN) begin
            // Reset registers and control signals
            reg1    <= 32'd0;
            reg2    <= 32'd0;
            reg3    <= 32'd0;
            reg4    <= 32'd0;
            awready <= 1'b0;
            wready  <= 1'b0;
            arready <= 1'b0;
            bvalid  <= 1'b0;
            rvalid  <= 1'b0;
            rdata   <= 32'd0;
        end 
        else   begin
                w_en<=1'b1;
            // Handle Write Address phase (AW)
            if (S_AXI_AWVALID && !awready) 
            begin
                awready <= 1'b1;  // Address is ready to accept    
            end 
            
            else if (S_AXI_WVALID && S_AXI_WREADY) begin
                awready <= 1'b0;  // Once data is written, reset awready
            end

            // Handle Write Data phase (WDATA)
            else if (S_AXI_WVALID && !wready && w_en==1'b1) begin
                wready <= 1'b1;  // Write data is ready
                // Decode address and write data to registers
                case(S_AXI_AWADDR)
              //      8'h0 : reg1 <= S_AXI_WDATA ;  // Write to reg1
             //       8'h4 : reg2 <= S_AXI_WDATA;  // Write to reg2
                    8'h0 : reg1 <= WR_RD_DATA[23:0];  // Write to reg1
                    8'h4 : reg2 <= WR_RD_DATA[23:0]; //  Write to reg2
                    8'h8 : reg3 <= WR_RD_DATA[23:0];
                    default : ;  // Undefined addresses
                endcase          
            end
            
            else
             begin
                wready <= 1'b0;
            end
        end
         
 // Handle Write Response phase 
if (S_AXI_WVALID && S_AXI_WREADY) begin
        bvalid <= 1'b1;  // Data has been written successfully
end else if (bvalid && S_AXI_BREADY) begin
        bvalid <= 1'b0;  // Clear write response once acknowledged
    end

// Handle Read Address phase 
if (S_AXI_ARVALID && !arready) begin
    arready <= 1'b1;  // Read address is ready
    w_en <= 1'b0;     // Disable write during read
end else begin
    arready <= 1'b0;
end

// Handle Read Data phase 
if (S_AXI_ARVALID && arready && w_en == 1'b0) begin
    case(S_AXI_ARADDR)
        8'h0 : rdata <= reg1[23:0];  // Read 24-bit data from reg1
        8'h4 : rdata <= reg2[23:0];  // Read 24-bit data from reg2
        8'h8 : rdata <= reg3[23:0];  // Read 32-bit data from reg3 (sum)
        8'hC : rdata <= reg4[23:0];  // Read 24-bit data from reg4 (carry)
        default : rdata <= 32'd0;    // Default to 0 if unknown address
    endcase
    rvalid <= 1'b1;  // Data is valid for reading
end else if (S_AXI_RVALID && S_AXI_RREADY) begin
    rvalid <= 1'b0;  // Clear read valid signal once acknowledged
end
end

// Handle data transmission based on reg2[0]
always @(posedge S_AXI_ACLK) begin
    sdata_out<=1'b0;
    cntr<=5'd23;
    if (reg2[0] == 1'b1) begin     // Check if the command bit is set in reg2
        sdata_out <= reg1[cntr];  // Send bit from reg1[23:0]
        cntr <= cntr - 1'b1;
        if (cntr == 5'd0) begin
            cntr <= 5'd23;        // Reset counter after sending all 24 bits
        end
    end else begin
        sdata_out <= 1'b0;      // No transmission if command bit is not set
    end
end
  
endmodule
