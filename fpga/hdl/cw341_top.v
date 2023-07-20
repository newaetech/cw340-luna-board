/* 
ChipWhisperer Bergen Target - Example of connections between example registers
and rest of system.

Copyright (c) 2021, NewAE Technology Inc.
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

module cw341_top #(
    parameter pBYTECNT_SIZE = 7,
    parameter pPT_WIDTH = 128,
    parameter pCT_WIDTH = 128,
    parameter pKEY_WIDTH = 128,
    parameter pSRAM_DATA_WIDTH = 16,
    parameter pSRAM_ADDR_WIDTH = 19
)(
    // USB Interface
    input wire                          usb_clk,        // Clock
    //output wire                         usb_clk_buf,
    inout wire [7:0]                    USB_AD,         // Address (when ALEn is low) and data (when ALEn is high)
    input wire                          USB_nRD,        // !RD, low when addr valid for read
    //input wire                        USB_nWR,        // not available on CW341
    input wire                          USB_nCE,        // !CE, active low chip enable
    input wire                          USB_ALEn,       // USB_SPARE3
    //input wire                        usb_trigger,    // High when trigger requested

    // Buttons/LEDs on Board
    input wire [7:0]                    USRDIP,

    input wire                          OT_PORN,
    input wire                          USRSW0,     // Pushbutton SW0, used here as reset
    output reg  [7:0]                   USRLED,

    // PLL
    input wire                          PLL_CLK1,
    input wire                          PLL_CLK2_ORIG,
    input wire                          PLL_CLK2_ALT,

    // 20-Pin Connector Stuff
    //output wire                         CWIO_IO4,
    //output wire                         CWIO_HS1,
    //input  wire                         CWIO_HS2,

    // SRAM:
    output wire [pSRAM_ADDR_WIDTH-1:0]  SRAM_A,
    inout  wire [pSRAM_DATA_WIDTH-1:0]  SRAM_DQ,
    output wire                         SRAM_CS1n,
    output wire                         SRAM_LBn,
    output wire                         SRAM_UBn,
    output wire                         SRAM_OEn,
    output wire                         SRAM_WEn,

    // Hyperram:
    inout  wire [7:0]                   hypr1_dq,
    inout  wire                         hypr1_rwds,
    output wire                         hypr1_ckp,
    output wire                         hypr1_ckn,
    output wire                         hypr1_rst_l,
    output wire                         hypr1_cs_l,

    inout  wire [7:0]                   hypr2_dq,
    inout  wire                         hypr2_rwds,
    output wire                         hypr2_ckp,
    output wire                         hypr2_ckn,
    output wire                         hypr2_rst_l,
    output wire                         hypr2_cs_l,

    // XADC:
    input  wire                         vauxp0,
    input  wire                         vauxn0,
    input  wire                         vauxp1,
    input  wire                         vauxn1,
    input  wire                         vauxp8,
    input  wire                         vauxn8,
    input  wire                         vauxp12,
    input  wire                         vauxn12

);


    wire [pKEY_WIDTH-1:0] crypt_key;
    wire [pPT_WIDTH-1:0] crypt_textout;
    wire [pCT_WIDTH-1:0] crypt_cipherin;
    wire crypt_init;
    wire crypt_ready;
    wire crypt_start;
    wire crypt_done;
    wire crypt_busy;

    wire [7:0] usb_dout;
    wire isout;
    wire [7:0] reg_address;
    wire [pBYTECNT_SIZE-1:0] reg_bytecnt;
    wire reg_addrvalid;
    wire [7:0] write_data;
    wire [7:0] read_data;
    wire [7:0] read_data_main;
    wire [7:0] read_data_xadc;
    wire reg_read;
    wire reg_write;
    wire [2:0] clk_settings;
    wire ext_clk;

    wire resetn = USRSW0 & OT_PORN;
    wire reset = !resetn;
    wire usb_trigger = 1'b0;
    wire usb_clk_buf;

    wire        lb1_wr;
    wire        lb1_rd;
    wire [31:0] lb1_addr;
    wire [31:0] lb1_wr_d;
    wire [31:0] lb1_rd_d;
    wire        lb1_rd_rdy;

    wire        lb2_wr;
    wire        lb2_rd;
    wire [31:0] lb2_addr;
    wire [31:0] lb2_wr_d;
    wire [31:0] lb2_rd_d;
    wire        lb2_rd_rdy;

    wire        manual_lb1_wr;
    wire        manual_lb1_rd;
    wire [31:0] manual_lb1_addr;
    wire [31:0] manual_lb1_wr_d;
    wire        auto_lb1_wr;
    wire        auto_lb1_rd;
    wire [31:0] auto_lb1_addr;
    wire [31:0] auto_lb1_wr_d;

    wire        manual_lb2_wr;
    wire        manual_lb2_rd;
    wire [31:0] manual_lb2_addr;
    wire [31:0] manual_lb2_wr_d;
    wire        auto_lb2_wr;
    wire        auto_lb2_rd;
    wire [31:0] auto_lb2_addr;
    wire [31:0] auto_lb2_wr_d;


    wire        hreset;
    wire        memtest_error;
    wire        clk_90p_locked;
    wire        hypr1_busy;
    wire        hypr2_busy;
    wire        hypr1_busy_stuck;
    wire        hypr2_busy_stuck;

    wire        lb_manual;
    wire        auto_clear_fail;
    wire        auto_check1;
    wire        auto_check2;
    wire        auto_lfsr_mode;
    wire        auto_pass;
    wire        auto_fail;
    wire [15:0] auto_iterations;
    wire [31:0] auto_current_addr;
    wire [31:0] auto_errors;
    wire [31:0] auto_error_addr;
    wire [31:0] auto_addr_stop;


    wire [31:0] sram_runs;
    wire [7:0] sram_top_address;
    wire [7:0] sram_write_wait1;
    wire [7:0] sram_write_wait2;
    wire [7:0] sram_read_wait;
    wire sram_en;
    wire sram_pass;
    wire sram_fail;

    wire led_test_mode;
    wire led_flash_all;
    wire [7:0] test_leds;
    wire usrled;

    // USB CLK Heartbeat
    reg [24:0] usb_timer_heartbeat;
    always @(posedge usb_clk_buf) usb_timer_heartbeat <= usb_timer_heartbeat +  25'd1;

    // CRYPT CLK Heartbeat
    reg [24:0] ext_clk_heartbeat;
    always @(posedge ext_clk) ext_clk_heartbeat <= ext_clk_heartbeat +  23'd1;

    always @(*) begin
        if (led_test_mode) begin
            if (led_flash_all)
                USRLED = {8{usb_timer_heartbeat[23]}};
            else
                USRLED = test_leds;
        end
        else begin
            USRLED[0] = usb_timer_heartbeat[24];
            USRLED[1] = ext_clk_heartbeat[24];
            USRLED[2] = usrled;
            USRLED[3] = hypr1_busy_stuck || hypr2_busy_stuck;
            USRLED[4] = ~clk_90p_locked;
            USRLED[5] = reset;
            USRLED[6] = 1'b0;
            USRLED[7] = 1'b0;
        end
    end

    assign read_data = read_data_main | read_data_xadc;

    cw341_usb_reg_main #(
        .pBYTECNT_SIZE          (pBYTECNT_SIZE),
        .pUSE_ALE               (1),
        .pDATA_WIDTH            (8)
    ) U_usb_reg_main (
        .clk_usb                (usb_clk_buf), 
        .reset                  (reset),
        .cwusb_din              (USB_AD), 
        .cwusb_dout             (usb_dout), 
        .cwusb_rdn              (USB_nRD), 
        //.cwusb_wrn              (USB_nWR),
        .cwusb_cen              (USB_nCE),
        .cwusb_alen             (USB_ALEn),
        .cwusb_addr             (USB_AD),
        .cwusb_isout            (isout), 
        .fast_fifo_read         (1'b0),
        .reg_address            (reg_address), 
        .reg_bytecnt            (reg_bytecnt), 
        .reg_datao              (write_data), 
        .reg_datai              (read_data),
        .reg_read               (reg_read), 
        .reg_write              (reg_write) 
    );

    cw341_reg #(
       .pBYTECNT_SIZE           (pBYTECNT_SIZE),
       .pPT_WIDTH               (pPT_WIDTH),
       .pCT_WIDTH               (pCT_WIDTH),
       .pKEY_WIDTH              (pKEY_WIDTH)
    ) U_c341_reg (
       .reset_i                 (reset),
       .crypto_clk              (ext_clk),
       .usb_clk                 (usb_clk_buf), 
       .hclk                    (ext_clk),
       .reg_address             (reg_address),
       .reg_bytecnt             (reg_bytecnt), 
       .read_data               (read_data_main), 
       .write_data              (write_data),
       .reg_read                (reg_read), 
       .reg_write               (reg_write), 
       .reg_addrvalid           (1'b1),

       .exttrigger_in           (usb_trigger),

       .I_textout               (128'b0),               // unused
       .I_cipherout             (crypt_cipherin),
       .I_ready                 (crypt_ready),
       .I_done                  (crypt_done),
       .I_busy                  (crypt_busy),

       .O_user_led              (usrled),
       .O_key                   (crypt_key),
       .O_textin                (crypt_textout),
       .O_cipherin              (),                     // unused
       .O_start                 (crypt_start),
       .O_clksettings           (clk_settings),

       .reg_hreset              (hreset         ),
       .hypr1_busy              (hypr1_busy_stuck),
       .hypr2_busy              (hypr2_busy_stuck),
       .clk_90p_locked          (clk_90p_locked ),

       .O_lb_manual             (lb_manual       ),
       .O_auto_clear_fail       (auto_clear_fail ),
       .O_auto_check1           (auto_check1 ),
       .O_auto_check2           (auto_check2 ),
       .O_auto_lfsr_mode        (auto_lfsr_mode ),
       .I_auto_pass             (auto_pass       ),
       .I_auto_fail             (auto_fail       ),
       .I_auto_iterations       (auto_iterations ),
       .I_auto_current_addr     (auto_current_addr ),
       .I_auto_errors           (auto_errors     ),
       .I_auto_error_addr       (auto_error_addr ),
       .O_auto_stop_addr        (auto_addr_stop  ),

       .lb1_wr                  (manual_lb1_wr         ),
       .lb1_rd                  (manual_lb1_rd         ),
       .lb1_addr                (manual_lb1_addr       ),
       .lb1_wr_d                (manual_lb1_wr_d       ),
       .lb1_rd_d                (lb1_rd_d       ),
       .lb1_rd_rdy              (lb1_rd_rdy     ),

       .lb2_wr                  (manual_lb2_wr         ),
       .lb2_rd                  (manual_lb2_rd         ),
       .lb2_addr                (manual_lb2_addr       ),
       .lb2_wr_d                (manual_lb2_wr_d       ),
       .lb2_rd_d                (lb2_rd_d       ),
       .lb2_rd_rdy              (lb2_rd_rdy     ),

       .O_sram_en               (sram_en),
       .I_sram_pass             (sram_pass & ~sram_fail),
       .I_sram_runs             (sram_runs),
       .O_sram_write_wait1      (sram_write_wait1),
       .O_sram_write_wait2      (sram_write_wait2),
       .O_sram_read_wait        (sram_read_wait),
       .O_sram_top_address      (sram_top_address),

       .I_dips                  (USRDIP),
       .O_led_test_mode         (led_test_mode),
       .O_led_flash_all         (led_flash_all),
       .O_test_leds             (test_leds)
    );

    //assign USB_AD = (isout && USB_ALEn)? usb_dout : 8'bZ;
    assign USB_AD = (isout)? usb_dout : 8'bZ;

    clocks U_clocks (
       .usb_clk                 (usb_clk),
       .usb_clk_buf             (usb_clk_buf),
       .I_clock_settings        (clk_settings),
       .I_cw_clkin              (CWIO_HS2),
       .I_pll_clk1              (PLL_CLK1),
       .I_pll_clk2_orig         (PLL_CLK2_ORIG),
       .I_pll_clk2_alt          (PLL_CLK2_ALT),
       .O_cw_clkout             (CWIO_HS1),
       .O_ext_clk               (ext_clk)
    );


   wire aes_clk;
   wire [127:0] aes_key;
   wire [127:0] aes_pt;
   wire [127:0] aes_ct;
   wire aes_load;
   wire aes_busy;

   assign aes_clk = ext_clk;
   assign aes_key = crypt_key;
   assign aes_pt = crypt_textout;
   assign crypt_cipherin = aes_ct;
   assign aes_load = crypt_start;
   assign crypt_ready = 1'b1;
   assign crypt_done = ~aes_busy;
   assign crypt_busy = aes_busy;

   // Example AES Core
   aes_core aes_core (
       .clk             (aes_clk),
       .load_i          (aes_load),
       .key_i           ({aes_key, 128'h0}),
       .data_i          (aes_pt),
       .size_i          (2'd0), //AES128
       .dec_i           (1'b0),//enc mode
       .data_o          (aes_ct),
       .busy_o          (aes_busy)
   );

   //assign CWIO_IO4 = aes_busy;
   wire CWIO_HS2 = 1'b0;
   wire CWIO_HS1;


   assign lb1_wr        = (lb_manual)? manual_lb1_wr : auto_lb1_wr;
   assign lb1_rd        = (lb_manual)? manual_lb1_rd : auto_lb1_rd;
   assign lb1_addr      = (lb_manual)? manual_lb1_addr : auto_lb1_addr;
   assign lb1_wr_d      = (lb_manual)? manual_lb1_wr_d : auto_lb1_wr_d;

   assign lb2_wr        = (lb_manual)? manual_lb2_wr : auto_lb2_wr;
   assign lb2_rd        = (lb_manual)? manual_lb2_rd : auto_lb2_rd;
   assign lb2_addr      = (lb_manual)? manual_lb2_addr : auto_lb2_addr;
   assign lb2_wr_d      = (lb_manual)? manual_lb2_wr_d : auto_lb2_wr_d;


    hyperram_wrapper U_hyperram_wrapper (
        .hreset                         (hreset),
        .hclk                           (ext_clk),
        .error                          (),
        .clk_90p_locked                 (clk_90p_locked),

        .lb1_wr                         (lb1_wr         ),
        .lb1_rd                         (lb1_rd         ),
        .lb1_addr                       (lb1_addr       ),
        .lb1_wr_d                       (lb1_wr_d       ),
        .lb1_rd_d                       (lb1_rd_d       ),
        .lb1_rd_rdy                     (lb1_rd_rdy     ),

        .lb2_wr                         (lb2_wr         ),
        .lb2_rd                         (lb2_rd         ),
        .lb2_addr                       (lb2_addr       ),
        .lb2_wr_d                       (lb2_wr_d       ),
        .lb2_rd_d                       (lb2_rd_d       ),
        .lb2_rd_rdy                     (lb2_rd_rdy     ),

        .hypr1_dq                       (hypr1_dq    ),
        .hypr1_rwds                     (hypr1_rwds  ),
        .hypr1_ckp                      (hypr1_ckp   ),
        .hypr1_ckn                      (hypr1_ckn   ),
        .hypr1_rst_l                    (hypr1_rst_l ),
        .hypr1_cs_l                     (hypr1_cs_l  ),
        .hypr1_busy                     (hypr1_busy  ),

        .hypr2_dq                       (hypr2_dq    ),
        .hypr2_rwds                     (hypr2_rwds  ),
        .hypr2_ckp                      (hypr2_ckp   ),
        .hypr2_ckn                      (hypr2_ckn   ),
        .hypr2_rst_l                    (hypr2_rst_l ),
        .hypr2_cs_l                     (hypr2_cs_l  ),
        .hypr2_busy                     (hypr2_busy  )
    );

    simple_hyperram_rwtest U_hyperram_test(
        .clk                            (ext_clk        ),
        .reset                          (reset          ),
        .active_usb                     (~lb_manual     ),
        .clear_fail                     (auto_clear_fail),
        .check1                         (auto_check1 ),
        .check2                         (auto_check2 ),
        .lfsr_mode                      (auto_lfsr_mode ),
        .pass                           (auto_pass      ),
        .fail                           (auto_fail      ),
        .iteration                      (auto_iterations),
        .current_addr                   (auto_current_addr),
        .total_errors                   (auto_errors    ),
        .error_addr                     (auto_error_addr),
        .addr_stop                      (auto_addr_stop ),
                                                     
        .lb1_wr                         (auto_lb1_wr    ),
        .lb1_rd                         (auto_lb1_rd    ),
        .lb1_addr                       (auto_lb1_addr  ),
        .lb1_wr_d                       (auto_lb1_wr_d  ),
        .lb1_rd_d                       (lb1_rd_d       ),
        .lb1_rd_rdy                     (lb1_rd_rdy     ),
        .hr1_busy                       (hypr1_busy     ),
        .hr1_busy_stuck                 (hypr1_busy_stuck),
                                                     
        .lb2_wr                         (auto_lb2_wr    ),
        .lb2_rd                         (auto_lb2_rd    ),
        .lb2_addr                       (auto_lb2_addr  ),
        .lb2_wr_d                       (auto_lb2_wr_d  ),
        .lb2_rd_d                       (lb2_rd_d       ),
        .lb2_rd_rdy                     (lb2_rd_rdy     ),
        .hr2_busy                       (hypr2_busy     ),
        .hr2_busy_stuck                 (hypr2_busy_stuck)
    );


    simple_sram_rwtest #(
        .pDATA_WIDTH            (pSRAM_DATA_WIDTH),
        .pADDR_WIDTH            (pSRAM_ADDR_WIDTH)
    ) U_sram_test (
        .clk                    (usb_clk_buf),
        .reset                  (reset),
        .active                 (sram_en),
        .pass                   (sram_pass),
        .fail                   (sram_fail),
        .test_runs              (sram_runs),
        .I_top_address          (sram_top_address),
        .write_wait1            (sram_write_wait1),
        .write_wait2            (sram_write_wait2),
        .read_wait              (sram_read_wait),

        .wen                    (SRAM_WEn),
        .oen                    (SRAM_OEn),
        .cen                    (SRAM_CS1n),
        .lbn                    (SRAM_LBn),
        .ubn                    (SRAM_UBn),
        .addr                   (SRAM_A),
        .data                   (SRAM_DQ)
    );



   /* TODO: later
    `ifndef __ICARUS__
        xadc_wiz_0 U_xadc (
          .di_in                (0),                    // input wire [15 : 0] di_in
          .daddr_in             (0),                    // input wire [6 : 0] daddr_in
          .den_in               (0),                    // input wire den_in
          .dwe_in               (0),                    // input wire dwe_in
          .drdy_out             (),                     // output wire drdy_out
          .do_out               (),                     // output wire [15 : 0] do_out
          .dclk_in              (usb_clk_buf),          // input wire dclk_in
          .reset_in             (reset),                // input wire reset_in
          .vp_in                (),                     // input wire vp_in
          .vn_in                (),                     // input wire vn_in
          .user_temp_alarm_out  (),                     // output wire user_temp_alarm_out
          .vccint_alarm_out     (),                     // output wire vccint_alarm_out
          .vccaux_alarm_out     (),                     // output wire vccaux_alarm_out
          .ot_out               (),                     // output wire ot_out
          .channel_out          (),                     // output wire [4 : 0] channel_out
          .eoc_out              (),                     // output wire eoc_out
          .vbram_alarm_out      (),                     // output wire vbram_alarm_out
          .alarm_out            (),                     // output wire alarm_out
          .eos_out              (),                     // output wire eos_out
          .busy_out             ()                      // output wire busy_out
        );
    `endif
   */

    sysmon #(
       .pBYTECNT_SIZE           (pBYTECNT_SIZE)
    ) U_sysmon (
       .reset_i                 (reset),
       .clk_usb                 (usb_clk_buf), 
       .reg_address             (reg_address),
       .reg_bytecnt             (reg_bytecnt), 
       .reg_datao               (read_data_xadc), 
       .reg_datai               (write_data),
       .reg_read                (reg_read), 
       .reg_write               (reg_write), 

       .vauxp0                  (vauxp0),
       .vauxn0                  (vauxn0),
       .vauxp1                  (vauxp1),
       .vauxn1                  (vauxn1),
       .vauxp8                  (vauxp8),
       .vauxn8                  (vauxn8),
       .vauxp12                 (vauxp12),
       .vauxn12                 (vauxn12),
       .xadc_error              ()
    ); 



endmodule

`default_nettype wire

