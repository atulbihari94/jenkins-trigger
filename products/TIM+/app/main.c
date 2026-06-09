/* TIM+ Product - Main Application */
#include "board_config.h"

#define PRODUCT_NAME "TIM_PLUS"
#define FIRMWARE_VERSION "1.5.1"

int main(void) {
    Board_Init();
    LoRa_Join();
    /* TIM+ product main loop */
    while(1) {
        /* TIM+ occupancy sensing logic */
    }
    return 0;
}
