# 操作系统导论中文版

本项目的目标是获取一份中文版《操作系统导论》的相对准确的markdown版本，从而方便AI阅读。

## 目录

- 前言
- 第一部分：基础概念
  - 第1章：关于操作系统的一则对话
  - 第2章：操作系统虚拟化
  - 第3章：并发
  - 第4章：持久化
- 第二部分：虚拟化
  - 第5章：虚拟化简介
  - 第6章：进程
  - 第7章：CPU调度
  - 第8章：内存管理API
  - 第9章：虚拟内存
  - 第10章：高级虚拟内存技术
  - 第11章：并发和锁
  - 第12章：条件变量
  - 第13章：信号量
  - 第14章：并发中的高级主题
- 第三部分：持久化
  - 第15章：磁盘和I/O设备
  - 第16章：文件系统
  - 第17章：文件系统实现
  - 第18章：日志文件系统
  - 第19章：快速文件系统(FFS)
  - 第20章：崩溃恢复
  - 第21章：分布式系统
- 第四部分：安全与保护
  - 第22章：保护
  - 第23章：安全
  - 第24章：虚拟机监控器
  - 第25章：数据库名字管理
  - 第26章：并发控制
  - 第27章：恢复系统
  - 第28章：分布式数据库
- 第五部分：实例研究
  - 第29章：Linux操作系统
  - 第30章：Windows操作系统
- 附录
  - 附录A：系统调用接口
  - 附录B：命令行工具
  - 附录C：实验指导
  - 附录D：术语表
  - 附录E：参考文献


## 如何转译

这里介绍我是如何进行转译工作的。在网络上我只能找到pdf版本的资源，由于claude code不能直接读pdf，且pdf转换成markdown也没有非常统一的方法(我尝试过marker，效果并不是很好)。所以我认为最好的方式就是：

1. 整页渲染pdf图片(`pdf_render_image/`目录)，用于ai理解内容排版
2. 提取pdf图片 (`pdf_extract_image/`目录)，用于ai生成markdown的时候引用图片
3. 提取pdf文本 (`pdf_extract_text/`目录)，用于ai利用该文本生成markdown
4. 让一个agent A 组织多个agent B，每个agent B只翻译一小节，要求如下：
   1. 文档生成在 `markdown/[pdf file name as dir name]/index.md`，如有必要，切割成多个文档。
   2. pdf_extract_image 和 pdf_render_image 中小节内容是对应的，但有的小节没有图片，pdf_extract_image中就不会有对应的目录。
   3. 如果需要引用图片，把图片复制到`markdown/[pdf file name as dir name]/images/`目录下引用，如果不需要就不创建该目录。

### 获取pdf

你可以通过 pdf_download_links 自行下载按章节进行中文翻译的pdf，下载链接提取自 https://github.com/iTanken/ostep-chinese 中提到的中文pdf链接。

看起来是原书作者 remzi-arpacidusseau 把pdf上传到了他所在学校的服务器，download_links.txt 中的链接全部指向服务器。

```bash
wget -c -v -i ./pdf_download_links.txt
```

我已经下载好后的文件放在pdf目录下。