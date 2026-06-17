//---Direction determination --- 
module  MOTOR_DIR_DET (
  input             CLK ,  
  input             ADC_CS_N ,       
  input             RESET_N, 
  input             Impartial ,     
  input             Outlet   ,      
  input             RightSmallBias,
  input             RightBigBias  ,
  input             RightBigBias1 ,
  input             RightBigBias2 ,
  input             LeftSmallBias ,
  input             LeftBigBias   ,
  input             LeftBigBias1  ,
  input             LeftBigBias2  ,
  
    
  input  [15:0]     ADC_R0,
  input  [15:0]     ADC_L0,
  input  [15:0]     ADC_CN,

  output reg [15:0] L_SPEED,
  output reg [15:0] R_SPEED,
 
  output reg        GO_BACK_L ,
  output reg        GO_BACK_R ,  
  output reg        GO_STOP , 
   //--FOR TEST
  output reg [11:0] ST  , 
  output [7:0]      STATUS    
  );
//----PARAMETER---   
  parameter  ADC_MAX    = 12'hCC0;
  //parameter  SEC        = 50000000 ; 
    
  reg  [15:0] HIGH_SPH ,HIGH_SPL;  
  wire [31:0] TIME_SHORS_L;
  //wire [31:0] DIV_S ;  
  //parameter  DIV_S  = 32'b0000000000000000111111111111;   
  //reg  [31:0] TIME ;  
  reg  [31:0] DELAY ;
  reg         rR,rL,rR2,rL2,rR3,rL3,rB  ; 

  parameter  initial_SPEED  = 16'd61440; 
  //wire [15:0] initial_SPEED  ; 
  wire [15:0] K_L , K_R ,K_C ;
  wire [23:0] RATE_L ; 
  //wire [7:0]  RATE ; 
  reg         rADC_CS_N ; 

  //--INITIAL SPEED ---   
  //SPEED_SET spp ( .result (initial_SPEED ) );

  //--DELAY TIME--  
  //TIME_CONSTANT ( .result (DIV_S) );   
  //assign TIME_SHORS_L = SEC/DIV_S;

  //--STATUS-- 
  assign STATUS = { rR3, rL3, rB, rR2, rL2, rR, rL } ;
  
  //--SPEED BASE ON ADC--
  assign K_L = ( HIGH_SPH * ADC_L0[11:0])/ ADC_MAX  ; 
  assign K_R = ( HIGH_SPH * ADC_R0[11:0])/ ADC_MAX  ; 
  assign K_C = ( HIGH_SPH * ADC_CN[11:0])/ ADC_MAX  ; 
  
  //--SPEED RATE ---
  parameter  RATE  = 8'd240; 
  //REAT r( .result (RATE));
  assign  RATE_L = HIGH_SPH  * RATE;

  //---Direction determination --- 
always @( negedge RESET_N or posedge  CLK  ) begin 
    if ( !RESET_N) begin 
        ST<= 1; 
        { rR3,rL3 ,rB ,rR2,rL2,rR,rL }<=7'h0;  
		  HIGH_SPH <=initial_SPEED ;		  
		  L_SPEED  <= HIGH_SPH;
          R_SPEED  <= HIGH_SPH;
		  GO_BACK_L <=0;
		  GO_BACK_R <=0;   
		  GO_STOP   <=1; 
		  //TIME  <= TIME_SHORS_L;
   end 
   else begin 
	  rADC_CS_N <= ADC_CS_N ; 
     case (ST) 
     0: 	begin 
	      ST<=1  ;
	      GO_STOP <=0; 
//====================================================================================Outlet		
         if   ( Outlet )  begin   							 
			             begin    
			               { rR3,rL3 ,rB ,rR2,rL2,rR,rL }<=7'h10;  
               	      GO_BACK_L <=1;
		                  GO_BACK_R <=1;
								
				            if (!rB) begin 
						    	L_SPEED  <=R_SPEED-R_SPEED/4;
							   R_SPEED  <=L_SPEED-L_SPEED/4;
							  end 
						 end 	 
				     end
