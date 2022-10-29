`timescale 1ns / 1ps


module puf_top(
    //input  sys_clk_pin,   // 100Mhz sys clock
    input  CLK100MHZ,   // 100Mhz sys clock
	input [3:0]sw, //slide switch //active high
	input [3:0]btn, //push button //active high buttons
	
	//RGB LEDs
	output led0_b, 
	output led0_g, 
	output led0_r, 
	output led1_b, 
	output led1_g, 
	output led1_r, 
	output led2_b, 
	output led2_g, 
	output led2_r, 
	output led3_b, 
	output led3_g, 
	output led3_r, 
	
	//user LEDs
	output [3:0] led, //active high LEDs
	
	//output RNG clocks
	output [7:0] jb
	//output rng_clk1, //clock output from mux1
	//output rng_clk2 //clock output from mux2
	
	
    );
	
//here is how we make use of leds, buttons and switches; Please check the xdc for the FPGA pin assignment
//no debouncer used since there is already schmitt trigger implemented for the buttons on the board
//btn[0] is a counter reset. When pressed it resets the counter
//btn[1] is used to enable the rng
//btn[2] is used to disable the rng
//btn[3] is used to capture switches for challenge; We have only 3 switches so have to do this muxing to capture 8 challenge bits
	//'0' challenge[3:0] = sw[3:0]
	// '1' challenge[7:4] = sw[3:0] 
	
//user LEDs
//cnt1_finish -> led[0] 
//cnt2_finish --> led[1]
//cnt1_led --> led[2]
//cnt2_led -->led[3]

    (* dont_touch = "yes" *) reg [9:0] challenge=0;
    (* dont_touch = "yes" *) wire [63:0] enables;
    (* dont_touch = "yes" *) reg en_rng=0 ;
    
//RGB LEDs
assign led0_b	   = 1'b0;
assign led0_g      = en_rng; //RNG enabled
assign led0_r      = ~en_rng; //RNG disabled
assign led1_b      = 1'b0;
assign led1_g	   = 1'b1; //Code is alive
assign led1_r	   = 1'b0;
assign led2_b	   = 1'b0;
assign led2_g      = btn[3]; //btn 3 pressed
assign led2_r      = 1'b0; //RNG disabled
assign led3_b      = 1'b0;
assign led3_g	   = ~btn[0]; //out of reset
assign led3_r	   = btn[0]; // under reset
/*assign jb[0]	   = CLK100MHZ;
assign jb[1]	   = CLK100MHZ;
assign jb[2]	   = CLK100MHZ;
assign jb[3]	   = CLK100MHZ;
assign jb[4]	   = CLK100MHZ;
assign jb[5]	   = CLK100MHZ;
assign jb[6]	   = CLK100MHZ;
assign jb[7]	   = CLK100MHZ;
*/


/*always @(posedge btn[1] or posedge btn[2])
	if (btn[2] ==1)
	en_rng <= 0;
	else if (btn[1] ==1)
	en_rng <= 1;
*/

always @(posedge CLK100MHZ)
	if (btn[0] ==1)
		en_rng <= 0;
	else if (btn[1] ==1)
		en_rng <= 1;

	
always @(posedge CLK100MHZ)
begin
	if (btn[2] ==1)
	challenge[4:0] <= {1'b0, sw[3:0]};
	if (btn[3] ==1)
	challenge[9:5] <= {1'b0, sw[3:0]};
end
	

    assign enables = {64{en_rng}};

    (* dont_touch = "yes" *) rng_puf puf_32bit(.clock(CLK100MHZ), .reset(btn[0]),.enable(enables),.challenge(challenge), 
												.mux1_clk(), .mux2_clk(),.cnt1_finish(led[0]), .cnt2_finish(led[1]), .cnt1_led(led[2]),.cnt2_led(led[3]));
endmodule