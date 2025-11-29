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

claude code不能直接读pdf，pdf转换成markdown也没有非常统一的方法，所以最好的方式就是把pdf整页渲染成图片，再把pdf中的图片元素提取出来，现在许多模型有相当不错的识图能力，让AI根据图片转markdown，再用AI对最终的markdown建立目录索引，就可以得到pdf转markdown的电子书。

### 生成索引

使用claude code的无头模式总结每一个pdf的内容，然后生成300字摘要，再根据摘要生成索引到readme。