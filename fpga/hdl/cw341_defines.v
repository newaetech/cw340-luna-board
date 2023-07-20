/* 
ChipWhisperer Artix Target - Register address definitions for reference target.

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

// *** WARNING***  
// Two identical copies are maintained in this repo: 
// - one in software/chipwhisperer/capture/targets/defines/, used by CW305.py at runtime
// - one in hardware/victims/cw305_artixtarget/fpga/common/, used by Vivado when building the bitfile
// Ideally we could use a symlink but that doesn't work on Windows. There are solutions to that 
// (https://stackoverflow.com/questions/5917249/git-symlinks-in-windows) but they have their own risks.
// Since this is the only symlink candidate in this repo at this moment, it seems easier/less risky
// to deal with having two files.

// config and AES:
`define REG_CLKSETTINGS                 8'h00
`define REG_USER_LED                    8'h01
`define REG_CRYPT_TYPE                  8'h02
`define REG_CRYPT_REV                   8'h03
`define REG_IDENTIFY                    8'h04
`define REG_CRYPT_GO                    8'h05
`define REG_CRYPT_TEXTIN                8'h06
`define REG_CRYPT_CIPHERIN              8'h07
`define REG_CRYPT_TEXTOUT               8'h08
`define REG_CRYPT_CIPHEROUT             8'h09
`define REG_CRYPT_KEY                   8'h0a
`define REG_BUILDTIME                   8'h0b
`define REG_DIPS                        8'h0c
`define REG_LEDS                        8'h0d

// hyperram:
`define REG_LB_ACTION                   8'h80
`define REG_LB_DATA1                    8'h81
`define REG_LB_ADDR                     8'h82
`define REG_HYPER_STATUS                8'h83
`define REG_HYPER_RESET                 8'h84
`define REG_LB_DATA2                    8'h85
`define REG_LB_MANUAL                   8'h86
`define REG_LB_ERRORS                   8'h87
`define REG_LB_ERROR_ADDR               8'h88
`define REG_LB_STOP_ADDR                8'h89
`define REG_LB_ITERATIONS               8'h8a
`define REG_LB_CURRENT_ADDR             8'h8b

// SRAM:
`define REG_SRAM_EN                     8'h40
`define REG_SRAM_PASS                   8'h41
`define REG_SRAM_MEM_BYTES              8'h42
`define REG_SRAM_RUNS                   8'h43
`define REG_SRAM_WRITE_WAIT1            8'h44
`define REG_SRAM_WRITE_WAIT2            8'h45
`define REG_SRAM_READ_WAIT              8'h46

// XADC:
`define REG_XADC_DRP_ADDR               8'hc0
`define REG_XADC_DRP_DATA               8'hc1
`define REG_XADC_STAT                   8'hc2

