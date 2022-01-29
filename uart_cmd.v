`timescale 1ns/1ps

// CMD: SR<A3><A2><A1><A0>
// RES: <R3><R2><R1><R0>
// CMD: SW<A3><A2><A1><A0><W3><W2><W1><W0>
// RES: <C1><C0>

module uart_cmd(clk,reset_n,rx_data,rx_pop,rx_empty,tx_data,tx_push,tx_full,paddr,pwrite,penable,pwdata,prdata,pready);
   input        clk;
   input        reset_n;

   // UART RX FIFO
   input [7:0] 	rx_data;
   input        rx_empty;
   output       rx_pop;

   // UART TX FIFO
   output [7:0]  tx_data;
   output        tx_push;
   input         tx_full;

   // Internal APB3 bus.
   // psel address decoder is not included this module. 
   output [31:0] paddr;
   output        pwrite;
   output        penable;
   output [31:0] pwdata;
   input  [31:0] prdata;
   input         pready;

   // reg
   reg [4:0]  r_state;        // main fsm state
   reg [1:0]  r_data_byte_pos;    // 0: [31:24],1:[23:16],2:[15:8],3:[7:0]
   reg        r_data_nibble_pos;  // 0: hier nibble, 1: lower nibble 
   reg [31:0] r_addr;
   reg [31:0] r_wdata;
   reg [31:0] r_rdata;
   reg [7:0]  r_checksum;
      
   // logic
   reg [4:0]  c_next_state;
   reg [3:0]  c_rx_data_hex2bin; // nibble bin from ascii code rx_data.
   reg [3:0]  c_tx_data_nibble;
   reg [7:0]  c_tx_data_nibble_bin2hex;
   reg [7:0]  c_tx_data;
   wire       w_rx_not_empty;
   wire       w_tx_not_full;
   wire       w_rx_pop;
   wire       w_tx_push;
   wire       w_penable;
   wire       w_pwrite;

`define UART_CMD_STATE_IDLE                    5'd0
`define UART_CMD_STATE_SINGLE_COM              5'd1
`define UART_CMD_STATE_SINGLE_RD_ADDR          5'd3
`define UART_CMD_STATE_SINGLE_RD_APB_SETUP     5'd4
`define UART_CMD_STATE_SINGLE_RD_APB_ACCESS    5'd5
`define UART_CMD_STATE_SINGLE_RD_DATA          5'd6
`define UART_CMD_STATE_SINGLE_WR_ADDR          5'd7
`define UART_CMD_STATE_SINGLE_WR_DATA          5'd8
`define UART_CMD_STATE_SINGLE_WR_APB_SETUP     5'd9
`define UART_CMD_STATE_SINGLE_WR_APB_ACCESS    5'd10
`define UART_CMD_STATE_SINGLE_WR_CHECKSUM      5'd11
   
   assign     w_rx_not_empty = ~rx_empty;
   assign     w_tx_not_full  = ~tx_full;
   
   assign     w_rx_pop = w_rx_not_empty & 
			 (~((r_state==`UART_CMD_STATE_SINGLE_RD_APB_SETUP ) |
			    (r_state==`UART_CMD_STATE_SINGLE_RD_APB_ACCESS) |
			    (r_state==`UART_CMD_STATE_SINGLE_RD_DATA      ) |
			    (r_state==`UART_CMD_STATE_SINGLE_WR_APB_SETUP ) |
			    (r_state==`UART_CMD_STATE_SINGLE_WR_APB_ACCESS) |
			    (r_state==`UART_CMD_STATE_SINGLE_WR_CHECKSUM  )));
   assign     w_tx_push = w_tx_not_full &
			  ((r_state==`UART_CMD_STATE_SINGLE_RD_DATA      ) |
			   (r_state==`UART_CMD_STATE_SINGLE_WR_CHECKSUM  ));
   


   assign     w_penable = (r_state==`UART_CMD_STATE_SINGLE_RD_APB_ACCESS) |
			  (r_state==`UART_CMD_STATE_SINGLE_WR_APB_ACCESS) ;

   assign     w_pwrite  = (r_state==`UART_CMD_STATE_SINGLE_WR_APB_SETUP ) |
			  (r_state==`UART_CMD_STATE_SINGLE_WR_APB_ACCESS) ;

   assign     rx_pop = w_rx_pop;
   assign     tx_push = w_tx_push;
   assign     tx_data = c_tx_data;
   
   // APB3
   assign     paddr   = r_addr;
   assign     penable = w_penable;
   assign     pwrite  = w_pwrite;
   assign     pwdata  = r_wdata;
   
   parameter p_dly = 0.001;
   

   // r_addr
   always @(posedge clk or negedge reset_n)begin
	      if (~reset_n) begin
	 r_addr <= 32'h00000000;
      end
      else begin
	 if (((r_state==`UART_CMD_STATE_SINGLE_RD_ADDR)|
	      (r_state==`UART_CMD_STATE_SINGLE_WR_ADDR))&
	     w_rx_pop) begin
	    case ({r_data_byte_pos,r_data_nibble_pos})
	      3'b000: r_addr <= #p_dly {              c_rx_data_hex2bin,r_addr[27:0]};
	      3'b001: r_addr <= #p_dly {r_addr[31:28],c_rx_data_hex2bin,r_addr[23:0]};
	      3'b010: r_addr <= #p_dly {r_addr[31:24],c_rx_data_hex2bin,r_addr[19:0]};
	      3'b011: r_addr <= #p_dly {r_addr[31:20],c_rx_data_hex2bin,r_addr[15:0]};
	      3'b100: r_addr <= #p_dly {r_addr[31:16],c_rx_data_hex2bin,r_addr[11:0]};
	      3'b101: r_addr <= #p_dly {r_addr[31:12],c_rx_data_hex2bin,r_addr[7:0] };
	      3'b110: r_addr <= #p_dly {r_addr[31:8] ,c_rx_data_hex2bin,r_addr[3:0] };
	      3'b111: r_addr <= #p_dly {r_addr[31:4] ,c_rx_data_hex2bin             };
	    endcase
	 end // if (((r_state==`UART_CMD_STATE_SINGLE_RD_ADDR)|...
	 else begin
	    r_addr <= #p_dly r_addr;
	 end // else: !if(((r_state==`UART_CMD_STATE_SINGLE_RD_ADDR)|...
      end // else: !if(~reset_n)
   end // always @ (posedge clk or negedge reset_n)

   // r_rdata
   always @(posedge clk or negedge reset_n)begin
      if (~reset_n) begin
	 r_rdata <= 32'h00000000;
      end
      else begin
	 if ((r_state==`UART_CMD_STATE_SINGLE_WR_APB_ACCESS) & pready ) begin
	    r_rdata <= #p_dly prdata;
	 end
	 else begin
	    r_rdata <= #p_dly r_rdata;
	 end
      end // else: !if(~reset_n)
   end // always @ (posedge clk or negedge reset_n)

   // r_wdata
   always @(posedge clk or negedge reset_n)begin
	      if (~reset_n) begin
	 r_wdata <= 32'h00000000;
      end
      else begin
	 if ((r_state==`UART_CMD_STATE_SINGLE_WR_DATA) &
	     w_rx_pop) begin
	    case ({r_data_byte_pos,r_data_nibble_pos})
	      3'b000: r_wdata <= #p_dly {               c_rx_data_hex2bin,r_wdata[27:0]};
	      3'b001: r_wdata <= #p_dly {r_wdata[31:28],c_rx_data_hex2bin,r_wdata[23:0]};
	      3'b010: r_wdata <= #p_dly {r_wdata[31:24],c_rx_data_hex2bin,r_wdata[19:0]};
	      3'b011: r_wdata <= #p_dly {r_wdata[31:20],c_rx_data_hex2bin,r_wdata[15:0]};
	      3'b100: r_wdata <= #p_dly {r_wdata[31:16],c_rx_data_hex2bin,r_wdata[11:0]};
	      3'b101: r_wdata <= #p_dly {r_wdata[31:12],c_rx_data_hex2bin,r_wdata[7:0] };
	      3'b110: r_wdata <= #p_dly {r_wdata[31:8] ,c_rx_data_hex2bin,r_wdata[3:0] };
	      3'b111: r_wdata <= #p_dly {r_wdata[31:4] ,c_rx_data_hex2bin             };
	    endcase
	 end
	 else begin
	    r_wdata <= #p_dly r_wdata;
	 end // else: !if((r_state==`UART_CMD_STATE_SINGLE_WR_DATA) &...	 
      end // else: !if(~reset_n)
   end // always @ (posedge clk or negedge reset_n)   

   // r_state
   always @(posedge clk or negedge reset_n)begin
	      if (~reset_n) begin
	 r_state <= `UART_CMD_STATE_IDLE;
      end
      else begin
	 r_state <= #p_dly c_next_state;
      end
   end

   //r_data_byte_pos;    // 0: [31:24], 1:[23:16],2:[15:8],3:[7:0]
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_data_byte_pos   <= 2'b00;
      end
      else begin
	 // if address data input state and lower nibble
	 if ( ( r_state==`UART_CMD_STATE_SINGLE_RD_ADDR ) |
	      ( r_state==`UART_CMD_STATE_SINGLE_WR_ADDR ) |
	      ( r_state==`UART_CMD_STATE_SINGLE_WR_DATA ) )begin
	    if (r_data_nibble_pos & w_rx_pop ) begin
	       r_data_byte_pos <= #p_dly r_data_byte_pos + 1'b1;
	    end
	    else begin
	       r_data_byte_pos <= #p_dly r_data_byte_pos;
	    end
	 end
	 else if ( ( r_state==`UART_CMD_STATE_SINGLE_RD_DATA ) |
		   ( r_state==`UART_CMD_STATE_SINGLE_WR_CHECKSUM ) )begin
	    if (r_data_nibble_pos & w_tx_push ) begin
	       r_data_byte_pos <= #p_dly r_data_byte_pos + 1'b1;
	    end
	    else begin
	       r_data_byte_pos <= #p_dly r_data_byte_pos;
	    end
	 end
	 else begin
	    r_data_byte_pos <= #p_dly 2'b00;
	 end
      end // else: !if(~reset_n)
   end

   //r_data_nibble_pos;    // 0: high 1:low
    always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_data_nibble_pos   <= 1'b0;
      end
      else begin
	 // if address data input state and lower nibble
	 if ( ( r_state==`UART_CMD_STATE_SINGLE_RD_ADDR ) |
	      ( r_state==`UART_CMD_STATE_SINGLE_WR_ADDR ) |
	      ( r_state==`UART_CMD_STATE_SINGLE_WR_DATA ) )begin
	    if ( w_rx_pop ) begin
	       r_data_nibble_pos <= #p_dly ~r_data_nibble_pos;
	    end
	    else begin
	       r_data_nibble_pos <= #p_dly r_data_nibble_pos;
	    end
	 end
	 else if ( ( r_state==`UART_CMD_STATE_SINGLE_RD_DATA ) |
		   ( r_state==`UART_CMD_STATE_SINGLE_WR_CHECKSUM ))begin
	    if ( w_tx_push ) begin
	       r_data_nibble_pos <= #p_dly ~r_data_nibble_pos;
	    end
	    else begin
	       r_data_nibble_pos <= #p_dly r_data_nibble_pos;
	    end
	 end
	 else begin
	    r_data_nibble_pos <= #p_dly 1'b0;
	 end
      end // else: !if(~reset_n)
    end // always @ (posedge clk or negedge reset_n)

   // r_checksum
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
	 r_checksum   <= 8'h00;
      end
      else begin
	 if (  r_state==`UART_CMD_STATE_IDLE ) begin
	    r_checksum   <= #p_dly 8'h00;
	 end
	 else if ( ( ( r_state==`UART_CMD_STATE_SINGLE_WR_ADDR ) |
		     ( r_state==`UART_CMD_STATE_SINGLE_WR_DATA ) ) & w_rx_pop )begin
	    if (r_data_nibble_pos==1'b0) begin
	       r_checksum <= #p_dly r_checksum + {c_rx_data_hex2bin,4'h0};
	    end
	    else begin
	       r_checksum <= #p_dly r_checksum + c_rx_data_hex2bin;
	    end
	 end
	 else begin
	    r_checksum <= #p_dly r_checksum;
	 end // else: !if( ( ( r_state==`UART_CMD_STATE_SINGLE_WR_ADDR ) |...
      end // else: !if(~reset_n)
   end // always @ (posedge clk or negedge reset_n)
   
   // c_next_state
   always @(r_state or w_rx_pop or rx_data or r_data_byte_pos or r_data_nibble_pos or pready or w_tx_push) begin
      case (r_state)
	`UART_CMD_STATE_IDLE : 
	  begin
	     // S(0x53)
	     if (w_rx_pop & (rx_data==8'h53)) begin
		c_next_state = `UART_CMD_STATE_SINGLE_COM;
	     end
	     else begin
		c_next_state = `UART_CMD_STATE_IDLE;
	     end
	  end
	`UART_CMD_STATE_SINGLE_COM :
	  begin
	     if (w_rx_pop) begin
		// R(0x52)
		if (rx_data==8'h52) begin
		   c_next_state = `UART_CMD_STATE_SINGLE_RD_ADDR;		   
		end
		// W(0x57)
		else if (rx_data==8'h57) begin
		   c_next_state = `UART_CMD_STATE_SINGLE_WR_ADDR;
		end
		else begin
		   c_next_state = `UART_CMD_STATE_IDLE;
		end
	     end
	     else begin
		c_next_state = r_state;
	     end
	  end // case: `UART_CMD_STATE_SINGLE_COM
	`UART_CMD_STATE_SINGLE_RD_ADDR :
	  begin
	     if ( ( r_data_byte_pos==2'b11 ) & 
		  r_data_nibble_pos &
		  w_rx_pop ) begin
		c_next_state = `UART_CMD_STATE_SINGLE_RD_APB_SETUP;
	     end
	     else begin
		c_next_state = r_state;
	     end
	  end // case: `UART_CMD_STATE_SINGLE_RD_ADDR
	`UART_CMD_STATE_SINGLE_RD_APB_SETUP :
	  begin
	     c_next_state = `UART_CMD_STATE_SINGLE_RD_APB_ACCESS;
	  end
	`UART_CMD_STATE_SINGLE_RD_APB_ACCESS:
	  begin
	     if (pready) begin
		c_next_state = `UART_CMD_STATE_SINGLE_RD_DATA;
	     end
	     else begin
		c_next_state = r_state;
	     end
	  end
	`UART_CMD_STATE_SINGLE_RD_DATA:
	  begin
	     if ( ( r_data_byte_pos==2'b11 ) & 
		  r_data_nibble_pos &
		  w_tx_push ) begin
		c_next_state = `UART_CMD_STATE_IDLE;
	     end
	     else begin
		c_next_state = r_state;
	     end
	  end // case: `UART_CMD_STATE_SINGLE_RD_DATA

	`UART_CMD_STATE_SINGLE_WR_ADDR:
	  begin
	     if ( ( r_data_byte_pos==2'b11 ) & 
		  r_data_nibble_pos &
		  w_rx_pop ) begin
		c_next_state = `UART_CMD_STATE_SINGLE_WR_DATA;
	     end
	     else begin
		c_next_state = r_state;
	     end
	  end // case: `UART_CMD_STATE_SINGLE_WR_ADDR

	`UART_CMD_STATE_SINGLE_WR_DATA:
	  begin
	     if ( ( r_data_byte_pos==2'b11 ) & 
		  r_data_nibble_pos &
		  w_rx_pop ) begin
		c_next_state = `UART_CMD_STATE_SINGLE_WR_APB_SETUP;
	     end
	     else begin
		c_next_state = r_state;
	     end
	  end // case: `UART_CMD_STATE_SINGLE_WR_DATA
	`UART_CMD_STATE_SINGLE_WR_APB_SETUP:
	  begin
	     c_next_state = `UART_CMD_STATE_SINGLE_WR_APB_ACCESS;
	  end

	`UART_CMD_STATE_SINGLE_WR_APB_ACCESS:
	  begin
	     if (pready) begin
		c_next_state = `UART_CMD_STATE_SINGLE_WR_CHECKSUM;
	     end
	     else begin
		c_next_state = r_state;
	     end
	  end

	`UART_CMD_STATE_SINGLE_WR_CHECKSUM:
	  begin
	     if ( ( r_data_byte_pos==2'b00 ) & 
		  r_data_nibble_pos &
		  w_tx_push ) begin
		c_next_state = `UART_CMD_STATE_IDLE;
	     end
	     else begin
		c_next_state = r_state;
	     end
	  end // case: `UART_CMD_STATE_SINGLE_WR_CHECKSUM
	default :
	  c_next_state = `UART_CMD_STATE_IDLE;
      endcase // case (r_state)
   end // always @ (r_state or w_rx_pop or rx_data or r_data_byte_pos or r_data_nibble_pos or pready or w_tx_push)

   // c_rx_data_hex2bin
   always @(rx_data)begin
      case (rx_data)
	8'h30:       c_rx_data_hex2bin = 4'h0;
	8'h31:       c_rx_data_hex2bin = 4'h1;
	8'h32:       c_rx_data_hex2bin = 4'h2;
	8'h33:       c_rx_data_hex2bin = 4'h3;
	8'h34:       c_rx_data_hex2bin = 4'h4;
	8'h35:       c_rx_data_hex2bin = 4'h5;
	8'h36:       c_rx_data_hex2bin = 4'h6;
	8'h37:       c_rx_data_hex2bin = 4'h7;
	8'h38:       c_rx_data_hex2bin = 4'h0;
	8'h39:       c_rx_data_hex2bin = 4'h1;
	8'h41,8'h61: c_rx_data_hex2bin = 4'ha;
	8'h42,8'h62: c_rx_data_hex2bin = 4'hb;
	8'h43,8'h63: c_rx_data_hex2bin = 4'hc;
	8'h44,8'h64: c_rx_data_hex2bin = 4'hd;
	8'h45,8'h65: c_rx_data_hex2bin = 4'he;
	8'h46,8'h66: c_rx_data_hex2bin = 4'hf;
	default : c_rx_data_hex2bin = 4'h0;
      endcase // case (rx_data)   
   end // always @ (rx_data)
   
   //c_tx_data_nibble
   always @ (r_state or 
	     r_data_byte_pos or r_data_nibble_pos or
	     r_rdata or r_checksum) begin
      if (r_state == `UART_CMD_STATE_SINGLE_RD_DATA ) begin
	 case ({r_data_byte_pos,r_data_nibble_pos})
	   3'b000: c_tx_data_nibble = r_rdata[31:28];
	   3'b001: c_tx_data_nibble = r_rdata[27:24];
	   3'b010: c_tx_data_nibble = r_rdata[23:20];
	   3'b011: c_tx_data_nibble = r_rdata[19:16];
	   3'b100: c_tx_data_nibble = r_rdata[15:12];
	   3'b101: c_tx_data_nibble = r_rdata[11:8];
	   3'b110: c_tx_data_nibble = r_rdata[7:4];
	   3'b111: c_tx_data_nibble = r_rdata[3:0];
	 endcase // case ({r_data_byte_pos,r_data_nibble_pos})
      end // if (r_state == `UART_CMD_STATE_SINGLE_RD_DATA )
      else if ( r_state == `UART_CMD_STATE_SINGLE_WR_CHECKSUM )begin
	 if (r_data_nibble_pos) begin
	    c_tx_data_nibble = r_checksum[7:4];
	 end
	 else begin
	    c_tx_data_nibble = r_checksum[3:0];
	 end
      end
      else begin
	 c_tx_data_nibble = r_rdata[3:0];
      end
   end // always @ (r_state or...    

   //c_tx_data_nibble_bin2hex
   always @ (c_tx_data_nibble) begin   
      case (c_tx_data_nibble)
	4'h0 : c_tx_data_nibble_bin2hex = 8'h30;
	4'h1 : c_tx_data_nibble_bin2hex = 8'h31;
	4'h2 : c_tx_data_nibble_bin2hex = 8'h32;
	4'h3 : c_tx_data_nibble_bin2hex = 8'h33;
	4'h4 : c_tx_data_nibble_bin2hex = 8'h34;
	4'h5 : c_tx_data_nibble_bin2hex = 8'h35;
	4'h6 : c_tx_data_nibble_bin2hex = 8'h36;
	4'h7 : c_tx_data_nibble_bin2hex = 8'h37;
	4'h8 : c_tx_data_nibble_bin2hex = 8'h38;
	4'h9 : c_tx_data_nibble_bin2hex = 8'h39;
	4'ha : c_tx_data_nibble_bin2hex = 8'h41;
	4'hb : c_tx_data_nibble_bin2hex = 8'h42;
	4'hc : c_tx_data_nibble_bin2hex = 8'h43;
	4'hd : c_tx_data_nibble_bin2hex = 8'h44;
	4'he : c_tx_data_nibble_bin2hex = 8'h45;
	4'hf : c_tx_data_nibble_bin2hex = 8'h46;
      endcase // case (c_tx_data_nibble)
   end // always @ (c_tx_data_nibble)

   //c_tx_data
   always @(c_tx_data_nibble_bin2hex or r_state) begin
      case (r_state)
	`UART_CMD_STATE_SINGLE_RD_DATA,
	`UART_CMD_STATE_SINGLE_WR_CHECKSUM: c_tx_data = c_tx_data_nibble_bin2hex;
	default :  c_tx_data = c_tx_data_nibble_bin2hex;
      endcase // case (r_state)
   end   

endmodule // uart_cmd
