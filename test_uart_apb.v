`timescale 1ns/1ps

module tb_top();

   reg r_clk;
   reg r_reset_n;
   reg r_rx;
   reg [15:0] r_baudrate;

   reg 	      r_pready=1;
   reg [31:0] r_prdata=32'h00000000;

   wire [31:0] w_paddr;
   wire        w_penable;
   wire [31:0] w_pwdata;
   wire        w_tx;
   
   parameter p_dly = 0.001;

   // 10MHz : half period 50[ns] 
   parameter p_clk_half_period = 50;

   // 2Mbps : period 500[ns]
   parameter p_baudrate_period = 500;

   // SIM END 10[ms]
   parameter p_sim_timeout = 10_000_000;
	  
   initial begin
      r_clk = 0;
      r_reset_n = 1;
      r_rx = 1;
      // baudrate = ( clk freq / baudrate ) - 3
      r_baudrate = 16'd3; // (10 / 2) - 2 = 16'd3
      
      #p_clk_half_period;
      #p_clk_half_period;
      r_reset_n = 0;
      #p_clk_half_period;
      #p_clk_half_period;
      r_reset_n = 1;
      #p_clk_half_period;
      #p_clk_half_period;
      forever begin
	 #p_clk_half_period;
	 r_clk = ~r_clk;
      end
   end // initial begin


   initial begin
      @(posedge r_clk);
      #p_dly;
      uart_sent(8'h53);
      uart_sent(8'h52);
      
      uart_sent(8'h46);
      uart_sent(8'h45);

      uart_sent(8'h44);
      uart_sent(8'h43);

      uart_sent(8'h42);
      uart_sent(8'h41);

      uart_sent(8'h30);
      uart_sent(8'h31);

      wait(w_tx==1'b0);
      
      uart_sent(8'h53);
      uart_sent(8'h57);
      uart_sent(8'h30);
      uart_sent(8'h31);
      uart_sent(8'h32);
      uart_sent(8'h33);
      uart_sent(8'h34);
      uart_sent(8'h35);
      uart_sent(8'h36);
      uart_sent(8'h37);

      uart_sent(8'h38);
      uart_sent(8'h39);
      uart_sent(8'h3A);
      uart_sent(8'h3B);
      uart_sent(8'h3C);
      uart_sent(8'h3D);
      uart_sent(8'h3E);
      uart_sent(8'h3F);      
      

      

      @(posedge r_clk);
      #p_dly;
   end
   
   initial begin
      $dumpfile("test_uart_apb.vcd");
      $dumpvars(0);
      #p_sim_timeout;
      $display("Sim finished. timeout at %t",$realtime);
      $finish;
   end

   task uart_sent;
      input reg [7:0] data;
      begin 
	 r_rx = 0;
	 #p_baudrate_period;
	 r_rx = data[0];
	 #p_baudrate_period;
	 r_rx = data[1];
	 #p_baudrate_period;
	 r_rx = data[2];
	 #p_baudrate_period;
	 r_rx = data[3];
	 #p_baudrate_period;
	 r_rx = data[4];
	 #p_baudrate_period;
	 r_rx = data[5];
	 #p_baudrate_period;
	 r_rx = data[6];
	 #p_baudrate_period;
	 r_rx = data[7];
	 #p_baudrate_period;
	 r_rx = 1'b1;
	 #p_baudrate_period;
      end
   endtask

   
   
   uart_apb i_uart_apb(.clk(r_clk),
		       .reset_n(r_reset_n),
		       .rx(r_rx),
		       .tx(w_tx),
		       .baudrate(r_baudrate),

		       .paddr(w_paddr),
		       .penable(w_penable),
		       .pwrite(w_pwrite),
		       .pwdata(w_pwdata),
		       .prdata(r_prdata),
		       .pready(r_pready));
endmodule // tb_top
