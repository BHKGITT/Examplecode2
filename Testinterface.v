module Stream_Interface#(parameter C_M_AXIS_TDATA_WIDTH	= 8, parameter DEPTH = 4096 )
    (
        /* AXI4 Steam Interface Signals */
        input                              M_AXIS_ACLK,   //100Mhz
        input                              M_AXIS_ARESETN, 
        input                              M_AXIS_TREADY,
        output                             M_AXIS_TVALID,
        output[C_M_AXIS_TDATA_WIDTH -1 :0] M_AXIS_TDATA,
        output[C_M_AXIS_TDATA_WIDTH -1 :0] M_AXIS_TSTRB,
        output                             M_AXIS_TLAST,
        input                              START
    );
    
//    localparam NUMBER_OF_OUTPUT_BYTES = 5850;
//    localparam ValidCondition = 27;
    
    parameter MICROSECONDS = 5900 ;
    parameter Even = 2 ;
    parameter Odd  = 1 ;
    
    //Internal Signal Declaration 
    integer i,j ;
    wire[31:0] LoadCounter ;
    reg[31:0] TlastCounter = 32'd0 ;
    reg[C_M_AXIS_TDATA_WIDTH -1 :0] IncrementValue = 8'd4;
    reg[C_M_AXIS_TDATA_WIDTH -1:0] DataHold ;
    reg[C_M_AXIS_TDATA_WIDTH -1:0] AxiData ;
    reg        axis_tvalid ;
    reg        axis_tlast ;
    wire       tx_en ;
    
    reg[C_M_AXIS_TDATA_WIDTH -1 : 0]DataBuf[DEPTH -1 :0];
    reg[15:0] ReadPointer = 16'd0 ;
    
    //FSM signals Declaration 
    reg[2:0]    FSM_State = IDLE ;
    localparam IDLE = 0 ; 
    localparam DATA_SEND = 1 ; 
    localparam DMA_TRANSFER = 2 ; 
     
    assign M_AXIS_TVALID = axis_tvalid ;
    assign M_AXIS_TDATA  = AxiData ;
    assign M_AXIS_TLAST  = axis_tlast ;
    assign M_AXIS_TSTRB	 = {(C_M_AXIS_TDATA_WIDTH){1'b1}};
    assign tx_en = M_AXIS_TREADY && axis_tvalid; 
    
    //Timer Instance 
	Timer59us DUT
        (
            .Clock_100Mhz(M_AXIS_ACLK),    //Input 100Mhz 
            .TimerStart(START),            //Input signal need to give by PS 
            .Timer_pulse(),                //Output 
            .Output_Cntr(LoadCounter)      //Output 
        );    
    
    always@(posedge M_AXIS_ACLK)
    begin 
        if(M_AXIS_ARESETN == 1'b0)
            begin 
                for(i=0 ; i < DEPTH ; i=i+1)
                begin 
                    DataBuf[i] <= 8'd2;
                end 
                FSM_State <= IDLE ;
                DataHold  <= 8'd0;
            end 
        else begin 
            case(FSM_State )
                IDLE : begin 
                            if((START == 1'b1) && (LoadCounter < MICROSECONDS) )
                                begin 
                                    FSM_State <= DATA_SEND ;
                                end 
                            else begin 
                                FSM_State <= IDLE ;
                            end 
                       end 
           DATA_SEND : begin 
                            if((START == 1'b1) && (LoadCounter < DEPTH) )
                                begin 
                                    DataHold <= DataBuf[ReadPointer] ;
                                    ReadPointer <= ReadPointer + 1'b1 ;
                                end 
                            else if((START == 1'b1) && (LoadCounter > DEPTH) )
                                begin                                 
                                    for(j=0 ; j< DEPTH ; j=j+1)
                                    begin 
                                        DataBuf[j] <= IncrementValue ;
                                    end 
                                    IncrementValue <= IncrementValue + Even ;
                                    ReadPointer <= 16'd0 ;
                                    axis_tvalid <= 1'b1 ;
                                    FSM_State   <= DMA_TRANSFER ;
                                end 
                            else begin                              
                                FSM_State   <= IDLE ;
                            end 
                       end 
        DMA_TRANSFER : begin 
                            if((LoadCounter == MICROSECONDS) && tx_en)
                                begin 
                                    AxiData <= DataHold ;
                                end 
                             else if(LoadCounter < MICROSECONDS)
                                begin 
                                    FSM_State <= DMA_TRANSFER ;
                                end 
                             else begin  
                                FSM_State  <= IDLE ;
                             end              
                       end 
             default : ;
            endcase 
        end 
    end     
    
    // axi_tlast Generation 
    always@(posedge M_AXIS_ACLK )
    begin 
        if(tx_en)
            begin 
                TlastCounter <= TlastCounter + 1'b1;
                if(TlastCounter == (DEPTH -1))
                    begin 
                        axis_tlast   <= 1'b1 ;
                        TlastCounter <= 32'd0 ;
                    end 
                else begin 
                    axis_tlast <= 1'b0 ;
                end 
            end 
    end
endmodule
