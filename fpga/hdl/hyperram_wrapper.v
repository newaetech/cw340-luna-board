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

Wrapper for hr_pll_example module.
Look there for full register definitions, but basically it works like this:
(reads and writes are on the lb1_* and lb2_* interfaces, "1" are for hyperram chip 1,
"2" for chip 2; that interface should be self-explanatory)

1. To configure the controller and the Hyperram:
    (a) write the control word to LB address 0x14,
    (b) write 0x05 to LB address 0x1c

2. To write:
    (a) write the hyperram address to LB address 0x10
    (b) write 32 bits data to LB address 0x14
    (c) (optionally) write the next 32 bits data to LB address 0x18
    (d) write 0x03 (to write 64 bits) or 0x01 (to write 32 bits) to LB address 0x1c

3. To read:
    (a) write the hyperram address to LB address 0x10
    (b) write 0x04 to LB address 0x1c
    (c) obtain the first 32 bits read data by reading LB address 0x14
    (d) (optionally) obtain the next 32 bits data by reading LB address 0x18

IMPORTANT NOTE: the hyperram_busy status signals have some lag (after
dispatching a job to hr_pll_example, it takes a few cycles for busy to
assert).

*************************************************************************/

module hyperram_wrapper (
    input wire                          hreset,
    input wire                          hclk,

    // status/debug:
    output wire                         error,
    output wire                         clk_90p_locked,

    // register interface:
    input  wire                         lb1_wr,
    input  wire                         lb1_rd,
    input  wire [31:0]                  lb1_addr,
    input  wire [31:0]                  lb1_wr_d,
    output wire [31:0]                  lb1_rd_d,
    output wire                         lb1_rd_rdy,

    input  wire                         lb2_wr,
    input  wire                         lb2_rd,
    input  wire [31:0]                  lb2_addr,
    input  wire [31:0]                  lb2_wr_d,
    output wire [31:0]                  lb2_rd_d,
    output wire                         lb2_rd_rdy,

    // Hyperram:
    inout  wire [7:0]                   hypr1_dq,
    inout  wire                         hypr1_rwds,
    output wire                         hypr1_ckp,
    output wire                         hypr1_ckn,
    output wire                         hypr1_rst_l,
    output wire                         hypr1_cs_l,
    output wire                         hypr1_busy,

    inout  wire [7:0]                   hypr2_dq,
    inout  wire                         hypr2_rwds,
    output wire                         hypr2_ckp,
    output wire                         hypr2_ckn,
    output wire                         hypr2_rst_l,
    output wire                         hypr2_cs_l,
    output wire                         hypr2_busy
);

    wire        clk_90p;
    wire [7:0]  hypr1_dq_in;
    wire [7:0]  hypr1_dq_out;
    wire        hypr1_dq_oe_l;
    wire        hypr1_rwds_in;
    wire        hypr1_rwds_out;
    wire        hypr1_rwds_oe_l;
    wire        hypr1_ck;

    wire [7:0]  hypr2_dq_in;
    wire [7:0]  hypr2_dq_out;
    wire        hypr2_dq_oe_l;
    wire        hypr2_rwds_in;
    wire        hypr2_rwds_out;
    wire        hypr2_rwds_oe_l;
    wire        hypr2_ck;

    assign error = hypr1_busy || hypr2_busy; // TODO- change later


    `ifdef __ICARUS__
        assign hypr1_dq = (~hypr1_dq_oe_l)? 8'bz : hypr1_dq_out;
        assign hypr1_dq_in = hypr1_dq;
        assign hypr1_rwds = (~hypr1_rwds_oe_l)? 1'bz : hypr1_rwds_out;

        assign hypr2_dq = (~hypr2_dq_oe_l)? 8'bz : hypr2_dq_out;
        assign hypr2_dq_in = hypr2_dq;
        assign hypr2_rwds = (~hypr2_rwds_oe_l)? 1'bz : hypr2_rwds_out;

    `else
        genvar i;
        generate
            for (i = 0; i < 8; i = i + 1) begin: gen_dq_iobuf
                IOBUF U_hypr1_dq_io (
                    .I          (hypr1_dq_out[i]),
                    .O          (hypr1_dq_in[i]),
                    .T          (hypr1_dq_oe_l),
                    .IO         (hypr1_dq[i])
                );
                IOBUF U_hypr2_dq_io (
                    .I          (hypr2_dq_out[i]),
                    .O          (hypr2_dq_in[i]),
                    .T          (hypr2_dq_oe_l),
                    .IO         (hypr2_dq[i])
                );

            end
        endgenerate

        IOBUF U_hypr1_rwds_io (
            .I          (hypr1_rwds_out),
            .O          (hypr1_rwds_in),
            .T          (hypr1_rwds_oe_l),
            .IO         (hypr1_rwds)
        );
        IOBUF U_hypr2_rwds_io (
            .I          (hypr2_rwds_out),
            .O          (hypr2_rwds_in),
            .T          (hypr2_rwds_oe_l),
            .IO         (hypr2_rwds)
        );

    `endif


`ifdef HYPERRAM_MODEL
    hr_model U_hyperram1 (
        .reset          (hreset         ),
        .clk            (hclk           ),
        .lb_wr          (lb1_wr         ),
        .lb_rd          (lb1_rd         ),
        .lb_addr        (lb1_addr       ),
        .lb_wr_d        (lb1_wr_d       ),
        .lb_rd_d        (lb1_rd_d       ),
        .lb_rd_rdy      (lb1_rd_rdy     ),
        .hyperram_busy  (hypr1_busy      )
    );

    hr_model U_hyperram2 (
        .reset          (hreset         ),
        .clk            (hclk           ),
        .lb_wr          (lb2_wr         ),
        .lb_rd          (lb2_rd         ),
        .lb_addr        (lb2_addr       ),
        .lb_wr_d        (lb2_wr_d       ),
        .lb_rd_d        (lb2_rd_d       ),
        .lb_rd_rdy      (lb2_rd_rdy     ),
        .hyperram_busy  (hypr2_busy      )
    );


