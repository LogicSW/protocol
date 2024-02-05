`timescale 1ns / 1ps

module uart_hello #(
	parameter WAIT_TICKS = 19200, // 1sec WAIT�� ���� counter ����
	parameter DATA_LENGTH = 14 // Hello World!\n ���ڿ� ����
)(
	input clk,
	output logic tx	// ���� bit
);


logic [DATA_LENGTH*8-1:0] test_data = "Hello World!\n"; // [103:0]
wire 	mclk;		// mmcm clock
logic	clk_uart; 	// uart clock
wire 	rst_n;		// reset


logic [7:0] data;		// 8��Ʈ�� ������ ��Ʈ ���� (UART Ư����)
logic [3:0] idx_byte;	// 
logic [3:0] data_limit;	// ������ ��Ʈ ���� ��, �� ���� ����.
int wait_ticks;			// 1�� WAIT�� ���� counter

enum logic [3:0] {
	RESET,      // �ʱ�ȭ ����
    READY,			// �غ� ����
	WAIT,		// "Hello World\n" ���� 1�� wait
	GET_DATA,		// �۽��� ����Ʈ�� data �������Ϳ� ������
	START_BIT,	// Start 1 bit
	DATA_BIT,		// Data 8 bit
	STOP_BIT,	// Stop 1 bit
    ERROR           // ERROR ����
} state, next_state;



// IP CATALOG for FPGA

mmcm_100MHz mmcm ( 
	 .reset(1'b0)
	,.clk_in1(clk)
	,.clk_out1(mclk) // ��� : 100MHz
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
// UART Ŭ�� ����  (100MHz(MMCM ���) / 5208(cnt ��) = 19.2kHz)
// Baudrate: 19.2k  (19.2kHz Ŭ���̹Ƿ� �ʴ� 19200��Ʈ �۽�) <= ǥ�� UART Baudrate
always @(posedge mclk) begin // 100 MHz���� = 10^(-8) sec����
	static int cnt;

	if (cnt >= 2604) begin // 5208�� / 2 = 2604 
		cnt <= 0;
		clk_uart <= ~clk_uart; // clk_uart�� 19.2kHz(5.2*10^(-5)sec)�� ����.
	end else begin
		cnt <= cnt + 1;
        clk_uart <= clk_uart; 
	end
end
// ���� ����
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

		WAIT:								// clk_uart�� 19.2kHz(5.2*10^(-5)sec)�� ����.
			if (wait_ticks >= WAIT_TICKS) 	// ��, WAIT_TICKS=19200�̹Ƿ�, 5.2*10^(-5)sec*19200 = 1sec
				next_state = GET_DATA;

		GET_DATA:
			next_state = START_BIT;

		START_BIT:	
			next_state = DATA_BIT;

		DATA_BIT: 		
			if (data_limit == 8) // 8��Ʈ ������ ���� �Ϸ��, ���� state
				next_state = STOP_BIT;

		STOP_BIT: begin
			if (idx_byte == 0) // 
				next_state = READY;
			else
				next_state = GET_DATA;
		end
        ERROR:
            next_state = RESET; // Error�� , reset
		default:
			next_state = READY;	// Undefined State
	endcase
end

always @(posedge clk_uart or negedge rst_n) begin
	if (!rst_n) begin // �� if�� ������ �ռ���, ���� �߻�. ambiguous clock in event control 
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
                data <= test_data[idx_byte*8-1 -: 8]; // [idx_byte*8 : 1] ��Ʈ �������� 8��Ʈ �� �߶� data�� ����.
                data_limit <= 0; // ������ ��Ʈ ���� �� limit counter �ʱ�ȭ
            end
    
            START_BIT:
                tx <= 0;					// start bit = 0 : ���� ����
    
            DATA_BIT: begin
                tx 	<= data[data_limit];		// 8��Ʈ �����͸� �� ��Ʈ�� tx�� ����.
                data_limit <= data_limit + 1; 	// data_limit�� 0���� 8���� ����.
            end
    
            STOP_BIT: begin
                tx <= 1;					// stop_bit = 1 : ���� ������
                idx_byte <= idx_byte - 1;	// idx_byte = 12 , 11, 10 ... �̷��� [idx_byte*8-1 -: 8]���� �ֻ��� ��Ʈ���� �߶� ���ʷ� ����.
            end
            
            ERROR: 
                tx <= 1;
            
            default: 
                tx <= 1;
        
        endcase
    end
end

endmodule