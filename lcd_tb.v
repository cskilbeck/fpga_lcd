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

    wire [9:0] pixel_x;
    wire [9:0] pixel_y;

    lcd_driver lcd( .VGA_CLK(clk),
                    .RESETn(reset_n),
                    .HSYNC(LCD_HSYNC),
                    .VSYNC(LCD_VSYNC),
                    .DEN(LCD_DEN),
                    .XPOS(pixel_x),
                    .YPOS(pixel_y) );

    reg [7:0] box_x = 8'b0;
    reg [7:0] box_y = 8'b0;

    always @(negedge LCD_VSYNC) begin
        box_x <= box_x + 1'b1;
        box_y <= box_y + 1'b1;
    end

endmodule
