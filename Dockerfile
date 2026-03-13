# ESP-IDF v4.4 kullanıyoruz (Retro-Go ile en uyumlu sürüm)
FROM espressif/idf:release-v4.4

WORKDIR /app

# Sistem bağımlılıklarını ve Retro-Go için gerekli Python kütüphanelerini kur
RUN apt-get update && apt-get install -y python3-pip && \
    pip3 install pillow click

ADD . /app

# MUHAMMED: SDK Yamalarını Uygula (S3 Desteği ve SD Düzeltmeleri)
RUN cd /opt/esp/idf && \
	patch --ignore-whitespace -p1 -i "/app/tools/patches/panic-hook (esp-idf 4).diff" && \
	patch --ignore-whitespace -p1 -i "/app/tools/patches/sdcard-fix (esp-idf 4).diff"

# Derleme Süreci
SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    # Öncelikle senin ana hedefini derliyoruz
    python rg_tool.py --target=esp32-s3-devkit release && \
    # Muhammed'in isteği üzerine diğer hedefler de tutuluyor (Silme yapılmadı)
	python rg_tool.py --target=odroid-go release && \
	python rg_tool.py --target=mrgc-g32 release

# Build klasörünü görünür yap
RUN ls -la build/
