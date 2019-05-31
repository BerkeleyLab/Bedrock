//-------------------------------------------------
// Xilinx XADC core support
//-------------------------------------------------
#ifndef XADC_MON_H
#define XADC_MON_H

#define XADC_BASE2_XADC 0x0
#define XADC_BASE2_SFR  0x100000

#define SFR_BIT_BUSY    0
#define SFR_BIT_EOC     1
#define SFR_BIT_EOS     2
#define SFR_BIT_OT      4
#define SFR_BYTE_CHANNEL_OUT 4
#define SFR_BYTE_ALM_INT     12
#define SFR_BIT_XADC_RESET   0

// UG480 Table 4-1
enum XADC_CHANNEL {
    XADC_CHAN_TEMP       = 0,
    XADC_CHAN_VCCINT     = 1,
    XADC_CHAN_VCCAUX     = 2,
    XADC_CHAN_VPVN       = 3,
    XADC_CHAN_VREFP      = 4,
    XADC_CHAN_VREFN      = 5,
    XADC_CHAN_VCCBRAM    = 6,
    XADC_CHAN_CAL        = 8,
	XADC_CHAN_VCCPINT    = 13,
	XADC_CHAN_VCCPAUX    = 14,
	XADC_CHAN_VCCODDR    = 15,
    XADC_CHAN_VAUX0      = 16,
    XADC_CHAN_VAUX1      = 17,
    XADC_CHAN_VAUX2      = 18,
    XADC_CHAN_VAUX3      = 19,
    XADC_CHAN_VAUX4      = 20,
    XADC_CHAN_VAUX5      = 21,
    XADC_CHAN_VAUX6      = 22,
    XADC_CHAN_VAUX7      = 23,
    XADC_CHAN_VAUX8      = 24,
    XADC_CHAN_VAUX9      = 25,
    XADC_CHAN_VAUX10     = 26,
    XADC_CHAN_VAUX11     = 27,
    XADC_CHAN_VAUX12     = 28,
    XADC_CHAN_VAUX13     = 29,
    XADC_CHAN_VAUX14     = 30,
    XADC_CHAN_VAUX15     = 31
};

#endif
