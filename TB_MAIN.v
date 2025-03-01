`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.03.2025 11:53:50
// Design Name: 
// Module Name: TB_Main
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


module TB_Main;
    // Parameters for the design under test
    parameter C_S_AXI_DATA_WIDTH = 32;
    parameter C_S_AXI_ADDR_WIDTH = 6; 
    // Signals for the DUT (Device Under Test)
    reg S_AXI_ACLK;
    reg S_AXI_ARESETN;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR;
    reg [2 : 0] S_AXI_AWPROT;
    reg S_AXI_AWVALID;
    wire S_AXI_AWREADY;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA;
    reg [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB;
    reg S_AXI_WVALID;
    wire S_AXI_WREADY;
    wire [1 : 0] S_AXI_BRESP;
    wire S_AXI_BVALID;
    reg S_AXI_BREADY;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR;
    reg [2 : 0] S_AXI_ARPROT;
    reg S_AXI_ARVALID;
    wire S_AXI_ARREADY;
    wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA;
    wire [1 : 0] S_AXI_RRESP;
    wire S_AXI_RVALID;
    reg S_AXI_RREADY;
    
    wire sdata_out;  // Extra output signal
    wire serial_datain_tb ;
    // Instantiate the Unit Under Test (UUT)
    AXI4_INTERFACE #(
        .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
    ) uut (
        .S_AXI_ACLK(S_AXI_ACLK),
        .S_AXI_ARESETN(S_AXI_ARESETN),
        .S_AXI_AWADDR(S_AXI_AWADDR),
        .S_AXI_AWPROT(S_AXI_AWPROT),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWREADY(S_AXI_AWREADY),
        .S_AXI_WDATA(S_AXI_WDATA),
        .S_AXI_WSTRB(S_AXI_WSTRB),
        .S_AXI_WVALID(S_AXI_WVALID),
        .S_AXI_WREADY(S_AXI_WREADY),
        .S_AXI_BRESP(S_AXI_BRESP),
        .S_AXI_BVALID(S_AXI_BVALID),
        .S_AXI_BREADY(S_AXI_BREADY),
        .S_AXI_ARADDR(S_AXI_ARADDR),
        .S_AXI_ARPROT(S_AXI_ARPROT),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_RDATA(S_AXI_RDATA),
        .S_AXI_RRESP(S_AXI_RRESP),
        .S_AXI_RVALID(S_AXI_RVALID),
        .S_AXI_RREADY(S_AXI_RREADY),
        .serial_datain(serial_datain_tb),
        .sdata_out(sdata_out)
    );
    // Clock generation
    initial begin
        S_AXI_ACLK = 0;
        forever #5 S_AXI_ACLK = ~S_AXI_ACLK;  // Generate clock with a period of 10ns
    end
    // Reset generation
    initial begin
        S_AXI_ARESETN = 0;
        #20;
        S_AXI_ARESETN = 1;  // Release reset after 50ns
    end    
    //Write Operation 
    task WR_TASK(input[5:0] PS_WR_ADDR , input[31:0] PS_ADDR_DATA);
    begin 
        S_AXI_AWADDR  = PS_WR_ADDR;    //Address to select respective case statement
        S_AXI_WDATA   = PS_ADDR_DATA;  // Write Addr_data
        S_AXI_WSTRB   = 4'b1111;       // Enable all byte lanes
        S_AXI_AWVALID = 1;             // Initiate address valid
        S_AXI_WVALID  = 1;             // Initiate write data valid
        S_AXI_BREADY  = 1;             // Indicates Master can accept write Response
        #20;
        S_AXI_AWVALID = 0;
        S_AXI_WVALID  = 0;
        #10;
        S_AXI_BREADY  = 0;
    end 
    endtask     
    //Read Operation 
    reg[23:0] RD_ADDR_DATA ;
    task RD_TASK(input[5:0] PS_RD_ADDR);
    begin
        S_AXI_ARADDR  = PS_RD_ADDR; 
        S_AXI_ARVALID = 1; 
        RD_ADDR_DATA  = S_AXI_RDATA[23:0];
        #100;
        S_AXI_ARVALID = 0;
        S_AXI_RREADY  = 1;
        #10;
        S_AXI_RREADY  = 0; 
    end 
    endtask 
    // Stimulus
    initial begin
        $monitor("Time: %t, RD_ADDR_DATA  : %h , sdata_out: %b", $time, RD_ADDR_DATA, sdata_out);
        // Initializing signals
        S_AXI_AWADDR  = 0;
        S_AXI_AWPROT  = 3'b000;
        S_AXI_AWVALID = 0;
        S_AXI_WDATA   = 0;
        S_AXI_WSTRB   = 0;
        S_AXI_WVALID  = 0;
        S_AXI_BREADY  = 0;
        S_AXI_ARADDR  = 0;
        S_AXI_ARPROT  = 3'b000;
        S_AXI_ARVALID = 0;
        S_AXI_RREADY  = 0;
        //Write Operation         
        #20;
        WR_TASK(6'h0 , 32'hA1A1A1A1);       //1st Write  (High : 1 , 3 , 8 , 9 , 11 , 16)
        WR_TASK(6'h1 , 32'hB2B2B2B2);       //2nd Write  (High : 1 , 3 , 4 , 7 , 9 , 11 , 12 , 15 )
        WR_TASK(6'h2 , 32'hC3C3C3C3);       //3rd Write  (High : 1 , 2 , 7 , 8 , 9 , 10 , 15 , 16 )
        WR_TASK(6'h3 , 32'hD4D4D4D4);       //4th Write  (High : 1 , 2 , 4 , 6 , 9 , 10 , 12 , 14 )
        WR_TASK(6'h4 , 32'hE5E5E5E5);       //5th Write  (High : 1 , 2 , 3 , 6 , 8 , 9 , 10 , 11 , 14 , 16 )
        WR_TASK(6'h5 , 32'h10234678);       //6th Write  (High : 3 , 7 , 8 , 10 , 14 , 15 )
        WR_TASK(6'h6 , 32'h02143576);       //7th Write  (High : 4 , 6 , 11 , 12 , 14 , 16 )
        WR_TASK(6'h7 , 32'h30215571);       //8th Write  (High : 3 , 8 , 10 , 12 , 14 , 16 )
        WR_TASK(6'h8 , 32'h10101010);       //9th Write  (High : 4 , 12 )
        WR_TASK(6'h9 , 32'h87654321);       //10th Write (High : 2 , 3 , 6 , 8 , 10 , 15 , 16)
        WR_TASK(6'hA , 32'h12125678);       //11th Write 
        WR_TASK(6'hB , 32'h10284678);       //12th Write 
        WR_TASK(6'hC , 32'h10111678);       //13th Write 
        #50;
//        //Read Operation 
//        RD_TASK(6'h0 );
//        RD_TASK(6'h1 );
//        RD_TASK(6'h2 );
//        RD_TASK(6'h3 );
//        RD_TASK(6'h4 );
//        RD_TASK(6'h5 );
//        RD_TASK(6'h6 );
//        RD_TASK(6'h7 );
//        RD_TASK(6'h8 );
//        RD_TASK(6'h9 );
//        RD_TASK(6'hA );
//        RD_TASK(6'hB );
//        RD_TASK(6'hC );
        //End of Simulation  
        #9500 $finish();
    end
endmodule