`else
    hr_pll_example U_hyperram1 (
        .simulation_en  (1'b0           ),
        .auto_cfg_en    (1'b0           ),
        .reset          (hreset         ),
        .clk            (hclk           ),
        .clk_90p        (clk_90p        ),
        .lb_wr          (lb1_wr         ),
        .lb_rd          (lb1_rd         ),
        .lb_addr        (lb1_addr       ),
        .lb_wr_d        (lb1_wr_d       ),
        .lb_rd_d        (lb1_rd_d       ),
        .lb_rd_rdy      (lb1_rd_rdy     ),
        .sump2_events   (               ),
                                       
        .dram_dq_in     (hypr1_dq_in     ),
        .dram_dq_out    (hypr1_dq_out    ),
        .dram_dq_oe_l   (hypr1_dq_oe_l   ),
                                       
        .dram_rwds_in   (hypr1_rwds_in   ),
        .dram_rwds_out  (hypr1_rwds_out  ),
        .dram_rwds_oe_l (hypr1_rwds_oe_l ),
                                       
        .dram_ck        (hypr1_ck        ),
        .dram_rst_l     (hypr1_rst_l     ),
        .dram_cs_l      (hypr1_cs_l      ),

        .hyperram_busy  (hypr1_busy      )
    );

    hr_pll_example U_hyperram2 (
        .simulation_en  (1'b0           ),
        .auto_cfg_en    (1'b0           ),
        .reset          (hreset         ),
        .clk            (hclk           ),
        .clk_90p        (clk_90p        ),
        .lb_wr          (lb2_wr         ),
        .lb_rd          (lb2_rd         ),
        .lb_addr        (lb2_addr       ),
        .lb_wr_d        (lb2_wr_d       ),
        .lb_rd_d        (lb2_rd_d       ),
        .lb_rd_rdy      (lb2_rd_rdy     ),
        .sump2_events   (               ),
                                       
        .dram_dq_in     (hypr2_dq_in     ),
        .dram_dq_out    (hypr2_dq_out    ),
        .dram_dq_oe_l   (hypr2_dq_oe_l   ),

        .dram_rwds_in   (hypr2_rwds_in   ),
        .dram_rwds_out  (hypr2_rwds_out  ),
        .dram_rwds_oe_l (hypr2_rwds_oe_l ),

        .dram_ck        (hypr2_ck        ),
        .dram_rst_l     (hypr2_rst_l     ),
        .dram_cs_l      (hypr2_cs_l      ),

        .hyperram_busy  (hypr2_busy      )
    );
`endif


    `ifdef __ICARUS__
        assign hypr1_ckp = hypr1_ck;
        assign hypr1_ckn = hypr1_ck;
        assign hypr2_ckp = hypr2_ck;
        assign hypr2_ckn = hypr2_ck;
        assign clk_90p = hclk;
        assign clk_90p_locked = 1'b1;

    `else
        OBUFDS #(
           .IOSTANDARD       ("LVDS"),
           .SLEW             ("FAST")
        ) U_OBUFDS_hypr1_clk_out (
           .O                (hypr1_ckp),
           .OB               (hypr1_ckn),
           .I                (hypr1_ck)
        );

        OBUFDS #(
           .IOSTANDARD       ("LVDS"),
           .SLEW             ("FAST")
        ) U_OBUFDS_hypr2_clk_out (
           .O                (hypr2_ckp),
           .OB               (hypr2_ckn),
           .I                (hypr2_ck)
        );

        wire clk_90p_fb;
        // TODO: optimize mul/div settings for 200 MHz clock (or whatever we end up using)
        PLLE3_BASE #(
            .CLKFBOUT_MULT      (16),
            .CLKFBOUT_PHASE     (0),
            .CLKIN_PERIOD       (14),
            .DIVCLK_DIVIDE      (1),
            .CLKOUT0_DIVIDE     (16),
            .CLKOUT0_PHASE      (90)
        ) U_clk90p (
            .CLKIN              (hclk),
            .LOCKED             (clk_90p_locked),
            .CLKOUTPHY          (),
            .CLKOUT0            (clk_90p),
            .CLKOUT0B           (),
            .CLKOUT1            (),
            .CLKOUT1B           (),
            .CLKOUTPHYEN        (1'b0),
            .PWRDWN             (1'b0),
            .RST                (hreset),
            .CLKFBIN            (clk_90p_fb),
            .CLKFBOUT           (clk_90p_fb)
        );

   `endif


endmodule
`default_nettype wire

