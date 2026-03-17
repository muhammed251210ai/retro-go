/* * RetroGo Configuration - Kynex Sovereign Phantom Driver (v325.10)
 * Geliştirici: Muhammed (Kynex)
 * Özellikler: API Interception (Macro Hack), Phantom Pin 21, Absolute Switch
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

// =========================================================================
// MUHAMMED: RETRO-GO'YU KÖR EDEN KOD (API INTERCEPTION)
// Retro-Go her tuş kontrolü yaptığında bu filtreye takılacak.
static inline int kynex_gpio_get_level_wrapper(gpio_num_t pin) {
    // Eğer Retro-Go 0. pini (BOOT) sorarsa, ONA HER ZAMAN 1 (BASILMADI) DÖNDÜR!
    if (pin == GPIO_NUM_0) {
        return 1; 
    }
    // Diğer tüm pinler için gerçek sistem fonksiyonunu çağır
    return (gpio_get_level)(pin); 
}
// Sistemin orjinal komutunu bizim hayalet fonksiyonla değiştiriyoruz
#define gpio_get_level kynex_gpio_get_level_wrapper
// =========================================================================

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

// MUHAMMED: Menü tuşu artık sanal bir pin olan GPIO 21'de bekliyor.
#define RG_GAMEPAD_GPIO_MAP { \
    {RG_KEY_SELECT, .num = GPIO_NUM_6,  .pullup = 1, .level = 0}, \
    {RG_KEY_START,  .num = GPIO_NUM_17, .pullup = 1, .level = 0}, \
    {RG_KEY_MENU,   .num = GPIO_NUM_21, .pullup = 1, .level = 0}, \
}

// KARAR MEKANİZMASI: Sadece bu görev gerçek 0. pini okuyabilir.
static inline void kynex_phantom_switch_task(void *arg) {
    int hold_timer = 0;
    bool was_pressed = false;

    // Gerçek pini okumak için donanımı hazırlıyoruz
    (gpio_set_direction)(GPIO_NUM_0, GPIO_MODE_INPUT);
    (gpio_set_pull_mode)(GPIO_NUM_0, GPIO_PULLUP_ONLY);

    while(1) {
        // Parantez içindeki (gpio_get_level) hack'i bypass eder ve GERÇEK tuşu okur!
        if((gpio_get_level)(GPIO_NUM_0) == 0) { 
            was_pressed = true;
            hold_timer++;
            
            // 1.5 Saniye basılı tutuldu mu? (30 * 50ms)
            if(hold_timer > 30) { 
                const esp_partition_t* target = esp_partition_find_first(ESP_PARTITION_TYPE_APP, ESP_PARTITION_SUBTYPE_APP_OTA_0, NULL);
                if(target) { 
                    esp_ota_set_boot_partition(target); 
                    esp_restart(); 
                } else {
                    esp_restart(); // Hata varsa da sistemi sıfırla
                }
            }
        } else { 
            // TUŞ BIRAKILDIĞINDA
            if(was_pressed && hold_timer > 0 && hold_timer <= 30) {
                // KISA BASILDI! Şimdi Retro-Go'yu kandırmak için Sanal Pin 21'i çekiyoruz
                (gpio_set_direction)(GPIO_NUM_21, GPIO_MODE_INPUT_OUTPUT);
                (gpio_set_level)(GPIO_NUM_21, 0); // Sanal tuşa basıldı
                vTaskDelay(pdMS_TO_TICKS(100));   // 100ms basılı tut
                (gpio_set_level)(GPIO_NUM_21, 1); // Sanal tuşu bırak
            }
            was_pressed = false;
            hold_timer = 0; 
        }
        vTaskDelay(pdMS_TO_TICKS(50)); 
    }
}

// Görevi en yüksek öncelikle (15) çekirdek 0'a sabitliyoruz
#define RG_TARGET_INIT() xTaskCreatePinnedToCore(kynex_phantom_switch_task, "k_phn", 2048, NULL, 15, NULL, 0);

#endif /* _RG_TARGET_CONFIG_H_ */
