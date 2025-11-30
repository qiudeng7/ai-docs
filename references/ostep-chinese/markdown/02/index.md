# 第02章 操作系统虚拟化

## 概述

本章介绍了操作系统的基本概念和三个主要主题：虚拟化、并发和持久性。操作系统通过虚拟化技术将物理资源（CPU、内存、磁盘）转换为更通用、更强大且更易于使用的虚拟形式。

## 2.1 虚拟化CPU

### 基本概念

在单处理器系统上，操作系统通过虚拟化CPU技术，让多个程序看起来像在同时运行。这种假象是通过在硬件的帮助下，由操作系统负责提供的。

### 示例程序分析

**CPU虚拟化示例程序（cpu.c）**：
```c
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <assert.h>
#include "common.h"

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "usage: cpu <string>\n");
        exit(1);
    }
    char *str = argv[1];
    while (1) {
        Spin(1);
        printf("%s\n", str);
    }
    return 0;
}
```

**运行示例**：
```bash
prompt> gcc -o cpu cpu.c -Wall
prompt> ./cpu "A"
A
A
A
^C
prompt>

# 同时运行多个程序
prompt> ./cpu A & ; ./cpu B & ; ./cpu C & ; ./cpu D &
[1] 7353 [2] 7354 [3] 7355 [4] 7356
A B D C A B D C A C B D ...
```

### 关键机制

操作系统通过以下方式实现CPU虚拟化：
- **时分复用**：在单个CPU上快速切换运行多个进程
- **调度策略**：决定在特定时间应该运行哪个进程
- **上下文切换**：保存当前进程状态，加载下一个进程状态

## 2.2 虚拟化内存

### 物理内存模型

现代机器提供的物理内存模型非常简单：内存就是一个字节数组。要读取内存，必须指定一个地址；要写入内存，必须指定要写入给定地址的数据。

### 内存虚拟化示例

**内存访问程序（mem.c）**：
```c
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include "common.h"

int main(int argc, char *argv[]) {
    int *p = malloc(sizeof(int));              // a1
    assert(p != NULL);
    printf("(%d) memory address of p: %08x\n",
           getpid(), (unsigned) p);            // a2
    *p = 0;                                    // a3
    while (1) {
        Spin(1);
        *p = *p + 1;
        printf("(%d) p: %d\n", getpid(), *p);  // a4
    }
    return 0;
}
```

**运行结果**：
```bash
prompt> ./mem
(2134) memory address of p: 00200000
(2134) p: 1
(2134) p: 2
(2134) p: 3
(2134) p: 4
(2134) p: 5
^C

# 同时运行多个实例
prompt> ./mem &; ./mem &
[1] 24113
[2] 24114
(24113) memory address of p: 00200000
(24114) memory address of p: 00200000
(24113) p: 1
(24114) p: 1
(24114) p: 2
(24113) p: 2
(24113) p: 3
(24114) p: 3
(24113) p: 4
(24114) p: 4 ...
```

### 虚拟地址空间

每个进程都访问自己的私有虚拟地址空间，操作系统以某种方式将其映射到机器的物理内存上。这种机制确保：
- 每个进程都有独立的地址空间
- 一个进程的内存引用不会影响其他进程
- 物理内存作为共享资源由操作系统管理

## 2.3 并发

### 并发问题

并发指同时处理多件事情时出现的问题。这些问题不仅出现在操作系统中，也出现在多线程程序中。

### 多线程示例

**多线程程序（threads.c）**：
```c
#include <stdio.h>
#include <stdlib.h>
#include "common.h"

volatile int counter = 0;
int loops;

void *worker(void *arg) {
    int i;
    for (i = 0; i < loops; i++) {
        counter++;
    }
    return NULL;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "usage: threads <value>\n");
        exit(1);
    }
    loops = atoi(argv[1]);
    pthread_t p1, p2;
    printf("Initial value : %d\n", counter);

    Pthread_create(&p1, NULL, worker, NULL);
    Pthread_create(&p2, NULL, worker, NULL);
    Pthread_join(p1, NULL);
    Pthread_join(p2, NULL);
    printf("Final value    : %d\n", counter);
    return 0;
}
```

