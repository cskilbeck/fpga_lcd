module counter
(
    input XTAL_IN,
    output [5:0] LED
);

    localparam WAIT_TIME = 13500000;
    reg [5:0] ledCounter = 0;
    reg [23:0] clockCounter = 0;

    always @(posedge out_clkoutd) begin
        clockCounter <= clockCounter + 1;
        if (clockCounter == WAIT_TIME) begin
            clockCounter <= 0;
            ledCounter <= ledCounter + 1;
        end
    end

    wire out_clk;
    wire out_clkoutd;
    wire clk_lock;

    assign LED = ~ledCounter;

    always @(negedge XTAL_IN) begin
        if(BTN_USER) begin
            pixel_color <= pixel_x >= 100 && pixel_x < 200 && pixel_y >= 100 && pixel_y < 200 ? 16'hf81f : 16'b0;
        end
        else begin
            pixel_color <= pixel_x >= 0 && pixel_x < 100 && pixel_y >= 0 && pixel_y < 100 ? 16'hffff : 16'b0;
        end
    end

endmodule
