`timescale 1 ns / 1 ps
`default_nettype none

/***********************************************************************
This file is part of the ChipWhisperer Project. See www.newae.com for more
details, or the codebase at http://www.chipwhisperer.com

Copyright (c) 2023, NewAE Technology Inc. All rights reserved.
Author: Jean-Pierre Thibault <jpthibault@newae.com>

  chipwhisperer is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  chipwhisperer is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with chipwhisperer.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************/

module hr_model (
    input wire                          reset,
    input wire                          clk,

    // register interface:
    input  wire                         lb_wr,
    input  wire                         lb_rd,
    input  wire [31:0]                  lb_addr,
    input  wire [31:0]                  lb_wr_d,
    output reg  [31:0]                  lb_rd_d,
    output reg                          lb_rd_rdy,
    output reg                          hyperram_busy
);

reg [31:0] memory [0:1023];
reg [31:0] read_data;
reg [31:0] mem_addr;
reg [31:0] mem_wdata;
reg hr_busy_start;
reg reading;

always @(posedge clk) begin
    if (reset) begin
        hr_busy_start <= 1'b1;
        reading <= 1'b0;
    end

    else begin
        if (lb_wr) begin
            if ((lb_addr == 32'h1c) && (lb_wr_d == 32'h01)) begin
                memory[mem_addr] <= mem_wdata;
                $display("%0t Writing %0h to %0h", $time, mem_wdata, mem_addr);
                hr_busy_start <= 1'b1;
                reading <= 1'b0;
            end
            else if ((lb_addr == 32'h1c) && (lb_wr_d == 32'h04)) begin
                read_data <= memory[mem_addr];
                $display("%0t Reading %0h from %0h", $time, memory[mem_addr], mem_addr);
                hr_busy_start <= 1'b1;
                reading <= 1'b1;
            end
            else if (lb_addr == 32'h10) begin
                hr_busy_start <= 1'b0;
                mem_addr <= lb_wr_d;
            end
            else if (lb_addr == 32'h14) begin
                hr_busy_start <= 1'b0;
                mem_wdata <= lb_wr_d;
            end
        end
        else if (lb_rd) begin
            hr_busy_start <= 1'b1;
            reading <= 1'b1;
        end
        else
            hr_busy_start <= 1'b0;
    end

end

initial begin
    lb_rd_rdy = 0;
    while (1) begin
        wait(hr_busy_start);
        hyperram_busy = 1'b1;
        repeat ($urandom_range(2,10)) @(posedge clk);
        //repeat (2) @(posedge clk);
        hyperram_busy = 1'b0;
        if (reading) begin
            lb_rd_rdy = 1'b1;
            lb_rd_d = read_data;
            repeat (2) @(posedge clk);
            lb_rd_rdy = 1'b0;
        end
        @(posedge clk);
    end
end


endmodule
`default_nettype wire

