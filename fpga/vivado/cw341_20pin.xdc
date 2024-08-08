# default unless otherwise specified:
set_property IOSTANDARD LVCMOS18 [get_ports *]

set_property -dict { PACKAGE_PIN C24   IOSTANDARD LVCMOS18 } [get_ports { usb_clk }]; # labeled /USB_RD on schematic

set_property -dict { PACKAGE_PIN AM34  IOSTANDARD   LVCMOS18 } [get_ports { USB_ALEn }];  # NOTE: using USB_SPI_CS; needs jumper between J23 and J24
set_property -dict { PACKAGE_PIN  C23  IOSTANDARD   LVCMOS18 } [get_ports { USB_nRD   }]; # labeled /USB_RD on schematic
set_property -dict { PACKAGE_PIN  D23  IOSTANDARD   LVCMOS18 } [get_ports { USB_nCE   }]; # labeled /USB_CE on schematic

set_property -dict { PACKAGE_PIN  P20  IOSTANDARD   LVCMOS18 } [get_ports { USB_AD[0]  }];
set_property -dict { PACKAGE_PIN  P21  IOSTANDARD   LVCMOS18 } [get_ports { USB_AD[1]  }];
set_property -dict { PACKAGE_PIN  N22  IOSTANDARD   LVCMOS18 } [get_ports { USB_AD[2]  }];
set_property -dict { PACKAGE_PIN  M22  IOSTANDARD   LVCMOS18 } [get_ports { USB_AD[3]  }];
set_property -dict { PACKAGE_PIN  R23  IOSTANDARD   LVCMOS18 } [get_ports { USB_AD[4]  }];
set_property -dict { PACKAGE_PIN  P23  IOSTANDARD   LVCMOS18 } [get_ports { USB_AD[5]  }];
set_property -dict { PACKAGE_PIN  R25  IOSTANDARD   LVCMOS18 } [get_ports { USB_AD[6]  }];
set_property -dict { PACKAGE_PIN  R26  IOSTANDARD   LVCMOS18 } [get_ports { USB_AD[7]  }];

#$set_property -dict { PACKAGE_PIN  M20  IOSTANDARD   LVCMOS18 } [get_ports { USB_D[4]  }];
#$set_property -dict { PACKAGE_PIN  L20  IOSTANDARD   LVCMOS18 } [get_ports { USB_D[5]  }];
#$set_property -dict { PACKAGE_PIN  R21  IOSTANDARD   LVCMOS18 } [get_ports { USB_D[6]  }];
#$set_property -dict { PACKAGE_PIN  R22  IOSTANDARD   LVCMOS18 } [get_ports { USB_D[7]  }];

set_property -dict { PACKAGE_PIN AH32  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[0] }]; # OT_IOR6
set_property -dict { PACKAGE_PIN AJ33  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[1] }]; # OT_IOR7
set_property -dict { PACKAGE_PIN AH34  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[2] }]; # OT_IOR8
set_property -dict { PACKAGE_PIN AH31  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[3] }]; # OT_IOR9
set_property -dict { PACKAGE_PIN AH27  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[4] }]; # OT_IOR10
set_property -dict { PACKAGE_PIN AH33  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[5] }]; # OT_IOR11
set_property -dict { PACKAGE_PIN AH28  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[6] }]; # OT_IOR12
set_property -dict { PACKAGE_PIN AH26  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[7] }]; # OT_IOR13


#set_property -dict { PACKAGE_PIN AM10  IOSTANDARD   LVCMOS18 } [get_ports { USRDIP[0] }]; # OT_IOB6 NB: USRDIP[0:6] are in bank 64 with CW 20-pin signals and must be set to the same voltage as those
#set_property -dict { PACKAGE_PIN AP10  IOSTANDARD   LVCMOS18 } [get_ports { USRDIP[1] }]; # OT_IOB7
#set_property -dict { PACKAGE_PIN AL9   IOSTANDARD   LVCMOS18 } [get_ports { USRDIP[2] }]; # OT_IOB8
#set_property -dict { PACKAGE_PIN AP11  IOSTANDARD   LVCMOS18 } [get_ports { USRDIP[3] }]; # OT_IOB9
#set_property -dict { PACKAGE_PIN AM12  IOSTANDARD   LVCMOS18 } [get_ports { USRDIP[4] }]; # OT_IOB10
#set_property -dict { PACKAGE_PIN AN11  IOSTANDARD   LVCMOS18 } [get_ports { USRDIP[5] }]; # OT_IOB11
#set_property -dict { PACKAGE_PIN AN12  IOSTANDARD   LVCMOS18 } [get_ports { USRDIP[6] }]; # OT_IOB12
#set_property -dict { PACKAGE_PIN AK30  IOSTANDARD   LVCMOS18 } [get_ports { USRDIP[7] }]; # OT_IOR5 NB: cannot be 3.3V


