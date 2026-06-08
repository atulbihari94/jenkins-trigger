/* FLO Product - Main Application */
#include "board_config.h"

#define PRODUCT_NAME "FLO"
#define FIRMWARE_VERSION "1.6.0"

int main(void) {
    Board_Init();
    LoRa_Join();
    /* FLO product main loop */
    while(1) {
        /* FLO sensing logic */
    }
    return 0;
}
