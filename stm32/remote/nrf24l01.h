#ifndef NRF24L01_H
#define NRF24L01_H

#include "stm32f1xx_hal.h"
#include <stdint.h>

#define NRF_R_REG       0x00
#define NRF_W_REG       0x20
#define NRF_R_RX_PL     0x61
#define NRF_W_TX_PL     0xA0
#define NRF_FLUSH_TX    0xE1
#define NRF_FLUSH_RX    0xE2
#define NRF_NOP         0xFF

#define NRF_CONFIG      0x00
#define NRF_EN_AA       0x01
#define NRF_EN_RXADDR   0x02
#define NRF_SETUP_AW    0x03
#define NRF_SETUP_RETR  0x04
#define NRF_RF_CH       0x05
#define NRF_RF_SETUP    0x06
#define NRF_STATUS      0x07
#define NRF_RX_ADDR_P0  0x0A
#define NRF_TX_ADDR     0x10
#define NRF_RX_PW_P0    0x11

#define NRF_RX_DR       (1 << 6)
#define NRF_TX_DS       (1 << 5)
#define NRF_MAX_RT      (1 << 4)

#define NRF_CHANNEL     76
#define NRF_PAYLOAD_LEN  1

void    NRF_Init      (SPI_HandleTypeDef *hspi,
                       GPIO_TypeDef *ce_port,  uint16_t ce_pin,
                       GPIO_TypeDef *csn_port, uint16_t csn_pin);
void    NRF_SetRxMode (void);
void    NRF_SetTxMode (void);
uint8_t NRF_DataReady (void);
void    NRF_ReadPayload(uint8_t *buf, uint8_t len);
void    NRF_SendPayload(uint8_t *buf, uint8_t len);

#endif
