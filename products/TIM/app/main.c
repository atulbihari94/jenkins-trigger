/* TIM Product - Main Application */
#include "board_config.h"

#define PRODUCT_NAME "TIM"
#define FIRMWARE_VERSION "3.6.0"

int main(void) {
    Board_Init();
    LoRa_Join();
    /* TIM product main loop */
    while(1) {
        /* TIM sensing logic */
    }
    return 0;
}
