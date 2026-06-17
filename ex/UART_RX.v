// 8N1 UART Receiver — 50MHz clock, 115200bps
// Baud divisor: 50_000_000 / 115_200 = 434
module UART_RX (
    input        CLK,
    input        RESET_N,
    input        RXD,
    output reg [7:0] DATA,
    output reg   VALID
);

parameter BAUD_DIV = 434;
parameter HALF_DIV = 217;

// 2-FF metastability synchronizer
reg rxd_s1, rxd_s2;
always @(posedge CLK) begin
    rxd_s1 <= RXD;
    rxd_s2 <= rxd_s1;
end

reg [8:0] cnt;
reg [2:0] bit_idx;
reg [7:0] shift;
reg [1:0] state;

localparam IDLE  = 2'd0;
localparam START = 2'd1;
localparam DATA  = 2'd2;
localparam STOP  = 2'd3;

always @(posedge CLK or negedge RESET_N) begin
    if (!RESET_N) begin
        state   <= IDLE;
        VALID   <= 0;
        cnt     <= 0;
        bit_idx <= 0;
    end else begin
        VALID <= 0;
        case (state)
        IDLE: begin
            if (!rxd_s2) begin          // start bit falling edge
                cnt   <= 1;
                state <= START;
            end
        end
        START: begin
            if (cnt == HALF_DIV) begin  // sample middle of start bit
                cnt <= 1;
                if (!rxd_s2) begin
                    bit_idx <= 0;
                    state   <= DATA;
                end else
                    state <= IDLE;      // glitch — discard
            end else
                cnt <= cnt + 1;
        end
        DATA: begin
            if (cnt == BAUD_DIV) begin  // one full baud period per bit
                cnt   <= 1;
                shift <= {rxd_s2, shift[7:1]};  // LSB first
                if (bit_idx == 7)
                    state <= STOP;
                else
                    bit_idx <= bit_idx + 1;
            end else
                cnt <= cnt + 1;
        end
        STOP: begin
            if (cnt == BAUD_DIV) begin
                cnt   <= 0;
                state <= IDLE;
                if (rxd_s2) begin       // valid stop bit
                    DATA  <= shift;
                    VALID <= 1;
                end
            end else
                cnt <= cnt + 1;
        end
        endcase
    end
end

endmodule
