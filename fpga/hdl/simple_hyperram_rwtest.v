/* 
Copyright (c) 2023, NewAE Technology Inc.
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


module simple_hyperram_rwtest (
    input wire                          clk,
    input wire                          reset,
    input wire                          active_usb,
    input wire                          clear_fail,
    input wire                          check1,
    input wire                          check2,
    input wire                          lfsr_mode,
    output reg                          pass,
    output reg                          fail,
    output reg  [15:0]                  iteration,
    output wire [31:0]                  current_addr,
    output reg  [31:0]                  total_errors,
    output reg  [31:0]                  error_addr,
    input  wire [31:0]                  addr_stop,

    output wire                         lb1_wr,
    output wire                         lb1_rd,
    output wire [31:0]                  lb1_addr,
    output reg  [31:0]                  lb1_wr_d,
    input  wire [31:0]                  lb1_rd_d,
    input  wire                         lb1_rd_rdy,
    input  wire                         hr1_busy,
    output reg                          hr1_busy_stuck,

    output wire                         lb2_wr,
    output wire                         lb2_rd,
    output wire [31:0]                  lb2_addr,
    output reg  [31:0]                  lb2_wr_d,
    input  wire [31:0]                  lb2_rd_d,
    input  wire                         lb2_rd_rdy,
    input  wire                         hr2_busy,
    output reg                          hr2_busy_stuck

);

localparam pS_IDLE            = 3'd0;
localparam pS_SET_ADDR        = 3'd1;
localparam pS_SET_DATA        = 3'd2;
localparam pS_WRITE           = 3'd3;
localparam pS_WAIT_NOT_BUSY   = 3'd4;
localparam pS_READ            = 3'd5;
localparam pS_WAIT_RDATA      = 3'd6;
localparam pS_CHECK_RDATA     = 3'd7;
reg [2:0] state, next_state;

reg reset_address;
reg incr_address;
reg incr_iteration;
reg load_lfsr;
reg [31:0] lfsr;

wire [31:0] bitflips = 32'h1234_5678;
wire [31:0] expected_data1 = (lfsr_mode)? lfsr ^ haddr : lfsr;
wire [31:0] expected_data2 = (lfsr_mode)? lfsr ^ haddr ^ bitflips : lfsr;

reg writing;

reg        lb_wr;
reg        lb_rd;
reg [31:0] lb_addr;
reg [31:0] lb1_rd_d_r;
reg [31:0] lb2_rd_d_r;
reg        lb1_rd_rdy_r;
reg        lb2_rd_rdy_r;

assign lb1_wr           = lb_wr;
assign lb1_rd           = lb_rd;
assign lb1_addr         = lb_addr;

assign lb2_wr           = lb_wr;
assign lb2_rd           = lb_rd;
assign lb2_addr         = lb_addr;

assign current_addr = haddr;

// since "active" controls FSM states, let's sync it properly:
(* ASYNC_REG = "TRUE" *) reg[2:0] active_pipe;
reg active;
always @ (posedge clk) begin
    if (reset) begin
        active_pipe <= 0;
        active <= 0;
    end 
    else begin
        {active, active_pipe} <= {active_pipe, active_usb};
    end 
end


reg [31:0] haddr = 32'b0;
reg [1:0] errors;
reg set_write_mode;
reg set_read_mode;
reg [2:0] wait_count;
reg restart_wait_count;

// FSM issues write command + data, read command:
always @(*) begin
    // defaults:
    reset_address = 0;
    incr_address = 0;
    incr_iteration = 0;
    load_lfsr = 0;
    lb_wr = 0;
    lb_rd = 0;
    lb1_wr_d = 0;
    lb2_wr_d = 0;
    set_write_mode = 0;
    set_read_mode = 0;
    errors = 0;
    restart_wait_count = 1'b0;
    lb_addr = 0;

    case (state)
        pS_IDLE: begin
            if (~active)
                next_state = pS_IDLE;
            else begin
                reset_address = 1'b1;
                load_lfsr = 1'b1;
                set_write_mode = 1'b1;
                next_state = pS_SET_ADDR;
            end
        end

        pS_SET_ADDR: begin
            lb_addr = 32'h10;
            lb1_wr_d = haddr;
            lb2_wr_d = haddr;
            lb_wr = 1'b1;
            if (writing)
                next_state = pS_SET_DATA;
            else
                next_state = pS_READ;
        end

        pS_SET_DATA: begin
            lb_addr = 32'h14;
            lb1_wr_d = expected_data1;
            lb2_wr_d = expected_data2;
            lb_wr = 1'b1;
            next_state = pS_WRITE;
        end

        pS_WRITE: begin
            lb_addr = 32'h1c;
            lb1_wr_d = 32'h1;
            lb2_wr_d = 32'h1;
            lb_wr = 1'b1;
            restart_wait_count = 1'b1;
            next_state = pS_WAIT_NOT_BUSY;
        end

        pS_WAIT_NOT_BUSY: begin
            if (~active)
                next_state = pS_IDLE;
            // it takes a few cycles for busy to assert, so wait a bit before acting on it:
            else if (hr1_busy || hr2_busy || wait_count < 4)
                next_state = pS_WAIT_NOT_BUSY;
            else if (haddr == addr_stop) begin
                reset_address = 1'b1;
                set_read_mode = 1'b1;
                load_lfsr = 1'b1;
                next_state = pS_SET_ADDR;
            end
            else begin
                incr_address = 1'b1;
                next_state = pS_SET_ADDR;
            end
        end

        pS_READ: begin
            lb_addr = 32'h1c;
            lb1_wr_d = 32'h4;
            lb2_wr_d = 32'h4;
            lb_wr = 1'b1;
            restart_wait_count = 1'b1;
            next_state = pS_WAIT_RDATA;
        end

        pS_WAIT_RDATA: begin
            if (~active)
                next_state = pS_IDLE;
            // it takes a few cycles for busy to assert, so wait a bit before acting on it:
            else if (hr1_busy || hr2_busy || wait_count < 4)
                next_state = pS_WAIT_RDATA;
            else begin
                lb_addr = 32'h14;
                lb_rd = 1'b1;
                next_state = pS_CHECK_RDATA;
            end
        end

        pS_CHECK_RDATA: begin
            if (~active)
                next_state = pS_IDLE;
            else if (lb1_rd_rdy_r && lb2_rd_rdy_r) begin
                if ( (~check1 || (lb1_rd_d_r == expected_data1)) &&
                     (~check2 || (lb2_rd_d_r == expected_data2)) )
                    errors = 0;
                else if (check1 && check2 && (lb1_rd_d_r != expected_data1) && (lb2_rd_d_r != expected_data2))
                    errors = 2;
                else
                    errors = 1;
                if (haddr == addr_stop) begin
                    reset_address = 1'b1;
                    set_write_mode = 1'b1;
                    incr_iteration = 1'b1;
                    //load_lfsr = 1'b1;
                    //next_state = pS_SET_ADDR;
                    next_state = pS_IDLE;
                end
                else begin
                    incr_address = 1'b1;
                    next_state = pS_SET_ADDR;
                end
            end
            else
                next_state = pS_CHECK_RDATA;
        end

    endcase

end


// sequential logic controlled by FSM + verify read data:
always @ (posedge clk) begin
    if (reset) begin
        state <= pS_IDLE;
        haddr <= 0;
        iteration <= 0;
        pass <= 0;
        fail <= 0;
        total_errors <= 0;
        error_addr <= 0;
        writing <= 1'b0;
    end

    else begin
        state <= next_state;

        if (clear_fail) 
            total_errors <= 0;
        else
            total_errors <= total_errors + errors;

        if (state == pS_READ) begin
            lb1_rd_rdy_r <= 1'b0;
            lb2_rd_rdy_r <= 1'b0;
        end
        else  begin
            if (lb1_rd_rdy) begin
                lb1_rd_d_r <= lb1_rd_d;
                lb1_rd_rdy_r <= 1'b1;
            end
            if (lb2_rd_rdy) begin
                lb2_rd_d_r <= lb2_rd_d;
                lb2_rd_rdy_r <= 1'b1;
            end
        end

        if (restart_wait_count)
            wait_count <= 0;
        else
            wait_count <= wait_count + 1;

        if (set_write_mode)
            writing <= 1'b1;
        else if (set_read_mode)
            writing <= 1'b0;

        if (reset_address)
            haddr <= 0;
        else begin
            if (incr_address)
                haddr <= haddr + 1;
        end

        if (~active)
            iteration <= 0;
        else if (incr_iteration)
            iteration <= iteration + 1;

        if (!active | clear_fail)
            pass <= 1'b0;
        else if (errors > 0)
            pass <= 1'b0;
        else if (incr_iteration & !fail & |lfsr)
            pass <= 1'b1;

        if (clear_fail) begin
            fail <= 1'b0;
            error_addr <= 0;
        end
        else if (errors > 0) begin
            fail <= 1'b1;
            if (total_errors == 0)
                error_addr <= haddr;
        end
    end
end

always @ (posedge clk) begin
    if (reset) begin
        lfsr <= 0;
    end
    else begin
        if (load_lfsr)
            lfsr <= {iteration, ~iteration};
        else if (state == pS_SET_ADDR)
            if (lfsr_mode)
                lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
            else
                lfsr <= lfsr + 1;
    end
end

// detect busy being stuck high for > 100 cycles:
reg [7:0] hr1_busy_count;
reg [7:0] hr2_busy_count;
always @ (posedge clk) begin
    if (!hr1_busy) begin
        hr1_busy_stuck <= 1'b0;
        hr1_busy_count <= 0;
    end
    else if (hr1_busy_count < 100)
        hr1_busy_count <= hr1_busy_count + 1;
    else
        hr1_busy_stuck <= 1'b1;

    if (!hr2_busy) begin
        hr2_busy_stuck <= 1'b0;
        hr2_busy_count <= 0;
    end
    else if (hr2_busy_count < 100)
        hr2_busy_count <= hr2_busy_count + 1;
    else
        hr2_busy_stuck <= 1'b1;
end

`ifdef ILA_HYPERRAM_TEST
ila_hyperram_test U_ila_hyperram_test (
	.clk            (clk                ),
	.probe0         (active             ),
	.probe1         (pass               ),
	.probe2         (fail               ),
	.probe3         (state              ), // 2:0
	.probe4         (iteration          ), // 15:0
	.probe5         (errors             ), // 1:0
	.probe6         (total_errors       ), // 31:0
	.probe7         (expected_data1     ), // 31:0
	.probe8         (expected_data2     ), // 31:0
	.probe9         (lb1_rd_rdy         ),
	.probe10        (lb2_rd_rdy         ),
	.probe11        (lb1_rd_d_r         ), // 31:0
	.probe12        (lb2_rd_d_r         ), // 31:0
	.probe13        (writing            ),
        .probe14        (lfsr               ), // 31:0
        .probe15        (lb1_rd_rdy_r       ),
        .probe16        (lb2_rd_rdy_r       ),
        .probe17        (lb1_wr             ),
        .probe18        (lb1_rd             ),
        .probe19        (lb1_addr           ), // 31:0
        .probe20        (lb1_wr_d           ), // 31:0
        .probe21        (lb1_rd_d           ), // 31:0
        .probe22        (hr1_busy           ),
        .probe23        (haddr              ), // 31:0
        .probe24        (hr1_busy_stuck     ),
        .probe25        (hr2_busy_stuck     )
);
`endif

endmodule

`default_nettype wire

