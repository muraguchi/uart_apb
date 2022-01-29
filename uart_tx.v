`timescale 1ns/1ps

module uart_tx(clk,reset_n,baudrate,tx_data,tx_push,tx_full,tx);
   input        clk;
   input        reset_n;
   input [15:0] baudrate;
   input [7:0]  tx_data;
   input        tx_push;
   output       tx_full;
   output       tx;
   
   // reg
   reg [15:0] r_wait;    // wait down counter @ clk
   reg [4:0]  r_state;   // FSM   
   reg [7:0]  r_tx_data; // tx data
   reg        r_tx;      // tx out
   reg        r_tx_ready; // tx ready
   
   // logic
   reg [4:0]  c_next_state;
   reg        c_tx;
   
   // wire
   wire       w_wait_expired;
   wire       w_tx_pop;
   wire [7:0] w_tx_pop_data;
   
   wire       w_empty;
   
`define UART_TX_STATE_IDLE            5'd0
`define UART_TX_STATE_START_TRANS     5'd1
`define UART_TX_STATE_START_WAIT      5'd2
`define UART_TX_STATE_B0_TRANS        5'd3
`define UART_TX_STATE_B0_WAIT         5'd4
`define UART_TX_STATE_B1_TRANS        5'd5
`define UART_TX_STATE_B1_WAIT         5'd6
`define UART_TX_STATE_B2_TRANS        5'd7
`define UART_TX_STATE_B2_WAIT         5'd8
`define UART_TX_STATE_B3_TRANS        5'd9
`define UART_TX_STATE_B3_WAIT         5'd10
`define UART_TX_STATE_B4_TRANS        5'd11
`define UART_TX_STATE_B4_WAIT         5'd12
`define UART_TX_STATE_B5_TRANS        5'd13
`define UART_TX_STATE_B5_WAIT         5'd14
`define UART_TX_STATE_B6_TRANS        5'd15
`define UART_TX_STATE_B6_WAIT         5'd16
`define UART_TX_STATE_B7_TRANS        5'd17
`define UART_TX_STATE_B7_WAIT         5'd18
`define UART_TX_STATE_STOP_TRANS      5'd19
`define UART_TX_STATE_STOP_WAIT       5'd20
   
   parameter p_dly = 0.001;
   
   assign     w_wait_expired = ( r_wait == 16'd0 );
   assign     w_tx_pop       = ( r_state == `UART_TX_STATE_IDLE ) & ( ~w_empty );
   assign     tx             = r_tx;

   // r_tx
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_tx <= 1'b1;
      end
      else begin
	 r_tx <= #p_dly c_tx;
      end
   end
   
   // r_wait
   always @ (posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_wait[15:0] <= 16'd0;
      end
      else begin
	 
	 if (r_state==`UART_TX_STATE_IDLE) begin
	    r_wait[15:0] <= #p_dly {1'b0,baudrate[15:1]} - 1; 
	 end
	 else if ( ( r_state == `UART_TX_STATE_START_TRANS ) |
		   ( r_state == `UART_TX_STATE_B0_TRANS ) | 
		   ( r_state == `UART_TX_STATE_B1_TRANS ) |
		   ( r_state == `UART_TX_STATE_B2_TRANS ) |
		   ( r_state == `UART_TX_STATE_B3_TRANS ) |
		   ( r_state == `UART_TX_STATE_B4_TRANS ) |
		   ( r_state == `UART_TX_STATE_B5_TRANS ) |
		   ( r_state == `UART_TX_STATE_B6_TRANS ) |
		   ( r_state == `UART_TX_STATE_B7_TRANS ) ) begin
	    r_wait[15:0] <= #p_dly baudrate[15:0];
	 end // if ( ( r_state == `UART_TX_STATE_START_TRANS ) |...
	 else if ( r_state == `UART_TX_STATE_STOP_TRANS ) begin
	    r_wait[15:0] <= #p_dly (baudrate[15:0] - 1'b1); 
	 end
	 else begin
	    if (w_wait_expired) begin
	       r_wait <= #p_dly 16'd0;
	    end
	    else begin
	       r_wait <= #p_dly ( r_wait - 1'b1 ) ;
	    end
	 end // else: !if( ( r_state == `UART_TX_STATE_START_TRANS ) |...
      end // else: !if(~reset_n)
   end // always @ (posedge clk or negedge reset_n)
   
   // r_tx_data
   always @ (posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_tx_data[7:0] <= 8'hff;
      end
      else begin
	 if ( w_tx_pop ) begin
	    r_tx_data[7:0] <= #p_dly w_tx_pop_data ;
	 end
	 else begin
	    r_tx_data[7:0] <= #p_dly r_tx_data[7:0];
	 end
      end // else: !if(~reset_n)
   end // always @ (posedge clk or negedge reset_n)

   // r_state
   always @(posedge clk or negedge reset_n)begin
	      if (~reset_n) begin
	 r_state <= `UART_TX_STATE_IDLE;	 
      end
      else begin
	 r_state <= #p_dly c_next_state;
      end
   end

   // c_next_state
   always @(r_state or w_tx_pop or w_wait_expired) begin
      case (r_state)
	`UART_TX_STATE_IDLE : 
	  begin
	     if (w_tx_pop) begin
		c_next_state = `UART_TX_STATE_START_TRANS;
	     end
	     else begin
		c_next_state = `UART_TX_STATE_IDLE;
	     end	  
	  end
	`UART_TX_STATE_START_TRANS :
	  begin
	     c_next_state = `UART_TX_STATE_START_WAIT;
	  end
	`UART_TX_STATE_START_WAIT :
	  begin
	     if (w_wait_expired) begin
		c_next_state = `UART_TX_STATE_B0_TRANS;
	     end
	     else begin
		c_next_state = `UART_TX_STATE_START_WAIT;
	     end
	  end
	`UART_TX_STATE_B0_TRANS :
	  begin
	     c_next_state = `UART_TX_STATE_B0_WAIT;
	  end
	`UART_TX_STATE_B0_WAIT :
	  begin
	     if (w_wait_expired) begin
		c_next_state = `UART_TX_STATE_B1_TRANS;
	     end
	     else begin
		c_next_state = `UART_TX_STATE_B0_WAIT;
	     end
	  end
	`UART_TX_STATE_B1_TRANS :
	  begin
	     c_next_state = `UART_TX_STATE_B1_WAIT;
	  end
	`UART_TX_STATE_B1_WAIT :
	  begin
	     if (w_wait_expired) begin
		c_next_state = `UART_TX_STATE_B2_TRANS;
	     end
	     else begin
		c_next_state = `UART_TX_STATE_B1_WAIT;
	     end
	  end
	`UART_TX_STATE_B2_TRANS :
	  begin
	     c_next_state = `UART_TX_STATE_B2_WAIT;
	  end
	`UART_TX_STATE_B2_WAIT :
	  begin
	     if (w_wait_expired) begin
		c_next_state = `UART_TX_STATE_B3_TRANS;
	     end
	     else begin
		c_next_state = `UART_TX_STATE_B2_WAIT;
	     end
	  end
	`UART_TX_STATE_B3_TRANS :
	  begin
	     c_next_state = `UART_TX_STATE_B3_WAIT;
	  end
	`UART_TX_STATE_B3_WAIT :
	  begin
	     if (w_wait_expired) begin
		c_next_state = `UART_TX_STATE_B4_TRANS;
	     end
	     else begin
		c_next_state = `UART_TX_STATE_B3_WAIT;
	     end
	  end
	`UART_TX_STATE_B4_TRANS :
	  begin
	     c_next_state = `UART_TX_STATE_B4_WAIT;
	  end
	`UART_TX_STATE_B4_WAIT :
	  begin
	     if (w_wait_expired) begin
		c_next_state = `UART_TX_STATE_B5_TRANS;
	     end
	     else begin
		c_next_state = `UART_TX_STATE_B4_WAIT;
	     end
	  end
	`UART_TX_STATE_B5_TRANS :
	  begin
	     c_next_state = `UART_TX_STATE_B5_WAIT;
	  end
	`UART_TX_STATE_B5_WAIT :
	  begin
	     if (w_wait_expired) begin
		c_next_state = `UART_TX_STATE_B6_TRANS;
	     end
	     else begin
		c_next_state = `UART_TX_STATE_B5_WAIT;
	     end
	  end
	`UART_TX_STATE_B6_TRANS :
	  begin
	     c_next_state = `UART_TX_STATE_B6_WAIT;
	  end
	`UART_TX_STATE_B6_WAIT :
	  begin
	     if (w_wait_expired) begin
		c_next_state = `UART_TX_STATE_B7_TRANS;
	     end
	     else begin
		c_next_state = `UART_TX_STATE_B6_WAIT;
	     end
	  end
	`UART_TX_STATE_B7_TRANS :
	  begin
	     c_next_state = `UART_TX_STATE_B7_WAIT;
	  end
	`UART_TX_STATE_B7_WAIT :
	  begin
	     if (w_wait_expired) begin
		c_next_state = `UART_TX_STATE_STOP_TRANS;
	     end
	     else begin
		c_next_state = `UART_TX_STATE_B7_WAIT;
	     end
	  end
	`UART_TX_STATE_STOP_TRANS :
	  begin
	     c_next_state = `UART_TX_STATE_STOP_WAIT;
	  end
	`UART_TX_STATE_STOP_WAIT :
	  begin
	     if (w_wait_expired) begin
		c_next_state = `UART_TX_STATE_IDLE;
	     end
	     else begin
		c_next_state = `UART_TX_STATE_STOP_WAIT;
	     end
	  end
	default :
	  c_next_state = `UART_TX_STATE_IDLE;
      endcase // case (r_state)
   end // always @ (r_state or w_wait_expired)

   // c_tx
   always @(r_state or r_tx_data) begin
      case (r_state)
	`UART_TX_STATE_IDLE :
	  begin
	     c_tx = 1'b1;
	  end
	`UART_TX_STATE_START_TRANS :
	  begin
	     c_tx = 1'b0;
	  end
	`UART_TX_STATE_B0_TRANS :
	  begin
	     c_tx = r_tx_data[0];
	  end
	`UART_TX_STATE_B1_TRANS :
	  begin
	     c_tx = r_tx_data[1];
	  end
	`UART_TX_STATE_B2_TRANS :
	  begin
	     c_tx = r_tx_data[2];
	  end
	`UART_TX_STATE_B3_TRANS :
	  begin
	     c_tx = r_tx_data[3];
	  end
	`UART_TX_STATE_B4_TRANS :
	  begin
	     c_tx = r_tx_data[4];
	  end
	`UART_TX_STATE_B5_TRANS :
	  begin
	     c_tx = r_tx_data[5];
	  end
	`UART_TX_STATE_B6_TRANS :
	  begin
	     c_tx = r_tx_data[6];
	  end
	`UART_TX_STATE_B7_TRANS :
	  begin
	     c_tx = r_tx_data[7];
	  end
	`UART_TX_STATE_STOP_TRANS :
	  begin
	     c_tx = 1'b1;
	  end
	default:
	  begin
	     c_tx = r_tx;
	  end
      endcase // case (r_state)
   end // always @ (...
   
   // 16 deep sync fifo
   uart_fifo i_uart_fifo(.clk(clk),
			 .reset_n(reset_n),
			 .wdata(tx_data),
			 .rdata(w_tx_pop_data),
			 .push(tx_push),
			 .pop(w_tx_pop),
			 .empty(w_empty),
			 .full(tx_full));
   
    
endmodule // uart_tx
