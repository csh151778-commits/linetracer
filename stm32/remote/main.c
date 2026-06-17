/**
 * STM32 리모컨 펌웨어 — 버튼 입력 → NRF24L01 TX → 차량
 *
 * ── 타겟 MCU ────────────────────────────────────────────────
 *   STM32F103C8T6 (Blue Pill), 72MHz
 *
 * ── CubeIDE/CubeMX 설정 ─────────────────────────────────────
 *   Clock: HSE 8MHz, PLL x9 → 72MHz
 *   SPI1 : Full-Duplex Master, 8-bit, CPOL=Low CPHA=1Edge, Prescaler /8
 *   GPIO PA1: Output Push-Pull (NRF CE)
 *   GPIO PA4: Output Push-Pull (NRF CSN), 초기값 HIGH
 *   GPIO PB0~PB5: Input Pull-Up (버튼)
 *
 * ── 핀 연결 ─────────────────────────────────────────────────
 *   NRF24L01 VCC → 3.3V  GND → GND
 *   CE   → PA1     CSN  → PA4
 *   SCK  → PA5     MOSI → PA7     MISO → PA6
 *
 * ── 버튼 배선 (버튼 한쪽 → GND, 반대쪽 → PBx) ──────────────
 *   PB0 : 전진  (↑)
 *   PB1 : 후진  (↓)
 *   PB2 : 좌회전(←)
 *   PB3 : 우회전(→)
 *   PB4 : 정지
 *   PB5 : 자동 (라인 추적 복귀)
 *
 * ── 동작 ────────────────────────────────────────────────────
 *   - 버튼 누름  → 해당 명령 20ms마다 연속 전송
 *   - 버튼 없음  → CMD_AUTO 전송 (자동으로 라인 추적 복귀)
 *   - 명령 변경 시 즉시 전송, 유지 시 20ms 주기 재전송
 *     (FPGA 워치독 500ms 이내에 계속 갱신)
 */

#include "main.h"
#include "nrf24l01.h"

SPI_HandleTypeDef hspi1;

// ── 명령 코드 (FPGA RF_CMD_DEC.v와 동일) ────────────────────
#define CMD_AUTO    0x00
#define CMD_STOP    0x01
#define CMD_FORWARD 0x02
#define CMD_BACK    0x03
#define CMD_LEFT    0x04
#define CMD_RIGHT   0x05

// ── 버튼 핀 정의 ─────────────────────────────────────────────
#define BTN_FWD   GPIO_PIN_0
#define BTN_BACK  GPIO_PIN_1
#define BTN_LEFT  GPIO_PIN_2
#define BTN_RIGHT GPIO_PIN_3
#define BTN_STOP  GPIO_PIN_4
#define BTN_AUTO  GPIO_PIN_5

#define BTN_ON(pin) (HAL_GPIO_ReadPin(GPIOB, (pin)) == GPIO_PIN_RESET)

// ── 내부 선언 ────────────────────────────────────────────────
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_SPI1_Init(void);

// ────────────────────────────────────────────────────────────
int main(void)
{
    HAL_Init();
    SystemClock_Config();
    MX_GPIO_Init();
    MX_SPI1_Init();

    NRF_Init(&hspi1, GPIOA, GPIO_PIN_1, GPIOA, GPIO_PIN_4);
    NRF_SetTxMode();

    uint8_t cmd      = CMD_AUTO;
    uint8_t prev_cmd = 0xFF;    // 처음 한 번은 반드시 전송
    uint32_t last_tx = 0;

    while (1) {
        // ── 버튼 우선순위: 방향 > 정지 > 자동 ──────────────
        if      (BTN_ON(BTN_FWD))   cmd = CMD_FORWARD;
        else if (BTN_ON(BTN_BACK))  cmd = CMD_BACK;
        else if (BTN_ON(BTN_LEFT))  cmd = CMD_LEFT;
        else if (BTN_ON(BTN_RIGHT)) cmd = CMD_RIGHT;
        else if (BTN_ON(BTN_STOP))  cmd = CMD_STOP;
        else if (BTN_ON(BTN_AUTO))  cmd = CMD_AUTO;
        else                         cmd = CMD_AUTO;  // 아무 버튼 없음 → 자동 복귀

        uint32_t now = HAL_GetTick();

        // 명령 변경 시 즉시 전송, 동일 명령은 20ms마다 재전송
        if (cmd != prev_cmd || (now - last_tx) >= 20) {
            NRF_SendPayload(&cmd, NRF_PAYLOAD_LEN);
            prev_cmd = cmd;
            last_tx  = now;
        }

        HAL_Delay(5);   // 5ms 루프 (버튼 응답성)
    }
}

