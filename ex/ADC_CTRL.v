module ADC_CTRL	(	
input            RESET_N , 
input  [2:0]     ADC_CH,
output   reg     CONVST , 
input				  iCLK,
input	   [11:0]  iCREG,
output	reg [11:0]oADC_D,
output	reg [11:0]CD0,CD1,CD2,CD3,CD4,CD5,CD6,CD7,
output	reg     CH_CH , 
output	reg	  oDIN,
output	reg 	  oCS_n,
output	reg	  oSCLK,
input				  iDOUT,
output reg [7:0] ST,
output reg [4:0] COUNTER

				);
				
parameter  L_DELY =100 ;  //100 
parameter  H_DELY =1300 ; //1300
	
reg [11:0] CREG ;
reg [11:0] ADC_DATA;
reg        rCONVST ; 
reg [31:0] DELAY ;  

always@( negedge RESET_N or posedge iCLK )
   if ( !RESET_N) begin 
	   ST      <=0; 
	   CONVST  <=0; 
		CH_CH   <=0; 
	end 
else 
begin
case (ST)
0:begin 
      ST     <=1;
		oCS_n  <=1; 
		oSCLK  <=0;
		COUNTER<=12;
		CREG   <=iCREG ;
		{oADC_D[11:0] , ADC_DATA[11:0] } <= { ADC_DATA[11:0] ,12'h0};
             if ( iCREG [10:8] ==0 )   CD5 <=ADC_DATA ; 
		  else if ( iCREG [10:8] ==1 )   CD7 <=ADC_DATA ; 	 
		  else if ( iCREG [10:8] ==2 )   CD0 <=ADC_DATA ; 	 
		  else if ( iCREG [10:8] ==3 )   CD2 <=ADC_DATA ; 	 
		  else if ( iCREG [10:8] ==4 )   CD4 <=ADC_DATA ; 	 
		  else if ( iCREG [10:8] ==5 )   CD6 <=ADC_DATA ; 	 
		  else if ( iCREG [10:8] ==6 )   CD1 <=ADC_DATA ; 	 
		  else if ( iCREG [10:8] ==7 )   CD3 <=ADC_DATA ; 	 
  end 
1:begin 
      oCS_n  <=0; 
      ST<=2;
  end 
2:begin 
      {oDIN,CREG[11:0]} <= {CREG[11:0], 1'b0} ;
       ADC_DATA[11:0]   <= {ADC_DATA[10:0], iDOUT} ; 		
       ST<=3;
  end 
3:begin 
      oSCLK  <=1;
      COUNTER<=COUNTER-1;
      ST<=4;
  end 
4:begin 
       oSCLK  <=0;
        if ( COUNTER!=0)  ST<=2 ; 
        else ST<=5; 
  end 
5:begin 
		  CONVST <= 1; 
        ST<=6 ;
		  DELAY <=0;
end
6: begin
      if ( DELAY == H_DELY) begin 
		      ST<=7 ; 
			   CONVST <= 0;
				DELAY <=0;
		end 
		else  DELAY <=DELAY+1 ; 
end
7: begin
      if ( DELAY == L_DELY) begin 
		      ST<=8 ; 
				CH_CH<=0; 
			   CONVST <= 0;
				DELAY<=0 ; 
		end 
		else  DELAY <=DELAY+1 ; 
end 

8: begin
      if ( DELAY ==L_DELY) begin 
		      ST<=0 ; 
				CH_CH<=1; 
			   CONVST <= 0;
		end 
		else  DELAY <=DELAY+1 ; 
end 


endcase
end

endmodule
