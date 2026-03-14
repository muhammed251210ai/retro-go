# **************************************************************************
# * Kynex Sovereign - Retro-Go Dockerfile v192.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: ESP-IDF v4.4 üzerinde S3 Master derleme
# * Hata Düzeltme: Python3 zorlaması ve bağımlılık garantisi eklendi.
# * Talimat: Asla satır silmeden, tam ve tek parça kod blokları içinde ver.
# **************************************************************************

# ESP-IDF v4.4 (Retro-Go için en kararlı sürüm)
FROM espressif/idf:release-v4.4

WORKDIR /app

# Bağımlılıkları tek seferde kuruyoruz
RUN apt-get update && apt-get install -y python3-pip && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install pillow click

# Proje dosyalarını Docker içine alıyoruz
ADD . /app

# Yamaları Uygula (Panic hook ve SD Fix)
# Dosyalar varsa yama yapar, yoksa hata vermeden geçer.
RUN cd /opt/esp/idf && \
	if [ -f "/app/tools/patches/panic-hook (esp-idf 4).diff" ]; then patch --ignore-whitespace -p1 -i "/app/tools/patches/panic-hook (esp-idf 4).diff"; fi && \
	if [ -f "/app/tools/patches/sdcard-fix (esp-idf 4).diff" ]; then patch --ignore-whitespace -p1 -i "/app/tools/patches/sdcard-fix (esp-idf 4).diff"; fi

# MUHAMMED: Hata ve Hız Ayarı
SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    # Eski build klasörünü temizleyip yeniden oluşturuyoruz (Exit status 2 fix)
    rm -rf build && \
    mkdir -p build && \
    # Sadece senin S3 konsolun için derleme yapıyoruz
    python3 rg_tool.py --target=esp32-s3-devkit release

# Derlenen dosyaları doğrula
RUN ls -R build/
