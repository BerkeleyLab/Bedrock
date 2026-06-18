#include <stdint.h>
#include "common.h"
#include "spi_memio.h"
#include "settings.h"

int main(void)
{
	volatile uint32_t *p_memio = (uint32_t *)BASE_MEMIO;

	//-------------------------------
	// Read in default mode (1x)
	//-------------------------------
	for (unsigned i=0; i<11; i++) p_memio[i];

	//-------------------------------
	// Read in qspi mode (4x)
	//-------------------------------
	MEMIO_CFG(BASE_MEMIO, 0, 1, 1, 8);
	for (unsigned i=0; i<11; i++) p_memio[i];

	//-------------------------------
	// Read in qspi DDR mode (8x)
	//-------------------------------
	MEMIO_CFG(BASE_MEMIO, 1, 1, 1, 8);
	for (unsigned i=0; i<11; i++) p_memio[i];

	return p_memio[1];
}
