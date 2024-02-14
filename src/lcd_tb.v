`timescale 1ps/1ps

module test();

    reg clk = 0;

    always
        #111111 clk <= ~clk;

    initial begin
        #70000000000 $finish;
    end

    initial begin
        #222222 reset_n <= 1'b1;
    end

    initial begin
        $dumpfile("lcd.vcd");
        $dumpvars(0,test);
    end

    reg reset_n = 1'b0;

    wire LCD_HSYNC;
    wire LCD_VSYNC;
    wire LCD_DEN;

    wire [4:0] LCD_R;
    wire [5:0] LCD_G;
    wire [4:0] LCD_B;

    wire [10:0] pixel_x;
    wire [10:0] pixel_y;

    lcd_driver lcd( .PIXEL_CLK(clk),
                    .RESETn(reset_n),
                    .HSYNC(LCD_HSYNC),
                    .VSYNC(LCD_VSYNC),
                    .DEN(LCD_DEN),
                    .XPOS(pixel_x),
                    .YPOS(pixel_y) );

endmodule
