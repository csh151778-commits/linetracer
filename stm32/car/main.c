/**
 * STM32 차량측 펌웨어 — NRF24L01 RX → UART → FPGA
 *
 * ── 타겟 MCU ────────────────────────────────────────────────
 *   STM32F103C8T6 (Blue Pill), 72MHz
 *
 * ── CubeIDE/CubeMX 설정 ─────────────────────────────────────
 *   Clock: HSE 8MHz, PLL x9 → 72MHz
 *   SPI1 : Full-Duplex Master, 8-bit, CPOL=Low CPHA=1Edge, Prescaler /8 (9MHz)
 *   USART1: Asynchronous, 115200bps, 8N1, TX only
 *   GPIO PA1: Output Push-Pull (NRF CE)
 *   GPIO PA4: Output Push-Pull (NRF CSN), 초기값 HIGH
 *
 * ── 핀 연결 ─────────────────────────────────────────────────
 *   NRF24L01          STM32
 *   VCC       →  3.3V
 *   GND       →  GND
 *   CE        →  PA1
 *   CSN       →  PA4
 *   SCK       →  PA5  (SPI1_SCK)
 *   MOSI      →  PA7  (SPI1_MOSI)
 *   MISO      →  PA6  (SPI1_MISO)
 *   IRQ       →  (미연결)
 *
 *   STM32 PA9 (USART1_TX)  →  FPGA TMD1[7] (PIN_D11)
 *
 * ── FPGA 명령 프로토콜 ───────────────────────────────────────
 *   0x00 AUTO     라인 자동 추적
 *   0x01 STOP     정지
 *   0x02 FORWARD  전진
 *   0x03 BACK     후진
 *   0x04 LEFT     좌회전 (탱크)
 *   0x05 RIGHT    우회전 (탱크)
 */

#include "main.h"
#include "nrf24l01.h"

// CubeMX가 생성하는 핸들
SPI_HandleTypeDef  hspi1;
UART_HandleTypeDef huart1;

// ── 내부 선언 ────────────────────────────────────────────────
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_SPI1_Init(void);
static void MX_USART1_UART_Init(void);

// ── Arduino 조이스틱 ASCII → FPGA 커맨드 바이트 변환 ─────────
// Arduino가 보내는 문자: 'U'=전진, 'D'=후진, 'L'=좌회전, 'R'=우회전, 'C'=중앙(자동)
//
// ※ 주의: Arduino 원본 코드의 주석이 뒤바뀌어 있음.
//   주석은 왼쪽(L)이지만 실제로 'R'을 전송, 오른쪽(R)이지만 'L'을 전송.
//   실제 테스트 후 좌우가 반대이면 여기서 'L'↔'R' 스왑.
static uint8_t ascii_to_cmd(char c) {
    switch (c) {
        case 'U': return 0x02;   // FORWARD
        case 'D': return 0x03;   // BACK
        case 'L': return 0x04;   // LEFT
        case 'R': return 0x05;   // RIGHT
        case 'C': return 0x00;   // AUTO (center → 라인 추적 복귀)
        default:  return 0x00;   // 알 수 없으면 AUTO
    }
}

// ────────────────────────────────────────────────────────────
int main(void)
{
    HAL_Init();
    SystemClock_Config();
    MX_GPIO_Init();
    MX_SPI1_Init();
    MX_USART1_UART_Init();

    NRF_Init(&hspi1, GPIOA, GPIO_PIN_1, GPIOA, GPIO_PIN_4);
    NRF_SetRxMode();

    char rf_char;
    uint8_t cmd;

    while (1) {
        if (NRF_DataReady()) {
            NRF_ReadPayload((uint8_t *)&rf_char, NRF_PAYLOAD_LEN);
            cmd = ascii_to_cmd(rf_char);
            HAL_UART_Transmit(&huart1, &cmd, 1, 10);
        }
    }
}

// ── 주변장치 초기화 ──────────────────────────────────────────

void SystemClock_Config(void)
{
    RCC_OscInitTypeDef osc = {0};
    RCC_ClkInitTypeDef clk = {0};

    // HSE 8MHz → PLL x9 → 72MHz
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
    clk.AHBCLKDivider  = RCC_SYSCLK_DIV1;    // AHB  = 72MHz
    clk.APB1CLKDivider = RCC_HCLK_DIV2;      // APB1 = 36MHz
    clk.APB2CLKDivider = RCC_HCLK_DIV1;      // APB2 = 72MHz
    HAL_RCC_ClockConfig(&clk, FLASH_LATENCY_2);
}

static void MX_GPIO_Init(void)
{
    GPIO_InitTypeDef gpio = {0};
    __HAL_RCC_GPIOA_CLK_ENABLE();

    // PA1=CE, PA4=CSN — 출력, 초기값 LOW(CE) / HIGH(CSN)
    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_1, GPIO_PIN_RESET);
    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_4, GPIO_PIN_SET);
    gpio.Pin   = GPIO_PIN_1 | GPIO_PIN_4;
    gpio.Mode  = GPIO_MODE_OUTPUT_PP;
    gpio.Speed = GPIO_SPEED_FREQ_HIGH;
    HAL_GPIO_Init(GPIOA, &gpio);
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
    hspi1.Init.BaudRatePrescaler = SPI_BAUDRATEPRESCALER_8;  // 72/8 = 9MHz
    hspi1.Init.FirstBit          = SPI_FIRSTBIT_MSB;
    hspi1.Init.CRCCalculation    = SPI_CRCCALCULATION_DISABLE;
    HAL_SPI_Init(&hspi1);

    // SPI1 GPIO: PA5=SCK, PA6=MISO, PA7=MOSI
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

static void MX_USART1_UART_Init(void)
{
    __HAL_RCC_USART1_CLK_ENABLE();
    huart1.Instance          = USART1;
    huart1.Init.BaudRate     = 115200;
    huart1.Init.WordLength   = UART_WORDLENGTH_8B;
    huart1.Init.StopBits     = UART_STOPBITS_1;
    huart1.Init.Parity       = UART_PARITY_NONE;
    huart1.Init.Mode         = UART_MODE_TX;
    huart1.Init.HwFlowCtl   = UART_HWCONTROL_NONE;
    huart1.Init.OverSampling = UART_OVERSAMPLING_16;
    HAL_UART_Init(&huart1);

    // PA9 = USART1_TX
    GPIO_InitTypeDef gpio = {0};
    gpio.Pin   = GPIO_PIN_9;
    gpio.Mode  = GPIO_MODE_AF_PP;
    gpio.Speed = GPIO_SPEED_FREQ_HIGH;
    HAL_GPIO_Init(GPIOA, &gpio);
}

// HAL이 내부적으로 호출하는 콜백
void HAL_MspInit(void) { __HAL_RCC_AFIO_CLK_ENABLE(); }