set_property -dict { PACKAGE_PIN AC31  IOSTANDARD   LVCMOS18 } [get_ports { OT_PORN }];
set_property -dict { PACKAGE_PIN  E23  IOSTANDARD   LVCMOS18 } [get_ports { USRSW0 }]; # USR_DBG_nRST
#set_property -dict { PACKAGE_PIN  Y10  IOSTANDARD   LVCMOS18 } [get_ports { USRSW1 }]; # ???


set_property -dict { PACKAGE_PIN AK12  IOSTANDARD   LVCMOS33 } [get_ports { CWIO_HS1 }]; 
set_property -dict { PACKAGE_PIN AL12  IOSTANDARD   LVCMOS33 } [get_ports { CWIO_HS2 }]; 
#set_property -dict { PACKAGE_PIN AL10  IOSTANDARD   LVCMOS33 } [get_ports { CWIO_IO1 }];   # OT_IOB4
#set_property -dict { PACKAGE_PIN AN9   IOSTANDARD   LVCMOS33 } [get_ports { CWIO_IO2 }];   # OT_IOB5
#set_property -dict { PACKAGE_PIN AM10  IOSTANDARD   LVCMOS33 } [get_ports { CWIO_IO3 }];   # OT_IOB6
set_property -dict { PACKAGE_PIN AM11  IOSTANDARD   LVCMOS33 } [get_ports { CWIO_IO4 }]; 
#set_property -dict { PACKAGE_PIN AN11  IOSTANDARD   LVCMOS33 } [get_ports { CWIO_MISO }];  # OT_IOB11
#set_property -dict { PACKAGE_PIN AN12  IOSTANDARD   LVCMOS33 } [get_ports { CWIO_MOSI }];  # OT_IOB12
#set_property -dict { PACKAGE_PIN  Y20  IOSTANDARD   LVCMOS33 } [get_ports { CWIO_RST }];   # ???
#set_property -dict { PACKAGE_PIN AP13  IOSTANDARD   LVCMOS33 } [get_ports { CWIO_TPDIC }]; # PMOD2_IO7_3V3
#set_property -dict { PACKAGE_PIN AL13  IOSTANDARD   LVCMOS33 } [get_ports { CWIO_TPDID }]; # PMOD2_IO8_3V3


set_property IOSTANDARD ANALOG [get_ports { vauxp0 }]; 
set_property IOSTANDARD ANALOG [get_ports { vauxn0 }]; 
set_property IOSTANDARD ANALOG [get_ports { vauxp1 }]; 
set_property IOSTANDARD ANALOG [get_ports { vauxn1 }]; 
set_property IOSTANDARD ANALOG [get_ports { vauxp8 }]; 
set_property IOSTANDARD ANALOG [get_ports { vauxn8 }]; 
set_property IOSTANDARD ANALOG [get_ports { vauxp12 }]; 
set_property IOSTANDARD ANALOG [get_ports { vauxn12 }]; 


set_property -dict { PACKAGE_PIN  AJ29 IOSTANDARD   LVCMOS18 } [get_ports { PLL_CLK1 }];
set_property -dict { PACKAGE_PIN  AN29 IOSTANDARD   LVCMOS18 } [get_ports { PLL_CLK2_ORIG }];
set_property -dict { PACKAGE_PIN  E22  IOSTANDARD   LVCMOS18 } [get_ports { PLL_CLK2_ALT }];

