`timescale 1ns/1ps

module uart_rx(clk,reset_n,rx,baudrate,rx_pop,rx_data,rx_empty);
   input  clk;
   input  reset_n;
   input  rx;
   input [15:0] baudrate;

   input        rx_pop;
   output [7:0] rx_data;
   output       rx_empty;

   // reg
   reg [15:0] r_wait;  // wait down counter @ clk
   reg [2:0]  r_rx;    // shift reg [1:0] synchronizer. [2] is one cycle old value, [1] is current value.   
   reg [4:0]  r_state; //    
   reg [7:0]  r_rx_data;
   reg        r_rx_push;

   // logic
   reg [4:0]  c_next_state;
   
   // wire
   wire       s_detect_rx_fall;
   wire       s_wait_expired;

   parameter p_dly = 0.001;

`define UART_RX_STATE_IDLE         5'd0
`define UART_RX_STATE_START_WAIT   5'd1 
`define UART_RX_STATE_START_CAP    5'd2
`define UART_RX_STATE_B0_WAIT      5'd3
`define UART_RX_STATE_B0_CAP       5'd4
`define UART_RX_STATE_B1_WAIT      5'd5
`define UART_RX_STATE_B1_CAP       5'd6
`define UART_RX_STATE_B2_WAIT      5'd7
`define UART_RX_STATE_B2_CAP       5'd8
`define UART_RX_STATE_B3_WAIT      5'd9
`define UART_RX_STATE_B3_CAP       5'd10
`define UART_RX_STATE_B4_WAIT      5'd11
`define UART_RX_STATE_B4_CAP       5'd12
`define UART_RX_STATE_B5_WAIT      5'd13
`define UART_RX_STATE_B5_CAP       5'd14
`define UART_RX_STATE_B6_WAIT      5'd15
`define UART_RX_STATE_B6_CAP       5'd16
`define UART_RX_STATE_B7_WAIT      5'd17
`define UART_RX_STATE_B7_CAP       5'd18
`define UART_RX_STATE_STOP_WAIT    5'd19
`define UART_RX_STATE_STOP_CAP     5'd20

   assign     s_detect_rx_fall =  (r_rx[2] & (~r_rx[1])); // old bit H, current bit L
   assign     s_wait_expired   =  ( r_wait == 16'd0 );
//   assign     rx_data  = r_rx_data;
   
   // r_rx
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_rx[2:0] <= 3'b111;
      end
      else begin
	 r_rx[2:0] <= #p_dly {r_rx[1:0],rx};
      end
   end
   
   // r_wait
   always @ (posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_wait[15:0] <= 16'd0;
      end
      else begin 
	 if (r_state==`UART_RX_STATE_IDLE) begin
	    r_wait[15:0] <= #p_dly {1'b0,baudrate[15:1]} - 1; 
	 end
	 else if ( ( r_state == `UART_RX_STATE_START_CAP ) |
		   ( r_state == `UART_RX_STATE_B0_CAP ) | 
		   ( r_state == `UART_RX_STATE_B1_CAP ) |
		   ( r_state == `UART_RX_STATE_B2_CAP ) |
		   ( r_state == `UART_RX_STATE_B3_CAP ) |
		   ( r_state == `UART_RX_STATE_B4_CAP ) |
		   ( r_state == `UART_RX_STATE_B5_CAP ) |
		   ( r_state == `UART_RX_STATE_B6_CAP ) |
		   ( r_state == `UART_RX_STATE_B7_CAP ) ) begin
	    r_wait[15:0] <= #p_dly baudrate[15:0]; 
	 end // if ( ( r_state == `UART_RX_STATE_START_CAP ) |...
	 else begin
	    if (s_wait_expired) begin
	       r_wait <= #p_dly 16'd0;
	    end
	    else begin
	       r_wait <= #p_dly ( r_wait - 1'b1 ) ;
	    end
	 end // else: !if( ( r_state == `UART_RX_STATE_START_CAP ) |...
      end // else: !if(~reset_n)
   end // always @ (posedge clk or negedge reset_n)
   
   // r_rx_data
   always @ (posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_rx_data[7:0] <= 8'd0;
      end
      else begin
	 case (r_state)
	   `UART_RX_STATE_B0_CAP :
	     begin
		r_rx_data[7:0] <= #p_dly {r_rx_data[7:1],r_rx[1]};
	     end
	   `UART_RX_STATE_B1_CAP :
	     begin
		r_rx_data[7:0] <= #p_dly {r_rx_data[7:2],r_rx[1],r_rx_data[0]};
	     end
	   `UART_RX_STATE_B2_CAP :
	     begin
		r_rx_data[7:0] <= #p_dly {r_rx_data[7:3],r_rx[1],r_rx_data[1:0]};
	     end
	   `UART_RX_STATE_B3_CAP :
	     begin
		r_rx_data[7:0] <= #p_dly {r_rx_data[7:4],r_rx[1],r_rx_data[2:0]};
	     end
	   `UART_RX_STATE_B4_CAP :
	     begin
		r_rx_data[7:0] <= #p_dly {r_rx_data[7:5],r_rx[1],r_rx_data[3:0]};
	     end
	   `UART_RX_STATE_B5_CAP :
	     begin
		r_rx_data[7:0] <= #p_dly {r_rx_data[7:6],r_rx[1],r_rx_data[4:0]};
	     end	   
	   `UART_RX_STATE_B6_CAP :
	     begin
		r_rx_data[7:0] <= #p_dly {r_rx_data[7],r_rx[1],r_rx_data[5:0]};
	     end
	   `UART_RX_STATE_B7_CAP :
	     begin
		r_rx_data[7:0] <= #p_dly {r_rx[1],r_rx_data[6:0]};
	     end
	   default :
	     begin
		r_rx_data[7:0] <= #p_dly r_rx_data[7:0];
	     end
	 endcase // case (r_state)
      end // else: !if(~reset_n)
   end // always @ (posedge clk or negedge reset_n)

   // r_rx_push
   always @ (posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_rx_push <= 1'b0;
      end
      else begin
	 if ( (r_state==`UART_RX_STATE_STOP_CAP) & r_rx[1] ) begin
	    r_rx_push <= #p_dly 1'b1;
	 end
	 else begin
	    r_rx_push <= #p_dly 1'b0;
	 end
      end
   end // always @ (posedge clk or negedge reset_n)

   // r_state
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_state <= `UART_RX_STATE_IDLE;	 
      end
      else begin
	 r_state <= #p_dly c_next_state;
      end
   end

   // c_next_state
   always @(r_rx or r_state or s_detect_rx_fall or s_wait_expired) begin
      case (r_state)
	`UART_RX_STATE_IDLE : 
	  begin
	     if (s_detect_rx_fall) begin
		c_next_state = `UART_RX_STATE_START_WAIT;
	     end
	     else begin
		c_next_state = `UART_RX_STATE_IDLE;
	     end
	  end
	`UART_RX_STATE_START_WAIT :
	  begin
	     if (s_wait_expired) begin
		c_next_state = `UART_RX_STATE_START_CAP;
	     end
	     else begin
		c_next_state = `UART_RX_STATE_START_WAIT;
	     end
	  end
	`UART_RX_STATE_START_CAP :
	  begin
	     if (r_rx[1]) begin
		c_next_state = `UART_RX_STATE_IDLE;
	     end
	     else begin
		// framing error occurs. go back to idle.
		c_next_state = `UART_RX_STATE_B0_WAIT;
	     end	  
	  end
	`UART_RX_STATE_B0_WAIT :
	  begin
	     if (s_wait_expired) begin
		c_next_state = `UART_RX_STATE_B0_CAP;
	     end
	     else begin
		c_next_state = `UART_RX_STATE_B0_WAIT;
	     end	  
	  end
	`UART_RX_STATE_B0_CAP :
	  begin
	     c_next_state = `UART_RX_STATE_B1_WAIT;
	  end
	`UART_RX_STATE_B1_WAIT :
	  begin
	     if (s_wait_expired) begin
		c_next_state = `UART_RX_STATE_B1_CAP;
	     end
	     else begin
		c_next_state = `UART_RX_STATE_B1_WAIT;
	     end	  
	  end
	`UART_RX_STATE_B1_CAP :
	  begin
	     c_next_state = `UART_RX_STATE_B2_WAIT;
	  end
	`UART_RX_STATE_B2_WAIT :
	  begin
	     if (s_wait_expired) begin
		c_next_state = `UART_RX_STATE_B2_CAP;
	     end
	     else begin
		c_next_state = `UART_RX_STATE_B2_WAIT;
	     end	  
	  end
	`UART_RX_STATE_B2_CAP :
	  begin
	     c_next_state = `UART_RX_STATE_B3_WAIT;
	  end
	`UART_RX_STATE_B3_WAIT :
	  begin
	     if (s_wait_expired) begin
		c_next_state = `UART_RX_STATE_B3_CAP;
	     end
	     else begin
		c_next_state = `UART_RX_STATE_B3_WAIT;
	     end	  
	  end
	`UART_RX_STATE_B3_CAP :
	  begin
	     c_next_state = `UART_RX_STATE_B4_WAIT;
	  end
	`UART_RX_STATE_B4_WAIT :
	  begin
	     if (s_wait_expired) begin
		c_next_state = `UART_RX_STATE_B4_CAP;
	     end
	     else begin
		c_next_state = `UART_RX_STATE_B4_WAIT;
	     end	  
	  end
	`UART_RX_STATE_B4_CAP :
	  begin
	     c_next_state = `UART_RX_STATE_B5_WAIT;
	  end
	`UART_RX_STATE_B5_WAIT :
	  begin
	     if (s_wait_expired) begin
		c_next_state = `UART_RX_STATE_B5_CAP;
	     end
	     else begin
		c_next_state = `UART_RX_STATE_B5_WAIT;
	     end	  
	  end
	`UART_RX_STATE_B5_CAP :
	  begin
	     c_next_state = `UART_RX_STATE_B6_WAIT;
	  end
	`UART_RX_STATE_B6_WAIT :
	  begin
	     if (s_wait_expired) begin
		c_next_state = `UART_RX_STATE_B6_CAP;
	     end
	     else begin
		c_next_state = `UART_RX_STATE_B6_WAIT;
	     end	  
	  end
	`UART_RX_STATE_B6_CAP :
	  begin
	     c_next_state = `UART_RX_STATE_B7_WAIT;
	  end
	`UART_RX_STATE_B7_WAIT :
	  begin
	     if (s_wait_expired) begin
		c_next_state = `UART_RX_STATE_B7_CAP;
	     end
	     else begin
		c_next_state = `UART_RX_STATE_B7_WAIT;
	     end	  
	  end
	`UART_RX_STATE_B7_CAP :
	  begin
	     c_next_state = `UART_RX_STATE_STOP_WAIT;
	  end
	`UART_RX_STATE_STOP_WAIT :
	  begin
	     if (s_wait_expired) begin
		c_next_state = `UART_RX_STATE_STOP_CAP;
	     end
	     else begin
		c_next_state = `UART_RX_STATE_STOP_WAIT;
	     end	  
	  end
	`UART_RX_STATE_STOP_CAP :
	  begin
	     c_next_state = `UART_RX_STATE_IDLE;
	  end
	default :
	  c_next_state = `UART_RX_STATE_IDLE;
      endcase // case (r_state)
   end // always @ (r_rx or r_state or s_detect_rx_fall or s_wait_expired)

   // 16 deep sync fifo
   uart_fifo i_uart_fifo(.clk(clk),
			 .reset_n(reset_n),
			 .wdata(r_rx_data),
			 .rdata(rx_data),
			 .push(r_rx_push),
			 .pop(rx_pop),
			 .empty(rx_empty));
endmodule // uart_rx
