module  SENS_DT ( 
  input  SCK , 
  input  [7:0] TH , 
  input  [7:0] ADC , 
  output  reg  P 
); 

always @( posedge SCK ) 
        if (  ADC[7:0] > TH )   P <=1;  
   else if (  ADC[7:0] < TH )   P <=0; 
	
endmodule 	