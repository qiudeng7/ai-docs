#!/usr/bin/env python3
import shutil
import os

# 源目录和目标目录
source_dir = "pdf_extract_image/10/"
target_dir = "markdown/10/images/"

# 要复制的文件列表
files_to_copy = [
    "page_002_img_01.png",
    "page_002_img_02.png",
    "page_004_img_01.png",
    "page_004_img_02.png",
    "page_005_img_01.png",
    "page_005_img_02.png",
    "page_005_img_03.png",
    "page_006_img_01.png",
    "page_006_img_02.png",
    "page_006_img_03.png",
    "page_006_img_04.png",
    "page_006_img_05.png",
    "page_006_img_06.png",
    "page_006_img_07.png"
]

print("开始复制第10章图片文件...")

for filename in files_to_copy:
    source_path = os.path.join(source_dir, filename)
    target_path = os.path.join(target_dir, filename)

    try:
        shutil.copy2(source_path, target_path)
        print(f"✓ 成功复制: {filename}")
    except Exception as e:
        print(f"✗ 复制失败 {filename}: {e}")

print("复制完成!")

# 验证复制的文件
print("目标目录中的文件:")
os.system(f"ls -la {target_dir}")