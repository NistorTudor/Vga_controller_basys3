# VGA Controller Project

A comprehensive VGA controller implemented in Verilog HDL on the Basys 3 Digilent FPGA board for displaying dynamic graphics at Full HD resolution (1920x1080). The project utilizes a 148.5 MHz pixel clock frequency to meet the strict timing requirements of Full HD video output.

The design approach involved creating modular components: a timing generator for VGA sync signals, a graphics renderer for pixel data management, and a physics engine for object movement and collision detection. Multiple animated objects move across the screen with independent velocity vectors, while a real-time collision detection algorithm monitors interactions between objects. When collisions occur, objects exhibit realistic bouncing behavior and visual feedback through color changes.

The development process required careful consideration of FPGA resource utilization, timing constraints, and memory management to achieve smooth 60Hz refresh rates. This project demonstrates practical implementation of digital design concepts including state machines, clock domain management, and real-time graphics processing on reconfigurable hardware.
