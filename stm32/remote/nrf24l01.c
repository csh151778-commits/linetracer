#include "nrf24l01.h"

// 차량 ↔ 리모컨 공유 주소 (5바이트, 양쪽 동일)
static const uint8_t NRF_ADDR[5] = {0x34, 0x43, 0x10, 0x10, 0x01};

static SPI_HandleTypeDef *_spi;
static GPIO_TypeDef *_ce_port, *_csn_port;
static uint16_t     _ce_pin,   _csn_pin;

// ── 내부 헬퍼 ────────────────────────────────────────────────
static void CE_H (void) { HAL_GPIO_WritePin(_ce_port,  _ce_pin,  GPIO_PIN_SET);   }
static void CE_L (void) { HAL_GPIO_WritePin(_ce_port,  _ce_pin,  GPIO_PIN_RESET); }
static void CSN_H(void) { HAL_GPIO_WritePin(_csn_port, _csn_pin, GPIO_PIN_SET);   }
static void CSN_L(void) { HAL_GPIO_WritePin(_csn_port, _csn_pin, GPIO_PIN_RESET); }

static uint8_t spi_xfer(uint8_t byte) {
    uint8_t rx;
    HAL_SPI_TransmitReceive(_spi, &byte, &rx, 1, 100);
    return rx;
}

static uint8_t read_reg(uint8_t reg) {
    CSN_L();
    spi_xfer(NRF_R_REG | (reg & 0x1F));
    uint8_t val = spi_xfer(NRF_NOP);
    CSN_H();
    return val;
}

static void write_reg(uint8_t reg, uint8_t val) {
    CSN_L();
    spi_xfer(NRF_W_REG | (reg & 0x1F));
    spi_xfer(val);
    CSN_H();
}

static void write_addr(uint8_t reg, const uint8_t *addr) {
    CSN_L();
    spi_xfer(NRF_W_REG | (reg & 0x1F));
    for (int i = 0; i < 5; i++) spi_xfer(addr[i]);
    CSN_H();
}

static void flush_rx(void) { CSN_L(); spi_xfer(NRF_FLUSH_RX); CSN_H(); }
static void flush_tx(void) { CSN_L(); spi_xfer(NRF_FLUSH_TX); CSN_H(); }

static void clear_flags(void) {
    write_reg(NRF_STATUS, NRF_RX_DR | NRF_TX_DS | NRF_MAX_RT);
}

// ── 공용 설정 (RX/TX 공통) ───────────────────────────────────
static void common_config(void) {
    write_reg(NRF_EN_AA,      0x00);   // Auto-ACK 비활성 (단방향 단순 전송)
    write_reg(NRF_SETUP_AW,   0x03);   // 5바이트 주소
    write_reg(NRF_SETUP_RETR, 0x00);   // 재전송 없음
    write_reg(NRF_RF_CH,      NRF_CHANNEL);
    write_reg(NRF_RF_SETUP,   0x07);   // 1Mbps, 0dBm
}

// ── API 구현 ─────────────────────────────────────────────────
void NRF_Init(SPI_HandleTypeDef *hspi,
              GPIO_TypeDef *ce_port,  uint16_t ce_pin,
              GPIO_TypeDef *csn_port, uint16_t csn_pin) {
    _spi      = hspi;
    _ce_port  = ce_port;  _ce_pin  = ce_pin;
    _csn_port = csn_port; _csn_pin = csn_pin;
    CE_L();
    CSN_H();
    HAL_Delay(15);  // NRF24L01 전원 안정화 대기
}

void NRF_SetRxMode(void) {
    CE_L();
    common_config();
    write_reg(NRF_EN_RXADDR,  0x01);             // Pipe 0 활성
    write_addr(NRF_RX_ADDR_P0, NRF_ADDR);        // 수신 주소
    write_reg(NRF_RX_PW_P0,   NRF_PAYLOAD_LEN);  // 페이로드 1바이트
    write_reg(NRF_CONFIG,     0x0F);              // CRC 2B, PWR_UP, PRIM_RX
    clear_flags();
    flush_rx();
    CE_H();    // RX 리스닝 시작
    HAL_Delay(2);
}

void NRF_SetTxMode(void) {
    CE_L();
    common_config();
    write_reg(NRF_EN_RXADDR,  0x00);
    write_addr(NRF_TX_ADDR,   NRF_ADDR);   // 송신 목적지 주소
    write_reg(NRF_CONFIG,     0x0E);       // CRC 2B, PWR_UP, PRIM_TX
    clear_flags();
    flush_tx();
    HAL_Delay(2);
}

uint8_t NRF_DataReady(void) {
    return (read_reg(NRF_STATUS) & NRF_RX_DR) ? 1 : 0;
}

void NRF_ReadPayload(uint8_t *buf, uint8_t len) {
    CSN_L();
    spi_xfer(NRF_R_RX_PL);
    for (uint8_t i = 0; i < len; i++) buf[i] = spi_xfer(NRF_NOP);
    CSN_H();
    write_reg(NRF_STATUS, NRF_RX_DR);   // RX_DR 플래그 클리어
}

void NRF_SendPayload(uint8_t *buf, uint8_t len) {
    CE_L();
    flush_tx();
    CSN_L();
    spi_xfer(NRF_W_TX_PL);
    for (uint8_t i = 0; i < len; i++) spi_xfer(buf[i]);
    CSN_H();
    // CE 펄스 (>10μs) → 전송 트리거
    CE_H();
    HAL_Delay(1);
    CE_L();
    // TX 완료 또는 타임아웃 대기
    uint32_t deadline = HAL_GetTick() + 50;
    while (!(read_reg(NRF_STATUS) & (NRF_TX_DS | NRF_MAX_RT))) {
        if (HAL_GetTick() > deadline) break;
    }
    write_reg(NRF_STATUS, NRF_TX_DS | NRF_MAX_RT);
}
