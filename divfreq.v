module divfreq(CLK, CLK_div, speed_control);

  input CLK;
  input int speed_control;
  output logic CLK_div;
  
  bit[24:0] Count;
  
  always @(posedge CLK)
  begin
    if(Count > speed_control) //1 HZ
    begin
      Count <= 25'b0;
      CLK_div <= ~CLK_div;
    end
    else
      Count <= Count + 1'b1;
  end
endmodule

module divfreq1000HZ(CLK, CLK_div, bcd_out, score, tens_score, COM);

  input CLK;
  input logic[3:0] score, tens_score;
  output logic CLK_div;
  output logic[3:0] bcd_out;
  output logic[1:0] COM;
  
  bit[24:0] Count;
  
  always @(posedge CLK)
  begin
    if(Count > 25000) //1000 HZ
    begin
      Count <= 25'b0;
      CLK_div <= ~CLK_div;
    end
    else
      Count <= Count + 1'b1;
	 
	 if(Count < 25000/2) begin
	   COM = 2'b10;
	   bcd_out = score;
	 end
	 else begin
	   COM = 2'b01;
	   bcd_out = tens_score;
	 end
  end
endmodule
