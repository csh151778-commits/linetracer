module  TRACE_SENSOR_MOTOR  ( 
//--IRDA remote command 
input         TRACK   ,
input         START   ,
input         TURN_R  , 
input         TURN_L  , 
input         MANU_T  , 
input         RETURN  , 
input         FD_BK   ,

input         CLK ,
input         RESET_N ,
input         TR_ON_OFF , 

input         L0,L1,L2,L3,     //L  SENSOR 
input         CN ,             //I  SENSOR 
input         R0,R1,R2,R3 ,    //R  SENSOR   
 
input [15:0]  ADC_CN ,
input [15:0]  ADC_L0 , 
input [15:0]  ADC_R0 ,
input [15:0]  ADC_L1, 
input [15:0]  ADC_R1 ,
input [15:0]  ADC_L2, 
input [15:0]  ADC_R2 ,
output        M0A, 
output        M0B,
output        M1A,
output        M1B,


output [11:0] ST ,
output [15:0] L_SPEED,
output [15:0] R_SPEED ,
output        L,R,C,
output [7:0]  STATUS ,
input         ADC_CS_N,
output      Impartial     ,
output      Outlet        ,
output      RightSmallBias,
output      RightBigBias  ,
output      RightBigBias1 ,
output      RightBigBias2 ,
output      LeftSmallBias ,
output      LeftBigBias   ,
output      LeftBigBias1  ,
output      LeftBigBias2 

); 

//--PARAMETER----
parameter MAL_SPEED = 16'hf000 ;

//---WIRE /REG--- 
wire GO_BACK_L , GO_BACK_R ; 
wire CENTER ,GO_STOP ;  
 
SENS_RESPONSE re (
      .ADC_CS_N  ( ADC_CS_N ) , 
      .ADC_CN    ( ADC_CN[11:4]),
      .ADC_L0    ( ADC_L0[11:4]),
      .ADC_R0    ( ADC_R0[11:4]),
      .ADC_L1    ( ADC_L1[11:4]),
      .ADC_R1    ( ADC_R1[11:4]),
      .ADC_L2    ( ADC_L2[11:4]),
      .ADC_R2    ( ADC_R2[11:4]),
      .Impartial     (Impartial     ),
      .Outlet        (Outlet        ),
      .RightSmallBias(RightSmallBias),
      .RightBigBias  (RightBigBias  ),
      .RightBigBias1 (RightBigBias1 ),
      .RightBigBias2 (RightBigBias2 ),
      .LeftSmallBias (LeftSmallBias ),
      .LeftBigBias   (LeftBigBias   ),
      .LeftBigBias1  (LeftBigBias1  ),
      .LeftBigBias2  (LeftBigBias2  ),
      .L         ( L), 
      .R         ( R), 
      .C         ( C) ,
      .CLK_50    ( CLK )
);                     
//---Direction determination --- 
MOTOR_DIR_DET  sl(
         .RESET_N       ( TR_ON_OFF & RESET_N ) ,
         .ADC_CS_N      ( ADC_CS_N) , 
         .CLK           ( CLK     ), 
         .Impartial     (Impartial     ),
         .Outlet        (Outlet        ),
         .RightSmallBias(RightSmallBias),
         .RightBigBias  (RightBigBias  ),
         .RightBigBias1 (RightBigBias1 ),
         .RightBigBias2 (RightBigBias2 ),
         .LeftSmallBias (LeftSmallBias ),
         .LeftBigBias   (LeftBigBias   ),
         .LeftBigBias1  (LeftBigBias1  ),
         .LeftBigBias2  (LeftBigBias2  ),
         	
         .ADC_R0    ( ADC_R0)   ,
         .ADC_L0    ( ADC_L0)   ,
         .ADC_CN    ( ADC_CN)   ,
         .L_SPEED   ( L_SPEED),
         .R_SPEED   ( R_SPEED),
         .GO_BACK_L ( GO_BACK_L ),
         .GO_BACK_R ( GO_BACK_R ),
		 .GO_STOP   ( GO_STOP)
  );       
       
//--- Manual / Auto mode mux ---
// Manual steering: tank-turn (one motor reverses for L/R turn)
//   TURN_R=1 : left forward,  right backward  → right turn
//   TURN_L=1 : left backward, right forward   → left turn
//   FD_BK=1  : both backward (straight reverse)
//   FD_BK=0  : both forward  (straight forward)
wire man_go_back_l = TURN_R ? 1'b0 : (TURN_L ? 1'b1 : FD_BK);
wire man_go_back_r = TURN_L ? 1'b0 : (TURN_R ? 1'b1 : FD_BK);
wire man_go_stop   = ~START;

wire mux_go_back_l, mux_go_back_r, mux_go_stop;
wire [15:0] mux_l_speed, mux_r_speed;

assign mux_go_back_l = TRACK ? GO_BACK_L : man_go_back_l;
assign mux_go_back_r = TRACK ? GO_BACK_R : man_go_back_r;
assign mux_go_stop   = TRACK ? GO_STOP   : man_go_stop;
assign mux_l_speed   = TRACK ? L_SPEED   : MAL_SPEED;
assign mux_r_speed   = TRACK ? R_SPEED   : MAL_SPEED;

//--- PWM GENERATE---
MOTOR_PWM_OUT  mv(
         .CLOCK_50  ( CLK        ),
         .GO_BACK_L ( mux_go_back_l ),
         .GO_BACK_R ( mux_go_back_r ),
         .GO_STOP   ( mux_go_stop   ),
         .L_SPEED   ( mux_l_speed   ),
         .R_SPEED   ( mux_r_speed   ),
         .M0A(M0A),
         .M0B(M0B),
         .M1A(M1A),
         .M1B(M1B)
   );
	
endmodule  

