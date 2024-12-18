`include "cw341_defines.v"
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

module sysmon #(
   parameter pBYTECNT_SIZE = 7
)(
   input  wire                                  reset_i,
   input  wire                                  clk_usb,
   input  wire [7:0]                            reg_address,  // Address of register
   input  wire [pBYTECNT_SIZE-1:0]              reg_bytecnt,  // Current byte count
   input  wire [7:0]                            reg_datai,    // Data to write
   output wire [7:0]                            reg_datao,    // Data to read
   input  wire                                  reg_read,     // Read flag
   input  wire                                  reg_write,    // Write flag

   input  wire                                  vauxp0,
   input  wire                                  vauxn0,
   input  wire                                  vauxp1,
   input  wire                                  vauxn1,
   input  wire                                  vauxp8,
   input  wire                                  vauxn8,
   input  wire                                  vauxp12,
   input  wire                                  vauxn12,
   output wire                                  xadc_error

); 

   reg  [6:0]   drp_addr;
   reg          drp_den;
   reg  [15:0]  drp_din;
   reg          drp_dwe;
   wire [15:0]  drp_dout;
   reg  [15:0]  drp_dout_reg;
   wire         drp_drdy;

   wire user_temp_alarm_out;
   wire vccint_alarm_out;
   wire vccaux_alarm_out;
   wire ot_out;
   wire vbram_alarm_out;

// DRP usage:
// Writes: push write data to DRP data, then write DRP_ADDR with MSB set.
// Reads: write DRP_ADDR with MSB clear, then obtain read data from DRP_DATA.

   reg [7:0] reg_datao_reg;
   assign reg_datao = reg_datao_reg;

   wire [4:0] xadc_stat;
   reg  [4:0] xadc_stat_hold;
   
   assign xadc_stat[0] = ot_out;
   assign xadc_stat[1] = user_temp_alarm_out;
   assign xadc_stat[2] = vccint_alarm_out;
   assign xadc_stat[3] = vccaux_alarm_out;
   assign xadc_stat[4] = vbram_alarm_out;
   
   assign xadc_error = |xadc_stat;

   always @(*) begin
      if (reg_read) begin
         case (reg_address)
           `REG_XADC_DRP_ADDR: reg_datao_reg = {1'b0, drp_addr};
           `REG_XADC_DRP_DATA: reg_datao_reg = drp_dout_reg[reg_bytecnt*8 +: 8];
           `REG_XADC_STAT: reg_datao_reg = {3'b0, xadc_stat_hold};
           default: reg_datao_reg = 0;
         endcase
      end
      else
         reg_datao_reg = 0;
   end

   // alarms can be transient, so hold until cleared:
   always @(posedge clk_usb) begin
      if (reset_i)
         xadc_stat_hold <= 0;
      else begin
         if (reg_write && (reg_address == `REG_XADC_STAT))
            xadc_stat_hold <= 0;
         else begin
            if (xadc_stat[0]) xadc_stat_hold[0] <= 1'b1;
            if (xadc_stat[1]) xadc_stat_hold[1] <= 1'b1;
            if (xadc_stat[2]) xadc_stat_hold[2] <= 1'b1;
            if (xadc_stat[3]) xadc_stat_hold[3] <= 1'b1;
            if (xadc_stat[4]) xadc_stat_hold[4] <= 1'b1;
         end
      end
   end

   always @(posedge clk_usb) begin
      if (reset_i) begin
         drp_dwe <= 1'b0;
         drp_den <= 1'b0;
      end
      else begin
         if (reg_write) begin
            if (reg_address == `REG_XADC_DRP_ADDR) begin
               drp_addr <= reg_datai[6:0];
               drp_den <= 1'b1;
               // DRP write:
               if (reg_datai[7])
                  drp_dwe <= 1'b1;
               // DRP read:
               else
                  drp_dwe <= 1'b0;
            end

            else begin
               drp_dwe <= 1'b0;
               drp_den <= 1'b0;
               if (reg_address == `REG_XADC_DRP_DATA)
                  drp_din[reg_bytecnt*8 +: 8] <= reg_datai;
            end

         end

         else begin
            drp_dwe <= 1'b0;
            drp_den <= 1'b0;
         end

         // when AXI4-stream is enabled (e.g. required for MIG, DRP read data
         // is only valid on drp_drdy:
         if (drp_drdy)
            drp_dout_reg <= drp_dout;

      end
   end

   `ifdef ILA_XADC_DRP
        ila_drp U_ila_drp (
            .clk            (clk_usb),      // input wire clk
            .probe0         (drp_addr),     // input wire [6:0]  probe0  
            .probe1         (drp_den),      // input wire [7:0]  probe1 
            .probe2         (drp_din),      // input wire [15:0] probe2 
            .probe3         (drp_dout),     // input wire [15:0] probe3 
            .probe4         (drp_drdy),     // input wire [0:0]  probe4 
            .probe5         (drp_dwe),      // input wire [0:0]  probe5 
            .probe6         (user_temp_alarm_out),
            .probe7         (vccint_alarm_out),
            .probe8         (vccaux_alarm_out),
            .probe9         (ot_out),
            .probe10        (vbram_alarm_out)
        );
   `endif


   `ifndef __ICARUS__
        system_management_wiz_0 U_sysmom (
          .di_in                (drp_din),              // input wire [15 : 0] di_in
          .daddr_in             (drp_addr),             // input wire [6 : 0] daddr_in
          .den_in               (drp_den),              // input wire den_in
          .dwe_in               (drp_dwe),              // input wire dwe_in
          .drdy_out             (drp_drdy),             // output wire drdy_out
          .do_out               (drp_dout),             // output wire [15 : 0] do_out
          .vp                   (),                     // input wire vp_in
          .vn                   (),                     // input wire vn_in
          .vauxp0               (vauxp0),               // input wire vauxp0
          .vauxn0               (vauxn0),               // input wire vauxn0
          .vauxp1               (vauxp1),               // input wire vauxp1
          .vauxn1               (vauxn1),               // input wire vauxn1
          .vauxp8               (vauxp8),               // input wire vauxp8
          .vauxn8               (vauxn8),               // input wire vauxn8
          .vauxp12              (vauxp12),              // input wire vauxp12
          .vauxn12              (vauxn12),              // input wire vauxn12
          .user_temp_alarm_out  (user_temp_alarm_out),  // output wire user_temp_alarm_out
          .vccint_alarm_out     (vccint_alarm_out),     // output wire vccint_alarm_out
          .vccaux_alarm_out     (vccaux_alarm_out),     // output wire vccaux_alarm_out
          .ot_out               (ot_out),               // output wire ot_out
          .channel_out          (),                     // output wire [4 : 0] channel_out
          .eoc_out              (),                     // output wire eoc_out
          .vbram_alarm_out      (vbram_alarm_out),      // output wire vbram_alarm_out
          .alarm_out            (),                     // output wire alarm_out
          .eos_out              (),                     // output wire eos_out
          .busy_out             (),                     // output wire busy_out
          .dclk_in              (clk_usb)               // required if AXI4-stream interface is disabled
          // AXI4-stream interface is enabled because it is required for the temp_out output 
          // (which is required if MIG IP is instantiated); if not using IP which requires temp_out,
          // you can disable this: (don't forget to uncomment the dclk_in clock input)
          //.temp_out             (O_xadc_temp_out),      // output wire [11:0] temp_out
          //.m_axis_tvalid        (),                     // output wire m_axis_tvalid
          //.m_axis_tready        (1'b0),                 // input wire m_axis_tready
          //.m_axis_tdata         (),                     // output wire [15 : 0] m_axis_tdata
          //.m_axis_tid           (),                     // output wire [4 : 0] m_axis_tid
          //.m_axis_aclk          (clk_usb),              // input wire m_axis_aclk
          //.s_axis_aclk          (clk_usb),              // input wire s_axis_aclk
          //.m_axis_resetn        (~reset_i)              // input wire m_axis_resetn
        );

   `endif


endmodule
`default_nettype wire
