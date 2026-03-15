/* * RetroGo Configuration - Kynex Sovereign Typo Fixer (v241.0)
 * Geliştirici: Muhammed (Kynex)
 * Özellikler: RG_SCREEN_WIDTH Typo Fixed, Calibrated ADC, HW BOOT Anchor
 * Donanım: ESP32-S3 N16R8
 * Talimat: Asla satır silmeden, tam ve tek parça kod.
 */

#ifndef _RG_TARGET_CONFIG_H_
#define _RG_TARGET_CONFIG_H_

#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include "driver/gpio.h"
#include "esp_ota_ops.h"
#include "esp_partition.h"
#include "esp_system.h"

// Target definition
#define RG_TARGET_NAME             "KYNEX-SOVEREIGN-DUALBOOT-V241"

// STORAGE (Dahili Hafıza Mühürlendi)
#define RG_STORAGE_DRIVER           2   
#define RG_STORAGE_ROOT             "/ffat"
#define RG_STORAGE_FLASH_PARTITION  "ffat"

// AUDIO (PWM Pin 18)
#define RG_AUDIO_USE_INT_DAC        0   
#define RG_AUDIO_USE_EXT_DAC        0   
#define RG_AUDIO_USE_PWM            1   
#define RG_GPIO_SND_PWM             GPIO_NUM_18 

// VIDEO (Mutlak Yatay Konfigürasyon ve Hayalet Pin)
#define RG_SCREEN_DRIVER            0   
#define RG_SCREEN_HOST              SPI2_HOST
#define RG_SCREEN_SPEED             SPI_MASTER_FREQ_20M 
// MUHAMMED: İŞTE O UTANÇ VERİCİ HATA DÜZELTİLDİ!
#define RG_SCREEN_WIDTH             320
#define RG_SCREEN_HEIGHT            240
#define RG_SCREEN_ROTATE            1   // 90 Derece Yatay Kilit
#define RG_GPIO_LCD_MISO            GPIO_NUM_13
#define RG_GPIO_LCD_MOSI            GPIO_NUM_11
#define RG_GPIO_LCD_CLK             GPIO_NUM_12
#define RG_GPIO_LCD_CS              GPIO_NUM_10
#define RG_GPIO_LCD_DC              GPIO_NUM_9
#define RG_GPIO_LCD_RST             GPIO_NUM_14
// Çökmeyi engelleyen Hayalet Arka Işık Pini
#define RG_GPIO_LCD_BCKL            GPIO_NUM_47  

// EKRAN DÜZELTMESİ (ILI9341)
#define RG_SCREEN_INIT()                                                                                        \
    ILI9341_CMD(0x36, 0x28);                                                                                    \
    ILI9341_CMD(0xB1, 0x00, 0x1B);                                                                              \
    ILI9341_CMD(0xB6, 0x08, 0x82, 0x27);

// ANALOG JOYSTICK (GERÇEK DÜNYA KALİBRASYONU - 1000 ve 3000 Eşikleri)
#define RG_GAMEPAD_ADC_MAP {\
    {RG_KEY_UP,    ADC_UNIT_1, ADC_CHANNEL_3, ADC_ATTEN_DB_11, 0, 1000},    \
    {RG_KEY_DOWN,  ADC_UNIT_1, ADC_CHANNEL_3, ADC_ATTEN_DB_11, 3000, 4096}, \
    {RG_KEY_LEFT,  ADC_UNIT_1, ADC_CHANNEL_4, ADC_ATTEN_DB_11, 3000, 4096}, \
    {RG_KEY_RIGHT, ADC_UNIT_1, ADC_CHANNEL_4, ADC_ATTEN_DB_11, 0, 1000},    \
    {RG_KEY_X,     ADC_UNIT_1, ADC_CHANNEL_1, ADC_ATTEN_DB_11, 0, 1000},    \
    {RG_KEY_B,     ADC_UNIT_1, ADC_CHANNEL_1, ADC_ATTEN_DB_11, 3000, 4096}, \
    {RG_KEY_Y,     ADC_UNIT_1, ADC_CHANNEL_2, ADC_ATTEN_DB_11, 3000, 4096}, \
    {RG_KEY_A,     ADC_UNIT_1, ADC_CHANNEL_2, ADC_ATTEN_DB_11, 0, 1000},    \
}

// FİZİKSEL BUTONLAR (Kısa basım için GPIO_21 Menu tuşu)
#define RG_GAMEPAD_GPIO_MAP {\
    {RG_KEY_SELECT, .num = GPIO_NUM_6,  .pullup = 1, .level = 0}, \
    {RG_KEY_START,  .num = GPIO_NUM_17, .pullup = 1, .level = 0}, \
    {RG_KEY_MENU,   .num = GPIO_NUM_21, .pullup = 1, .level = 0}, \
}

// KYNEX-OS (OTA_0) GEÇİŞ GÖREVİ (Sistem geçişi BOOT - GPIO 0 tuşunda)
static inline void kynex_os_switch_task(void *arg) {
    gpio_set_direction(GPIO_NUM_0, GPIO_MODE_INPUT); 
    gpio_set_pull_mode(GPIO_NUM_0, GPIO_PULLUP_ONLY);
    int kynex_timer = 0;
    while(1) {
        if(gpio_get_level(GPIO_NUM_0) == 0) { 
            kynex_timer++;
            if(kynex_timer > 20) { 
                const esp_partition_t* kynex_part = esp_partition_find_first(ESP_PARTITION_TYPE_APP, ESP_PARTITION_SUBTYPE_APP_OTA_0, NULL);
                if(kynex_part) { esp_ota_set_boot_partition(kynex_part); esp_restart(); }
            }
        } else { kynex_timer = 0; }
        vTaskDelay(pdMS_TO_TICKS(100)); 
    }
}

// Sistemi Başlatma Kancası
#define RG_TARGET_INIT() xTaskCreate(kynex_os_switch_task, "kynex_sw", 2048, NULL, 5, NULL);

#endif /* _RG_TARGET_CONFIG_H_ */
