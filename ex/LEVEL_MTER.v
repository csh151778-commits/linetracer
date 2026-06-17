module  LEVEL_MTER (
 input  [12:0]iVV,
 output [7:0] oLEVEL 
);

 parameter STEP    =  8 ; 
 parameter MAX     =  5000;      //4095 
 parameter LEVEL   =  MAX/STEP ; //
assign oLEVEL =(
 (iVV > 8*LEVEL  )?8'hFF :(  //
 (iVV > 7*LEVEL  )?8'h7F :(  //
 (iVV > 6*LEVEL  )?8'h3F :(  //
 (iVV > 5*LEVEL  )?8'h1F :(  //
 (iVV > 4*LEVEL  )?8'h0F :(  //
 (iVV > 3*LEVEL  )?8'h07 :(  //
 (iVV > 2*LEVEL  )?8'h03 :(  //
 (iVV > 1*LEVEL  )?8'h01 :0  //
))))))));

endmodule  
