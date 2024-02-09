module vga_driver (
    input wire clock,
    input wire reset_n,
    input [15:0] pixel_color,
    output hsync,
    output vsync,
    output [4:0] red,
    output [5:0] green,
    output [4:0] blue,
    output display_enable,
    output [9:0] pixel_x,
    output [9:0] pixel_y
);

    parameter [9:0] H_VISIBLE =  10'd479;
    parameter [9:0] H_FRONT   =  10'd2;
    parameter [9:0] H_PULSE   =  10'd21;
    parameter [9:0] H_BACK    =  10'd22;

    parameter [9:0] V_VISIBLE  =  10'd271;
    parameter [9:0] V_FRONT    =  10'd7;
    parameter [9:0] V_PULSE    =  10'd2;
    parameter [9:0] V_BACK     =  10'd7;

    parameter   LOW     = 1'b0;
    parameter   HIGH    = 1'b1;

    parameter   OFF_5 = 5'b0;
    parameter   OFF_6 = 6'b0;

    parameter   ON_5 = 5'b11111;
    parameter   ON_6 = 6'b111111;

    parameter   [1:0]   STATE_VISIBLE       = 2'd0;
    parameter   [1:0]   STATE_FRONT_PORCH   = 2'd1;
    parameter   [1:0]   STATE_PULSE         = 2'd2;
    parameter   [1:0]   STATE_BACK_PORCH    = 2'd3;

    reg              hysnc_reg;
    reg              vsync_reg;

    reg             display_enable_reg;

    reg     [4:0]    red_reg;
    reg     [5:0]    green_reg;
    reg     [4:0]    blue_reg;

    reg              end_of_line;

    reg     [9:0]    horiz_counter;
    reg     [9:0]    vert_counter;

    reg     [1:0]    horiz_state;
    reg     [1:0]    vert_state;

    reg     [9:0]    pixel_x_reg;
    reg     [9:0]    pixel_y_reg;

    always@(posedge clock) begin

        if (!reset_n) begin
            horiz_counter <= 9'd0;
            vert_counter <= 9'd0;
            horiz_state <= STATE_VISIBLE;
            vert_state <= STATE_VISIBLE;
            end_of_line <= LOW;
        end
        else begin
            case (horiz_state)
                STATE_VISIBLE: begin
                    if(horiz_counter == H_VISIBLE) begin
                        horiz_counter <= 9'd0;
                        horiz_state <= STATE_FRONT_PORCH;
                    end
                    else begin
                        horiz_counter <= horiz_counter + 1'd1;
                    end
                    hysnc_reg <= HIGH;
                    end_of_line <= LOW;
                    pixel_x_reg <= horiz_counter;
                end
                STATE_FRONT_PORCH: begin
                    if(horiz_counter == H_FRONT) begin
                        horiz_counter <= 9'd0;
                        horiz_state <= STATE_PULSE;
                    end
                    else begin
                        horiz_counter <= horiz_counter + 1'd1;
                    end
                    hysnc_reg <= HIGH;
                end
                STATE_PULSE: begin
                    if(horiz_counter == H_PULSE) begin
                        horiz_counter <= 9'd0;
                        horiz_state <= STATE_BACK_PORCH;
                    end
                    else begin
                        horiz_counter <= horiz_counter + 1'd1;
                    end
                    hysnc_reg <= LOW;
                end
                STATE_BACK_PORCH: begin
                    if(horiz_counter == (H_BACK - 1)) begin
                        end_of_line <= HIGH;
                    end
                    else begin
                        end_of_line <=  LOW;
                        if(horiz_counter == H_BACK) begin
                            horiz_counter <= 9'd0;
                            horiz_state <= STATE_VISIBLE;
                        end
                        else begin
                            horiz_counter <= horiz_counter + 1'd1;
                            horiz_state <= STATE_BACK_PORCH;
                        end
                        hysnc_reg <= HIGH;
                    end
                end
            endcase

            case(vert_state)
                STATE_VISIBLE: begin
                    vert_counter <= (end_of_line) ? ((vert_counter == V_VISIBLE) ? 9'd0 : (vert_counter+1'd1)) : vert_counter;
                    vsync_reg <= HIGH;
                    vert_state   <= (end_of_line) ? ((vert_counter == V_VISIBLE) ? STATE_FRONT_PORCH : STATE_VISIBLE) : STATE_VISIBLE;
                    pixel_y_reg <= vert_counter;
                    if(horiz_state == STATE_VISIBLE) begin  
                        display_enable_reg <= 1'b1;
                    end
                end
                STATE_FRONT_PORCH: begin
                    vert_counter <= (end_of_line) ? ((vert_counter == V_FRONT) ? 9'd0 : (vert_counter + 1'd1)) : vert_counter;
                    vsync_reg <= HIGH;
                    vert_state   <= (end_of_line) ? ((vert_counter == V_FRONT) ? STATE_PULSE : STATE_FRONT_PORCH) : STATE_FRONT_PORCH;
                    display_enable_reg <= 1'b0;
                end
                STATE_PULSE: begin
                    vert_counter <= (end_of_line) ? ((vert_counter == V_PULSE) ? 9'd0 : (vert_counter + 1'd1)) : vert_counter;
                    vsync_reg <= LOW;
                    vert_state   <= (end_of_line) ? ((vert_counter == V_PULSE) ? STATE_BACK_PORCH : STATE_PULSE) : STATE_PULSE;
                end
                STATE_BACK_PORCH: begin
                    vert_counter <= (end_of_line) ? ((vert_counter == V_BACK) ? 9'd0 : (vert_counter + 1'd1)) : vert_counter;
                    vsync_reg <= HIGH;
                    vert_state   <= (end_of_line) ? ((vert_counter == V_BACK) ? STATE_VISIBLE : STATE_BACK_PORCH) : STATE_BACK_PORCH;
                end
            endcase

            if(horiz_state == STATE_VISIBLE && vert_state == STATE_VISIBLE) begin
                red_reg    <= {pixel_color[15:11]};
                green_reg  <= {pixel_color[10:5] };
                blue_reg   <= {pixel_color[4:0]  };
            end
            else begin
                red_reg    <= OFF_5;
                green_reg  <= OFF_6;
                blue_reg   <= OFF_5;
            end
        end
    end

    assign hsync = hysnc_reg;
    assign vsync = vsync_reg;
    assign red = red_reg;
    assign green = green_reg;
    assign blue = blue_reg;
    assign display_enable = display_enable_reg;
    assign pixel_x = pixel_x_reg;
    assign pixel_y = pixel_y_reg;

endmodule
