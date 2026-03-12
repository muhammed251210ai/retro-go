FROM espressif/idf:release-v4.4

WORKDIR /app

ADD . /app

# RUN pip install -r requirements.txt

# Apply patches
RUN cd /opt/esp/idf && \
	patch --ignore-whitespace -p1 -i "/app/tools/patches/panic-hook (esp-idf 4).diff" && \
	patch --ignore-whitespace -p1 -i "/app/tools/patches/sdcard-fix (esp-idf 4).diff"

# Build
SHELL ["/bin/bash", "-c"]
RUN . /opt/esp/idf/export.sh && \
    idf.py set-target esp32s3 && \
    python rg_tool.py --target=esp32-s3-devkit release && \
	python rg_tool.py --target=odroid-go release && \
	python rg_tool.py --target=mrgc-g32 release
