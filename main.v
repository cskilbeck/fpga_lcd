module main
(
    input           BTN_RESET,
    input           BTN_USER,
    input           XTAL_IN,

    output          LCD_CLK,
    output          LCD_HSYNC,
    output          LCD_VSYNC,
    output          LCD_DEN,

    output  wire [4:0]   LCD_R,
    output  wire [5:0]   LCD_G,
    output  wire [4:0]   LCD_B,

    output  logic [5:0]   LED
);

    //////////////////////////////////////////////////////////////////////
    // PLL (GW1NR-9C C6/I5 -Tang Nano 9K proto dev board)

    wire CLK_SYS;
    wire CLK_LOCK;

    rPLL #  (
            .FCLKIN("27"),
            .IDIV_SEL(0),       // -> PFD = 27 MHz (range: 3-400 MHz)
            .FBDIV_SEL(9),      // -> CLKOUT = 270 MHz (range: 3.125-600 MHz)
            .DYN_SDIV_SEL(30),
            .ODIV_SEL(2)        // -> VCO = 540 MHz (range: 400-1200 MHz)
            )
            pll
            (
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
            .CLKIN(XTAL_IN),        // 27 MHz
            .CLKOUT(CLK_SYS),       // 270 MHz
            .CLKOUTD(LCD_CLK),      // 9 MHz
            .LOCK(CLK_LOCK)
            );

    logic [15:0] pixel_color = 16'hf00f;

    logic [9:0] pixel_x;
    logic [9:0] pixel_y;

    lcd_driver lcd( .VGA_CLK(LCD_CLK),
                    .RESETn(BTN_RESET),
                    .HSYNC(LCD_HSYNC),
                    .VSYNC(LCD_VSYNC),
                    .DEN(LCD_DEN),
                    .XPOS(pixel_x),
                    .YPOS(pixel_y)
                    );

    //////////////////////////////////////////////////////////////////////
    // DRAW

    always @(posedge LCD_CLK) begin
        if(BTN_USER) begin
            pixel_color <= pixel_x >= 100 && pixel_x < 200 && pixel_y >= 100 && pixel_y < 200 ? 16'b1111111111111111 : 16'b0;
        end
        else begin
            pixel_color <= pixel_x >= 0 && pixel_x < 100 && pixel_y >= 0 && pixel_y < 100 ? 16'b1111100000011111 : 16'b0;
        end
    end

    assign LCD_R = LCD_DEN ? pixel_color[15:11] : 5'b0;
    assign LCD_G = LCD_DEN ? pixel_color[10:5] : 6'b0;
    assign LCD_B = LCD_DEN ? pixel_color[4:0] : 5'b0;

    //////////////////////////////////////////////////////////////////////
    // LED

    logic [31:0] counter;

    always @(posedge XTAL_IN or negedge BTN_RESET) begin
       if (!BTN_RESET)
           counter <= 32'd0;
       else if (counter < 32'd6_750_000)
           counter <= counter + 1;
       else
           counter <= 32'd0;
    end

    always @(posedge XTAL_IN or negedge BTN_RESET) begin
       if (!BTN_RESET)
           LED <= 6'b111110;
       else if (counter == 32'd6_750_000)
           LED[5:0] <= {LED[0],LED[5:1]};
       else
           LED <= LED;
    end

endmodule
