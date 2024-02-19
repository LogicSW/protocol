`timescale 1ns / 1ps

module spi_top #(
	parameter WAIT_TICKS = 19200, // 1sec WAIT를 위한 counter 제한
	parameter DATA_LENGTH = 14 // Hello World!\n 문자열 갯수
)(
	input wire clk,
	input wire miso,
	output wire mosi,
	output logic sclk,
	output logic cs_n, // chip selective falling edge일 때, 통신 시작을 알림.
	output reg [7:0] data
);



reg cs_n_value = 1;

assign 
assign cs_n = cs_n_value;

// state 정의.
enum logic [3:0] {
	RESET,			// 초기화 상태
    READY,			// 준비 상태
	WAIT,			// 사이 1초 wait
	GET_DATA,		// 송신할 바이트를 data 레지스터에 가져옴
	START_BIT,		// Start 1 bit
	DATA_BIT,		// Data 8 bit
	STOP_BIT,		// Stop 1 bit
    ERROR           // ERROR 상태
} state, next_state;


// IP catalog 정의.
mmcm_100MHz mmcm (
	.reset(1'b0).
	.clk_in1(clk),
	.clk_out1(clk_mmcm),
	.locked(mmcm_locked)
);

ila_spi ila (
   .clk(clk_mmcm)
  ,.probe0(sck)
  ,.probe1(miso)
  ,.probe2(mosi)
  ,.probe3(cs_n)
  ,.probe4(state)
  ,.probe5(next_state)
  ,.probe6(idx_bit)
  ,.probe7(idx_reg)
);


vio_spi vio(
   .clk(clk_mmcm)
  ,.probe_out0(rst_n)
);

always_ff @(posedge clk_mmcm or negedge rst_n) begin
	static logic [2:0] clk_spi_div;

	clk_spi_div <= clk_spi_div + 1;
	if (clk_spi_div == 3'b111)
		clk_spi <= ~clk_spi;
end








// 동작 정의
// 1. state
always @(posedge clk_spi or negedge rst_n) begin
	if (~rst_n)
		state <= RESET;
	else
		state <= next_state;	
end

// 2. next_state 정의
always (*) begin
	next_state = state;
	case (state)
		RESET : 
			next_state = READY;
		READY : 
			next_state = WAIT;
		WAIT : 
			if 

	endcase

end	

always @(posedge w_SPI_Clk or posedge i_SPI_CS_n)
  begin
    if (i_SPI_CS_n)
    begin
      r_RX_Bit_Count <= 0;
      r_RX_Done      <= 1'b0;
    end
    else
    begin
      r_RX_Bit_Count <= r_RX_Bit_Count + 1;

      // Receive in LSB, shift up to MSB
      r_Temp_RX_Byte <= {r_Temp_RX_Byte[6:0], i_SPI_MOSI};
    
      if (r_RX_Bit_Count == 3'b111)
      begin
        r_RX_Done <= 1'b1;
        r_RX_Byte <= {r_Temp_RX_Byte[6:0], i_SPI_MOSI};
      end
      else if (r_RX_Bit_Count == 3'b010)
      begin
        r_RX_Done <= 1'b0;        
      end

    end // else: !if(i_SPI_CS_n)
  end // always @ (posedge w_SPI_Clk or posedge i_SPI_CS_n)