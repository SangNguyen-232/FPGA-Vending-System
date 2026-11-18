`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2024 11:13:52 AM
// Design Name: 
// Module Name: button_debounce
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


module button_debounce(
    input clk,
    input rst,
    input button_in,
    output reg button_flag
);
    reg [1:0] sync;          // Two-stage button synchronizer
    reg stable_state;        // Last accepted button state
    reg [19:0] counter;      // Debounce counter
    
    localparam DEBOUNCE_TIME = 20'd1250000; // Intended as 10 ms at 125 MHz; this 20-bit literal truncates to 201424

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync <= 2'b11;
            stable_state <= 1'b1;
            button_flag <= 1'b0;
            counter <= 20'd0;
        end else begin
            // Synchronize the button input
            sync[1] <= sync[0];
            sync[0] <= button_in;

            // Accept a stable transition after the debounce interval
            if (sync[0] == sync[1]) begin
                if (sync[0] != stable_state) begin
                    if (counter == DEBOUNCE_TIME) begin
                        stable_state <= sync[0];
                        if (stable_state == 1'b0) begin
                            button_flag <= 1'b1;
                        end
                    end else begin
                        counter <= counter + 1;
                    end
                end else begin
                    counter <= 0;
                    button_flag <= 1'b0;
                end
            end else begin
                counter <= 0;
            end
        end
    end
endmodule


