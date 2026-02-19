// AVR serial port code.
//
// Copyright (C) 2016-2018  Kevin O'Connor <kevin@koconnor.net>
//
// This file may be distributed under the terms of the GNU GPLv3 license.

#include <avr/interrupt.h> // USART_RX_vect
#include "autoconf.h" // CONFIG_T5UID1_SERIAL_PORT
#include "board/t5uid1/serial_irq.h" // t5uid1_rx_byte
#include "command.h" // DECL_CONSTANT_STR

#if CONFIG_SERIAL && CONFIG_T5UID1_SERIAL_PORT == CONFIG_SERIAL_PORT
  #error "The serial port selected for the T5UID1 screen is already used"
#endif

// Reserve serial pins
#if CONFIG_T5UID1_SERIAL_PORT == 0
  #if CONFIG_MACH_atmega1280 || CONFIG_MACH_atmega2560
    DECL_CONSTANT_STR("RESERVE_PINS_t5uid1", "PE0,PE1");
  #else
    DECL_CONSTANT_STR("RESERVE_PINS_t5uid1", "PD0,PD1");
  #endif
#elif CONFIG_T5UID1_SERIAL_PORT == 1
  DECL_CONSTANT_STR("RESERVE_PINS_t5uid1", "PD2,PD3");
#elif CONFIG_T5UID1_SERIAL_PORT == 2
  DECL_CONSTANT_STR("RESERVE_PINS_t5uid1", "PH0,PH1");
#else
  DECL_CONSTANT_STR("RESERVE_PINS_t5uid1", "PJ0,PJ1");
#endif

// Helper macros for defining serial port aliases
#define AVR_SERIAL_REG1(prefix, id, suffix) prefix ## id ## suffix
#define AVR_SERIAL_REG(prefix, id, suffix) AVR_SERIAL_REG1(prefix, id, suffix)

// Serial port register aliases
#define UCSRxA AVR_SERIAL_REG(UCSR, CONFIG_T5UID1_SERIAL_PORT, A)
#define UCSRxB AVR_SERIAL_REG(UCSR, CONFIG_T5UID1_SERIAL_PORT, B)
#define UCSRxC AVR_SERIAL_REG(UCSR, CONFIG_T5UID1_SERIAL_PORT, C)
#define UBRRx AVR_SERIAL_REG(UBRR, CONFIG_T5UID1_SERIAL_PORT,)
#define UDRx AVR_SERIAL_REG(UDR, CONFIG_T5UID1_SERIAL_PORT,)
#define UCSZx1 AVR_SERIAL_REG(UCSZ, CONFIG_T5UID1_SERIAL_PORT, 1)
#define UCSZx0 AVR_SERIAL_REG(UCSZ, CONFIG_T5UID1_SERIAL_PORT, 0)
#define U2Xx AVR_SERIAL_REG(U2X, CONFIG_T5UID1_SERIAL_PORT,)
#define RXENx AVR_SERIAL_REG(RXEN, CONFIG_T5UID1_SERIAL_PORT,)
#define TXENx AVR_SERIAL_REG(TXEN, CONFIG_T5UID1_SERIAL_PORT,)
#define RXCIEx AVR_SERIAL_REG(RXCIE, CONFIG_T5UID1_SERIAL_PORT,)
#define UDRIEx AVR_SERIAL_REG(UDRIE, CONFIG_T5UID1_SERIAL_PORT,)

#if defined(USART_RX_vect)
  // The atmega168 / atmega328 doesn't have an ID in the irq names
  #define USARTx_RX_vect USART_RX_vect
  #define USARTx_UDRE_vect USART_UDRE_vect
#else
  #define USARTx_RX_vect                                            \
      AVR_SERIAL_REG(USART, CONFIG_T5UID1_SERIAL_PORT, _RX_vect)
  #define USARTx_UDRE_vect                                          \
      AVR_SERIAL_REG(USART, CONFIG_T5UID1_SERIAL_PORT, _UDRE_vect)
#endif

#define T5UID1_UBRR(baud, cm) \
    (DIV_ROUND_CLOSEST(CONFIG_CLOCK_FREQ, (cm) * (baud)) - 1UL)

static uint16_t
calc_t5uid1_ubrr(uint32_t baud)
{
#if CONFIG_SERIAL_BAUD_U2X
    const uint32_t cm = 8UL;
#else
    const uint32_t cm = 16UL;
#endif
    switch (baud) {
    case 1200: return T5UID1_UBRR(1200UL, cm);
    case 2400: return T5UID1_UBRR(2400UL, cm);
    case 4800: return T5UID1_UBRR(4800UL, cm);
    case 9600: return T5UID1_UBRR(9600UL, cm);
    case 19200: return T5UID1_UBRR(19200UL, cm);
    case 38400: return T5UID1_UBRR(38400UL, cm);
    case 57600: return T5UID1_UBRR(57600UL, cm);
    case 115200: return T5UID1_UBRR(115200UL, cm);
    case 230400: return T5UID1_UBRR(230400UL, cm);
    case 250000: return T5UID1_UBRR(250000UL, cm);
    case 460800: return T5UID1_UBRR(460800UL, cm);
    case 500000: return T5UID1_UBRR(500000UL, cm);
    case 921600: return T5UID1_UBRR(921600UL, cm);
    default: return T5UID1_UBRR(115200UL, cm);
    }
}

void
t5uid1_init(uint32_t baud)
{
    UCSRxA = CONFIG_SERIAL_BAUD_U2X ? (1<<U2Xx) : 0;
    UBRRx = calc_t5uid1_ubrr(baud);
    UCSRxC = (1<<UCSZx1) | (1<<UCSZx0);
    UCSRxB = (1<<RXENx) | (1<<TXENx) | (1<<RXCIEx) | (1<<UDRIEx);
}

// Rx interrupt - data available to be read.
ISR(USARTx_RX_vect)
{
    t5uid1_rx_byte(UDRx);
}

// Tx interrupt - data can be written to serial.
ISR(USARTx_UDRE_vect)
{
    uint8_t data;
    int ret = t5uid1_get_tx_byte(&data);
    if (ret)
        UCSRxB &= ~(1<<UDRIEx);
    else
        UDRx = data;
}

// Enable tx interrupts
void
t5uid1_enable_tx_irq(void)
{
    UCSRxB |= 1<<UDRIEx;
}
