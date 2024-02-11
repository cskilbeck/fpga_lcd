`include "lcd_h.v"

`ifdef LCD_800_480

    `define H_SYNC_WIDTH 2
    `define H_BACK_PORCH 46
    `define H_DISPLAY 800
    `define H_FRONT_PORCH 210

    `define V_SYNC_WIDTH 5
    `define V_BACK_PORCH 23
    `define V_DISPLAY 480
    `define V_FRONT_PORCH 22

`elsif LCD_480_272

    `define H_SYNC_WIDTH 21
    `define H_BACK_PORCH 22
    `define H_DISPLAY 480
    `define H_FRONT_PORCH 1

    `define V_SYNC_WIDTH 1
    `define V_BACK_PORCH 6
    `define V_DISPLAY 272
    `define V_FRONT_PORCH 6

`else
!error! "`define LCD_480_272 OR LCD_800_480"
`endif

`define H_SYNC_TOTAL        `H_SYNC_WIDTH
`define H_BACK_PORCH_TOTAL  `H_SYNC_TOTAL + `H_BACK_PORCH
`define H_DISPLAY_TOTAL     `H_BACK_PORCH_TOTAL + `H_DISPLAY
`define H_FRONT_PORCH_TOTAL `H_DISPLAY_TOTAL + `H_FRONT_PORCH

`define V_SYNC_TOTAL        `V_SYNC_WIDTH
`define V_BACK_PORCH_TOTAL  `V_SYNC_TOTAL + `V_BACK_PORCH
`define V_DISPLAY_TOTAL     `V_BACK_PORCH_TOTAL + `V_DISPLAY
`define V_FRONT_PORCH_TOTAL `V_DISPLAY_TOTAL + `V_FRONT_PORCH

module lcd_driver(

    input wire PIXEL_CLK,
    input wire RESETn,
    output wire HSYNC,
    output wire VSYNC,
    output wire DEN,
    output wire [10:0] XPOS,
    output wire [10:0] YPOS
);

    parameter [10:0] HORIZ_SYNC_END        = 10'd `H_SYNC_TOTAL;
    parameter [10:0] HORIZ_BACK_PORCH_END  = 10'd `H_BACK_PORCH_TOTAL;
    parameter [10:0] HORIZ_DISPLAY_END     = 10'd `H_DISPLAY_TOTAL;
    parameter [10:0] HORIZ_FRONT_PORCH_END = 10'd `H_FRONT_PORCH_TOTAL;

    parameter [10:0] HORIZ_END_OF_LINE     = HORIZ_FRONT_PORCH_END - 10'd 1;

    parameter [10:0] VERT_SYNC_END         = 10'd `V_SYNC_TOTAL;
    parameter [10:0] VERT_BACK_PORCH_END   = 10'd `V_FRONT_PORCH_TOTAL;
    parameter [10:0] VERT_DISPLAY_END      = 10'd `V_DISPLAY_TOTAL;
    parameter [10:0] VERT_FRONT_PORCH_END  = 10'd `V_FRONT_PORCH_TOTAL;

    reg [10:0] h_counter;
    reg [10:0] v_counter;

    reg hsync;
    reg vsync;
    reg h_den;
    reg v_den;

    reg eol;
 
    always @(posedge PIXEL_CLK or negedge RESETn) begin
        if(!RESETn) begin
            hsync <= 1'b1;
            h_den <= 1'b0;
            eol <= 1'b0;
            h_counter <= 10'b0;
        end
        else begin
            if(h_counter == HORIZ_SYNC_END) begin
                hsync <= 1'b1;
            end
            if(h_counter == HORIZ_BACK_PORCH_END) begin
                h_den <= 1'b1;
            end
            if(h_counter == HORIZ_DISPLAY_END) begin
                h_den <= 1'b0;
            end
            if(h_counter == HORIZ_END_OF_LINE) begin
                eol <= 1'b1;
                h_den <= 1'b0;
            end
            if(h_counter == HORIZ_FRONT_PORCH_END) begin
                eol <= 1'b0;
                hsync <= 1'b0;
                h_counter <= 10'd0;
            end
            else begin
                h_counter <= h_counter + 10'b1;
            end
        end
    end

    always @(posedge PIXEL_CLK or negedge RESETn) begin
        if(!RESETn) begin
            vsync <= 1'b1;
            v_counter <= 10'b0;
            v_den <= 1'b0;
        end
        else if (eol) begin
            if(v_counter == VERT_SYNC_END) begin
                vsync <= 1'b1;
            end
            if(v_counter == VERT_BACK_PORCH_END) begin
                v_den <= 1'b1;
            end
            if(v_counter == VERT_DISPLAY_END) begin
                v_den <= 1'b0;
            end
            if(v_counter == VERT_FRONT_PORCH_END) begin
                v_counter <= 10'd0;
                vsync <= 1'b0;
            end
            else begin
                v_counter <= v_counter + 10'b1;
            end
        end
    end

    assign HSYNC = hsync;
    assign VSYNC = vsync;
    assign DEN = h_den && v_den;
    assign XPOS = DEN ? (h_counter - HORIZ_BACK_PORCH_END - 1) : 10'b0;
    assign YPOS = DEN ? (v_counter - VERT_BACK_PORCH_END - 1) : 10'b0;

endmodule
