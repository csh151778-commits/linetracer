module PWM  (
input        CLK_50, 
output reg   PWM_O ,
input [15:0] SPEED  
);

reg [15:0] CNT ; 
always @ ( posedge CLK_50 ) begin 
    CNT <=  CNT+1;  
	 if (CNT > SPEED )  PWM_O <= 0; 
	  else  PWM_O <= 1;  
end 

endmodule 