// ── 주변장치 초기화 ──────────────────────────────────────────

void SystemClock_Config(void)
{
    RCC_OscInitTypeDef osc = {0};
    RCC_ClkInitTypeDef clk = {0};

    osc.OscillatorType = RCC_OSCILLATORTYPE_HSE;
    osc.HSEState       = RCC_HSE_ON;
    osc.HSEPredivValue = RCC_HSE_PREDIV_DIV1;
    osc.PLL.PLLState   = RCC_PLL_ON;
    osc.PLL.PLLSource  = RCC_PLLSOURCE_HSE;
    osc.PLL.PLLMUL     = RCC_PLL_MUL9;
    HAL_RCC_OscConfig(&osc);

    clk.ClockType      = RCC_CLOCKTYPE_SYSCLK | RCC_CLOCKTYPE_HCLK |
                         RCC_CLOCKTYPE_PCLK1  | RCC_CLOCKTYPE_PCLK2;
    clk.SYSCLKSource   = RCC_SYSCLKSOURCE_PLLCLK;
    clk.AHBCLKDivider  = RCC_SYSCLK_DIV1;
    clk.APB1CLKDivider = RCC_HCLK_DIV2;
    clk.APB2CLKDivider = RCC_HCLK_DIV1;
    HAL_RCC_ClockConfig(&clk, FLASH_LATENCY_2);
}

static void MX_GPIO_Init(void)
{
    GPIO_InitTypeDef gpio = {0};
    __HAL_RCC_GPIOA_CLK_ENABLE();
    __HAL_RCC_GPIOB_CLK_ENABLE();

    // PA1=CE(Low), PA4=CSN(High)
    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_1, GPIO_PIN_RESET);
    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_4, GPIO_PIN_SET);
    gpio.Pin   = GPIO_PIN_1 | GPIO_PIN_4;
    gpio.Mode  = GPIO_MODE_OUTPUT_PP;
    gpio.Speed = GPIO_SPEED_FREQ_HIGH;
    HAL_GPIO_Init(GPIOA, &gpio);

    // PB0~PB5: 버튼 입력 (내부 풀업, 버튼 누름 = LOW)
    gpio.Pin  = BTN_FWD | BTN_BACK | BTN_LEFT | BTN_RIGHT | BTN_STOP | BTN_AUTO;
    gpio.Mode = GPIO_MODE_INPUT;
    gpio.Pull = GPIO_PULLUP;
    HAL_GPIO_Init(GPIOB, &gpio);
}

static void MX_SPI1_Init(void)
{
    __HAL_RCC_SPI1_CLK_ENABLE();
    hspi1.Instance               = SPI1;
    hspi1.Init.Mode              = SPI_MODE_MASTER;
    hspi1.Init.Direction         = SPI_DIRECTION_2LINES;
    hspi1.Init.DataSize          = SPI_DATASIZE_8BIT;
    hspi1.Init.CLKPolarity       = SPI_POLARITY_LOW;
    hspi1.Init.CLKPhase          = SPI_PHASE_1EDGE;
    hspi1.Init.NSS               = SPI_NSS_SOFT;
    hspi1.Init.BaudRatePrescaler = SPI_BAUDRATEPRESCALER_8;
    hspi1.Init.FirstBit          = SPI_FIRSTBIT_MSB;
    hspi1.Init.CRCCalculation    = SPI_CRCCALCULATION_DISABLE;
    HAL_SPI_Init(&hspi1);

    GPIO_InitTypeDef gpio = {0};
    gpio.Pin   = GPIO_PIN_5 | GPIO_PIN_7;
    gpio.Mode  = GPIO_MODE_AF_PP;
    gpio.Speed = GPIO_SPEED_FREQ_HIGH;
    HAL_GPIO_Init(GPIOA, &gpio);
    gpio.Pin  = GPIO_PIN_6;
    gpio.Mode = GPIO_MODE_INPUT;
    gpio.Pull = GPIO_NOPULL;
    HAL_GPIO_Init(GPIOA, &gpio);
}

void HAL_MspInit(void) { __HAL_RCC_AFIO_CLK_ENABLE(); }