set_property -dict { PACKAGE_PIN  F17  IOSTANDARD   LVCMOS18 } [get_ports { hypr1_dq[0] }];
set_property -dict { PACKAGE_PIN  D18  IOSTANDARD   LVCMOS18 } [get_ports { hypr1_dq[1] }];
set_property -dict { PACKAGE_PIN  D16  IOSTANDARD   LVCMOS18 } [get_ports { hypr1_dq[2] }];
set_property -dict { PACKAGE_PIN  E17  IOSTANDARD   LVCMOS18 } [get_ports { hypr1_dq[3] }];
set_property -dict { PACKAGE_PIN  G19  IOSTANDARD   LVCMOS18 } [get_ports { hypr1_dq[4] }];
set_property -dict { PACKAGE_PIN  H17  IOSTANDARD   LVCMOS18 } [get_ports { hypr1_dq[5] }];
set_property -dict { PACKAGE_PIN  D19  IOSTANDARD   LVCMOS18 } [get_ports { hypr1_dq[6] }];
set_property -dict { PACKAGE_PIN  E18  IOSTANDARD   LVCMOS18 } [get_ports { hypr1_dq[7] }];

set_property -dict { PACKAGE_PIN  E16  IOSTANDARD   LVCMOS18 } [get_ports { hypr1_rwds }];
set_property -dict { PACKAGE_PIN  G15  IOSTANDARD   LVDS     } [get_ports { hypr1_ckp }];
set_property -dict { PACKAGE_PIN  G14  IOSTANDARD   LVDS     } [get_ports { hypr1_ckn }];
set_property -dict { PACKAGE_PIN  G16  IOSTANDARD   LVCMOS18 } [get_ports { hypr1_rst_l }];
set_property -dict { PACKAGE_PIN  F15  IOSTANDARD   LVCMOS18 } [get_ports { hypr1_cs_l }];


set_property -dict { PACKAGE_PIN  K18  IOSTANDARD   LVCMOS18 } [get_ports { hypr2_dq[0] }];
set_property -dict { PACKAGE_PIN  J14  IOSTANDARD   LVCMOS18 } [get_ports { hypr2_dq[1] }];
set_property -dict { PACKAGE_PIN  L15  IOSTANDARD   LVCMOS18 } [get_ports { hypr2_dq[2] }];
set_property -dict { PACKAGE_PIN  J19  IOSTANDARD   LVCMOS18 } [get_ports { hypr2_dq[3] }];
set_property -dict { PACKAGE_PIN  H19  IOSTANDARD   LVCMOS18 } [get_ports { hypr2_dq[4] }];
set_property -dict { PACKAGE_PIN  K17  IOSTANDARD   LVCMOS18 } [get_ports { hypr2_dq[5] }];
set_property -dict { PACKAGE_PIN  J15  IOSTANDARD   LVCMOS18 } [get_ports { hypr2_dq[6] }];
set_property -dict { PACKAGE_PIN  J18  IOSTANDARD   LVCMOS18 } [get_ports { hypr2_dq[7] }];

set_property -dict { PACKAGE_PIN  K15  IOSTANDARD   LVCMOS18 } [get_ports { hypr2_rwds }];
set_property -dict { PACKAGE_PIN  K16  IOSTANDARD   LVDS     } [get_ports { hypr2_ckp }];
set_property -dict { PACKAGE_PIN  J16  IOSTANDARD   LVDS     } [get_ports { hypr2_ckn }];
set_property -dict { PACKAGE_PIN  L19  IOSTANDARD   LVCMOS18 } [get_ports { hypr2_rst_l }];
set_property -dict { PACKAGE_PIN  L18  IOSTANDARD   LVCMOS18 } [get_ports { hypr2_cs_l }];

#####
# SDRAM - 1.8V Only
set_property -dict { PACKAGE_PIN AE21  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[0]  }];
set_property -dict { PACKAGE_PIN AD20  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[1]  }];
set_property -dict { PACKAGE_PIN AD21  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[2]  }];
set_property -dict { PACKAGE_PIN AF23  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[3]  }];
set_property -dict { PACKAGE_PIN AF24  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[4]  }];
set_property -dict { PACKAGE_PIN AH24  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[5]  }];
set_property -dict { PACKAGE_PIN AK21  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[6]  }];
set_property -dict { PACKAGE_PIN AP20  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[7]  }];
set_property -dict { PACKAGE_PIN AP24  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[8]  }];
set_property -dict { PACKAGE_PIN AN23  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[9]  }];
set_property -dict { PACKAGE_PIN AJ24  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[10] }];
set_property -dict { PACKAGE_PIN AL25  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[11] }];
set_property -dict { PACKAGE_PIN AE23  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[12] }];
set_property -dict { PACKAGE_PIN AK20  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[13] }];
set_property -dict { PACKAGE_PIN AP21  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[14] }];
set_property -dict { PACKAGE_PIN AM20  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[15] }];
set_property -dict { PACKAGE_PIN AH22  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[16] }];
set_property -dict { PACKAGE_PIN AJ25  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[17] }];
set_property -dict { PACKAGE_PIN AL24  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_A[18] }];

