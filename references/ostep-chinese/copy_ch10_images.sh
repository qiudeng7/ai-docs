#!/bin/bash

# 复制第10章图片文件脚本

# 源目录
SOURCE_DIR="pdf_extract_image/10/"
# 目标目录
TARGET_DIR="markdown/10/images/"

# 要复制的文件列表
FILES=(
    "page_002_img_01.png"
    "page_002_img_02.png"
    "page_004_img_01.png"
    "page_004_img_02.png"
    "page_005_img_01.png"
    "page_005_img_02.png"
    "page_005_img_03.png"
    "page_006_img_01.png"
    "page_006_img_02.png"
    "page_006_img_03.png"
    "page_006_img_04.png"
    "page_006_img_05.png"
    "page_006_img_06.png"
    "page_006_img_07.png"
)

echo "开始复制第10章图片文件..."

# 复制每个文件
for file in "${FILES[@]}"; do
    echo "复制: $file"
    cp "$SOURCE_DIR$file" "$TARGET_DIR"
    if [ $? -eq 0 ]; then
        echo "✓ 成功复制: $file"
    else
        echo "✗ 复制失败: $file"
    fi
done

echo "图片复制完成!"

# 验证复制的文件
echo "验证复制的文件:"
ls -la "$TARGET_DIR" | grep "page_.*\.png"