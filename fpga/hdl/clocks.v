/* 
ChipWhisperer Artix Target - Select input clocks and drive output clocks.

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


`default_nettype none
`timescale 1ns / 1ns

module clocks (
    input  wire         usb_clk,
    output wire         usb_clk_buf,
    input  wire [2:0]   I_clock_settings,
    input  wire         I_cw_clkin,
    input  wire         I_pll_clk1,
    input  wire         I_pll_clk2_orig,
    input  wire         I_pll_clk2_alt,

    output wire         O_cw_clkout,
    output wire         O_ext_clk
);

    wire pll_clk2;

`ifdef __ICARUS__
    assign O_ext_clk = I_clock_settings ? I_cw_clkin : I_pll_clk1;
    assign O_cw_clkout = 1'b0; // TODO?
    assign usb_clk_buf = usb_clk;

`else
    wire hs2_clk_bufg;
    wire pll1_clk_bufg;
    wire pll2_clk_orig_bufg;
    wire pll2_clk_alt_bufg;
    wire usb_clk_bufg;
    wire pll2_clk;
    wire pll_clk;

    IBUFG clkibuf_usb (
        .O(usb_clk_bufg),
        .I(usb_clk) 
    );

    BUFG clkbuf_usb (
        .O(usb_clk_buf),
        .I(usb_clk_bufg)
    );

    IBUFG clkibuf_hs2 (
        .O(hs2_clk_bufg),
        .I(I_cw_clkin) 
    );

    IBUFG clkibuf_pll1 (
        .O(pll1_clk_bufg),
        .I(I_pll_clk1) 
    );

    IBUFG clkibuf_pll2_orig (
        .O(pll2_clk_orig_bufg),
        .I(I_pll_clk2_orig) 
    );

    IBUFG clkibuf_pll2_alt (
        .O(pll2_clk_alt_bufg),
        .I(I_pll_clk2_alt) 
    );



    BUFGMUX #(
        .CLK_SEL_TYPE ("ASYNC")
    ) CCLK_MUX0 (
       .O       (pll2_clk),
       .I0      (pll2_clk_alt_bufg),
       .I1      (pll2_clk_orig_bufg),
       .S       (I_clock_settings[2])
    );    

    BUFGMUX #(
        .CLK_SEL_TYPE ("ASYNC")
    ) CCLK_MUX1 (
       .O       (pll_clk),
       .I0      (pll1_clk_bufg),
       .I1      (pll2_clk),
       .S       (I_clock_settings[1])
    );    

    BUFGMUX #(
        .CLK_SEL_TYPE ("ASYNC")
    ) CCLK_MUX2 (
       .O       (O_ext_clk),
       .I0      (pll_clk),
       .I1      (hs2_clk_bufg),
       .S       (I_clock_settings[0])
    );    


`endif


endmodule

`default_nettype wire
