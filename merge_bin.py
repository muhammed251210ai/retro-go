# **************************************************************************
# * KynexOs v183.0 - Automatic Binary Merger Script
# * Geliştirici: Muhammed (Kynex)
# * Görev: Tüm sistem ve oyun dosyalarını tek bir 16MB imajda birleştirir.
# **************************************************************************
import os

Import("env")

def merge_binaries(source, target, indent):
    # Dosya yollarını tanımlıyoruz
    build_dir = env.subst("$BUILD_DIR")
    # Çıktı dosyasının adı
    output_bin = os.path.join(build_dir, "MASTER_KYNEX_SOVEREIGN.bin")
    
    # Parçaların konumları (Muhammed'in 16MB Haritası)
    # Not: launcher.bin ve ffat.bin dosyalarının proje kök dizininde olduğu varsayılır.
    bootloader = os.path.join(build_dir, "bootloader.bin")
    partitions = os.path.join(build_dir, "partitions.bin")
    kynexos = os.path.join(build_dir, "firmware.bin")
    
    # Dışarıdan gelen dosyalar (Eğer kök dizinde yoksa derleme hata vermez, sadece sistemleri birleştirir)
    retrogo = "launcher.bin"
    storage = "ffat.bin"

    print("\n[KYNEX-OS] Tek parça firmware oluşturuluyor...")

    cmd = [
        "$PYTHONEXE", "$OBJCOPY", "--chip", "esp32s3", "merge_bin",
        "-o", output_bin,
        "--flash_mode", "dio",
        "--flash_size", "16MB",
        "0x0000", bootloader,
        "0x8000", partitions
    ]

    # Retro-Go (Factory) kontrolü
    if os.path.exists(retrogo):
        cmd.extend(["0x10000", retrogo])
        print(f"[KYNEX-OS] Retro-Go eklendi: {retrogo}")
    
    # KynexOs (OTA_0) eklemesi
    cmd.extend(["0x410000", kynexos])
    
    # FFat (Storage) kontrolü
    if os.path.exists(storage):
        cmd.extend(["0xC10000", storage])
        print(f"[KYNEX-OS] Storage (Oyunlar) eklendi: {storage}")

    env.Execute(" ".join(cmd))
    print(f"\n[KYNEX-OS] BAŞARILI! Tek dosyan hazır: {output_bin}\n")

# Derleme bittikten sonra bu fonksiyonu çalıştır
env.AddPostAction("$BUILD_DIR/${PROGNAME}.bin", merge_binaries)
