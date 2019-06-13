#include "stdint.h"
#include "settings.h"
#include "spi.h"

static void test(void)
{
  // Send 'Hello' to slave0
  SPI_SET_DAT_BLOCK( BASE_SPI0, 'H' );
  SPI_SET_DAT_BLOCK( BASE_SPI0, 'e' );
  SPI_SET_DAT_BLOCK( BASE_SPI0, 'l' );
  SPI_SET_DAT_BLOCK( BASE_SPI0, 'l' );
  SPI_SET_DAT_BLOCK( BASE_SPI0, 'o' );

  // Send 'Hello' to slave1
  SPI_SET_DAT_BLOCK( BASE_SPI1, 'H' );
  SPI_SET_DAT_BLOCK( BASE_SPI1, 'e' );
  SPI_SET_DAT_BLOCK( BASE_SPI1, 'l' );
  SPI_SET_DAT_BLOCK( BASE_SPI1, 'l' );
  SPI_SET_DAT_BLOCK( BASE_SPI1, 'o' );

  // read back memory from slave0
  SPI_SET_DAT_BLOCK( BASE_SPI0, 0x81040000 );
  SPI_GET_DAT( BASE_SPI0 );

  // read back memory from slave1
  SPI_SET_DAT_BLOCK( BASE_SPI1, 0x00840000 );
  SPI_GET_DAT( BASE_SPI1 );
}

int main(void)
{

  // change spi speed of slave0 to 2, CPOL=0, CPHA=1, DW=32
  SPI_INIT(BASE_SPI0, 0, 0, 0, 1, 0, 32, 1);
  // change spi speed of slave1 to 4, CPOL=1, CPHA=1, DW=24
  SPI_INIT(BASE_SPI1, 0, 0, 1, 1, 0, 24, 4);
  test();

  // Now do it again with LSB first
  // change spi speed of slave0 to 2, CPOL=0, CPHA=1, DW=32
  SPI_INIT(BASE_SPI0, 0, 0, 0, 1, 1, 32, 1);
  // change spi speed of slave1 to 4, CPOL=1, CPHA=1, DW=24
  SPI_INIT(BASE_SPI1, 0, 0, 1, 1, 1, 24, 4);
  test();

  return 0;
}
