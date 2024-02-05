`timescale 1ns / 1ps

module uart_hello #(
	parameter WAIT_TICKS = 19200, // 1sec WAIT를 위한 counter 제한
	parameter DATA_LENGTH = 14 // Hello World!\n 문자열 갯수
)(
	input clk,
	output logic tx	// 전송 bit
);


logic [DATA_LENGTH*8-1:0] test_data = "Hello World!\n"; // [103:0]
wire 	mclk;		// mmcm clock
logic	clk_uart; 	// uart clock
wire 	rst_n;		// reset


logic [7:0] data;		// 8비트씩 데이터 비트 저장 (UART 특성상)
logic [3:0] idx_byte;	// 
logic [3:0] data_limit;	// 데이터 비트 전송 시, 그 갯수 제한.
int wait_ticks;			// 1초 WAIT를 위한 counter

enum logic [3:0] {
	RESET,      // 초기화 상태
    READY,			// 준비 상태
	WAIT,		// "Hello World\n" 사이 1초 wait
	GET_DATA,		// 송신할 바이트를 data 레지스터에 가져옴
	START_BIT,	// Start 1 bit
	DATA_BIT,		// Data 8 bit
	STOP_BIT,	// Stop 1 bit
    ERROR           // ERROR 상태
} state, next_state;



// IP CATALOG for FPGA

mmcm_100MHz mmcm ( 
	 .reset(1'b0)
	,.clk_in1(clk)
	,.clk_out1(mclk) // 출력 : 100MHz
);


ila_uart_hello ila(
	 .clk		(mclk)
	,.probe0 	(clk_uart)
	,.probe1 	(tx)
	,.probe2 	(data)
	,.probe3 	(mmcm_locked)
	,.probe4 	(idx_byte)
	,.probe5 	(data_limit)
	,.probe6 	(state)
	,.probe7 	(next_state)
);


vio_uart_hello vio(
	 .clk 	(mclk) 
	,.probe_out0 (rst_n)
);

// UART BAUDRATE
// UART 클럭 생성  (100MHz(MMCM 출력) / 5208(cnt 값) = 19.2kHz)
// Baudrate: 19.2k  (19.2kHz 클럭이므로 초당 19200비트 송신) <= 표준 UART Baudrate
always @(posedge mclk) begin // 100 MHz마다 = 10^(-8) sec마다
	static int cnt;

	if (cnt >= 2604) begin // 5208번 / 2 = 2604 
		cnt <= 0;
		clk_uart <= ~clk_uart; // clk_uart는 19.2kHz(5.2*10^(-5)sec)를 가짐.
	end else begin
		cnt <= cnt + 1;
        clk_uart <= clk_uart; 
	end
end
// 동작 정의
always @(posedge clk_uart or negedge rst_n) begin
	if (!rst_n)
        state <= RESET;
	else
        state <= next_state;
end

always @ (*) begin

	next_state = state;

	case (state)
        
        RESET:
            next_state = READY;
		READY:
			next_state = WAIT;

		WAIT:								// clk_uart는 19.2kHz(5.2*10^(-5)sec)를 가짐.
			if (wait_ticks >= WAIT_TICKS) 	// 즉, WAIT_TICKS=19200이므로, 5.2*10^(-5)sec*19200 = 1sec
				next_state = GET_DATA;

		GET_DATA:
			next_state = START_BIT;

		START_BIT:	
			next_state = DATA_BIT;

		DATA_BIT: 		
			if (data_limit == 8) // 8비트 데이터 전송 완료시, 다음 state
				next_state = STOP_BIT;

		STOP_BIT: begin
			if (idx_byte == 0) // 
				next_state = READY;
			else
				next_state = GET_DATA;
		end
        ERROR:
            next_state = RESET; // Error시 , reset
		default:
			next_state = READY;	// Undefined State
	endcase
end

always @(posedge clk_uart or negedge rst_n) begin
	if (!rst_n) begin // 이 if문 없으면 합성시, 에러 발생. ambiguous clock in event control 
	        data 		<= 0;
            data_limit 	<= 0;
            idx_byte 	<= 0;
            wait_ticks 	<= 0;
            tx 			<= 1;
    end else begin

    	case (next_state)
            
            RESET: begin
                data 		<= 0;
                data_limit 	<= 0;
                idx_byte 	<= 0;
                wait_ticks 	<= 0;
                tx 			<= 1;
            end
    
            READY: begin
                data 		<= 0;
                data_limit 	<= 0;	
                idx_byte 	<= DATA_LENGTH; // idx_byte = 13
                wait_ticks 	<= 0;
                tx 			<= 1;
            end
    
            WAIT:
                wait_ticks <= wait_ticks + 1;
    
            GET_DATA: begin
                data <= test_data[idx_byte*8-1 -: 8]; // [idx_byte*8 : 1] 비트 범위에서 8비트 씩 잘라서 data에 저장.
                data_limit <= 0; // 데이터 비트 전송 전 limit counter 초기화
            end
    
            START_BIT:
                tx <= 0;					// start bit = 0 : 전송 시작
    
            DATA_BIT: begin
                tx 	<= data[data_limit];		// 8비트 데이터를 한 비트씩 tx에 전송.
                data_limit <= data_limit + 1; 	// data_limit를 0에서 8까지 더함.
            end
    
            STOP_BIT: begin
                tx <= 1;					// stop_bit = 1 : 전송 마무리
                idx_byte <= idx_byte - 1;	// idx_byte = 12 , 11, 10 ... 이렇게 [idx_byte*8-1 -: 8]에서 최상위 비트부터 잘라서 차례로 보냄.
            end
            
            ERROR: 
                tx <= 1;
            
            default: 
                tx <= 1;
        
        endcase
    end
end

endmodule