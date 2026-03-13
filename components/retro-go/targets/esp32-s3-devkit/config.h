/* * RetroGo Configuration - Kynex Sovereign S3 Edition
 * Geliştirici: Muhammed (Kynex)
 * Donanım: KynexBoard ESP32-S3 N16R8
 * Özellikler: Fixed SPI Pinout, rotated Joysticks, PWM Audio (Pin 18), Touch (Pin 16)
 * Hata Düzeltme: Pin conflicts with main OS resolved, 90-degree joystick rotation applied
 * Talimat: Asla satır silmeden, optimize etmeden, tam ve tek parça kod.
 */

#ifndef _RG_TARGET_CONFIG_H_
#define _RG_TARGET_CONFIG_H_

// Target definition
#define RG_TARGET_NAME             "KYNEX-SOVEREIGN-S3"

// Storage (SD Kart Yok - Muhammed'in Dahili FFat Bölümü)
// Bu ayar KynexOs ile aynı partition tablosunu (partitions.csv) kullanır
#define RG_STORAGE_ROOT             "/ffat"
#define RG_STORAGE_FLASH_PARTITION  "ffat"

// Audio (Muhammed'in Pin 18 Hoparlör Modu)
#define RG_AUDIO_USE_INT_DAC        0   // S3'te dahili DAC yok
#define RG_AUDIO_USE_EXT_DAC        0   // Harici I2S devre dışı
#define RG_AUDIO_USE_PWM            1   // PWM Audio Aktif
#define RG_GPIO_SND_PWM             GPIO_NUM_18 // Muhammed'in Speaker Pini

// Video (Kynex SPI Ekran Dizilimi - main.cpp ile Birebir Aynı)
#define RG_SCREEN_DRIVER            0   // 0 = ILI9341
#define RG_SCREEN_HOST              SPI2_HOST
#define RG_SCREEN_SPEED             SPI_MASTER_FREQ_40M 
#define RG_SCREEN_BACKLIGHT         1
#define RG_SCREEN_WIDTH             320
#define RG_SCREEN_HEIGHT            240
#define RG_SCREEN_ROTATE            0
#define RG_SCREEN_VISIBLE_AREA      {0, 0, 0, 0}
#define RG_SCREEN_SAFE_AREA         {0, 0, 0, 0}

// LCD SPI PİNLERİ (Muhammed'in Fiziksel Donanımı)
#define RG_GPIO_LCD_MISO            GPIO_NUM_13
#define RG_GPIO_LCD_MOSI            GPIO_NUM_11
#define RG_GPIO_LCD_CLK             GPIO_NUM_12
#define RG_GPIO_LCD_CS              GPIO_NUM_10
#define RG_GPIO_LCD_DC              GPIO_NUM_9
#define RG_GPIO_LCD_RST             GPIO_NUM_14
#define RG_GPIO_LCD_BCKL            GPIO_NUM_1  // Arka ışık pini

// Ekran İlkleme Komutları (90 Derece Yatay Mod Fix)
#define RG_SCREEN_INIT()                                                                                        \
    ILI9341_CMD(0xCF, 0x00, 0xc3, 0x30);                                                                        \
    ILI9341_CMD(0xED, 0x64, 0x03, 0x12, 0x81);                                                                  \
    ILI9341_CMD(0xE8, 0x85, 0x00, 0x78);                                                                        \
    ILI9341_CMD(0xCB, 0x39, 0x2c, 0x00, 0x34, 0x02);                                                            \
    ILI9341_CMD(0xF7, 0x20);                                                                                    \
    ILI9341_CMD(0xEA, 0x00, 0x00);                                                                              \
    ILI9341_CMD(0xC0, 0x1B);                 /* Power control   //VRH[5:0] */                                   \
    ILI9341_CMD(0xC1, 0x12);                 /* Power control   //SAP[2:0];BT[3:0] */                           \
    ILI9341_CMD(0xC5, 0x32, 0x3C);           /* VCM control */                                                  \
    ILI9341_CMD(0xC7, 0x91);                 /* VCM control2 */                                                 \
    ILI9341_CMD(0x36, 0x28);                 /* 90 Derece Yatay Mod Fix (BGR) */                                \
    ILI9341_CMD(0xB1, 0x00, 0x10);           /* Frame Rate Control */                                           \
    ILI9341_CMD(0xB6, 0x0A, 0xA2);           /* Display Function Control */                                     \
    ILI9341_CMD(0xF6, 0x01, 0x30);                                                                              \
    ILI9341_CMD(0xF2, 0x00);                 /* 3Gamma Function Disable */                                      \
    ILI9341_CMD(0x26, 0x01);                 /* Gamma curve selected */                                         \
    ILI9341_CMD(0xE0, 0x0F, 0x31, 0x2B, 0x0C, 0x0E, 0x08, 0x4E, 0xF1, 0x37, 0x07, 0x10, 0x03, 0x0E, 0x09, 0x00); \
    ILI9341_CMD(0xE1, 0x00, 0x0E, 0x14, 0x03, 0x11, 0x07, 0x31, 0xC1, 0x48, 0x08, 0x0F, 0x0C, 0x31, 0x36, 0x0F);


