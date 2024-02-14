`include "lcd_h.v"

module main
(
    input           BTN_RESET,
    input           BTN_USER,
    input           XTAL_IN,

    output          LCD_CLK,
    output          LCD_HSYNC,
    output          LCD_VSYNC,
    output          LCD_DEN,

    output [4:0]    LCD_R,
    output [5:0]    LCD_G,
    output [4:0]    LCD_B,

    output [5:0]    LED
);

    //////////////////////////////////////////////////////////////////////
    // PLL (GW1NR-9C C6/I5 -Tang Nano 9K proto dev board)

`ifdef LCD_480_272

    `define PLL_SDIV_SEL 30

`elsif LCD_800_480

    `define PLL_SDIV_SEL 8

`else
    !error! "`define LCD_480_272 OR LCD_800_480"
`endif

    wire CLK_SYS;
    wire CLK_LOCK;

    rPLL #(
            .FCLKIN("27"),
            .IDIV_SEL(0),
            .FBDIV_SEL(9),
            .DYN_SDIV_SEL(`PLL_SDIV_SEL),  // 9MHz or 33.75 MHz
            .ODIV_SEL(2)
    ) pll (
            .CLKOUTP(),
            .CLKOUTD3(),
            .RESET(1'b0),
            .RESET_P(1'b0),
            .CLKFB(1'b0),
            .FBDSEL(6'b0),
            .IDSEL(6'b0),
            .ODSEL(6'b0),
            .PSDA(4'b0),
            .DUTYDA(4'b0),
            .FDLY(4'b0),
            .CLKIN(XTAL_IN),
            .CLKOUT(CLK_SYS),
            .CLKOUTD(LCD_CLK),  
            .LOCK(CLK_LOCK)
    );

    /////////////////////////////////////////////////////////////////////
    // Character map

    reg           text_write_enable;
    reg [11:0]    text_address;
    reg [7:0]     text_write_data;
    reg [7:0]     text_read_data;
    reg           text_ce;
    reg           text_oce;
    reg           text_reset;

    assign text_reset = !BTN_RESET;
    assign text_write_enable = 1'b0;
    assign text_write_data = 8'b0;
    assign text_ce = 1'b1;
    assign text_oce = 1'b0;

    Gowin_SP_text text_ram(
        .dout(text_read_data),   // output [7:0] dout
        .clk(LCD_CLK),           // input clk
        .oce(text_oce),          // input oce
        .ce(text_ce),            // input ce
        .reset(text_reset),      // input reset
        .wre(text_write_enable), // input wre
        .ad(text_address),       // input [11:0] ad
        .din(text_write_data)    // input [7:0] din
    );

    /////////////////////////////////////////////////////////////////////
    // Font

    reg           font_write_enable;
    reg [9:0]     font_address;
    reg [7:0]     font_write_data;
    reg [7:0]     font_read_data;
    reg           font_ce;
    reg           font_oce;
    reg           font_reset;

    assign font_reset = !BTN_RESET;
    assign font_write_enable = 1'b0;
    assign font_write_data = 8'b0;
    assign font_ce = 1'b1;
    assign font_oce = 1'b0;

    Gowin_SP_font font_ram(
        .dout(font_read_data),   // output [7:0] dout
        .clk(LCD_CLK),           // input clk
        .oce(font_oce),          // input oce
        .ce(font_ce),            // input ce
        .reset(font_reset),      // input reset
        .wre(font_write_enable), // input wre
        .ad(font_address),       // input [11:0] ad
        .din(font_write_data)    // input [7:0] din
    );

    /////////////////////////////////////////////////////////////////////
    // LCD

    wire [10:0] pixel_x;
    wire [10:0] pixel_y;

    wire LCD_LINE;

    lcd_driver lcd( .PIXEL_CLK(LCD_CLK),
                    .RESETn(BTN_RESET),
                    .HSYNC(LCD_HSYNC),
                    .VSYNC(LCD_VSYNC),
                    .DEN(LCD_DEN),
                    .LINE(LCD_LINE),
                    .XPOS(pixel_x),
                    .YPOS(pixel_y)
                    );

    //////////////////////////////////////////////////////////////////////
    // DRAW

`define FORE_COLOR1 16'b 11111_111100_11100
`define FORE_COLOR2 16'b 00000_111111_00000

`define BACK_COLOR1 16'b 10000_000000_00111
`define BACK_COLOR2 16'b 00000_000000_00000

    reg [15:0] fore_color;
    reg [15:0] back_color;

    always @(negedge LCD_VSYNC) begin
        fore_color <= BTN_USER ? `FORE_COLOR1 : `FORE_COLOR2;
        back_color <= BTN_USER ? `BACK_COLOR1 : `BACK_COLOR2;
    end

    reg [10:0] px;
    reg [10:0] py;

    assign px = pixel_x + 11'd8;
    assign py = pixel_y;

    reg [7:0] row[4];
    reg [16:0] pixel;

    // text ram is 64x64, 1 byte per character
    // font ram is 8 bytes per glyph, 1BPP

    always @(posedge LCD_CLK) begin
        text_address <= {py[8:3], px[8:3]};
        font_address <= {text_read_data[6:0] - 7'd32, py[2:0]};
        row[px[1:0]] <= font_read_data;
        pixel <= row[px[1:0]][px[2:0]] ? fore_color : back_color;
    end

    assign LCD_R = (LCD_DEN) ? pixel[15:11] : 5'b0;
    assign LCD_G = (LCD_DEN) ? pixel[10:5] : 6'b0;
    assign LCD_B = (LCD_DEN) ? pixel[4:0] : 5'b0;

    //////////////////////////////////////////////////////////////////////
    // LED

    reg [31:0] counter;
    reg [5:0] led_reg;

`define LED_DELAY 32'd 6750000

    always @(posedge XTAL_IN or negedge BTN_RESET) begin
       if (!BTN_RESET)
           counter <= 32'd0;
       else if (counter < `LED_DELAY)
           counter <= counter + 1;
       else
           counter <= 32'd0;
    end

    always @(posedge XTAL_IN or negedge BTN_RESET) begin
       if (!BTN_RESET)
           led_reg <= 6'b111110;
       else if (counter == `LED_DELAY)
           led_reg[5:0] <= {led_reg[0],led_reg[5:1]};

    end

    assign LED = led_reg;

endmodule
