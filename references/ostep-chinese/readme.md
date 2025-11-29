# 操作系统导论中文版


## 文档处理

### 1. 获取pdf

你可以通过 pdf_download_links 自行下载按章节进行中文翻译的pdf，下载链接提取自 https://github.com/iTanken/ostep-chinese 中提到的中文pdf链接。

看起来是原书作者 remzi-arpacidusseau 把pdf上传到了他所在学校的服务器，download_links.txt中的链接全部指向服务器。

```bash
wget -c -v -i ./pdf_download_links.txt
```

我已经下载好后的文件放在pdf目录下。

### 转图片

claude code不能直接读pdf，为了方便AI处理，使用unipdf把pdf渲染成jpg，输出到`pdf-to-jpg`目录下

### 生成索引

使用claude code的无头模式总结每一个pdf的内容，然后生成300字摘要，再根据摘要生成索引到readme。