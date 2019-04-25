/*--------------------- 
作者：大亨利03 
来源：CSDN 
原文：https://blog.csdn.net/l03l03/article/details/81710723 
版权声明：本文为博主原创文章，转载请附上博文链接！*/


module d_buf(

            input                       clk,//写入时钟100M
            input                       rst_n,
            input                       r_clk,//读时钟75M
            input       [7:0]           data_in,
            input                       data_v,

            output                  data_ov,
            output  [15:0]      data_out

            );
            parameter           READ_END = 256-1;
            reg                 w_sel;//为0时，写入ram1,1则写入ram2
            reg                 data_v_dly;
            reg                 data_v_dly1;
            wire                    w_ram_en1,w_ram_en2;
            reg [9:0]           w_addr1,w_addr2;
            wire    [7:0]           w_data_1,w_data_2;
            reg                 r_start_flag;//跨时钟域的读使能信号
            reg [2:0]           r_start_buf;
            reg                 r_flag;
            reg [7:0]           r_cnt;
            reg                 r_flag_dly;
            reg                 r_sel;
            wire    [8:0]           r_addr1,r_addr2;
            wire   [15:0]       d_out_1,d_out_2;

            //延时data_v 一拍
            always@(posedge clk)
                data_v_dly <= data_v;

            always@(posedge clk)
                data_v_dly1 <= data_v_dly;

            always@(posedge clk,negedge rst_n)
                if(!rst_n)
                    w_sel <= 1'b0;
                else    if(data_v_dly && (~data_v))
                            w_sel <= ~w_sel;

            //写使能信号
            assign w_ram_en1 = data_v && (~w_sel);
            assign w_ram_en2 = w_sel && data_v;

            //产生写地址
            always@(posedge clk,negedge rst_n)
                if(!rst_n)
                    w_addr1 <= 'd0;
                else    if(w_ram_en1)
                            w_addr1 <= w_addr1 + 1'b1;
                else
                            w_addr1 <= 'd0;

            //产生写地址
            always@(posedge clk,negedge rst_n)
                if(!rst_n)
                    w_addr2 <= 'd0;
                else    if(w_ram_en2)
                            w_addr2 <= w_addr2 + 1'b1;
                else
                            w_addr2 <= 'd0;

            //利用data_v产生读开始标志（写时钟域：保持两个时钟周期，在r_clk中可踩到）         
            always@(posedge clk,negedge rst_n)
                if(!rst_n)
                    r_start_flag <= 1'b0;
                else    if(data_v == 1'b0 && data_v_dly1 == 1'b1)
                    r_start_flag <= 1'b1;
                else 
                    r_start_flag <= 1'b0;

            ram_w8x1024_r16x512 ram1_inst (
            .data ( data_in ),
            .rdaddress ( r_addr1 ),
            .rdclock ( r_clk ),
            .wraddress ( w_addr1 ),
            .wrclock ( clk ),
            .wren ( w_ram_en1 ),
            .q ( d_out_1 )
            );

            ram_w8x1024_r16x512 ram2_inst (
            .data ( data_in ),
            .rdaddress ( r_addr2 ),
            .rdclock ( r_clk ),
            .wraddress ( w_addr2 ),
            .wrclock ( clk ),
            .wren ( w_ram_en2 ),
            .q ( d_out_2 )
            );

            /* 
            //xilinx 的ram
            ram_w8x1024_r16x512 ram1(
            .clka       (clk),
            .wea        (w_ram_en1),
            .addra      (w_addr1),
            .dina       (data_in),
            .clkb       (r_clk),
            .addrb      (r_addr1),
            .doutb      (d_out_1)
            );

            ram_w8x1024_r16x512 ram2(
            .clka       (clk),
            .wea        (w_ram_en2),
            .addra      (w_addr2),
            .dina       (data_in),
            .clkb       (r_clk),
            .addrb      (r_addr2),
            .doutb      (d_out_2)
            );
             */
            //r_clk
            //寄存两拍
            always@(posedge r_clk)
                r_start_buf <= {r_start_buf[1:0],r_start_flag};

            //出现上升沿时，产生读开始标志r_flag
            always@(posedge r_clk)
                if(r_start_buf[2:1] == 2'b01)
                            r_flag <= 1'b1;
                else if ( r_cnt == READ_END)
                            r_flag <= 1'b0;

            //读开始，并计数
            always@(posedge r_clk,negedge rst_n)
                    if(!rst_n)
                        r_cnt <= 'd0;
                    else if(r_flag== 1'b1)
                        r_cnt <= r_cnt + 1'b1;
                    else
                        r_cnt <= 'd0;
            //r_flag延后一拍，产生读选r_sel信号
            always@(posedge r_clk)
                r_flag_dly <= r_flag;

            always@(posedge r_clk,negedge rst_n)
                if(!rst_n)
                    r_sel <= 1'b0;
                else    if(r_flag == 1'b0 && r_flag_dly == 1'b1)
                    r_sel <= ~r_sel;

            assign r_addr1  = r_cnt;
            assign r_addr2  = r_cnt;

            assign  data_out = r_sel?d_out_2:d_out_1;
            assign  data_ov = r_flag_dly;


endmodule
