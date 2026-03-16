/* * RetroGo Configuration - Kynex Sovereign Sonic Edition (v307.0)
 * Geliştirici: Muhammed (Kynex)
 * Özellikler: Dual Analog Sync, I2S Audio Fix, Absolute Logic
 */

#ifndef _RG_TARGET_CONFIG_H_
#define _RG_TARGET_CONFIG_H_

#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include "driver/gpio.h"
#include "driver/adc.h"
#include "esp_ota_ops.h"
#include "esp_partition.h"
#include "esp_system.h"

#define RG_TARGET_NAME             "KYNEX-SOVEREIGN-V307"

// STORAGE
#define RG_STORAGE_DRIVER           2              
#define RG_STORAGE_ROOT             "/sd"          
#define RG_STORAGE_FLASH_PARTITION  "storage"      

// AUDIO - MUHAMMED: SESİ CANLANDIRAN AYARLAR!
#define RG_AUDIO_USE_INT_DAC        0   
#define RG_AUDIO_USE_EXT_DAC        1   
#define RG_AUDIO_DRIVER             1               // I2S Driver Zorla
#define RG_GPIO_SND_I2S_BCK         GPIO_NUM_18
#define RG_GPIO_SND_I2S_WS          GPIO_NUM_8
#define RG_GPIO_SND_I2S_DATA        GPIO_NUM_3
#define RG_AUDIO_VOLUME_DEFAULT     80              // Başlangıç sesi %80
#define RG_AUDIO_REVERSE_CHANNELS   0

// VIDEO
#define RG_SCREEN_DRIVER            0   
#define RG_SCREEN_HOST              SPI2_HOST
#define RG_SCREEN_SPEED             SPI_MASTER_FREQ_20M 
#define RG_SCREEN_WIDTH             320
#define RG_SCREEN_HEIGHT            240
#define RG_SCREEN_ROTATE            1   
#define RG_GPIO_LCD_MISO            GPIO_NUM_13
#define RG_GPIO_LCD_MOSI            GPIO_NUM_11
#define RG_GPIO_LCD_CLK             GPIO_NUM_12
#define RG_GPIO_LCD_CS              GPIO_NUM_10
#define RG_GPIO_LCD_DC              GPIO_NUM_9
#define RG_GPIO_LCD_RST             GPIO_NUM_14
#define RG_GPIO_LCD_BCKL            GPIO_NUM_1  

#define RG_SCREEN_INIT() do { \
    ILI9341_CMD(0x36, 0x28); \
    ILI9341_CMD(0xB1, 0x00, 0x1B); \
    ILI9341_CMD(0xB6, 0x08, 0x82, 0x27); \
} while(0)

// ANALOG JOYSTICK - MUHAMMED: SAĞ VE SOL MANTIK EŞİTLENDİ!
// Sol Stick: UP/DOWN (CH3), LEFT/RIGHT (CH4)
// Sağ Stick: X/B (CH6), Y/A (UNIT2-CH4) -> Artık aynı eşik değerlerine (0-1000 ve 3000-4096) sahipler.
#define RG_GAMEPAD_ADC_MAP { \
    {RG_KEY_UP,    ADC_UNIT_1, ADC_CHANNEL_3, ADC_ATTEN_DB_11, 0, 1000}, \
    {RG_KEY_DOWN,  ADC_UNIT_1, ADC_CHANNEL_3, ADC_ATTEN_DB_11, 3000, 4096}, \
    {RG_KEY_LEFT,  ADC_UNIT_1, ADC_CHANNEL_4, ADC_ATTEN_DB_11, 3000, 4096}, \
    {RG_KEY_RIGHT, ADC_UNIT_1, ADC_CHANNEL_4, ADC_ATTEN_DB_11, 0, 1000}, \
    {RG_KEY_X,     ADC_UNIT_1, ADC_CHANNEL_6, ADC_ATTEN_DB_11, 0, 1000}, \
    {RG_KEY_B,     ADC_UNIT_1, ADC_CHANNEL_6, ADC_ATTEN_DB_11, 3000, 4096}, \
    {RG_KEY_Y,     ADC_UNIT_2, ADC_CHANNEL_4, ADC_ATTEN_DB_11, 3000, 4096}, \
    {RG_KEY_A,     ADC_UNIT_2, ADC_CHANNEL_4, ADC_ATTEN_DB_11, 0, 1000} \
}

#define RG_GAMEPAD_GPIO_MAP { \
    {RG_KEY_SELECT, .num = GPIO_NUM_6,  .pullup = 1, .level = 0}, \
    {RG_KEY_START,  .num = GPIO_NUM_17, .pullup = 1, .level = 0}, \
    {RG_KEY_MENU,   .num = GPIO_NUM_0,  .pullup = 1, .level = 0}, \
}

static inline void kynex_boot_switch_task(void *arg) {
    gpio_set_direction(GPIO_NUM_0, GPIO_MODE_INPUT); 
    int k_timer = 0;
    while(1) {
        if(gpio_get_level(GPIO_NUM_0) == 0) { 
            k_timer++;
            if(k_timer > 20) { 
                const esp_partition_t* k_p = esp_partition_find_first(ESP_PARTITION_TYPE_APP, ESP_PARTITION_SUBTYPE_APP_OTA_0, NULL);
                if(k_p) { esp_ota_set_boot_partition(k_p); esp_restart(); }
            }
        } else { k_timer = 0; }
        vTaskDelay(pdMS_TO_TICKS(100)); 
    }
}
#define RG_TARGET_INIT() xTaskCreate(kynex_boot_switch_task, "kynex_sw", 2048, NULL, 5, NULL);

#endif /* _RG_TARGET_CONFIG_H_ */
