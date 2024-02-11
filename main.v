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

`ifdef LCD_800_480

    `define PLL_SDIV_SEL 8

`elsif LCD_480_272

    `define PLL_SDIV_SEL 30

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

    reg [10:0] pixel_x;
    reg [10:0] pixel_y;

    lcd_driver lcd( .PIXEL_CLK(LCD_CLK),
                    .RESETn(BTN_RESET),
                    .HSYNC(LCD_HSYNC),
                    .VSYNC(LCD_VSYNC),
                    .DEN(LCD_DEN),
                    .XPOS(pixel_x),
                    .YPOS(pixel_y)
                    );

    //////////////////////////////////////////////////////////////////////
    // DRAW

`define OFF5 5'b00000
`define OFF6 6'b000000

`define BG5 5'b00000
`define BG6 6'b000000

`define ON5 5'b11111
`define ON6 6'b111111

    reg [7:0] box_x = 8'b0;
    reg [7:0] box_y = 8'b0;

    always @(negedge LCD_VSYNC) begin
        box_x <= box_x + 1'b1;
        box_y <= box_y + 1'b1;
    end

    assign LCD_R =  !LCD_DEN                                        ?   `OFF5   :
                    pixel_x[7:0] < box_x || pixel_y[7:0] < box_y    ?   `BG5    :
                    pixel_x[5] ^ pixel_y[5]                         ?   `ON5    :
                                                                        `OFF5   ;

    assign LCD_G =  !LCD_DEN                                        ?   `OFF6   :
                    pixel_x[7:0] < box_x || pixel_y[7:0] < box_y    ?   `BG6    :
                    pixel_x[6] ^ pixel_y[6]                         ?   `ON6    :
                                                                        `OFF6   ;

    assign LCD_B =  !LCD_DEN                                        ?   `OFF5   :
                    pixel_x[7:0] < box_x || pixel_y[7:0] < box_y    ?   `BG5    :
                    pixel_x[7] ^ pixel_y[7]                         ?   `ON5    :
                                                                        `OFF5   ;

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
