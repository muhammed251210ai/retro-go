/* * RetroGo Configuration - Kynex Sovereign Time-Freeze Hack (v325.11)
 * Geliştirici: Muhammed (Kynex)
 * Özellikler: vTaskSuspendAll (Time Freeze), Release-to-Menu, Long-to-OS
 * Donanım: ESP32-S3 N16R8 + MAX98357A I2S
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
#include "esp_rom_sys.h" // MUHAMMED: Mikro saniye bekleme komutu için eklendi

#define RG_TARGET_NAME             "KYNEX-SOVEREIGN-V325"

// STORAGE
#define RG_STORAGE_DRIVER           2              
#define RG_STORAGE_ROOT             "/sd"          
#define RG_STORAGE_FLASH_PARTITION  "storage"      

// AUDIO (MAX98357A I2S)
#define RG_AUDIO_USE_INT_DAC        0   
#define RG_AUDIO_USE_EXT_DAC        1   
#define RG_AUDIO_DRIVER             1               
#define RG_GPIO_SND_I2S_BCK         GPIO_NUM_18     
#define RG_GPIO_SND_I2S_WS          GPIO_NUM_8      
#define RG_GPIO_SND_I2S_DATA        GPIO_NUM_3      
#define RG_AUDIO_I2S_MONO           1               
#define RG_AUDIO_VOLUME_DEFAULT     100             
#define RG_AUDIO_I2S_PORT           I2S_NUM_0

// VIDEO & BACKLIGHT
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
#define RG_BACKLIGHT_DRIVER         1
#define RG_BACKLIGHT_FREQ           5000
#define RG_BACKLIGHT_LEVEL_DEFAULT  255

#define RG_SCREEN_INIT() do { \
    ILI9341_CMD(0x36, 0x28); \
    ILI9341_CMD(0xB1, 0x00, 0x1B); \
    ILI9341_CMD(0xB6, 0x08, 0x82, 0x27); \
} while(0)

// ANALOG JOYSTICK - 180 DERECE TERS TUTUŞ
#define RG_GAMEPAD_ADC_MAP { \
    {RG_KEY_UP,    ADC_UNIT_1, ADC_CHANNEL_3, ADC_ATTEN_DB_11, 0, 1000},    \
    {RG_KEY_DOWN,  ADC_UNIT_1, ADC_CHANNEL_3, ADC_ATTEN_DB_11, 3000, 4096}, \
    {RG_KEY_LEFT,  ADC_UNIT_1, ADC_CHANNEL_4, ADC_ATTEN_DB_11, 3000, 4096}, \
    {RG_KEY_RIGHT, ADC_UNIT_1, ADC_CHANNEL_4, ADC_ATTEN_DB_11, 0, 1000},    \
    {RG_KEY_Y,     ADC_UNIT_2, ADC_CHANNEL_4, ADC_ATTEN_DB_11, 0, 1000},    \
    {RG_KEY_A,     ADC_UNIT_2, ADC_CHANNEL_4, ADC_ATTEN_DB_11, 3000, 4096}, \
    {RG_KEY_X,     ADC_UNIT_1, ADC_CHANNEL_6, ADC_ATTEN_DB_11, 0, 1000},    \
    {RG_KEY_B,     ADC_UNIT_1, ADC_CHANNEL_6, ADC_ATTEN_DB_11, 3000, 4096}  \
}

// MUHAMMED: FİZİKSEL 0. PİNİ HARİTADAN SİLDİK, MENÜYÜ SANAL 21. PİNE GİZLEDİK
#define RG_GAMEPAD_GPIO_MAP { \
    {RG_KEY_SELECT, .num = GPIO_NUM_6,  .pullup = 1, .level = 0}, \
    {RG_KEY_START,  .num = GPIO_NUM_17, .pullup = 1, .level = 0}, \
    {RG_KEY_MENU,   .num = GPIO_NUM_21, .pullup = 1, .level = 0}, \
}

// ZAMAN DONDURUCU SİSTEM GEÇİŞ GÖREVİ
static inline void kynex_time_freeze_task(void *arg) {
    // Gerçek 0. Tuşun Ayarı
    gpio_set_direction(GPIO_NUM_0, GPIO_MODE_INPUT);
    gpio_pullup_en(GPIO_NUM_0);

    // Sanal 21. Tuşun Ayarı (Menü Tuşu)
    gpio_set_direction(GPIO_NUM_21, GPIO_MODE_OUTPUT);
    gpio_set_level(GPIO_NUM_21, 1); // 1 = Basılmamış

    while(1) {
        if(gpio_get_level(GPIO_NUM_0) == 0) { 
            // 1. ADIM: TUŞA BASILDIĞI AN ZAMANI DONDUR! (Retro-Go felç olur)
            vTaskSuspendAll(); 
            
            int hold_ms = 0;
            // Tuş basılı tutulduğu sürece içeride kal (Zaman donukken bekle)
            while(gpio_get_level(GPIO_NUM_0) == 0) {
                esp_rom_delay_us(1000); // 1 Milisaniye bekle
                hold_ms++;
                if(hold_ms >= 1500) { 
                    break; // 1.5 Saniye doldu, döngüden çık
                }
            }
            
            // 2. ADIM: ZAMANI ÇÖZ! (Sistem tekrar nefes almaya başlar)
            xTaskResumeAll(); 
            
            // 3. ADIM: KARAR VER
            if(hold_ms >= 1500) {
                // UZUN BASIŞ: Retro-Go menüyü açamadan KynexOS'a ışınlan!
                const esp_partition_t* target = esp_partition_find_first(ESP_PARTITION_TYPE_APP, ESP_PARTITION_SUBTYPE_APP_OTA_0, NULL);
                if(target) { 
                    esp_ota_set_boot_partition(target); 
                    esp_restart(); 
                } else {
                    esp_restart(); 
                }
            } else {
                // KISA BASIŞ (Bırakınca): Sanal pine dokun, menüyü açtır!
                gpio_set_level(GPIO_NUM_21, 0); // Sanal tuşu ez
                vTaskDelay(pdMS_TO_TICKS(50));  // Retro-Go'nun hissetmesi için 50ms bekle
                gpio_set_level(GPIO_NUM_21, 1); // Sanal tuşu bırak
            }
        }
        // Çok hızlı kontrol et ki Retro-Go bizden önce davranamasın
        vTaskDelay(pdMS_TO_TICKS(5)); 
    }
}

// Görevi en yüksek öncelik seviyesiyle başlatıyoruz!
#define RG_TARGET_INIT() xTaskCreate(kynex_time_freeze_task, "k_freeze", 2048, NULL, 20, NULL);

#endif /* _RG_TARGET_CONFIG_H_ */
