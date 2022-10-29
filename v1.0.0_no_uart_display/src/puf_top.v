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
	
	//UART
	input uart_txd_in,
	output uart_rxd_out,
	
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
    (* dont_touch = "yes" *) reg [5:0]addra=0;
    (* dont_touch = "yes" *) wire [63:0] enables;
    (* dont_touch = "yes" *) wire  clk_slow,counter_reset,cnt1_finish,cnt2_finish,cnt1_greater,cnt2_greater;
    (* dont_touch = "yes" *) wire [15:0] challenge_data;
    (* dont_touch = "yes" *) reg en_rng=0 ;
    (* dont_touch = "yes" *) reg send_result,btn2_d1,btn2_d2,btn3_d1,btn3_d2=0 ;
    
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



/*always @(posedge btn[1] or posedge btn[2])
	if (btn[2] ==1)
	en_rng <= 0;
	else if (btn[1] ==1)
	en_rng <= 1;
*/

always @(posedge CLK100MHZ or posedge counter_reset  )
	if (counter_reset) 
	begin
		en_rng <= 0;
	end
	else if (btn[1] ==1)
		en_rng <= 1;

	

//slow clock generator
// clock_divider instclock_divider
// (
	// .clk_100Mhz	(CLK100MHZ), //100 MHz clock input 
	// .clk_slow	(clk_slow) // Output clock

// );

always @(posedge CLK100MHZ)
begin
	btn2_d1 <= btn[2];
	btn2_d2 <= btn2_d1;
	btn3_d1 <= btn[3];
	btn3_d2 <= btn3_d1;
end


always @(posedge CLK100MHZ or posedge btn[0])
begin
	if (btn[0] ==1)
		challenge <= 10'd0;
	else
	begin
		if (btn2_d1 && ~btn2_d2)
			challenge[4:0] <= challenge[4:0] + 1;
		if (btn3_d1 && ~btn3_d2)
			challenge[9:5] <= challenge[9:5] + 1;
	end
end

	
assign counter_reset = btn[0] | send_result;
assign led[0] = cnt1_finish;
assign led[1] = cnt2_finish;
assign led[2] = cnt1_greater;
assign led[3] = cnt2_greater;

    assign enables = {64{en_rng}};

    (* dont_touch = "yes" *) rng_puf puf_32bit(.clock(CLK100MHZ), .reset(counter_reset),.enable(enables),.challenge(challenge), 
												.mux1_clk(), .mux2_clk(),.cnt1_finish(cnt1_finish), .cnt2_finish(cnt2_finish), .cnt1_led(cnt1_greater),.cnt2_led(cnt2_greater));
												
		
//UART
(* dont_touch = "yes" *) wire uartRdy, uartSend;
(* dont_touch = "yes" *) reg [10:0] challenge_plus_response;
(* dont_touch = "yes" *) wire [7:0] uartData;

always @(posedge CLK100MHZ)
begin
	if(cnt1_finish | cnt2_finish) begin
		challenge_plus_response <= {cnt1_greater,challenge};
		send_result				<= 1;
		
	end
	else if (uartSend == 1) begin
		send_result				<= 0;
	end
end


	(* dont_touch = "yes" *)  uart_state_ctrl   Inst_uart_state_ctrl (.send_msg(btn[0]), .send_data(send_result ), .uartRdy(uartRdy), .data(challenge_plus_response), .rom_rd(rom_rd),  .CLK(CLK100MHZ),.uartSend(uartSend), .uartData(uartData));
	(* dont_touch = "yes" *)  UART_TX_CTRL   Inst_UART_TX_CTRL(.SEND(uartSend), .DATA(uartData), .CLK(CLK100MHZ),.READY(uartRdy), .UART_TX(uart_rxd_out));


/*
always @(posedge CLK100MHZ)
begin
	if (btn[0] ==1)
		addra <= 0;
	else if (rom_rd ==1)
		addra <= addra +1;
end

//challenge input ROM
	challenge_input challenge_ROM_64x16(.clka(CLK100MHZ), .addra(addra), .douta(challenge_data));

*/
  
		
endmodule