#include <stdint.h>
#include "gpio.h"
#include "settings.h"

int main(void){
  uint32_t temp = 0;
  //---------------------------
  // Check 32 bit mode
  //---------------------------
  SET_GPIO32( BASE_GPIO, GPIO_OUT_REG, 0x12345678 );
  SET_GPIO32( BASE_GPIO, GPIO_OE_REG,  0xAAAAAAAA );
  temp = GET_GPIO32( BASE_GPIO, GPIO_IN_REG );
  // Should be 0x12345678 ^ 0xAAAAAAAA = 0xb89efcd2
  SET_GPIO32( BASE_GPIO, GPIO_OUT_REG, temp );
  SET_GPIO32( BASE_GPIO, GPIO_OUT_REG, 0xFFFFFFFF );

  //---------------------------
  // 16 bit mode
  //---------------------------
  SET_GPIO16( BASE_GPIO, GPIO_OE_REG, 1, 0xDEAD );
  SET_GPIO16( BASE_GPIO, GPIO_OE_REG, 0, 0xBEEF );

  //---------------------------
  // 8 bit mode
  //---------------------------
  SET_GPIO8(  BASE_GPIO, GPIO_OUT_REG, 0, 0x10 );
  SET_GPIO8(  BASE_GPIO, GPIO_OUT_REG, 1, 0x32 );
  SET_GPIO8(  BASE_GPIO, GPIO_OUT_REG, 2, 0x54 );
  SET_GPIO8(  BASE_GPIO, GPIO_OUT_REG, 3, 0x76 );

  SET_GPIO32( BASE_GPIO, GPIO_OUT_REG, 0xFFFFFFFF );
  SET_GPIO32( BASE_GPIO, GPIO_OE_REG,  0x00000000 );

  //---------------------------
  // 1 bit mode
  //---------------------------
  // Set bit 0, 2, 28 in GPIO_OE_REG
  SET_GPIO1( BASE_GPIO, GPIO_OE_REG, 0, 1 );
  SET_GPIO1( BASE_GPIO, GPIO_OE_REG, 2, 1 );
  SET_GPIO1( BASE_GPIO, GPIO_OE_REG,28, 1 );

  // Clear bit 1, 3, 31 in GPIO_OUT_REG
  SET_GPIO1( BASE_GPIO, GPIO_OUT_REG, 1, 0 );
  SET_GPIO1( BASE_GPIO, GPIO_OUT_REG, 3, 0 );
  SET_GPIO1( BASE_GPIO, GPIO_OUT_REG,31, 0 );

  return temp;
}
