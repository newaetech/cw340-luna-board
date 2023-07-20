/* 
ChipWhisperer Artix Target - Simple testbench to check for signs of life.

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

`timescale 1ns / 1ns
`default_nettype none 

`include "cw341_defines.v"

module tb();
    parameter pBYTECNT_SIZE = 7;
    parameter pADDR_WIDTH = 8;
    parameter pUSB_CLOCK_PERIOD = 10;
    parameter pPLL_CLOCK_PERIOD = 6;
    parameter pSEED = 1;
    parameter pTIMEOUT = 30000;
    parameter pVERBOSE = 0;
    parameter pDUMP = 0;

    reg usb_clk;
    reg usb_clk_enable;
    wire [7:0] usb_data;
    reg [7:0] usb_wdata;
    reg [7:0] usb_addr;
    reg usb_rdn;
    reg usb_wrn;
    reg usb_cen;
    reg usb_alen;
    reg usb_trigger;

    reg pushbutton;
    reg pll_clk1;
    wire tio_clkin;
    wire trig_out;

    wire [7:0] led;
    wire [7:0] usrdip;

    wire tio_trigger;
    wire tio_clkout;


    int seed;
    int errors;
    int warnings;
    int i;
    
    reg [31:0] write_data;

    wire clk = pll_clk1;  // shorthand for testbench

   int cycle;
   int total_time;

   reg [127:0] read_data;
   reg [127:0] expected_cipher = 128'h8a278bf8fa2812bc39e52c76205af377;

   localparam pSTREAM = 0;
   localparam pADC_LOW_RES = 0;
   localparam pSLOW_READS = 0; // TODO?

   initial begin
      seed = pSEED;
      errors = 0;
      warnings = 0;
      $display("Running with seed=%0d", seed);
      $urandom(seed);
      if (pDUMP) begin
         $dumpfile("results/tb.fst");
         $dumpvars(0, tb);
      end
      usb_clk = 1'b1;
      usb_clk_enable = 1'b1;
      pll_clk1 = 1'b1;

      usb_wdata = 0;
      usb_addr = 0;
      usb_rdn = 1;
      usb_wrn = 1;
      usb_cen = 1;
      usb_alen = 1;
      usb_trigger = 0;

      pushbutton = 1;
      pll_clk1 = 0;

      #(pUSB_CLOCK_PERIOD*2) pushbutton = 0;
      #(pUSB_CLOCK_PERIOD*2) pushbutton = 1;
      #(pUSB_CLOCK_PERIOD*10);

      write_byte(`REG_SRAM_MEM_BYTES, 32);
      write_byte(`REG_SRAM_EN, 1);

      write_bytes(4, `REG_LB_STOP_ADDR, 32'h3);
      write_byte(`REG_LB_MANUAL, 8);
      //repeat (50) @(posedge usb_clk);
      //write_byte(`REG_LB_MANUAL, 1);
      //repeat (10) @(posedge usb_clk);
      //write_byte(`REG_LB_MANUAL, 0);

      write_bytes(16, `REG_CRYPT_TEXTIN, {32'h12345678, 32'habcdef01, 32'h87654321, 32'hdeadbeef});
      write_bytes(16, `REG_CRYPT_KEY, {32'habcdef01, 32'h12345678, 32'hdeadbeef, 32'h87654321});

      $display("Encrypting via register...");
      write_byte(`REG_CRYPT_GO, 1);
      repeat (5) @(posedge usb_clk);
      wait_done();
      read_bytes(16, `REG_CRYPT_CIPHEROUT, read_data);
      if (read_data == expected_cipher) begin
         $display("Good result");
      end
      else begin
         errors += 1;
         $display("ERROR: expected %h", expected_cipher);
         $display("            got %h", read_data);
      end


      /*
      $display("Encrypting via usb_trigger (USB clock disabled)...");
      write_bytes(1, `REG_CRYPT_TEXTIN, 8'h01);
      expected_cipher = 128'h0efee0bff4cf170752994fb45bd45934;
      repeat (5) @(posedge usb_clk);
      usb_clk_enable = 1'b0;
      @(posedge usb_clk) usb_trigger = 1'b1;
      repeat (10) @(posedge usb_clk); 
      usb_trigger = 1'b0;
      repeat (30) @(posedge pll_clk1);
      usb_clk_enable = 1'b1;
      repeat (5) @(posedge usb_clk);
      wait_done();
      read_bytes(16, `REG_CRYPT_CIPHEROUT, read_data);
      if (read_data == expected_cipher) begin
         $display("Good result");
      end
      else begin
         errors += 1;
         $display("ERROR: expected %h", expected_cipher);
         $display("            got %h", read_data);
      end


      $display("Encrypting via usb_trigger (USB clock enabled)...");
      write_bytes(1, `REG_CRYPT_TEXTIN, 8'h02);
      expected_cipher = 128'h8623e205b50bede46f795d1aad15faae;
      @(posedge usb_clk) usb_trigger = 1'b1;
      repeat (10) @(posedge usb_clk); 
      usb_trigger = 1'b0;
      repeat (30) @(posedge pll_clk1);
      repeat (5) @(posedge usb_clk);
      wait_done();
      read_bytes(16, `REG_CRYPT_CIPHEROUT, read_data);
      if (read_data == expected_cipher) begin
         $display("Good result");
      end
      else begin
         errors += 1;
         $display("ERROR: expected %h", expected_cipher);
         $display("            got %h", read_data);
      end

      $display("Encrypting via usb_trigger (USB clock disabled, returns mid-encryption)...");
      write_bytes(1, `REG_CRYPT_TEXTIN, 8'h03);
      expected_cipher = 128'h46be87df4d18bfe6d0d1d3b20b6bf382;
      repeat (5) @(posedge usb_clk);
      usb_clk_enable = 1'b0;
      @(posedge usb_clk) usb_trigger = 1'b1;
      repeat (2) @(posedge usb_clk); 
      usb_trigger = 1'b0;
      repeat (2) @(posedge pll_clk1);
      usb_clk_enable = 1'b1;
      repeat (1) @(posedge usb_clk);
      wait_done();
      read_bytes(16, `REG_CRYPT_CIPHEROUT, read_data);
      if (read_data == expected_cipher) begin
         $display("Good result");
      end
      else begin
         errors += 1;
         $display("ERROR: expected %h", expected_cipher);
         $display("            got %h", read_data);
      end
      */


      $display("done!");
      #(pUSB_CLOCK_PERIOD*10);
      if (errors)
         $display("SIMULATION FAILED (%0d errors, %0d warnings).", errors, warnings);
      else
         $display("Simulation passed (%0d warnings).", warnings);
      $finish;

   end

   // maintain a cycle counter
   always @(posedge clk) begin
      if (pushbutton == 0)
         cycle <= 0;
      else
         cycle <= cycle + 1;
   end


   // timeout thread:
   initial begin
      #(pUSB_CLOCK_PERIOD*pTIMEOUT);
      errors += 1;
      $display("ERROR: global timeout");
      $display("SIMULATION FAILED (%0d errors).", errors);
      $finish;
   end


   reg read_select = 1'b0;

   reg usb_alen_del, usb_alen_del2, usb_alen_del3;
   always @(posedge clk) {usb_alen_del3, usb_alen_del2, usb_alen_del} <= {usb_alen_del2, usb_alen_del, usb_alen};
   wire usb_alen_stretched = !(!usb_alen || !usb_alen_del || !usb_alen_del2 || !usb_alen_del3);

   assign usb_data = (~usb_alen_stretched)? usb_addr :
                     (read_select)? 8'bz : usb_wdata;
   assign tio_clkin = pll_clk1;

   always @(*) begin
      if (usb_wrn == 1'b0)
         read_select = 1'b0;
      else if (usb_rdn == 1'b0)
         read_select = 1'b1;
   end

   //include "tb_cw305_reg_tasks.v"
   `include "tb_reg_tasks.v"

   always #(pUSB_CLOCK_PERIOD/2) usb_clk = !usb_clk;
   always #(pPLL_CLOCK_PERIOD/2) pll_clk1 = !pll_clk1;

   wire #1 usb_rdn_out = usb_rdn;
   wire #1 usb_wrn_out = usb_wrn;
   wire #1 usb_cen_out = usb_cen;
   wire #1 usb_trigger_out = usb_trigger;
   wire #1 usb_alen_out = usb_alen;

   wire trigger; // TODO: use it?

   cw341_top #(
      .pBYTECNT_SIZE            (pBYTECNT_SIZE)
   ) U_dut (
      .usb_clk                  (usb_clk & usb_clk_enable),
      .USB_AD                   (usb_data),
      .USB_nRD                  (usb_rdn_out),
      //.USB_nWR                  (usb_wrn_out),
      .USB_nCE                  (usb_cen_out),
      .USB_ALEn                 (usb_alen_out),
      //.usb_trigger              (usb_trigger_out),
      .USRDIP                   (usrdip),
      .USRSW0                   (pushbutton),
      .USRLED                   (led),
      .PLL_CLK1                 (pll_clk1)
      //.CWIO_IO4                 (trigger),
      //.CWIO_HS1                 (),             // unused
      //.CWIO_HS2                 (tio_clkin)
   );

   task wait_done;
      bit busy;
      busy = 1;
      while (busy == 1) begin
         //$display("checking busy...");
         read_byte(`REG_CRYPT_GO, busy);
      end
   endtask


endmodule

`default_nettype wire