set_property -dict { PACKAGE_PIN AE26  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_LBn }];
set_property -dict { PACKAGE_PIN AG25  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_UBn }];
set_property -dict { PACKAGE_PIN AG24  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_CS1n }];
set_property -dict { PACKAGE_PIN AE25  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_OEn }];
set_property -dict { PACKAGE_PIN AJ20  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_WEn }];

set_property -dict { PACKAGE_PIN AE20  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_DQ[0] }];
set_property -dict { PACKAGE_PIN AF22  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_DQ[1] }];
set_property -dict { PACKAGE_PIN AF20  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_DQ[2] }];
set_property -dict { PACKAGE_PIN AG22  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_DQ[3] }];
set_property -dict { PACKAGE_PIN AG20  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_DQ[4] }];
set_property -dict { PACKAGE_PIN AH23  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_DQ[5] }];
set_property -dict { PACKAGE_PIN AH21  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_DQ[6] }];
set_property -dict { PACKAGE_PIN AL20  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_DQ[7] }];
set_property -dict { PACKAGE_PIN AL23  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_DQ[8] }];
set_property -dict { PACKAGE_PIN AP23  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_DQ[9] }];
set_property -dict { PACKAGE_PIN AJ23  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_DQ[10] }];
set_property -dict { PACKAGE_PIN AN22  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_DQ[11] }];
set_property -dict { PACKAGE_PIN AL22  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_DQ[12] }];
set_property -dict { PACKAGE_PIN AM21  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_DQ[13] }];
set_property -dict { PACKAGE_PIN AN21  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_DQ[14] }];
set_property -dict { PACKAGE_PIN AK22  IOSTANDARD   LVCMOS18 } [get_ports { SRAM_DQ[15] }];

set_property PULLTYPE PULLUP [get_ports USRSW0]
set_property PULLTYPE PULLUP [get_ports OT_PORN]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {U_clocks/clkibuf_usb/O}]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets U_clocks/clkibuf_hs2/O]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets U_clocks/clkibuf_pll2/O]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets U_clocks/clkibuf_pll2_orig/O]
set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets U_clocks/pll2_clk]

# clocks:
create_clock -period 10.000 -name usb_clk -waveform {0.000 5.000} [get_nets usb_clk]
create_clock -period 10.000 -name CWIO_HS2 -waveform {0.000 5.000} [get_nets CWIO_HS2]
#create_clock -period 10.000 -name PLL_CLK1 -waveform {0.000 5.000} [get_nets PLL_CLK1]
set PLL_CLK1_HALF_PERIOD 8.0000
create_clock -period [expr 2*$PLL_CLK1_HALF_PERIOD] -name PLL_CLK1 -waveform "0.000 ${PLL_CLK1_HALF_PERIOD}" [get_nets PLL_CLK1]

# input clocks have same properties so there is no point in doing timing analysis for all of them:
set_case_analysis 0 [get_pins U_clocks/CCLK_MUX0/S]
set_case_analysis 0 [get_pins U_clocks/CCLK_MUX1/S]
set_case_analysis 0 [get_pins U_clocks/CCLK_MUX2/S]

# No spec for these, seems sensible:
set_input_delay -clock usb_clk -add_delay 2.000 [get_ports USB_AD]
set_input_delay -clock usb_clk -add_delay 2.000 [get_ports USB_nCE]
set_input_delay -clock usb_clk -add_delay 2.000 [get_ports USB_nRD]

#set_input_delay -clock usb_clk -add_delay 0.000 [get_ports USRDIP]
set_input_delay -clock [get_clocks usb_clk] -add_delay 0.500 [get_ports USRSW0]