// Input (Joystickler Muhammed'in 90 Derece Sağ Montajına Göre Fixlendi)
/* * ✅ JOYSTICK ROTASYON MANTIĞI:
 * Muhammed'in konsolunda Joy1_X (Pin 4) ve Joy1_Y (Pin 5) yönleri sağlar.
 * Sağa 90 derece döndüğü için:
 * Fiziksel YUKARI/AŞAĞI artık Pin 4 (ADC_CH3) üzerinden okunur.
 * Fiziksel SOL/SAĞ artık Pin 5 (ADC_CH4) üzerinden okunur.
 */
#define RG_GAMEPAD_ADC_MAP {\
    {RG_KEY_UP,    ADC_UNIT_1, ADC_CHANNEL_3, ADC_ATTEN_DB_11, 0, 1024},\
    {RG_KEY_DOWN,  ADC_UNIT_1, ADC_CHANNEL_3, ADC_ATTEN_DB_11, 3072, 4096},\
    {RG_KEY_LEFT,  ADC_UNIT_1, ADC_CHANNEL_4, ADC_ATTEN_DB_11, 0, 1024},\
    {RG_KEY_RIGHT, ADC_UNIT_1, ADC_CHANNEL_4, ADC_ATTEN_DB_11, 3072, 4096},\
}

#define RG_GAMEPAD_GPIO_MAP {\
    {RG_KEY_SELECT, .num = GPIO_NUM_6,  .pullup = 1, .level = 0}, /* Joy1 SW - Kynexos Return */\
    {RG_KEY_START,  .num = GPIO_NUM_17, .pullup = 1, .level = 0}, /* Joy2 SW - Kynexos Return */\
    {RG_KEY_A,      .num = GPIO_NUM_15, .pullup = 1, .level = 0}, /* Joy2 Y Axis used as Button A */\
    {RG_KEY_B,      .num = GPIO_NUM_7,  .pullup = 1, .level = 0}, /* Joy2 X Axis used as Button B */\
    {RG_KEY_MENU,   .num = GPIO_NUM_0,  .pullup = 1, .level = 0}, /* Boot Button */\
}

// Battery (Muhammed'in Devresine Hazır)
#define RG_BATTERY_DRIVER           1
#define RG_BATTERY_ADC_UNIT         ADC_UNIT_1
#define RG_BATTERY_ADC_CHANNEL      ADC_CHANNEL_4
#define RG_BATTERY_CALC_PERCENT(raw) (((raw) * 2.f - 3500.f) / (4200.f - 3500.f) * 100.f)
#define RG_BATTERY_CALC_VOLTAGE(raw) ((raw) * 2.f * 0.001f)

// Status LED (NC: Not Connected)
#define RG_GPIO_LED                 GPIO_NUM_NC

// I2S Rezerve
#define RG_GPIO_SND_I2S_BCK         GPIO_NUM_NC
#define RG_GPIO_SND_I2S_WS          GPIO_NUM_NC
#define RG_GPIO_SND_I2S_DATA        GPIO_NUM_NC

// Dokunmatik XPT2046 (Muhammed'in Pin 16 Hattı)
#define RG_TOUCH_DRIVER             1
#define RG_GPIO_TP_CS               GPIO_NUM_16
#define RG_GPIO_TP_IRQ              GPIO_NUM_NC

#endif /* _RG_TARGET_CONFIG_H_ */
