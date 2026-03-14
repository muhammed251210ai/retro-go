# **************************************************************************
# * Kynex Sovereign Retro-Go Dockerfile v189.0
# * Geliştirici: Muhammed (Kynex)
# * Görev: ESP-IDF v4.4 üzerinde Retro-Go Launcher derleme
# * Talimat: Asla satır silmeden, tam ve tek parça kod.
# **************************************************************************

# ESP-IDF v4.4 (Retro-Go için en kararlı sürüm)
FROM espressif/idf:release-v4.4

WORKDIR /app

# Bağımlılıkları tek seferde kuruyoruz
RUN apt-get update && apt-get install -y python3-pip && \
    pip3 install pillow click

# Proje dosyalarını Docker içine al
ADD . /app

# Retro-Go yamalarını çekirdek IDF'e uygula
RUN cd /opt/esp/idf && \
	patch --ignore-whitespace -p1 -i "/app/tools/patches/panic-hook (esp-idf 4).diff" && \
	patch --ignore-whitespace -p1 -i "/app/tools/patches/sdcard-fix (esp-idf 4).diff"

# Derleme işlemi (Bash kabuğu kullanarak)
SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    # Build klasörünü oluştur
    mkdir -p build && \
    # Sadece ESP32-S3 için release sürümünü derle (Hız ayarı)
    python rg_tool.py --target=esp32-s3-devkit release

# Derlenen dosyaların kontrolü
RUN ls -R build/
