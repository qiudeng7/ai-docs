#!/bin/bash

# 简单的操作系统导论中文版翻译脚本

# 翻译单个章节
translate_chapter() {
    local chapter_num="$1"
    local chapter_name="$2"

    echo "开始翻译第${chapter_num}章: $chapter_name"

    # 创建目录
    mkdir -p "markdown/$chapter_num"

    # 启动Claude Code翻译（允许文件写入）
    claude -p "@readme.md 理解我的翻译策略，现在你来处理第${chapter_num}章：$chapter_name。请将翻译结果保存到 markdown/$chapter_num/index.md 文件中。" --allowedTools "Read,Write" 

    echo "第${chapter_num}章翻译任务已启动"
}

# 如果提供了参数，翻译指定章节
if [ $# -ge 2 ]; then
    translate_chapter "$1" "$2"
else
    echo "用法: $0 <章节号> <章节名>"
    echo "示例: $0 01 \"关于操作系统的一则对话\""
fi