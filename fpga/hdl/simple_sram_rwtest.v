/* 
ChipWhisperer Bergen Target - simple SRAM R/W test

Copyright (c) 2020, NewAE Technology Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted without restriction. Note that modules within
the project may have additional restrictions, please carefully inspect
additional licenses.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of NewAE Technology Inc.
*/

`timescale 1ns / 1ps
`default_nettype none 


module simple_sram_rwtest #(
   parameter pDATA_WIDTH = 8,
   parameter pADDR_WIDTH = 20
)(
   input wire                           clk,
   input wire                           reset,
   input wire                           active,
   output reg                           pass,
   output reg                           fail,
   output reg [31:0]                    test_runs,
   input wire [7:0]                     I_top_address,
   input wire [7:0]                     write_wait1,
   input wire [7:0]                     write_wait2,
   input wire [7:0]                     read_wait,

   output reg                           wen,
   output wire                          ubn,
   output wire                          lbn,
   output reg                           oen,
   output reg                           cen,
   output reg  [pADDR_WIDTH-1:0]        addr,
   inout  wire [pDATA_WIDTH-1:0]        data
);


reg [pDATA_WIDTH-1:0] data_read_from_memory = 0;

localparam pS_IDLE         = 3'd0;
localparam pS_WRITE        = 3'd1;
localparam pS_WRITE_NEXT   = 3'd2;
localparam pS_READ         = 3'd3;
localparam pS_READ_NEXT    = 3'd4;
reg [2:0] state = pS_IDLE;


reg isout;
wire [pDATA_WIDTH-1:0] wdata;
wire [pDATA_WIDTH-1:0] expected;
reg [3:0] count;
reg restart_count;

wire [31:0] lfsr_data;
reg lfsr_load;
reg lfsr_next;
reg [31:0] lfsr_seed;

wire state_write = state == pS_WRITE || state == pS_WRITE_NEXT;
wire state_read = state == pS_READ || state == pS_READ_NEXT;
wire [pADDR_WIDTH-1:0] top_address = (I_top_address)? I_top_address : {pADDR_WIDTH{1'b1}};

assign data = (isout)? wdata : {pDATA_WIDTH{1'bz}};
assign wdata = lfsr_data[pDATA_WIDTH-1:0];
assign expected = lfsr_data[pDATA_WIDTH-1:0];

assign ubn = 1'b0;//wen;
assign lbn = 1'b0;//wen;

always @ (posedge clk) begin
   if (reset)
      count <= 0;
   else if (restart_count)
      count <= 0;
   else 
      count <= count + 1;
end


always @ (posedge clk) begin
   if (reset) begin
      state <= pS_IDLE;
      pass <= 0;
      fail <= 0;
      restart_count <= 0;
      lfsr_load <= 0;
      lfsr_next <= 0;
      lfsr_seed <= 1;
      test_runs <= 0;
   end 
   else begin
      restart_count <= 0;
      lfsr_load <= 0;
      lfsr_next <= 0;

      case (state)
         pS_IDLE: begin
            addr <= 0;
            wen <= 1;
            oen <= 1;
            isout <= 0;     
            if (active) begin
               wen <= 0;
               restart_count <= 1;
               lfsr_load <= 1;
               state <= pS_WRITE;
               cen <= 0;
            end
            else begin
               fail <= 0;
               pass <= 0;
               cen <= 1;
            end
         end

         pS_WRITE: begin
            cen <= 0;
            oen <= 1;
            if (~active)
               state <= pS_IDLE;
            else begin
               if (count == 1) begin
                  isout <= 1'b1;
               end
               //else if (count == 4) begin
               //else if (count == 8) begin // TODO ???
               else if (count == write_wait1) begin
                  restart_count <= 1;
                  cen <= 1'b1;
                  lfsr_next <= 1'b1;
                  state <= pS_WRITE_NEXT;
               end
            end
         end

         pS_WRITE_NEXT: begin
            cen <= 1;
            oen <= 1;
            isout <= 1'b0;
            if (addr == top_address) begin
               wen <= 1;
               //if (count == 2) begin
               if (count == write_wait2) begin
                  restart_count <= 1;
                  lfsr_load <= 1;
                  addr <= 0;
                  oen <= 0;
                  state <= pS_READ;
               end
            end
            else begin
               /* TODO ???
               addr <= addr + 1;
               state <= pS_WRITE;
               */
               //if (count == 4) begin
               if (count == write_wait2) begin
                   restart_count <= 1'b1;
                   addr <= addr + 1;
                   state <= pS_WRITE;
               end
            end
         end

         pS_READ: begin
            cen <= 0;
            oen <= 0;
            if (~active)
               state <= pS_IDLE;
            else begin
               //if (count == 4) begin
               //if (count == 8) begin // TODO ???
               if (count == read_wait) begin
                  restart_count <= 1;
                  state <= pS_READ_NEXT;
               end
            end
         end

         pS_READ_NEXT: begin
            cen <= 0;
            oen <= 0;
            addr <= addr + 1;
            if (data != expected) begin
               fail <= 1;
               pass <= 0;
            end
            else
               pass <= 1;
            if (addr == top_address) begin
               lfsr_seed <= lfsr_seed + 1;
               test_runs <= test_runs + 1;
               state <= pS_IDLE; // easiest way to restart
            end
            else begin
               state <= pS_READ;
               lfsr_next <= 1'b1;
            end
         end

         default: state <= pS_IDLE;
  
      endcase
   end
end

lfsr U_lfsr (
   .clk             (clk),
   .rst             (reset),
   .I_seed_data     (lfsr_seed),
   .I_lfsr_reset    (1'b0),
   .I_lfsr_load     (lfsr_load),
   .I_noise_valid   (2'b0),
   .I_noise_period  (8'b0),
   .I_next          (lfsr_next),   
   .out             (),
   .out_valid       (),
   .O_state         (lfsr_data)
);

   
   `ifdef ILA_SRAM
       ila_sram_test U_ila_sram (
	    .clk            (clk),                          // input wire clk
	    .probe0         (active),                       // 
	    .probe1         (pass),                         // 
	    .probe2         (fail),                         // 
	    .probe3         (wen),                          // 
	    .probe4         (oen),                          // 
	    .probe5         (cen),                          // 
	    .probe6         (ubn),                          // 
	    .probe7         (lbn),                          // 
	    .probe8         (addr),                         // 18:0
	    .probe9         (data),                         // 15:0
	    .probe10        (test_runs),                    // 15:0
	    .probe11        (isout),                        //
	    .probe12        (expected)                      // 15:0
       );
   `endif


endmodule

`default_nettype wire

