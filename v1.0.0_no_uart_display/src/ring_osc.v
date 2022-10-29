`timescale 1ns/1ps


module ring_osc (enable, out);

  parameter FEDBACK_BUF_CNT = 0;
  output out;
  input enable;

  (* dont_touch = "yes" *) reg [6:0] inv=0; // 7 stage inverter
  (* dont_touch = "yes" *) reg [FEDBACK_BUF_CNT:0] feedback=0;


genvar gi, gj;
	generate
		for (gi=0; gi<7; gi=gi+1) begin : geninv
			if(gi==0) // feedback to first stage
			     always @(*)
				    #2 inv[gi] = feedback[FEDBACK_BUF_CNT];
			else 
			     always @(*)
				    #2 inv[gi] = ~inv[gi-1];
		end
	endgenerate
	
	generate	
		for (gj=0; gj<=FEDBACK_BUF_CNT; gj=gj+1) begin : gen_fedbck_buf
		  if(gj == 0)
		      always @(*)
			      #2 feedback[0] = ~inv[6] & enable; //last inverter out to feedback
		  else 
		      always @(*)
			        #2 feedback[gj] = feedback[gj-1] & enable;
	end
		
	endgenerate

  assign out = feedback[0];

endmodule

/*
 LUT1: 1-input Look-Up Table with general output (Mapped to a LUT6)
// 7 Series
// Xilinx HDL Libraries Guide, version 2012.2
LUT1 #(
.INIT(2'b00) // Specify LUT Contents
) LUT1_inst (
.O(O), // LUT general output
.I0(I0) // LUT input
);
// End of LUT1_inst instantiation
*/