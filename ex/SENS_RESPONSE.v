module SENS_RESPONSE (
input       ADC_CS_N , 
//--ANALOG SENSOR 
input [7:0] ADC_CN ,
input [7:0] ADC_L0 , 
input [7:0] ADC_R0 ,
input [7:0] ADC_L1 , 
input [7:0] ADC_R1 ,
input [7:0] ADC_L2 , 
input [7:0] ADC_R2 ,

output      L , R  ,L0 , R0  , L1 , R1 ,L2 , R2,C, 
output      Impartial     ,
output      Outlet        ,
output      RightSmallBias,
output      RightBigBias  ,
output      RightBigBias1 ,
output      RightBigBias2 ,
output      LeftSmallBias ,
output      LeftBigBias   ,
output      LeftBigBias1  ,
output      LeftBigBias2  ,
input       CLK_50
); 


//wire   [7:0] BLANK_C  ;
//wire   [7:0] BLANK_R  ;
//wire   [7:0] BLANK_L  ;
parameter BLANK_C = 8'd112;
parameter BLANK_R = 8'd112;
parameter BLANK_L = 8'd112;

//wire   [7:0] STH ; 

//SEN_TH sn( .result(STH) );

//assign   BLANK_C  =  STH;
//assign   BLANK_R  =  STH ;
//assign   BLANK_L  =  STH ;

//---- ADC 3CH IN-----

//--Sensing L0
SENS_DT  aL(  .SCK(ADC_CS_N), .TH(BLANK_L ), .ADC(ADC_L0), .P(L0)); 
//--Sensing R0   
SENS_DT  aR(  .SCK(ADC_CS_N), .TH(BLANK_R ), .ADC(ADC_R0), .P(R0)); 
//--Sensing L1 	   
SENS_DT aL1(  .SCK(ADC_CS_N), .TH(BLANK_L ), .ADC(ADC_L1), .P(L1)); 
//--Sensing R1   
SENS_DT aR1(  .SCK(ADC_CS_N), .TH(BLANK_R ), .ADC(ADC_R1), .P(R1)); 
//--Sensing L2 	   
SENS_DT aL2(  .SCK(ADC_CS_N), .TH(BLANK_L ), .ADC(ADC_L2), .P(L2)); 
//--Sensing R2   
SENS_DT aR2(  .SCK(ADC_CS_N), .TH(BLANK_R ), .ADC(ADC_R2), .P(R2)); 
//--Sensing  CENTER 
SENS_DT  aC(  .SCK(ADC_CS_N), .TH(BLANK_C ), .ADC(ADC_CN), .P(C)); 
 
assign L =L0 ; 
assign R =R0 ; 

 
assign Impartial        = ( ~L &  C & ~R ) | (  L &  C &  R );
assign Outlet           = ( ~L & ~C & ~R ) ; 
assign RightSmallBias   = (  L &  C & ~R ) ;
assign RightBigBias     = (  L & ~C & ~R ) ;
assign RightBigBias1    =   L1 ;
assign RightBigBias2    =   L2;
assign LeftSmallBias    = ( ~L &  C &  R ) ;
assign LeftBigBias      = ( ~L & ~C &  R ) ; 
assign LeftBigBias1     =   R1  ; 
assign LeftBigBias2     =   R2; 

endmodule 