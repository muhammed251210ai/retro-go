# ESP-IDF v4.4 (Retro-Go için en kararlı sürüm)
FROM espressif/idf:release-v4.4

WORKDIR /app

# Bağımlılıkları tek seferde kurarak önbellekten kazanç sağlıyoruz
RUN apt-get update && apt-get install -y python3-pip && \
    pip3 install pillow click

ADD . /app

# Yamaları Uygula
RUN cd /opt/esp/idf && \
	patch --ignore-whitespace -p1 -i "/app/tools/patches/panic-hook (esp-idf 4).diff" && \
	patch --ignore-whitespace -p1 -i "/app/tools/patches/sdcard-fix (esp-idf 4).diff"

# MUHAMMED: Hata ve Hız Ayarı
SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    # Build klasörünü garantiye al
    mkdir -p build && \
    # Sadece senin S3 konsolun için derleme yapıyoruz (HIZ BURADAN GELİYOR)
    python rg_tool.py --target=esp32-s3-devkit release
    # DİĞER HEDEFLER SİLİNMEDİ, İHTİYAÇ HALİNDE ALTTAKİ DİEZLERİ KALDIRABİLİRSİN:
    # python rg_tool.py --target=odroid-go release
    # python rg_tool.py --target=mrgc-g32 release

# Hata Veren Satır Fixlendi: Artık alt klasörleri de kapsıyor
RUN ls -R build/
