module ADC_CH_OUT (
      input           CLK_50,		
      //ADC         
	  output          ADC_CONVST , 
      inout           ADC_CS_N,
      output          ADC_DIN,
      input           ADC_DOUT,
      output          ADC_SCLK,
	  //LEVEL LED 
	  output    [7:0] LED ,
	  output   [11:0] ADC_D ,
      output   [11:0] CD0,CD1,CD2,CD3,CD4,CD5,CD6,CD7,
	  output   [15:0] VIN ,		
	  output          SYS_CLK ,
	  input           RESET_N  ,
	  input      [3:0]SW,
	  output reg [2:0]ADC_CH,
	  output          CH_CH 
);
parameter SCAL = 4 ;
//----WIRE/REG-----
wire  [5:0]CH;
reg 	[7:0]TIME;
wire       CLK_40 ;

//----ADC SYSTEM-CLOCK-----
always @(posedge CLK_50  ) TIME<=TIME+1;
EX_PLL  pl( .areset(0), .inclk0(CLK_50), .c0(CLK_40), .locked());
assign SYS_CLK = CLK_50;// TIME[0]; //25M

//---Voltage Detector Scalling---   
assign VIN = CD7 * SCAL ; // 4.096 * 4 

//----CHANNEL Auto-Switching ----
always @(negedge RESET_N  or  posedge CH_CH  )
if (!RESET_N ) ADC_CH <=0; 
else ADC_CH <= ADC_CH+1 ; 

//----CHANNEL SETTING ---
assign CH= { 
  SW[2] ,       //S/D = 1: SINGLE-ENDED/DIFFERENTIAL BIT
  ADC_CH [2:0] ,//3'b000 ,
  SW[1] ,       //UNI = 1: UNIPOLAR/BIPOLAR BIT
  SW[0]         //SLP = 1: SLEEP MODE BIT
};

//---ADC CONTROLLER
ADC_CTRL	adc(	// for DE1-SOC , ltc2308 
               .CONVST( ADC_CONVST)  ,
					.iCLK  ( SYS_CLK),
					.iCREG ( {CH[5:0],6'b000000} ),
					                                                      
					.oADC_D( ADC_D ),
					.CD0   ( CD0),
					.CD1   ( CD1),
					.CD2   ( CD2),
					.CD3   ( CD3),
					.CD4   ( CD4),
					.CD5   ( CD5),
					.CD6   ( CD6),
					.CD7   ( CD7),
					.CH_CH ( CH_CH ),
					.oDIN  ( ADC_DIN),
					.oCS_n ( ADC_CS_N),
					.oSCLK  ( ADC_SCLK),
					.iDOUT   ( ADC_DOUT),
					.RESET_N ( RESET_N  ) 
				);

//---- ADC to LEVEL-LED ---
LEVEL_MTER v1(
	           .iVV   ( CD7 * SCAL ),
	           .oLEVEL( LED ) 
           );

endmodule