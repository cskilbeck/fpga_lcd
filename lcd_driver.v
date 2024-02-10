`define H_PULSE_WIDTH 21
`define H_BACK_PORCH 22
`define H_DISPLAY 479
`define H_FRONT_PORCH 1

`define V_PULSE_WIDTH 1
`define V_BACK_PORCH 6
`define V_DISPLAY 271
`define V_FRONT_PORCH 6

module lcd_driver(

    input wire VGA_CLK,
    input wire RESETn,
    output wire HSYNC,
    output wire VSYNC,
    output wire DEN,
    output wire [9:0] XPOS,
    output wire [9:0] YPOS
);

    parameter [9:0] HORIZ_PULSE_WIDTH     = 9'd `H_PULSE_WIDTH;
    parameter [9:0] HORIZ_BACK_PORCH      = 9'd `H_PULSE_WIDTH + `H_BACK_PORCH;
    parameter [9:0] HORIZ_DISPLAY_ACTIVE  = 9'd `H_PULSE_WIDTH + `H_BACK_PORCH + `H_DISPLAY;
    parameter [9:0] HORIZ_END_OF_LINE     = 9'd `H_PULSE_WIDTH + `H_BACK_PORCH + `H_DISPLAY  + `H_FRONT_PORCH - 1;
    parameter [9:0] HORIZ_FRONT_PORCH     = 9'd `H_PULSE_WIDTH + `H_BACK_PORCH + `H_DISPLAY  + `H_FRONT_PORCH;

    parameter [9:0] VERT_PULSE_WIDTH      = 9'd `V_PULSE_WIDTH;
    parameter [9:0] VERT_BACK_PORCH       = 9'd `V_PULSE_WIDTH + `V_BACK_PORCH;
    parameter [9:0] VERT_DISPLAY_ACTIVE   = 9'd `V_PULSE_WIDTH + `V_BACK_PORCH + `V_DISPLAY;
    parameter [9:0] VERT_FRONT_PORCH      = 9'd `V_PULSE_WIDTH + `V_BACK_PORCH + `V_DISPLAY  + `V_FRONT_PORCH;

    reg [9:0] h_counter;
    reg [9:0] v_counter;

    reg hsync;
    reg vsync;
    reg h_den;
    reg v_den;

    reg eol;
 
    always @(posedge VGA_CLK or negedge RESETn) begin
        if(!RESETn) begin
            hsync <= 1'b1;
            h_den <= 1'b0;
            eol <= 1'b0;
            h_counter <= 9'b0;
        end
        else begin
            if(h_counter == HORIZ_PULSE_WIDTH) begin
                hsync <= 1'b1;
            end
            if(h_counter == HORIZ_BACK_PORCH) begin
                h_den <= 1'b1;
            end
            if(h_counter == HORIZ_DISPLAY_ACTIVE) begin
                h_den <= 1'b0;
            end
            if(h_counter == HORIZ_END_OF_LINE) begin
                eol <= 1'b1;
                h_den <= 1'b0;
            end
            if(h_counter == HORIZ_FRONT_PORCH) begin
                eol <= 1'b0;
                hsync <= 1'b0;
                h_counter <= 9'd0;
            end
            else begin
                h_counter <= h_counter + 9'b1;
            end
        end
    end

    always @(posedge VGA_CLK or negedge RESETn) begin
        if(!RESETn) begin
            vsync <= 1'b1;
            v_counter <= 9'b0;
            v_den <= 1'b0;
        end
        else if (eol) begin
            if(v_counter == VERT_PULSE_WIDTH) begin
                vsync <= 1'b1;
            end
            if(v_counter == VERT_BACK_PORCH) begin
                v_den <= 1'b1;
            end
            if(v_counter == VERT_DISPLAY_ACTIVE) begin
                v_den <= 1'b0;
            end
            if(v_counter == VERT_FRONT_PORCH) begin
                vsync <= 1'b0;
                v_counter <= 9'd0;
            end
            else begin
                v_counter <= v_counter + 9'b1;
            end
        end
    end

    assign HSYNC = hsync;
    assign VSYNC = vsync;
    assign DEN = h_den && v_den;
    assign XPOS = h_den ? (h_counter - HORIZ_BACK_PORCH) : 9'b0;
    assign YPOS = h_den ? (v_counter - VERT_BACK_PORCH) : 9'b0;

endmodule
