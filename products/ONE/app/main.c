/* ONE (FSO) Product - Main Application */
#include "board_config.h"

#define PRODUCT_NAME "ONE-FSO"
#define FIRMWARE_VERSION "3.1.1"

int main(void) {
    Board_Init();
    LoRa_Join();
    /* ONE product main loop */
    while(1) {
        /* Occupancy sensing logic */
    }
    return 0;
}
