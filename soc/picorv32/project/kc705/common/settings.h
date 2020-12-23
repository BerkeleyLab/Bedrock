#ifndef SETTINGS_H
#define SETTINGS_H
//-----------------------------
// Global settings file
//-----------------------------
// can be pretty much included by anyone (.S, .c, .h)
// Some of the constants here are expected by the startup script / library files
// and need to be defined even if not used

// Base addresses of Peripherals
#define BASE_GPIO              0x01000000
#define BASE_UART0             0x02000000    // Debug UART

#define BASE_I2C               BASE_GPIO

#define F_CLK                   125000000     // [Hz] for KC705

#define BOOTLOADER_DELAY    (F_CLK/1000)  // How long to wait in the bootloader for a connection

// GPIO PIN assignments (must match top.v)
#define PIN_I2C_SDA              0
#define PIN_I2C_SCL              1
#define PIN_PCA9584_RST          2
#define LCD_DB4_LS               8
#define LCD_DB5_LS               9
#define LCD_DB6_LS               10
#define LCD_DB7_LS               11
#define LCD_RW_LS                12
#define LCD_RS_LS                13
#define LCD_E_LS                 14

// I2C specific settings
// VC707 only works when I2C_DELAY_US >= 3
#define I2C_DELAY_US             5              //~half a clock period [us]

// I2C Addresses
#define I2C_ADR_PCA9584          0x74           // right shifted 7 bit i2c address of the KC705 I2C multiplexer
#define I2C_ADR_SI570            0x5D
#define I2C_ADR_FMC_HPC          0x00
#define I2C_ADR_FMC_LPC          0x00
#define I2C_ADR_EEPROM           0x54
#define I2C_ADR_SFP_1            0x50           // SFP ID block (standardized)
#define I2C_ADR_SFP_2            0x51           // Finisar advanced diagnostic block
#define I2C_ADR_ADV7511          0x39
#define I2C_ADR_DDR3_1           0x50
#define I2C_ADR_DDR3_2           0x18
#define I2C_ADR_SI5324           0x68

// I2C multiplexer channels
#define I2C_CH_SI570             (1<<0)
#define I2C_CH_FMC_HPC           (1<<1)
#define I2C_CH_FMC_LPC           (1<<2)
#define I2C_CH_EEPROM            (1<<3)
#define I2C_CH_SFP               (1<<4)
#define I2C_CH_ADV7511           (1<<5)
#define I2C_CH_DDR3              (1<<6)
#define I2C_CH_SI5324            (1<<7)

#endif