//====================================================================================LeftBigBias2 (극단 좌편향)
			else if   ( LeftBigBias2 ) begin
		               GO_BACK_L <=0;
		               GO_BACK_R <=0;
							begin
                     { rR3,rL3 ,rB ,rR2,rL2,rR,rL } <=7'h40;
							L_SPEED <=  RATE_L[23:8]  ;
							R_SPEED <=  0;
							end
					  end
//====================================================================================LeftBigBias1
			else if   ( LeftBigBias1 ) begin
		               GO_BACK_L <=0;
		               GO_BACK_R <=0;
							begin
                     { rR3,rL3 ,rB ,rR2,rL2,rR,rL } <=7'h20;
							L_SPEED <=  RATE_L[23:8]  ;
							R_SPEED <=  5;
							end
					  end
//====================================================================================LeftBigBias
			else if   ( LeftBigBias ) begin
		               GO_BACK_L <=0;
		               GO_BACK_R <=0;
							begin
                     { rR3,rL3 ,rB ,rR2,rL2,rR,rL } <=7'h08;
							L_SPEED <=  RATE_L[23:8]  ;
							R_SPEED <=  10;
							end

					  end
//====================================================================================RightBigBias2 (극단 우편향)
		  else if    ( RightBigBias2 ) begin
		               GO_BACK_L <=0;
		               GO_BACK_R <=0;
							begin
                     { rR3,rL3 ,rB ,rR2,rL2,rR,rL }<=7'h10;
							 L_SPEED  <= 0 ;
							 R_SPEED  <= RATE_L[23:8]  ;
							end
                 end
//====================================================================================RightBigBias1
		  else if    ( RightBigBias1 ) begin
		               GO_BACK_L <=0;
		               GO_BACK_R <=0;
							begin
                     { rR3,rL3 ,rB ,rR2,rL2,rR,rL }<=7'h08;
							 L_SPEED  <= 5 ;
							 R_SPEED  <= RATE_L[23:8]  ;
							end
                 end
//====================================================================================RightBigBias
		  else if    ( RightBigBias ) begin
		               GO_BACK_L <=0;
		               GO_BACK_R <=0;
							begin
                     { rR3,rL3 ,rB ,rR2,rL2,rR,rL }<=7'h04;
							 L_SPEED  <= 10 ;
							 R_SPEED  <= RATE_L[23:8]  ;
							end
                 end
//====================================================================================LeftSmallBias					  
			else if    (LeftSmallBias )  begin 
		                  GO_BACK_L <=0;
		                  GO_BACK_R <=0;							
								begin 
                          { rR3,rL3 ,rB ,rR2,rL2,rR,rL }<=7'h02;  
							     L_SPEED  <=HIGH_SPH/2;
						        R_SPEED  <=HIGH_SPH/3; 
								end
						 end	 
//====================================================================================RightSmallBias					  
			else if   ( RightSmallBias )  begin 
		               GO_BACK_L <=0;
		               GO_BACK_R <=0;						
			            begin 
                     { rR3,rL3 ,rB ,rR2,rL2,rR,rL }<=7'h01;  
							    L_SPEED   <=HIGH_SPH/3; 
							    R_SPEED   <=HIGH_SPH/2;
							end 
						 end
//====================================================================================Impartial				  
			else  if ( Impartial ) begin  
		                 GO_BACK_L <=0;
		                 GO_BACK_R <=0;
							  begin 
						       { rR3,rL3 ,rB ,rR2,rL2,rR,rL }<=7'h00  ; 
						       L_SPEED  <= HIGH_SPH;								 
						       R_SPEED  <= HIGH_SPH;
							  end 	  
			  end		  
     end  
     1:begin
       if ( rADC_CS_N  &  ~ADC_CS_N )  ST<=2 ;  
     end 
     2:begin
       if ( ~rADC_CS_N  &  ADC_CS_N )  ST<=0 ;  
     end 
   endcase   
  end 
 end 
 	
           
endmodule 
