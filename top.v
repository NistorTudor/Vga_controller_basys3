`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/27/2025 10:17:56 AM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module top(
    input        clk,
    input        reset,
    input        [11:0]sw,
    
    output wire  hsync,
    output wire  vsync,
    output wire  [3:0]  vgaRed,
    output wire  [3:0]  vgaGreen,
    output wire  [3:0]  vgaBlue
);

    wire [11:0] h_count_reg;
    wire [11:0] v_count_reg;
    wire        video_on;
    wire        clk_148Mhz;

    vga_controller vga_controller_i (
        .clk_148Mhz  (clk_148Mhz),
        .reset       (reset),
        .video_on    (video_on),
        .hsync       (hsync),
        .vsync       (vsync),
        .h_count_reg (h_count_reg),
        .v_count_reg (v_count_reg),
        .vgaBlue     (vgaBlue),
        .vgaGreen    (vgaGreen),
        .vgaRed      (vgaRed),
        .sw          (sw)
    );

    design_1_wrapper design_1_wrapper_i(
    .clk_in1_0  (clk),
    .clk_out1_0 (clk_148Mhz),
    .reset_0    (reset)
);



endmodule