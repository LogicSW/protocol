`timescale 1ns / 1ps
module spi_top#(
	parameter TICKS_WAIT = 100, // 1sec WAIT를 위한 counter 제한
	parameter DATA_LENGTH = 14, // Hello World!\n 문자열 갯수
	parameter SPI_MODE = 0
)(
	input wire clk, // FPGA clock
	input wire miso,
	output logic mosi,
	output logic sclk,
	output logic cs_n // chip selective falling edge일 때, 통신 시작을 알림.
);

logic [DATA_LENGTH*8-1:0] test_data = "Hello World!\n";
logic rst_n;
reg cs_n_value = 1;
logic clk_spi; // spi clock으로 3.125 MHz으로 세팅.

reg [2:0] RX_Bit_Count;
reg [2:0] TX_Bit_Count;
reg [7:0] Temp_RX_Byte;
reg [7:0] RX_Byte;

localparam N_REGS = 1;
localparam int read_after_start = 2; 
localparam int TICKS_BEFORE_STOP = 2; 
localparam logic [7:0] ADDR_ID = 8'hD0;
localparam logic [7:0] ADDR [N_REGS] = '{ADDR_ID};

// SPI 4가지 모드 정의
assign CPOL_value  = (SPI_MODE == 2) | (SPI_MODE == 3);
assign CPHA_value  = (SPI_MODE == 1) | (SPI_MODE == 3);
assign real_clk_spi = CPHA_value ? ~clk_spi : clk_spi; // SPI MODE에 따른 action clk

/* Counters & Indexes */
logic [3:0] idx_bit;
logic [1:0] idx_reg;
logic [23:0] cnt_wait;
logic [1:0] cnt_start;
logic [1:0] cnt_stop;
logic [7:0] reg_vals;

// state 정의.
enum logic [3:0] {
	RESET,			// 초기화 상태
    READY,			// 준비 상태
	WAIT,			// 다음 통신까지 1초 wait
	READ_START,		// Start 단계
	CTRL_SEND,		// Send signal
	READ_REG,		// Read register
	READ_STOP,		// Read Stop
    ERROR           // ERROR 상태
} state, next_state;


// IP catalog 정의.
mmcm_100MHz mmcm_spi (
	.reset(1'b0),
	.clk_in1(clk),
	.clk_out1(clk_mmcm),
	.locked(mmcm_locked)
);

ila_spi ila_spi (
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


vio_spi vio_spi (
   .clk(clk_mmcm)
  ,.probe_out0(rst_n)
);

// SPI clock  = 3.125 MHz
// 100MHz(MMCM 출력) / 32(clk_spi_dvi 관련 값) = 3.125 MHz(SPI clock)
// 표준 SPI
always @(posedge clk_mmcm) begin // 100 MHz = 10^(-8) sec
	static int clk_spi_div;

	if (clk_spi_div >= 16) begin // 32 / 2 = 16
		clk_spi_div <= 0;
		clk_spi <= ~clk_spi;
	end else begin
		clk_spi_div <= clk_spi_div + 1;
        clk_spi <= clk_spi; 
	end
end

// 동작 정의
// 1. state
always @(posedge real_clk_spi or negedge rst_n) begin
	if (~rst_n)
		state <= RESET;
	else
		state <= next_state;	
end

// 2. next_state 정의
always @ (*) begin
	next_state = state;
	case (state)
		RESET : 
			next_state = READY;

		READY : 
			next_state = WAIT;

		WAIT : begin
			if (cnt_wait >= TICKS_WAIT)
				next_state = READ_START;
		end

		READ_START : begin
			if (cnt_start >= read_after_start)
				next_state = CTRL_SEND; 
		end

		CTRL_SEND : begin 
			if ((idx_bit == 8) && sck)
				next_state = READ_REG;
		end

		READ_REG : begin
			if (idx_reg == N_REGS)
				next_state = READ_STOP;
		end

		READ_STOP : begin 
			if (cnt_stop >= TICKS_BEFORE_STOP)
				next_state = RESET;
		end

		ERROR : 
			next_state = RESET;

		default :
			next_state = ERROR;
	endcase
end

always_ff @(posedge real_clk_spi or negedge rst_n) begin
	if(~rst_n) begin
		sclk 		<= 0;
		cs_n 		<= 1;
		mosi 		<= 0;
		idx_bit		<= 0;
		idx_reg		<= 0;
		cnt_wait 	<= 0;
		cnt_start 	<= 0;
		cnt_stop 	<= 0;
		reg_vals	<= 0;
	end else begin
		case (next_state) 
			RESET: begin // RESET
				sclk 		<= 0;
				cs_n 		<= 1;
				mosi 		<= 0;
				idx_bit		<= 0;
				idx_reg		<= 0;
				cnt_wait 	<= 0;
				cnt_start 	<= 0;
				cnt_stop 	<= 0;
				reg_vals	<= 0;
			end
			
			READY: begin // 
				idx_bit		<= 0;
				idx_reg		<= 0;
				cnt_wait 	<= 0;
				cnt_start 	<= 0;
				cnt_stop 	<= 0;
			end
			
			WAIT: 
				cnt_wait <= cnt_wait + 1;

			READ_START: begin
				cs_n <= 0;
				cnt_start <= cnt_start + 1;
			end

			CTRL_SEND: begin
				if (state != next_state) begin
					sclk <= 0;
					mosi <= ADDR[idx_reg][7-idx_bit]; 
					idx_bit <= idx_bit + 1;
				end

				else begin
					sclk <= ~sclk;
				
					if (sck) begin
						mosi <= ADDR[idx_reg][7-idx_bit]; 
						idx_bit <= idx_bit + 1;
					end
				end
			end

			READ_REG: begin
				sclk <= ~sclk;

				if (state != next_state)
					idx_bit <= 0;
			
				if (~sck) begin
					reg_vals[8*((N_REGS-1)-idx_reg) + idx_bit] <= miso; 

					if (idx_bit == 7) begin
						idx_reg <= idx_reg + 1;
						idx_bit <= 0;
					end else begin
						idx_bit <= idx_bit + 1;
					end
				end
			end

			READ_STOP: begin
				if (cnt_stop == (TICKS_BEFORE_STOP-1))
					cs_n <= 1;

				cnt_stop <= cnt_stop + 1;
			end
			
			ERROR: begin
				
			end
		endcase
	end
end
endmodule
