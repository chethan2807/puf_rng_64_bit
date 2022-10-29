`timescale 1ns/1ps


module post_mux_counter    (
out     ,  // Output of the counter
finished,  // Output finished signal
enable  ,  // enable for counter
clk     ,  // clock Input
reset      // reset Input
);

//----------Output Ports--------------
  output reg finished;
  output reg [31:0] out;
//------------Input Ports--------------
  input enable, clk, reset;
//-------------Code Starts Here-------
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      out 		<= 32'd0;
      finished 	<= 0;
    end
	else begin
		if (out[31]==1) begin
			finished <= 1'b1;
		end
		if (enable & (out[31]!=1)) begin
			out <= out + 1;
		end
	end
  end

endmodule
