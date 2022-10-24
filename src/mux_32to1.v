`timescale 1ns/1ps


module mux_32to1(in_array, sel, out);

  input [31:0]in_array;
  input [4:0] sel;
  output reg out;

  always@(*) begin
    case (sel)
      5'd0:  out = in_array[0];
      5'd1:  out = in_array[1];
      5'd2:  out = in_array[2];
      5'd3:  out = in_array[3];
      5'd4:  out = in_array[4];
      5'd5:  out = in_array[5];
      5'd6:  out = in_array[6];
      5'd7:  out = in_array[7];
      5'd8:  out = in_array[8];
      5'd9:  out = in_array[9];
      5'd10: out = in_array[10];
      5'd11: out = in_array[11];
      5'd12: out = in_array[12];
      5'd13: out = in_array[13];
      5'd14: out = in_array[14];
      5'd15: out = in_array[15];
      5'd16: out = in_array[16];
      5'd17: out = in_array[17];
      5'd18: out = in_array[18];
      5'd19: out = in_array[19];
      5'd20: out = in_array[20];
      5'd21: out = in_array[21];
      5'd22: out = in_array[22];
      5'd23: out = in_array[23];
      5'd24: out = in_array[24];
      5'd25: out = in_array[25];
      5'd26: out = in_array[26];
      5'd27: out = in_array[27];
      5'd28: out = in_array[28];
      5'd29: out = in_array[29];
      5'd30: out = in_array[30];
      5'd31: out = in_array[31];
    endcase
  end

endmodule

































