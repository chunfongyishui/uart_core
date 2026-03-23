
module tb_uart_core;

//生成VCD文件
initial begin
	$dumpfile("tb_uart_core.vcd");
	$dumpvars(0, tb_uart_core );
end

// 时钟生成
reg clk;
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10单位时间的时钟周期 ,若单位周期为1ns，则此时钟为100M
end

//usr
reg rst = 1;
wire uart_tx;
reg [7:0] tx_date;
reg tx_en = 0;
wire tx_idle;

wire [7:0] rx_date;
wire rx_valid;

//由于小数计算不出来，生成的波特率会有差异，时序对不上可微调BAUDRATE参数
uart_core#(
.CLK_HZ(100000000),
.BAUDRATE(115200),
.CHECK_BIT(0),//0无，1奇，2偶
.STOP_BIT(1)//1位为1bit，2位为1.5bit，3为2bit
)uart_core(
.clk(clk),
.rst(rst),
.uart_rx(uart_tx),
.uart_tx(uart_tx),

.tx_en(tx_en),
.tx_date(tx_date),
.tx_idle(tx_idle),

.rx_date(rx_date),
.rx_valid(rx_valid)
);


task tx_pack(input [7:0] date);
begin
	@(posedge clk); tx_date <= date;
	wait(tx_idle);//等待tx_idle
	@(posedge clk); 
	tx_en <= 1;
	@(posedge clk); 
	tx_en <= 0;
end
endtask

initial begin
    #10;rst = 0;
	
	@(posedge clk);tx_pack(8'ha5);
	@(posedge clk);tx_pack(8'h00);

	
	
	#250000;
    $finish;
end

endmodule