set_output_delay -clock usb_clk 0.000 [get_ports USRLED]
set_output_delay -clock usb_clk 0.000 [get_ports CWIO_IO4]
set_output_delay -clock usb_clk 0.000 [get_ports CWIO_HS1]

set_false_path -to [get_ports USRLED]
set_false_path -to [get_ports CWIO_IO4]
set_false_path -to [get_ports CWIO_HS1]

#create_generated_clock -name HYPR1_CKOUT -combinational -source [get_pins U_hyperram_wrapper/U_OBUFDS_hypr1_clk_out/O] [get_ports hypr1_ckp]
#create_generated_clock -name HYPR2_CKOUT -combinational -source [get_pins U_hyperram_wrapper/U_OBUFDS_hypr2_clk_out/O] [get_ports hypr2_ckp]

set imax  0.500
set imin -0.500
set omax  0.500
set omin -0.500

# input is system synchronous
set_input_delay -clock PLL_CLK1 -max [expr $PLL_CLK1_HALF_PERIOD + $imax]  [get_ports { hypr1_dq hypr1_rwds }]
set_input_delay -clock PLL_CLK1 -min [expr $PLL_CLK1_HALF_PERIOD - $imin]  [get_ports { hypr1_dq hypr1_rwds }]
set_input_delay -clock PLL_CLK1 -max [expr $PLL_CLK1_HALF_PERIOD + $imax]  [get_ports { hypr1_dq hypr1_rwds }] -clock_fall -add_delay
set_input_delay -clock PLL_CLK1 -min [expr $PLL_CLK1_HALF_PERIOD - $imin]  [get_ports { hypr1_dq hypr1_rwds }] -clock_fall -add_delay

set_input_delay -clock PLL_CLK1 -max [expr $PLL_CLK1_HALF_PERIOD + $imax]  [get_ports { hypr2_dq hypr2_rwds }]
set_input_delay -clock PLL_CLK1 -min [expr $PLL_CLK1_HALF_PERIOD - $imin]  [get_ports { hypr2_dq hypr2_rwds }]
set_input_delay -clock PLL_CLK1 -max [expr $PLL_CLK1_HALF_PERIOD + $imax]  [get_ports { hypr2_dq hypr2_rwds }] -clock_fall -add_delay
set_input_delay -clock PLL_CLK1 -min [expr $PLL_CLK1_HALF_PERIOD - $imin]  [get_ports { hypr2_dq hypr2_rwds }] -clock_fall -add_delay


# output is source synchronous
set_output_delay -clock PLL_CLK1 -max $omax  [get_ports { hypr1_dq hypr1_rwds hypr1_cs_l }]
set_output_delay -clock PLL_CLK1 -min $omin  [get_ports { hypr1_dq hypr1_rwds hypr1_cs_l }]
set_output_delay -clock PLL_CLK1 -max $omax  [get_ports { hypr1_dq hypr1_rwds hypr1_cs_l }] -clock_fall -add_delay
set_output_delay -clock PLL_CLK1 -min $omin  [get_ports { hypr1_dq hypr1_rwds hypr1_cs_l }] -clock_fall -add_delay

set_output_delay -clock PLL_CLK1 -max $omax  [get_ports { hypr2_dq hypr2_rwds hypr2_cs_l }]
set_output_delay -clock PLL_CLK1 -min $omin  [get_ports { hypr2_dq hypr2_rwds hypr2_cs_l }]
set_output_delay -clock PLL_CLK1 -max $omax  [get_ports { hypr2_dq hypr2_rwds hypr2_cs_l }] -clock_fall -add_delay
set_output_delay -clock PLL_CLK1 -min $omin  [get_ports { hypr2_dq hypr2_rwds hypr2_cs_l }] -clock_fall -add_delay


set_clock_groups -asynchronous \
                 -group [get_clocks usb_clk ] \
                 -group [get_clocks CWIO_HS2 ]

set_clock_groups -asynchronous \
                 -group [get_clocks PLL_CLK1 ] \
                 -group [get_clocks CWIO_HS2 ]

set_clock_groups -asynchronous \
                 -group [get_clocks PLL_CLK1 ] \
                 -group [get_clocks usb_clk ]


set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets usb_clk_buf]
