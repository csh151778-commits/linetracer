// RF Command Decoder
// STM32 차량 펌웨어(stm32/car/main.c)가 ASCII→binary 변환 후 UART로 전달.
// FPGA는 binary 1바이트를 수신.
//
// Protocol (stm32/car/ascii_to_cmd 변환 결과):
//   0x00  AUTO     — 자동 라인 추적 (조이스틱 중립)
//   0x01  STOP     — 정지
//   0x02  FORWARD  — 전진
//   0x03  BACKWARD — 후진
//   0x04  LEFT     — 좌회전
//   0x05  RIGHT    — 우회전
module RF_CMD_DEC (
    input       CLK,
    input       RESET_N,
    input [7:0] DATA,
    input       VALID,
    output reg  TRACK,      // 1 = auto line trace, 0 = manual RF
    output reg  START,
    output reg  TURN_R,
    output reg  TURN_L,
    output reg  MANU_T,
    output reg  RF_RETURN,
    output reg  FD_BK
);

localparam CMD_AUTO    = 8'h00;
localparam CMD_STOP    = 8'h01;
localparam CMD_FORWARD = 8'h02;
localparam CMD_BACK    = 8'h03;
localparam CMD_LEFT    = 8'h04;
localparam CMD_RIGHT   = 8'h05;

// 500ms watchdog at 50MHz: if no command arrives, return to auto mode
parameter WATCHDOG_TIMEOUT = 32'd25_000_000;
reg [31:0] wd_cnt;

always @(posedge CLK or negedge RESET_N) begin
    if (!RESET_N) begin
        TRACK <= 1; START <= 0; TURN_R <= 0; TURN_L <= 0;
        MANU_T <= 0; RF_RETURN <= 0; FD_BK <= 0;
        wd_cnt <= 0;
    end else if (VALID) begin
        wd_cnt <= 0;
        case (DATA)
        CMD_AUTO: begin
            TRACK <= 1;
            START <= 0; TURN_R <= 0; TURN_L <= 0;
            MANU_T <= 0; RF_RETURN <= 0; FD_BK <= 0;
        end
        CMD_STOP: begin
            TRACK <= 0;
            START <= 0; TURN_R <= 0; TURN_L <= 0;
            MANU_T <= 0; RF_RETURN <= 0; FD_BK <= 0;
        end
        CMD_FORWARD: begin
            TRACK <= 0;
            START <= 1; TURN_R <= 0; TURN_L <= 0;
            MANU_T <= 1; RF_RETURN <= 0; FD_BK <= 0;
        end
        CMD_BACK: begin
            TRACK <= 0;
            START <= 1; TURN_R <= 0; TURN_L <= 0;
            MANU_T <= 1; RF_RETURN <= 0; FD_BK <= 1;
        end
        CMD_LEFT: begin
            TRACK <= 0;
            START <= 1; TURN_R <= 0; TURN_L <= 1;
            MANU_T <= 1; RF_RETURN <= 0; FD_BK <= 0;
        end
        CMD_RIGHT: begin
            TRACK <= 0;
            START <= 1; TURN_R <= 1; TURN_L <= 0;
            MANU_T <= 1; RF_RETURN <= 0; FD_BK <= 0;
        end
        endcase
    end else begin
        // Watchdog: RF 연결 끊기면 자동 라인 추적으로 복귀
        if (wd_cnt < WATCHDOG_TIMEOUT)
            wd_cnt <= wd_cnt + 1;
        else begin
            TRACK <= 1; START <= 0; TURN_R <= 0; TURN_L <= 0;
            MANU_T <= 0; RF_RETURN <= 0; FD_BK <= 0;
        end
    end
end

endmodule
