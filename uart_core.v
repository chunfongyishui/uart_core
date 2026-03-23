/*
uart_core#(
.CLK_HZ		(100000000),
.BAUDRATE	(115200),
.CHECK_BIT	(0),//0无，1奇，2偶
.STOP_BIT	(1)//1位为1bit，2位为1.5bit，3为2bit
)uart_core(
.clk		(clk),
.rst		(rst),
.uart_rx	(uart_rx),
.uart_tx	(uart_tx),
.tx_en		(tx_en),
.tx_date	(tx_date),
.tx_idle	(tx_idle),
.rx_date	(rx_date),
.rx_valid	(rx_valid)
);
*/

module uart_core#(
parameter CLK_HZ    = 50000000,
parameter BAUDRATE  = 115200,
parameter CHECK_BIT = 0,//0无，1奇，2偶
parameter STOP_BIT  = 1//1位为1bit，2位为1.5bit，3为2bit
)(
input 				clk		,
input 				rst		,
input 				uart_rx	,
output reg			uart_tx	,
input 				tx_en	,
input [7:0]			tx_date	,
output reg			tx_idle	,
output reg [7:0]	rx_date	,
output  			rx_valid
);

parameter UART_FLAG = (CLK_HZ / BAUDRATE) >> 1;
parameter RX_HALF_BIT = ((1 + 8 + (CHECK_BIT ? 1 : 0)) << 1) + (STOP_BIT + 1);
parameter TX_HALF_BIT = RX_HALF_BIT + 1;

//RX
reg [4:0] rx_st;
reg rx_cnt_start;always@(posedge clk)if(rst || (rx_st==30)) rx_cnt_start <= 0; else if((rx_st==10) && (~uart_rx))rx_cnt_start <= 1;
reg [31:0] rx_cnt;always@(posedge clk)if(rst || (rx_cnt>=UART_FLAG-1) || (~rx_cnt_start))rx_cnt <= 0;else rx_cnt <= rx_cnt + 1;
reg [7:0] rx_bit_counter;always@(posedge clk)if(rst || rx_st == 30)rx_bit_counter <= 0; else if((rx_st==20) && (rx_cnt==UART_FLAG-1)) rx_bit_counter <= rx_bit_counter + 1;

always@(posedge clk) if(rst) rx_st <= 0;else case(rx_st)
0 : rx_st <= 10;
10: if(uart_rx == 0) rx_st <= 20;
20: if(rx_bit_counter == RX_HALF_BIT) rx_st <= 30;  
30: rx_st <= 10;
default rx_st <= 0;
endcase

always@(posedge clk) if(rst) rx_date[0] = 0;else if(rx_st == 20 && rx_bit_counter == 2 )rx_date[0] = uart_rx;
always@(posedge clk) if(rst) rx_date[1] = 0;else if(rx_st == 20 && rx_bit_counter == 4 )rx_date[1] = uart_rx;
always@(posedge clk) if(rst) rx_date[2] = 0;else if(rx_st == 20 && rx_bit_counter == 6 )rx_date[2] = uart_rx;
always@(posedge clk) if(rst) rx_date[3] = 0;else if(rx_st == 20 && rx_bit_counter == 8 )rx_date[3] = uart_rx;
always@(posedge clk) if(rst) rx_date[4] = 0;else if(rx_st == 20 && rx_bit_counter == 10)rx_date[4] = uart_rx;
always@(posedge clk) if(rst) rx_date[5] = 0;else if(rx_st == 20 && rx_bit_counter == 12)rx_date[5] = uart_rx;
always@(posedge clk) if(rst) rx_date[6] = 0;else if(rx_st == 20 && rx_bit_counter == 14)rx_date[6] = uart_rx;
always@(posedge clk) if(rst) rx_date[7] = 0;else if(rx_st == 20 && rx_bit_counter == 16)rx_date[7] = uart_rx;

reg rx_check;always@(posedge clk) if(rst) rx_check = 0;else if(rx_st == 20 && rx_bit_counter == 18)rx_check = uart_rx;
reg [7:0] rx_check_sum;always@(posedge clk)if(rst) rx_check_sum <= 0;else if(rx_st == 20 && rx_bit_counter == 19) rx_check_sum <= rx_date[7] + rx_date[6] + rx_date[5] + rx_date[4] + rx_date[3] + rx_date[2] + rx_date[1] + rx_date[0];
reg rx_check_valid;always@(posedge clk)if(rst)rx_check_valid <= 1;else if(CHECK_BIT) rx_check_valid <= (CHECK_BIT == 1) ? (rx_check == rx_check_sum[0]) : (rx_check == ~rx_check_sum[0]);
assign rx_valid = (rx_st == 30 && rx_check_valid);

//TX
reg [31:0] tx_st;
reg tx_cnt_start;always@(posedge clk)if(rst || (tx_st==30)) tx_cnt_start <= 0; else if((tx_st==10) && tx_en)tx_cnt_start <= 1;
reg [31:0] tx_cnt;always@(posedge clk)if(rst || (tx_cnt>=UART_FLAG-1) || (~tx_cnt_start))tx_cnt <= 0;else tx_cnt <= tx_cnt + 1;
reg [7:0] tx_bit_counter;always@(posedge clk)if(rst || tx_st == 30)tx_bit_counter <= 0; else if((tx_st==20) && (tx_cnt==UART_FLAG-1)) tx_bit_counter <= tx_bit_counter + 1;

reg [7:0] tx_dater;always@(posedge clk)if(rst)tx_dater <= 0;else if(tx_en && tx_idle) tx_dater <= tx_date;
always@(posedge clk)if(rst || (tx_st == 10 && tx_en))tx_idle <= 0;else if(tx_st == 5) tx_idle <= 1;

reg [7:0] tx_check_sum;always@(posedge clk)if(rst) tx_check_sum <=0;else tx_check_sum <= tx_dater[7] + tx_dater[6] + tx_dater[5] + tx_dater[4] + tx_dater[3] + tx_dater[2] + tx_dater[1] + tx_dater[0];
reg tx_check;always@(posedge clk)if(rst) tx_check <= 0;else tx_check <= (CHECK_BIT == 1) ? tx_check_sum[0] : ~tx_check_sum[0];

always@(posedge clk)if(rst)tx_st <= 0;else case(tx_st)
0: tx_st <= 5;
5: tx_st <= 10;
10: if(tx_en) tx_st <= 20;
20: if(tx_bit_counter == RX_HALF_BIT + 1) tx_st <= 30;
30: tx_st <= 5;
default tx_st <= 0;
endcase

always@(posedge clk) if(rst) uart_tx = 1;else case(tx_bit_counter)
0: uart_tx <= 1;
1,2 : uart_tx <= 0;
3,4 : uart_tx <= tx_dater[0];
5,6 : uart_tx <= tx_dater[1];
7,8 : uart_tx <= tx_dater[2];
9,10: uart_tx <= tx_dater[3];
11,12:uart_tx <= tx_dater[4];
13,14:uart_tx <= tx_dater[5];
15,16:uart_tx <= tx_dater[6];
17,18:uart_tx <= tx_dater[7];
19,20:uart_tx <= (CHECK_BIT) ? tx_check : 1;
default uart_tx <= 1;
endcase

endmodule

