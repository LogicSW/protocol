`timescale 1ns / 1ps

module tb_uart_tx();

reg clk = 0;
logic tx;

always begin
	#83.33
	clk = ~clk;
end

uart_hello DUT(
	.clk(clk),
	.tx(tx)
);


endmodule