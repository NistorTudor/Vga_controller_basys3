`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 07/27/2025 01:26:01 PM
// Design Name:
// Module Name: vga_controller
// Project Name:
// Target Devices:
// Tool Versions:
// Description: VGA controller module generating sync signals, pixel coordinates,
//              and color data based on user inputs and patterns.
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module vga_controller(
    input clk_148MHz,
    input reset,     
    input [11:0] sw,  
    input btnU,       
    input btnD,       
    input btnR,     
    input btnL,       

    output hsync,     
    output vsync,    
    output video_on,  
    output reg [11:0] h_count_reg, // Horizontal pixel counter (current pixel X-coordinate)
    output reg [11:0] v_count_reg, // Vertical line counter (current pixel Y-coordinate)
    output reg [3:0] vgaRed,      
    output reg [3:0] vgaGreen,    
    output reg [3:0] vgaBlue      
);

    // --- VGA Timing Parameters (for 1920x1080 @ 60Hz) ---
    parameter HD       = 1920; // Horizontal Display (Active Pixels)
    parameter HF       = 88;   // Horizontal Front Porch
    parameter HR       = 44;   // Horizontal Sync Pulse
    parameter HB       = 148;  // Horizontal Back Porch
    parameter HMAX     = HD+HF+HB+HR; // Total Horizontal Pixels (Horizontal Line Length)

    parameter VD       = 1080; // Vertical Display (Active Lines)
    parameter VF       = 4;    // Vertical Front Porch
    parameter VR       = 5;    // Vertical Sync Pulse
    parameter VB       = 36;   // Vertical Back Porch
    parameter VMAX     = VD+VF+VB+VR; // Total Vertical Lines (Frame Height)

    // --- Drawing Parameters ---
    parameter R                  = 100; // Radius of the circle
    parameter R_SQ               = R*R; // Radius squared for circle drawing optimization (calculated parameter)
    parameter CIRC_WIDTH         = 2 * R; // Diameter of the circle (calculated parameter)
    parameter ONE_THIRD_CIRC_WIDTH = CIRC_WIDTH / 3; // For tri-color circle segments (calculated parameter)
    parameter TWO_THIRDS_CIRC_WIDTH = ONE_THIRD_CIRC_WIDTH * 2; // (calculated parameter)

    parameter BUTTON_MOVE_INTERVAL = 300000; // Debounce/speed interval for button-controlled movement

    // Square drawing parameters
    parameter SQUARE_X_START = 1400;
    parameter SQUARE_Y_START = 0;
    parameter SQUARE_LENGTH  = 200; // Width of the square (horizontal)
    parameter SQUARE_WIDTH   = 1080; // Height of the square (vertical, covers full screen height in this case)
    parameter SQUARE_X_END   = SQUARE_X_START + SQUARE_LENGTH; // (calculated parameter)
    parameter SQUARE_Y_END   = SQUARE_Y_START + SQUARE_WIDTH; // (calculated parameter)


    // --- Internal Registers and Wires ---
    reg [25:0] button_move_counter = 0; // Counter for button movement speed control
    reg [11:0] circ_center_h = HD / 2; // Horizontal center coordinate of the circle
    reg [11:0] circ_center_v = VD / 2; // Vertical center coordinate of the circle

    // Wires for collision detection and circle reset
    wire reset_circ_collision;       // Flag: true if circle collides with boundaries or square
    wire [11:0] circ_center_h_reset_val; // Horizontal reset position for circle
    wire [11:0] circ_center_v_reset_val; // Vertical reset position for circle

    // Wires for circle drawing calculations
    wire signed [12:0] dx_circ       = h_count_reg - circ_center_h; // Horizontal distance from circle center
    wire signed [12:0] dy_circ       = v_count_reg - circ_center_v; // Vertical distance from circle center
    wire [21:0] dist_sq_circ         = dx_circ*dx_circ + dy_circ*dy_circ; // Squared distance from circle center
    wire signed [12:0] relative_h    = h_count_reg - (circ_center_h - R); // Relative horizontal position within circle's diameter


    // --- Horizontal Counter Logic ---
    // Increments horizontal pixel counter, resets at HMAX
    always @(posedge clk_148MHz or posedge reset) begin
        if(reset)
            h_count_reg <= 0;
        else if(h_count_reg == HMAX)
            h_count_reg <= 0;
        else
            h_count_reg <= h_count_reg + 1;
    end

    // --- Vertical Counter Logic ---
    // Increments vertical line counter when horizontal counter resets, resets at VMAX
    always @(posedge clk_148MHz or posedge reset) begin
        if(reset)
            v_count_reg <= 0;
        else if (h_count_reg == HMAX) begin // Increment vertical counter at the end of each horizontal line
            if(v_count_reg == VMAX)
                v_count_reg <= 0;
            else
                v_count_reg <= v_count_reg + 1;
        end
    end

    // --- Button Movement Counter Logic ---
    // Controls speed of circle movement (debounces button presses)
    always @(posedge clk_148MHz or posedge reset) begin
        if (reset) begin
            button_move_counter <= 0;
        end else if (sw[2]) begin // Only active when sw[2] is on (circle pattern selected)
            if (button_move_counter >= BUTTON_MOVE_INTERVAL) begin
                button_move_counter <= 0; // Reset counter after interval
            end else begin
                button_move_counter <= button_move_counter + 1; // Increment counter
            end
        end
    end

    // --- Horizontal Circle Center Movement Logic ---
    // Updates horizontal center of circle based on button presses (L/R) and collision
    always @(posedge clk_148MHz or posedge reset) begin
        if (reset) begin
            circ_center_h <= HD/2; // Reset circle horizontal center
        end else if (sw[2]) begin // Only active when sw[2] is on
            if (reset_circ_collision) begin // If collision detected, reset position
                circ_center_h <= circ_center_h_reset_val;
            end else if (button_move_counter >= BUTTON_MOVE_INTERVAL) begin // Move only after interval
                if (btnL && circ_center_h > R) // Move left, with boundary check
                    circ_center_h <= circ_center_h - 1;
                else if (btnR && circ_center_h < (HD - R)) // Move right, with boundary check
                    circ_center_h <= circ_center_h + 1;
                // else circ_center_h remains unchanged
            end
        end
    end

    // --- Vertical Circle Center Movement Logic ---
    // Updates vertical center of circle based on button presses (U/D) and collision
    always @(posedge clk_148MHz or posedge reset) begin
        if (reset) begin
            circ_center_v <= VD/2; // Reset circle vertical center
        end else if (sw[2]) begin // Only active when sw[2] is on
            if (reset_circ_collision) begin // If collision detected, reset position
                circ_center_v <= circ_center_v_reset_val;
            end else if (button_move_counter >= BUTTON_MOVE_INTERVAL) begin // Move only after interval
                if (btnU && circ_center_v > R) // Move up, with boundary check
                    circ_center_v <= circ_center_v - 1;
                else if (btnD && circ_center_v < (VD - R)) // Move down, with boundary check
                    circ_center_v <= circ_center_v + 1;
                // else circ_center_v remains unchanged
            end
        end
    end

    // --- VGA Color Generation Logic ---
    // Determines pixel color based on video_on status and selected pattern (switches)
    always @(posedge clk_148MHz or posedge reset) begin
        if(reset) begin
            vgaRed   <= 4'b0000;
            vgaGreen <= 4'b0000;
            vgaBlue  <= 4'b0000;
        end else begin
            if(video_on) begin // Only draw within the active display area
                if(sw[0]) begin // Pattern 1: Horizontal color bands
                    if(h_count_reg < HD/3) begin
                        vgaRed   <= 4'b0000;
                        vgaGreen <= 4'b0000;
                        vgaBlue  <= 4'b1111; // Blue band
                    end else if (h_count_reg < (HD*2)/3) begin
                        vgaRed   <= 4'b1111;
                        vgaGreen <= 4'b1100;
                        vgaBlue  <= 4'b0000; // Yellowish-orange band
                    end else begin
                        vgaRed   <= 4'b1111;
                        vgaGreen <= 4'b0000;
                        vgaBlue  <= 4'b0000; // Red band
                    end
                end else if(sw[1]) begin // Pattern 2: Vertical color bands
                    if(v_count_reg < VD/3) begin
                        vgaRed   <= 4'b0000;
                        vgaGreen <= 4'b0000;
                        vgaBlue  <= 4'b0000; // Black band
                    end else if (v_count_reg < (VD*2)/3) begin
                        vgaRed   <= 4'b1111;
                        vgaGreen <= 4'b0000;
                        vgaBlue  <= 4'b0000; // Red band
                    end else begin
                        vgaRed   <= 4'b1111;
                        vgaGreen <= 4'b1100;
                        vgaBlue  <= 4'b0000; // Yellowish-orange band
                    end
                end else if(sw[2]) begin // Pattern 3: Circle with three segments or square + white background
                    if(dist_sq_circ <= R_SQ) begin // If pixel is inside the circle
                        if(relative_h < ONE_THIRD_CIRC_WIDTH) begin
                            vgaRed   <= 4'b0000;
                            vgaGreen <= 4'b0000;
                            vgaBlue  <= 4'b1111; // Blue segment
                        end else if (relative_h < TWO_THIRDS_CIRC_WIDTH) begin
                            vgaRed   <= 4'b1111;
                            vgaGreen <= 4'b1100;
                            vgaBlue  <= 4'b0000; // Yellowish-orange segment
                        end else begin
                            vgaRed   <= 4'b1111;
                            vgaGreen <= 4'b0000;
                            vgaBlue  <= 4'b0000; // Red segment
                        end
                    end else if(h_count_reg >= SQUARE_X_START && h_count_reg <= SQUARE_X_END &&
                                 ( (v_count_reg >= SQUARE_Y_START && v_count_reg <= 600) ||
                                   (v_count_reg >= 850 && v_count_reg <= SQUARE_Y_END) )
                                ) begin // If pixel is inside the square bars
                        vgaRed   <= 4'b0110;
                        vgaGreen <= 4'b1000;
                        vgaBlue  <= 4'b1101; // Specific color for the square bars
                    end else begin
                        vgaRed   <= 4'b1111;
                        vgaGreen <= 4'b1111;
                        vgaBlue  <= 4'b1111; // White background
                    end
                end else begin // Default pattern: Solid color when no switch is active
                    vgaRed   <= 4'b1111;
                    vgaGreen <= 4'b0011;
                    vgaBlue  <= 4'b1100; // Purple/Rosy-Magenta color (as per your last request)
                end
            end else begin // Outside active display area, always black
                vgaRed   <= 4'b0000;
                vgaGreen <= 4'b0000;
                vgaBlue  <= 4'b0000;
            end
        end
    end

    // --- Combinational Assignments for VGA Sync and Video_on ---
    // Generates hsync pulse when h_count_reg is within HR range
    assign hsync      = (h_count_reg >= (HD+HF) && h_count_reg <= (HD+HF+HR));

    // Generates vsync pulse when v_count_reg is within VR range
    assign vsync      = (v_count_reg >= (VD+VF) && v_count_reg <= (VD+VF+VR));

    // video_on is high when h_count_reg and v_count_reg are within active display area
    assign video_on   = (h_count_reg < HD) && (v_count_reg < VD);

    // --- Combinational Assignments for Circle Collision and Reset Values ---
    // Calculates if circle collides with screen boundaries or the fixed square
    assign reset_circ_collision = ( (circ_center_h + R >= SQUARE_X_START && circ_center_h - R <= SQUARE_X_END &&
                                     ( (circ_center_v + R >= SQUARE_Y_START && circ_center_v - R <= 600) ||
                                       (circ_center_v + R >= 850 && circ_center_v - R <= SQUARE_Y_END) ) ) ||
                                   (circ_center_h - R <= 0) ||   // Left boundary
                                   (circ_center_h + R >= HD) ||  // Right boundary
                                   (circ_center_v - R <= 0) ||   // Top boundary
                                   (circ_center_v + R >= VD) );  // Bottom boundary

    // Defines the reset position for the circle (center of screen)
    assign circ_center_h_reset_val = HD/2;
    assign circ_center_v_reset_val = VD/2;

endmodule