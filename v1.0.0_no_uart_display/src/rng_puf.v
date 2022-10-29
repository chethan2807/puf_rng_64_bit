`timescale 1ns / 1ps



module rng_puf(
    enable,
    challenge,
    mux1_clk, //mux1 ring oscillator clock out
    mux2_clk, //mux2 ring oscillator clock ou
    cnt1_led, //glow if mux1 counter is >
    cnt2_led, //glow if mux2 counter is >
	cnt1_finish, // it beccomes high when cnt1[21] is high
	cnt2_finish, // it beccomes high when cnt2[21] is high
    clock,
    reset
    );
  output cnt1_led,cnt2_led,cnt1_finish,cnt2_finish,mux1_clk,mux2_clk ;
  input [9:0] challenge;
  input [63:0] enable;
  input clock, reset;

  (* dont_touch = "yes" *) wire [63:0] ro_out;  // a 64 bit bus: each stems from the output of each ro
  (* dont_touch = "yes" *) wire first_mux_out, second_mux_out;  // output of muxes that go into the counters
  (* dont_touch = "yes" *) wire fin1, fin2;     // outputs of the counters that go into the race arbiter
  (* dont_touch = "yes" *) wire [31:0] pmc1_out, pmc2_out;  // for debug, output of the counters
  (* dont_touch = "yes" *) wire cnt_en;  //

   genvar i;
	generate
		for (i=0; i<32; i=i+1) begin : gen_ro
			(* dont_touch = "yes" *) ring_osc #(i) first_ro_0_31 (enable[i], ro_out[i]);
			(* dont_touch = "yes" *) ring_osc #(i) second_ro_32_64 (enable[i+32], ro_out[i+32]);
		end
	endgenerate

  (* dont_touch = "yes" *) mux_32to1 first_mux(ro_out[31:0], challenge[4:0], first_mux_out);
  (* dont_touch = "yes" *) mux_32to1 second_mux(ro_out[63:32], challenge[9:5], second_mux_out);

  (* dont_touch = "yes" *) post_mux_counter pmc1(pmc1_out, fin1, cnt_en, first_mux_out, reset);

  (* dont_touch = "yes" *) post_mux_counter pmc2(pmc2_out, fin2, cnt_en, second_mux_out, reset);

assign cnt1_led = pmc1_out > pmc2_out ;
assign cnt2_led = pmc2_out > pmc1_out ;
assign cnt1_finish = fin1;
assign cnt2_finish = fin2 ;
assign mux1_clk = first_mux_out ;
assign mux2_clk = second_mux_out ;
assign cnt_en = enable[0] & ~ (fin1 | fin2)  ;


endmodule
