/*--------------------- 
���ߣ������03 
��Դ��CSDN 
ԭ�ģ�https://blog.csdn.net/l03l03/article/details/81710723 
��Ȩ����������Ϊ����ԭ�����£�ת���븽�ϲ������ӣ�*/

`timescale 1ns/1ps
    module d_buf_tb();

        reg                 clk;
        reg                 rst_n;
        reg                 r_clk;//��ʱ��75M
        reg [7:0]           data_in;
        reg                 data_v;

        wire                    data_ov;
        wire    [15:0]      data_out;


        initial     
            begin
                clk = 0;
                r_clk = 0;
                data_v = 0;
                data_in= 0;
                rst_n = 0;
                #100 rst_n = 1;

            end

        always #5 clk = ~clk;//д��ʱ��100M
        always #6.6 r_clk = ~r_clk;//��ʱ��75M

        d_buf d_buf_inst(

        .clk                (clk),
        .rst_n              (rst_n),
        .r_clk              (r_clk),
        .data_in            (data_in),
        .data_v             (data_v),

        .data_ov            (data_ov),
        .data_out           (data_out)

    );

        initial
            begin
                #200;
                @(posedge clk)
                gen_frame();

                #500 $stop;
            end

        task gen_data();
            integer i;
            begin
            for(i=0;i<512;i=i+1)
                begin
                    @(posedge clk)
                    data_v <= 1'b1;
                    data_in <= i&8'hff;
                end
                @(posedge clk)
                    data_v = 0;
            end
        endtask

        task gen_rest();
            integer i;
            for(i=0;i<16;i=i+1)
                begin
                    @(posedge clk);
                end
        endtask

        task gen_frame();
            integer i;
            begin
                for(i=0;i<32;i=i+1)
                    begin
                        gen_data();
                        gen_rest();
                    end
            end
        endtask
    endmodule
