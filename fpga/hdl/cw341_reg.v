/* 
ChipWhisperer Artix Target - Example of connections between example registers
and rest of system.

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
`timescale 1ns / 1ps
`include "cw341_defines.v"

module cw341_reg #(
   parameter pBYTECNT_SIZE = 7,
   parameter pDONE_EDGE_SENSITIVE = 1,
   parameter pPT_WIDTH = 128,
   parameter pCT_WIDTH = 128,
   parameter pKEY_WIDTH = 128,
   parameter pCRYPT_TYPE = 2,
   parameter pCRYPT_REV = 4,
   parameter pIDENTIFY = 8'h2e
)(

// Interface to cw305_usb_reg_fe:
   input  wire                                  usb_clk,
   input  wire                                  crypto_clk,
   input  wire                                  hclk,
   input  wire                                  reset_i,
   input  wire [7:0]                            reg_address,     // Address of register
   input  wire [pBYTECNT_SIZE-1:0]              reg_bytecnt,  // Current byte count
   output reg  [7:0]                            read_data,       //
   input  wire [7:0]                            write_data,      //
   input  wire                                  reg_read,        // Read flag. One clock cycle AFTER this flag is high
                                                                 // valid data must be present on the read_data bus
   input  wire                                  reg_write,       // Write flag. When high on rising edge valid data is
                                                                 // present on write_data
   input  wire                                  reg_addrvalid,   // Address valid flag

// from top:
   input  wire                                  exttrigger_in,

// AES:
   input  wire [pPT_WIDTH-1:0]                  I_textout,
   input  wire [pCT_WIDTH-1:0]                  I_cipherout,
   input  wire                                  I_ready,  /* Crypto core ready. Tie to '1' if not used. */
   input  wire                                  I_done,   /* Crypto done. Can be high for one crypto_clk cycle or longer. */
   input  wire                                  I_busy,   /* Crypto busy. */

   output reg  [2:0]                            O_clksettings,
   output reg                                   O_user_led,
   output wire [pKEY_WIDTH-1:0]                 O_key,
   output wire [pPT_WIDTH-1:0]                  O_textin,
   output wire [pCT_WIDTH-1:0]                  O_cipherin,
   output wire                                  O_start,  /* High for one crypto_clk cycle, indicates text ready. */

// Hyperram:
   output wire                                  lb1_wr,
   output wire                                  lb1_rd,
   output wire [31:0]                           lb1_addr,
   output wire [31:0]                           lb1_wr_d,
   input  wire [31:0]                           lb1_rd_d,
   input  wire                                  lb1_rd_rdy,

   output wire                                  lb2_wr,
   output wire                                  lb2_rd,
   output wire [31:0]                           lb2_addr,
   output wire [31:0]                           lb2_wr_d,
   input  wire [31:0]                           lb2_rd_d,
   input  wire                                  lb2_rd_rdy,

   output reg                                   reg_hreset,

   input  wire                                  hypr1_busy,
   input  wire                                  hypr2_busy,
   input  wire                                  clk_90p_locked,

   output reg                                   O_lb_manual,
   output reg                                   O_auto_check1,
   output reg                                   O_auto_check2,
   output reg                                   O_auto_lfsr_mode,
   output reg                                   O_auto_clear_fail,
   input  wire                                  I_auto_pass,
   input  wire                                  I_auto_fail,
   input  wire [15:0]                           I_auto_iterations,
   input  wire [31:0]                           I_auto_current_addr,
   input  wire [31:0]                           I_auto_errors,
   input  wire [31:0]                           I_auto_error_addr,
   output reg  [31:0]                           O_auto_stop_addr,

// SRAM:
   output reg                                   O_sram_en,
   input  wire                                  I_sram_pass,
   input  wire [31:0]                           I_sram_runs,
   output reg  [7:0]                            O_sram_top_address,
   output reg  [7:0]                            O_sram_write_wait1,
   output reg  [7:0]                            O_sram_write_wait2,
   output reg  [7:0]                            O_sram_read_wait,

