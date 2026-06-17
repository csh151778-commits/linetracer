module MOTOR_PWM_OUT ( 
  input  CLOCK_50 , 
  input  GO_STOP  ,  
  input  GO_BACK_L   ,  
  input  GO_BACK_R   ,
  input [15:0] L_SPEED   ,
  input [15:0] R_SPEED   ,

 output M0A, //    1:0 F  1:1 = brake
 output M0B, //    L_MOTOR  
 output M1A, //
 output M1B,  //    R_MOTOR

 //--FOR TEST 
 output L_M , R_M  , N_M 
)  ;

//----     
//L_EMOTOR 
assign   M0A = GO_STOP?1:  ((GO_BACK_L)?0   : L_M); 
assign   M0B = GO_STOP?1:  ((GO_BACK_L)?L_M : 0  ); 
//R_EMOTOR          
assign   M1A = GO_STOP?1:  ((GO_BACK_R)?0  : R_M ); 
assign   M1B = GO_STOP?1:  ((GO_BACK_R)?R_M: 0   ); 

//---PWM SPEED  --

PWM  p_L(
 .CLK_50 (CLOCK_50),
 .SPEED  (L_SPEED),
 .PWM_O  (L_M)
);
PWM  p_R(
 .CLK_50 (CLOCK_50),
 .SPEED  (R_SPEED),
 .PWM_O  (R_M)
);

PWM  n_R(
 .CLK_50 (CLOCK_50),
 .SPEED  (16'hffff/3),
 .PWM_O  (N_M)
);


endmodule 