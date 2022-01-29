`timescale 1ns/1ps

// UART 2 APB master

// clk           : APB clock. 10MHz or faster clock is recommended.
// baudrate[15:0]: clock period/baudrate - 2 

module uart_apb(clk,reset_n,rx,tx,baudrate,paddr,pwrite,penable,pwdata,prdata,pready);
   input  clk;
   input  reset_n;

   // UART ports
   input  rx;
   output tx;

   // UART baudrate  eq. clk's period / baudrate period - 2
   // baudrate[15:0] must be 2 or more. 0 or 1 is not allowd.
   input [15:0] baudrate;

   // APB3 ports
   output [31:0] paddr;
   output        pwrite;
   output        penable;
   output [31:0] pwdata;
   input  [31:0] prdata;
   input         pready;

   wire   [7:0]  w_rx_data;
   wire          w_rx_empty;
   wire          w_rx_pop;

   wire [7:0] 	 w_tx_data;
   wire          w_tx_push;
   wire          w_tx_full;
   
   uart_cmd i_cmd(.clk(clk),
		  .reset_n(reset_n),

		  .rx_data (w_rx_data),
		  .rx_empty(w_rx_empty),
		  .rx_pop  (w_rx_pop),

		  .tx_data (w_tx_data),
		  .tx_push (w_tx_push),
		  .tx_full (w_tx_full),

		  .paddr(paddr),
		  .pwrite(pwrite),
		  .penable(penable),
		  .pwdata(pwdata),
		  .prdata(prdata),
		  .pready(pready));

   uart_tx i_tx(.clk(clk),
		.reset_n(reset_n),

		.baudrate(baudrate),

		.tx_data(w_tx_data),
		.tx_push(w_tx_push),
		.tx_full(w_tx_full),

		.tx(tx));

   uart_rx i_rx(.clk(clk),
		.reset_n(reset_n),

		.baudrate(baudrate),

		.rx_data(w_rx_data),
		.rx_pop(w_rx_pop),
		.rx_empty(w_rx_empty),

		.rx(rx));
endmodule // uart_apb