// LED/DIP testing:
   input  wire [7:0]                            I_dips,
   output wire [7:0]                            O_test_leds,
   output wire                                  O_led_test_mode,
   output wire                                  O_led_flash_all

);

   reg  [7:0]                   reg_read_data;
   reg  [pCT_WIDTH-1:0]         reg_crypt_cipherin;
   reg  [pKEY_WIDTH-1:0]        reg_crypt_key;
   reg  [pPT_WIDTH-1:0]         reg_crypt_textin;
   reg  [pPT_WIDTH-1:0]         reg_crypt_textout;
   reg  [pCT_WIDTH-1:0]         reg_crypt_cipherout;
   reg                          reg_crypt_go_pulse;
   wire                         reg_crypt_go_pulse_crypt;
   reg  [9:0]                   reg_test_leds;

   reg                          busy_usb;
   reg                          done_r;
   wire                         done_pulse;
   wire                         crypt_go_pulse;
   reg                          go_r;
   reg                          go;
   wire [31:0]                  buildtime;

   (* ASYNC_REG = "TRUE" *) reg  [pKEY_WIDTH-1:0] reg_crypt_key_crypt;
   (* ASYNC_REG = "TRUE" *) reg  [pPT_WIDTH-1:0] reg_crypt_textin_crypt;
   (* ASYNC_REG = "TRUE" *) reg  [pPT_WIDTH-1:0] reg_crypt_textout_usb;
   (* ASYNC_REG = "TRUE" *) reg  [pCT_WIDTH-1:0] reg_crypt_cipherout_usb;
   (* ASYNC_REG = "TRUE" *) reg  [1:0] go_pipe;
   (* ASYNC_REG = "TRUE" *) reg  [1:0] busy_pipe;


   reg  [63:0]                  reg_lb_both_rd_d;
   reg  [3:0]                   reg_lb_action;
   reg  [31:0]                  reg_lb_both_addr;
   reg  [63:0]                  reg_lb_both_data;


   always @(posedge crypto_clk) begin
       done_r <= I_done & pDONE_EDGE_SENSITIVE;
   end
   assign done_pulse = I_done & ~done_r;

   always @(posedge crypto_clk) begin
       if (done_pulse) begin
           reg_crypt_cipherout <= I_cipherout;
           reg_crypt_textout   <= I_textout;
       end
       reg_crypt_key_crypt <= reg_crypt_key;
       reg_crypt_textin_crypt <= reg_crypt_textin;
   end

   always @(posedge usb_clk) begin
       reg_crypt_cipherout_usb <= reg_crypt_cipherout;
       reg_crypt_textout_usb   <= reg_crypt_textout;
   end

   assign O_textin = reg_crypt_textin_crypt;
   assign O_key = reg_crypt_key_crypt;
   assign O_start = crypt_go_pulse || reg_crypt_go_pulse_crypt;
   assign O_test_leds = reg_test_leds[7:0];
   assign O_led_test_mode = reg_test_leds[8];
   assign O_led_flash_all = reg_test_leds[9];

   //////////////////////////////////
   // read logic:
   //////////////////////////////////

   always @(*) begin
      if (reg_addrvalid && reg_read) begin
         case (reg_address)
             // AES / config:
            `REG_CLKSETTINGS:           reg_read_data = {5'b0, O_clksettings};
            `REG_USER_LED:              reg_read_data = {7'b0, O_user_led};
            `REG_CRYPT_TYPE:            reg_read_data = pCRYPT_TYPE;
            `REG_CRYPT_REV:             reg_read_data = pCRYPT_REV;
            `REG_IDENTIFY:              reg_read_data = pIDENTIFY;
            `REG_CRYPT_GO:              reg_read_data = {7'b0, busy_usb};
            `REG_CRYPT_KEY:             reg_read_data = reg_crypt_key[reg_bytecnt*8 +: 8];
            `REG_CRYPT_TEXTIN:          reg_read_data = reg_crypt_textin[reg_bytecnt*8 +: 8];
            `REG_CRYPT_CIPHERIN:        reg_read_data = reg_crypt_cipherin[reg_bytecnt*8 +: 8];
            `REG_CRYPT_TEXTOUT:         reg_read_data = reg_crypt_textout_usb[reg_bytecnt*8 +: 8];
            `REG_CRYPT_CIPHEROUT:       reg_read_data = reg_crypt_cipherout_usb[reg_bytecnt*8 +: 8];
            `REG_BUILDTIME:             reg_read_data = buildtime[reg_bytecnt*8 +: 8];

            // Hyperram:
            `REG_LB_MANUAL:             reg_read_data = {7'b0, O_lb_manual};
            `REG_LB_DATA1:              reg_read_data = reg_lb_both_rd_d[reg_bytecnt*8 +: 8];
            `REG_LB_DATA2:              reg_read_data = reg_lb_both_rd_d[(reg_bytecnt+4)*8 +: 8];
            `REG_HYPER_STATUS:          reg_read_data = {3'b0, I_auto_pass, I_auto_fail, hypr2_busy, hypr1_busy, clk_90p_locked};
            `REG_LB_ERRORS:             reg_read_data = I_auto_errors[reg_bytecnt*8 +: 8];
            `REG_LB_ERROR_ADDR:         reg_read_data = I_auto_error_addr[reg_bytecnt*8 +: 8];
            `REG_LB_ITERATIONS:         reg_read_data = I_auto_iterations[reg_bytecnt*8 +: 8];
            `REG_LB_CURRENT_ADDR:       reg_read_data = I_auto_current_addr[reg_bytecnt*8 +: 8];

            // SRAM:
            `REG_SRAM_EN:               reg_read_data = {7'b0, O_sram_en};
            `REG_SRAM_PASS:             reg_read_data = {7'b0, I_sram_pass};
            `REG_SRAM_MEM_BYTES:        reg_read_data = O_sram_top_address;
            `REG_SRAM_RUNS:             reg_read_data = I_sram_runs[reg_bytecnt*8 +: 8];

            // LED/DIP test:
            `REG_DIPS:                  reg_read_data = I_dips;

            default:                    reg_read_data = 0;
         endcase
      end
      else
         reg_read_data = 0;
   end

   // Register output read data to ease timing. If you need read data one clock
   /* cycle earlier, simply remove this stage:
   always @(posedge usb_clk)
      read_data <= reg_read_data;
   */

   always @(*)
      read_data = reg_read_data;

   //////////////////////////////////
   // write logic (USB clock domain):
   //////////////////////////////////
   always @(posedge usb_clk) begin
      if (reset_i) begin
         O_clksettings <= 0;
         O_user_led <= 0;
         reg_crypt_go_pulse <= 1'b0;
         O_sram_en <= 1'b0;
         O_sram_top_address <= 8'd0;
         O_sram_write_wait1 <= 4;
         O_sram_write_wait2 <= 2;
         O_sram_read_wait <= 4;
         O_lb_manual <= 1;
         O_auto_clear_fail <= 0;
         O_auto_check1 <= 1;
         O_auto_check2 <= 1;
         O_auto_lfsr_mode <= 1;
         reg_test_leds <= 0;
      end

      else begin
         if (reg_addrvalid && reg_write) begin
            case (reg_address)
                // AES/config:
               `REG_CLKSETTINGS:        O_clksettings <= write_data[2:0];
               `REG_USER_LED:           O_user_led <= write_data;
               `REG_CRYPT_TEXTIN:       reg_crypt_textin[reg_bytecnt*8 +: 8] <= write_data;
               `REG_CRYPT_CIPHERIN:     reg_crypt_cipherin[reg_bytecnt*8 +: 8] <= write_data;
               `REG_CRYPT_KEY:          reg_crypt_key[reg_bytecnt*8 +: 8] <= write_data;

               // Hyperram:
               `REG_LB_DATA1:           reg_lb_both_data[reg_bytecnt*8 +: 8] <= write_data;
               `REG_LB_DATA2:           reg_lb_both_data[(reg_bytecnt+4)*8 +: 8] <= write_data;
               `REG_LB_ADDR:            reg_lb_both_addr[reg_bytecnt*8 +: 8] <= write_data;
               `REG_LB_ACTION:          reg_lb_action <= write_data[3:0];
               `REG_LB_MANUAL:          {O_auto_lfsr_mode, O_auto_check1, O_auto_check2, O_auto_clear_fail, O_lb_manual} <= write_data[4:0];
               `REG_LB_STOP_ADDR:       O_auto_stop_addr[reg_bytecnt*8 +: 8] <= write_data;

               // SRAM:
               `REG_SRAM_EN:            O_sram_en <= write_data[0];
               `REG_SRAM_MEM_BYTES:     O_sram_top_address <= write_data;
               `REG_SRAM_WRITE_WAIT1:   O_sram_write_wait1 <= write_data;
               `REG_SRAM_WRITE_WAIT2:   O_sram_write_wait2 <= write_data;
               `REG_SRAM_READ_WAIT:     O_sram_read_wait <= write_data;

               // LED/DIP test:
               `REG_LEDS:               reg_test_leds[reg_bytecnt*8 +: 8] <= write_data;

            endcase
         end
         // REG_CRYPT_GO register is special: writing it creates a pulse. Reading it gives you the "busy" status.
         if ( (reg_addrvalid && reg_write && (reg_address == `REG_CRYPT_GO)) )
            reg_crypt_go_pulse <= 1'b1;
         else
            reg_crypt_go_pulse <= 1'b0;

         // Hyperram reset:
         // write 0xff to do a single cycle reset, 0x01 to set, 0x00 to clear (hedging our bets!):
         if (reg_write && (reg_address == `REG_HYPER_RESET) && (write_data == 8'hFF) && ~reg_hreset)
             reg_hreset <= 1'b1;
         else
             reg_hreset <= 1'b0;
         if (reg_write && (reg_address == `REG_HYPER_RESET) && (write_data == 8'h01) && ~reg_hreset)
             reg_hreset <= 1'b1;
         else if (reg_write && (reg_address == `REG_HYPER_RESET) && (write_data == 8'h00) && ~reg_hreset)
             reg_hreset <= 1'b0;

      end
   end

   always @(posedge crypto_clk) begin
      {go_r, go, go_pipe} <= {go, go_pipe, exttrigger_in};
   end
   assign crypt_go_pulse = go & !go_r;

   cdc_pulse U_go_pulse (
      .reset_i       (reset_i),
      .src_clk       (usb_clk),
      .src_pulse     (reg_crypt_go_pulse),
      .dst_clk       (crypto_clk),
      .dst_pulse     (reg_crypt_go_pulse_crypt)
   );

   always @(posedge usb_clk)
      {busy_usb, busy_pipe} <= {busy_pipe, I_busy};



   // no need to allow for different *LB* addressing:
   assign lb1_addr = reg_lb_both_addr;
   assign lb2_addr = reg_lb_both_addr;

   assign lb1_wr_d = reg_lb_both_data[31:0];
   assign lb2_wr_d = reg_lb_both_data[63:32];

   reg action_pre;
   reg action_pre_r;

   wire reg_hypr1_wr_en = reg_lb_action[0];
   wire reg_hypr1_rd_en = reg_lb_action[1];
   wire reg_hypr2_wr_en = reg_lb_action[2];
   wire reg_hypr2_rd_en = reg_lb_action[3];

   reg lb1_wr_usb;
   reg lb1_rd_usb;
   reg lb2_wr_usb;
   reg lb2_rd_usb;

   always @(posedge usb_clk) begin
       action_pre_r <= action_pre;
       if ((reg_address == `REG_LB_ADDR) && (reg_bytecnt == 3))
           action_pre <= 1'b1;
       else
           action_pre <= 1'b0;
       if (action_pre && ~action_pre_r) begin
           lb1_wr_usb <= reg_hypr1_wr_en;
           lb1_rd_usb <= reg_hypr1_rd_en;
           lb2_wr_usb <= reg_hypr2_wr_en;
           lb2_rd_usb <= reg_hypr2_rd_en;
       end
       else begin
           lb1_wr_usb <= 1'b0;
           lb1_rd_usb <= 1'b0;
           lb2_wr_usb <= 1'b0;
           lb2_rd_usb <= 1'b0;
       end
   end

   cdc_pulse U_lb1w_pulse (
      .reset_i       (reset_i),
      .src_clk       (usb_clk),
      .src_pulse     (lb1_wr_usb),
      .dst_clk       (hclk),
      .dst_pulse     (lb1_wr)
   );
   cdc_pulse U_lb1r_pulse (
      .reset_i       (reset_i),
      .src_clk       (usb_clk),
      .src_pulse     (lb1_rd_usb),
      .dst_clk       (hclk),
      .dst_pulse     (lb1_rd)
   );
   cdc_pulse U_lb2w_pulse (
      .reset_i       (reset_i),
      .src_clk       (usb_clk),
      .src_pulse     (lb2_wr_usb),
      .dst_clk       (hclk),
      .dst_pulse     (lb2_wr)
   );
   cdc_pulse U_lb2r_pulse (
      .reset_i       (reset_i),
      .src_clk       (usb_clk),
      .src_pulse     (lb2_rd_usb),
      .dst_clk       (hclk),
      .dst_pulse     (lb2_rd)
   );

   always @(posedge hclk) begin
       // TODO: can *rd_rdy be sufficiently delayed that the host would need to check for it?
       if (lb1_rd_rdy)
           reg_lb_both_rd_d[31:0] <= lb1_rd_d;
       if (lb2_rd_rdy)
           reg_lb_both_rd_d[63:32] <= lb2_rd_d;
   end


   `ifdef ILA_REG
       ila_reg U_reg_ila (
	.clk            (usb_clk),                      // input wire clk
	.probe0         (reg_address),                  // input wire [7:0] probe1
	.probe1         (reg_bytecnt),                  // input wire [6:0]  probe1 
	.probe2         (read_data),                    // input wire [7:0]  probe2 
	.probe3         (write_data),                   // input wire [7:0]  probe3 
	.probe4         (reg_read),                     // input wire [0:0]  probe4 
	.probe5         (reg_write),                    // input wire [0:0]  probe5 
	.probe6         (reg_addrvalid),                // input wire [0:0]  probe6 
	.probe7         (reg_read_data),                // input wire [7:0]  probe7 
	.probe8         (exttrigger_in),                // input wire [0:0]  probe8 
	.probe9         (reset_i),                      // input wire [0:0]  probe9
	.probe10        (reg_crypt_go_pulse),           // input wire [0:0]  probe10
	.probe11        (reg_crypt_textin)             // input wire [127:0]  probe11
       );
   `endif


   `ifdef ILA_CRYPTO
       ila_crypto U_reg_aes (
	.clk            (crypto_clk),                   // input wire clk
	.probe0         (O_start),                      // input wire [0:0]  probe0  
	.probe1         (I_done),                       // input wire [0:0]  probe1 
	.probe2         (I_cipherout[7:0]),             // input wire [7:0]  probe2 
	.probe3         (O_textin[7:0]),                // input wire [7:0]  probe3 
	.probe4         (done_pulse)                    // input wire [0:0]  probe4 
       );
   `endif


   `ifdef ILA_HYPERRAM_REG
       ila_hyperram_reg U_ila_hyperram_reg (
           .clk         (hclk        ),
           .probe0      (lb1_wr      ),
           .probe1      (lb1_rd      ),
           .probe2      (lb1_addr    ),         // 31:0
           .probe3      (lb1_wr_d    ),         // 31:0
           .probe4      (lb1_rd_d    ),         // 31:0
           .probe5      (lb1_rd_rdy  ),

           .probe6      (reg_address ),         // 7:0
           .probe7      (reg_bytecnt ),         // 6:0
           .probe8      (read_data   ),         // 7:0
           .probe9      (write_data  ),         // 7:0
           .probe10     (reg_read    ),
 	   .probe11     (reg_write   ),

           .probe12     (lb2_wr      ),
           .probe13     (lb2_rd      ),
           .probe14     (lb2_addr    ),         // 31:0
           .probe15     (lb2_wr_d    ),         // 31:0
           .probe16     (lb2_rd_d    ),         // 31:0
           .probe17     (lb2_rd_rdy  ),

           .probe18     (1'b0        ),  
           .probe19     (reg_lb_action)         // 3:0
       );                            
   `endif


   `ifndef __ICARUS__
      USR_ACCESSE2 U_buildtime (
         .CFGCLK(),
         .DATA(buildtime),
         .DATAVALID()
      );
   `else
      assign buildtime = 0;
   `endif


endmodule

`default_nettype wire
