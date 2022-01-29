`timescale 1ns/1ps

// 16 depth fifo

module uart_fifo(clk,reset_n,wdata,rdata,push,pop,empty,full);
   input        clk;
   input        reset_n;
   
   input [7:0]  wdata;
   output [7:0] rdata;
   input        push;
   input        pop;
   output       empty;
   output       full;

   reg [7:0] 	r_fifo_data_d0;
   reg [7:0] 	r_fifo_data_d1;
   reg [7:0] 	r_fifo_data_d2;
   reg [7:0] 	r_fifo_data_d3;
   reg [7:0] 	r_fifo_data_d4;
   reg [7:0] 	r_fifo_data_d5;
   reg [7:0] 	r_fifo_data_d6;
   reg [7:0] 	r_fifo_data_d7;
   reg [7:0] 	r_fifo_data_d8;
   reg [7:0] 	r_fifo_data_d9;
   reg [7:0] 	r_fifo_data_d10;
   reg [7:0] 	r_fifo_data_d11;
   reg [7:0] 	r_fifo_data_d12;
   reg [7:0] 	r_fifo_data_d13;
   reg [7:0] 	r_fifo_data_d14;
   reg [7:0] 	r_fifo_data_d15;

   reg [4:0] 	r_wrptr;
   reg [4:0] 	r_rdptr;

   reg [7:0] 	c_rdata;
   
   wire         w_fifo_full;
   wire         w_fifo_empty;
   wire         w_valid_push;
   wire         w_valid_pop;
   
   parameter    p_dly=0.001;   
   
   assign       w_fifo_empty = ( r_wrptr[4:0] == r_rdptr[4:0] ) ;
   assign       w_fifo_full  = ( ( r_wrptr[3:0] == r_rdptr[3:0] ) & (r_wrptr[4] ^ r_rdptr[4]) );
   assign       w_valid_push = (~w_fifo_full) & push;
   assign       w_valid_pop  = (~w_fifo_empty) & pop;
   assign       rdata = c_rdata;
   assign       empty = w_fifo_empty;
   assign       full  = w_fifo_full;

   // r_wrptr
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_wrptr <= 5'd0;
      end
      else begin
	 if (w_valid_push) begin
	    r_wrptr <= #p_dly r_wrptr + 1'b1;
	 end
	 else begin
	    r_wrptr <= #p_dly r_wrptr;
	 end
      end
   end // always @ (posedge clk or negedge reset_n)
   
   
   // r_rdptr
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_rdptr <= 5'd0;
      end
      else begin
	 if (w_valid_pop) begin
	    r_rdptr <= #p_dly r_rdptr + 1'b1;
	 end
	 else begin
	    r_rdptr <= #p_dly r_rdptr;
	 end
      end
   end // always @ (posedge clk or negedge reset_n)

   // r_fifo_data_d0
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_fifo_data_d0 <= 8'h00;
      end
      else begin
	 if (w_valid_push & (r_wrptr[3:0]==4'd0) ) begin
	    r_fifo_data_d0 <= #p_dly wdata;
	 end
	 else begin
	    r_fifo_data_d0 <= #p_dly r_fifo_data_d0;
	 end
      end
   end      
   
   // r_fifo_data_d1
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_fifo_data_d1 <= 8'h00;
      end
      else begin
	 if (w_valid_push & (r_wrptr[3:0]==4'd1) ) begin
	    r_fifo_data_d1 <= #p_dly wdata;
	 end
	 else begin
	    r_fifo_data_d1 <= #p_dly r_fifo_data_d1;
	 end
      end
   end // always @ (posedge clk or negedge reset_n)
   
   // r_fifo_data_d2
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_fifo_data_d2 <= 8'h00;
      end
      else begin
	 if (w_valid_push & (r_wrptr[3:0]==4'd2) ) begin
	    r_fifo_data_d2 <= #p_dly wdata;
	 end
	 else begin
	    r_fifo_data_d2 <= #p_dly r_fifo_data_d2;
	 end
      end
   end // always @ (posedge clk or negedge reset_n)

   // r_fifo_data_d3
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_fifo_data_d3 <= 8'h00;
      end
      else begin
	 if (w_valid_push & (r_wrptr[3:0]==4'd3) ) begin
	    r_fifo_data_d3 <= #p_dly wdata;
	 end
	 else begin
	    r_fifo_data_d3 <= #p_dly r_fifo_data_d3;
	 end
      end
   end // always @ (posedge clk or negedge reset_n)
   
   // r_fifo_data_d4
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_fifo_data_d4 <= 8'h00;
      end
      else begin
	 if (w_valid_push & (r_wrptr[3:0]==4'd4) ) begin
	    r_fifo_data_d4 <= #p_dly wdata;
	 end
	 else begin
	    r_fifo_data_d4 <= #p_dly r_fifo_data_d4;
	 end
      end
   end // always @ (posedge clk or negedge reset_n)

   // r_fifo_data_d5
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_fifo_data_d5 <= 8'h00;
      end
      else begin
	 if (w_valid_push & (r_wrptr[3:0]==4'd5) ) begin
	    r_fifo_data_d5 <= #p_dly wdata;
	 end
	 else begin
	    r_fifo_data_d5 <= #p_dly r_fifo_data_d5;
	 end
      end
   end // always @ (posedge clk or negedge reset_n)
   
   // r_fifo_data_d6
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_fifo_data_d6 <= 8'h00;
      end
      else begin
	 if (w_valid_push & (r_wrptr[3:0]==4'd6) ) begin
	    r_fifo_data_d6 <= #p_dly wdata;
	 end
	 else begin
	    r_fifo_data_d6 <= #p_dly r_fifo_data_d6;
	 end
      end
   end // always @ (posedge clk or negedge reset_n)

   // r_fifo_data_d7
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_fifo_data_d7 <= 8'h00;
      end
      else begin
	 if (w_valid_push & (r_wrptr[3:0]==4'd7) ) begin
	    r_fifo_data_d7 <= #p_dly wdata;
	 end
	 else begin
	    r_fifo_data_d7 <= #p_dly r_fifo_data_d7;
	 end
      end
   end // always @ (posedge clk or negedge reset_n)

   // r_fifo_data_d8
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_fifo_data_d8 <= 8'h00;
      end
      else begin
	 if (w_valid_push & (r_wrptr[3:0]==4'd8) ) begin
	    r_fifo_data_d8 <= #p_dly wdata;
	 end
	 else begin
	    r_fifo_data_d8 <= #p_dly r_fifo_data_d8;
	 end
      end
   end // always @ (posedge clk or negedge reset_n)

   // r_fifo_data_d9
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_fifo_data_d9 <= 8'h00;
      end
      else begin
	 if (w_valid_push & (r_wrptr[3:0]==4'd9) ) begin
	    r_fifo_data_d9 <= #p_dly wdata;
	 end
	 else begin
	    r_fifo_data_d9 <= #p_dly r_fifo_data_d9;
	 end
      end
   end // always @ (posedge clk or negedge reset_n)

   // r_fifo_data_d10
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_fifo_data_d10 <= 8'h00;
      end
      else begin
	 if (w_valid_push & (r_wrptr[3:0]==4'd10) ) begin
	    r_fifo_data_d10 <= #p_dly wdata;
	 end
	 else begin
	    r_fifo_data_d10 <= #p_dly r_fifo_data_d10;
	 end
      end
   end // always @ (posedge clk or negedge reset_n)

   // r_fifo_data_d11
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_fifo_data_d11 <= 8'h00;
      end
      else begin
	 if (w_valid_push & (r_wrptr[3:0]==4'd11) ) begin
	    r_fifo_data_d11 <= #p_dly wdata;
	 end
	 else begin
	    r_fifo_data_d11 <= #p_dly r_fifo_data_d11;
	 end
      end
   end // always @ (posedge clk or negedge reset_n)

   // r_fifo_data_d12
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_fifo_data_d12 <= 8'h00;
      end
      else begin
	 if (w_valid_push & (r_wrptr[3:0]==4'd12) ) begin
	    r_fifo_data_d12 <= #p_dly wdata;
	 end
	 else begin
	    r_fifo_data_d12 <= #p_dly r_fifo_data_d12;
	 end
      end
   end // always @ (posedge clk or negedge reset_n)

   // r_fifo_data_d13
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_fifo_data_d13 <= 8'h00;
      end
      else begin
	 if (w_valid_push & (r_wrptr[3:0]==4'd13) ) begin
	    r_fifo_data_d13 <= #p_dly wdata;
	 end
	 else begin
	    r_fifo_data_d13 <= #p_dly r_fifo_data_d13;
	 end
      end
   end // always @ (posedge clk or negedge reset_n)

   // r_fifo_data_d14
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_fifo_data_d14 <= 8'h00;
      end
      else begin
	 if (w_valid_push & (r_wrptr[3:0]==4'd14) ) begin
	    r_fifo_data_d14 <= #p_dly wdata;
	 end
	 else begin
	    r_fifo_data_d14 <= #p_dly r_fifo_data_d14;
	 end
      end
   end // always @ (posedge clk or negedge reset_n)

   // r_fifo_data_d15
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_fifo_data_d15 <= 8'h00;
      end
      else begin
	 if (w_valid_push & (r_wrptr[3:0]==4'd15) ) begin
	    r_fifo_data_d15 <= #p_dly wdata;
	 end
	 else begin
	    r_fifo_data_d15 <= #p_dly r_fifo_data_d15;
	 end
      end
   end // always @ (posedge clk or negedge reset_n)
   


   always @(r_rdptr or 
	    r_fifo_data_d0 or r_fifo_data_d1 or
	    r_fifo_data_d2 or r_fifo_data_d3 or
	    r_fifo_data_d4 or r_fifo_data_d5 or
	    r_fifo_data_d6 or r_fifo_data_d7 or
	    r_fifo_data_d8 or r_fifo_data_d9 or
	    r_fifo_data_d10 or r_fifo_data_d11 or
	    r_fifo_data_d12 or r_fifo_data_d13 or
	    r_fifo_data_d14 or r_fifo_data_d15 ) begin
      case (r_rdptr[3:0])
	4'd0 : c_rdata = r_fifo_data_d0;
	4'd1 : c_rdata = r_fifo_data_d1;
	4'd2 : c_rdata = r_fifo_data_d2;
	4'd3 : c_rdata = r_fifo_data_d3;
	4'd4 : c_rdata = r_fifo_data_d4;
	4'd5 : c_rdata = r_fifo_data_d5;
	4'd6 : c_rdata = r_fifo_data_d6;
	4'd7 : c_rdata = r_fifo_data_d7;
	4'd8 : c_rdata = r_fifo_data_d8;
	4'd9 : c_rdata = r_fifo_data_d9;
	4'd10: c_rdata = r_fifo_data_d10;
	4'd11: c_rdata = r_fifo_data_d11;
	4'd12: c_rdata = r_fifo_data_d12;
	4'd13: c_rdata = r_fifo_data_d13;
	4'd14: c_rdata = r_fifo_data_d14;
	4'd15: c_rdata = r_fifo_data_d15;
      endcase
   end // always @ (...
   
   
endmodule // uart_fifo