**运行结果**：
```bash
prompt> gcc -o thread thread.c -Wall -pthread
prompt> ./thread 1000
Initial value : 0
Final value   : 2000

prompt> ./thread 100000
Initial value : 0
Final value   : 143012     // huh??

prompt> ./thread 100000
Initial value : 0
Final value  : 137298    // what the??
```

### 竞争条件

上述示例中出现的意外结果是由于竞争条件造成的。`counter++`操作需要三条指令：
1. 将计数器的值从内存加载到寄存器
2. 将其递增
3. 将其保存回内存

由于这三条指令不是原子执行的，就可能出现不一致的结果。

## 2.4 持久性

### 持久化需求

系统内存中的数据容易丢失，因为DRAM等设备以易失方式存储数值。如果断电或系统崩溃，内存中的所有数据都会丢失。因此，需要硬件和软件来持久地存储数据。

### 文件I/O示例

**I/O程序（io.c）**：
```c
#include <stdio.h>
#include <unistd.h>
#include <assert.h>
#include <fcntl.h>
#include <sys/types.h>

int main(int argc, char *argv[]) {
    int fd = open("/tmp/file", O_WRONLY | O_CREAT | O_TRUNC, S_IRWXU);
    assert(fd > -1);
    int rc = write(fd, "hello world\n", 13);
    assert(rc == 13);
    close(fd);
    return 0;
}
```

### 文件系统功能

文件系统负责：
- 确定新数据在磁盘上的存储位置
- 维护各种数据结构
- 处理I/O请求
- 实现写入协议（如日志或写时复制）
- 提供崩溃恢复机制

## 2.5 设计目标

### 主要设计目标

1. **抽象化**：提供方便易用的抽象，让系统更易于使用
2. **高性能**：最小化操作系统的开销，包括时间和空间开销
3. **保护**：确保程序之间以及程序与操作系统之间的隔离
4. **可靠性**：确保操作系统能够持续稳定运行
5. **其他目标**：能源效率、安全性、移动性等

### 抽象的重要性

抽象在计算机科学中至关重要：
- 使编写大型程序成为可能
- 将程序划分为小而易于理解的部分
- 隐藏底层复杂性
- 提供统一的接口

## 2.6 操作系统发展历史

### 早期阶段：批处理系统

- 操作系统只是常用函数库
- 一次只运行一个程序
- 由操作员控制作业执行顺序

### 发展阶段：保护和多道程序

- 引入系统调用概念
- 实现用户模式和内核模式
- 支持多道程序，提高CPU利用率
- 解决内存保护和并发问题

### UNIX时代

- 由贝尔实验室的Ken Thompson和Dennis Ritchie开发
- 汇集了许多优秀思想，创造了简单而强大的系统
- 倡导"构建小而强大的程序"的理念
- 开源软件的早期形式

### 现代操作系统

- 个人计算机时代：早期出现功能倒退
- 成熟系统的复兴：macOS X基于UNIX，Windows NT引入先进技术
- 移动设备时代：Linux在Android中广泛应用
- 云计算时代：Linux成为主导平台

## 2.7 小结

本章介绍了操作系统的基本概念和三个核心主题：

1. **虚拟化**：将物理资源转换为更易用的虚拟形式
2. **并发**：处理同时执行多个任务的问题
3. **持久性**：确保数据的长期存储和可靠性

现代操作系统通过这些技术使系统变得易于使用、高效和可靠。本书后续部分将深入探讨这些主题的实现细节。

## 参考资料

- [BS+09] "Tolerating File-System Mistakes with EnvyFS"
- [BH00] "The Evolution of Operating Systems"
- [BOH10] "Computer Systems: A Programmer's Perspective"
- [PP03] "Introduction to Computing Systems: From Bits and Gates to C and Beyond"
- [RT74] "The UNIX Time-Sharing System"

这些参考资料提供了操作系统理论和实践的深入背景知识。