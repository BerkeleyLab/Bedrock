#include <stdint.h>
#include "common.h"
#include "settings.h"

int main(void)
{
	volatile uint32_t *p_sram = (uint32_t *)BASE_SRAM;
	volatile uint8_t *p_sram8 = (uint8_t *)BASE_SRAM;

	for (unsigned i=0; i<=7; i++)
	    p_sram[i] = ((i + 3) << 24) |((i + 2) << 16) | ((i + 1) << 8) | i;

	for (unsigned i=0; i<=7; i++)
		p_sram8[i + 0x10] = i;

	return p_sram[1];
}
