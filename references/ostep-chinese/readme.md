# 操作系统导论中文版

本项目的目标是获取一份中文版《操作系统导论》的相对准确的markdown版本，从而方便AI阅读。

## 目录


## 如何工作

这里介绍我是如何进行工作的。在网络上我只能找到pdf版本的资源，claude code不能直接读pdf，pdf转换成markdown也没有非常统一的方法，我尝试过marker，效果并不是很好。所以我认为最好的方式就是把pdf整页渲染成图片，再把pdf中的图片元素提取出来，现在许多模型有相当不错的识图能力，让AI根据图片转markdown，再用AI对最终的markdown建立目录索引，就可以得到pdf转markdown的电子书。

### 获取pdf

你可以通过 pdf_download_links 自行下载按章节进行中文翻译的pdf，下载链接提取自 https://github.com/iTanken/ostep-chinese 中提到的中文pdf链接。

看起来是原书作者 remzi-arpacidusseau 把pdf上传到了他所在学校的服务器，download_links.txt 中的链接全部指向服务器。

```bash
wget -c -v -i ./pdf_download_links.txt
```

我已经下载好后的文件放在pdf目录下。