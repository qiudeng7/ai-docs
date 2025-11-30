# 第6章 机制：受限直接执行

## 概述

为了虚拟化CPU，操作系统需要以某种方式让许多任务共享物理CPU，让它们看起来像是同时运行。基本思想很简单：运行一个进程一段时间，然后运行另一个进程，如此轮换。通过以这种方式时分共享（time sharing）CPU，就实现了虚拟化。

然而，在构建这样的虚拟化机制时存在一些挑战：
- **性能**：如何在不增加系统开销的情况下实现虚拟化？
- **控制权**：如何有效地运行进程，同时保留对CPU的控制？

**关键问题**：如何高效、可控地虚拟化CPU？操作系统必须以高性能的方式虚拟化CPU，同时保持对系统的控制。为此，需要硬件和操作系统支持。

## 6.1 基本技巧：受限直接执行

为了使程序尽可能快地运行，操作系统开发人员想出了一种技术——我们称之为受限的直接执行（limited direct execution）。

### 直接执行协议

"直接执行"部分很简单：只需直接在CPU上运行程序即可。当OS希望启动程序运行时，它会：
1. 在进程列表中为其创建一个进程条目
2. 为其分配一些内存
3. 将程序代码（从磁盘）加载到内存中
4. 找到入口点（main()函数或类似的）
5. 跳转到那里，并开始运行用户的代码

**表6.1 直接运行协议（无限制）**

| 操作系统 | 程序 |
|---------|------|
| 在进程列表上创建条目 | |
| 为程序分配内存 | |
| 将程序加载到内存中 | |
| 根据argc/argv设置程序栈 | |
| 清除寄存器 | |
| 执行call main()方法 | 执行main() |
| | 从main中执行return |
| 释放进程的内存 | |
| 将进程从进程列表中清除 | |

### 挑战

这种方法产生了一些问题：
1. **限制问题**：如果我们只运行一个程序，操作系统怎么能确保程序不做任何我们不希望它做的事？
2. **切换问题**：当我们运行一个进程时，操作系统如何让它停下来并切换到另一个进程？

## 6.2 问题1：受限制的操作

直接执行的明显优势是快速。但是，在CPU上运行会带来一个问题——如果进程希望执行某种受限操作（如向磁盘发出I/O请求或获得更多系统资源），该怎么办？

### 解决方案：用户模式与内核模式

硬件通过提供不同的执行模式来协助操作系统：
- **用户模式（user mode）**：应用程序不能完全访问硬件资源
- **内核模式（kernel mode）**：操作系统可以访问机器的全部资源

硬件还提供了：
- 陷入（trap）内核的特别说明
- 从陷阱返回（return-from-trap）到用户模式程序的特别说明
- 让操作系统告诉硬件陷阱表（trap table）在内存中的位置的指令

### 系统调用机制

要执行系统调用，程序必须执行特殊的陷阱（trap）指令。该指令：
1. 同时跳入内核
2. 将特权级别提升到内核模式
3. 一旦进入内核，系统可以执行任何需要的特权操作
4. 完成后，操作系统调用从陷阱返回（return-from-trap）指令
5. 返回到发起调用的用户程序，同时将特权级别降低到用户模式

### 陷阱表机制

内核通过在启动时设置陷阱表（trap table）来实现控制：
1. 当机器启动时，它在特权（内核）模式下执行
2. 操作系统告诉硬件在发生某些异常事件时要运行哪些代码
3. 操作系统通过特殊指令通知硬件陷阱处理程序的位置
4. 设置陷阱表是特权操作，只能在内核模式下执行

**表6.2 受限直接运行协议**

| 操作系统@启动（内核模式） | 硬件 |
|------------------------|------|
| 初始化陷阱表 | 记住系统调用处理程序的地址 |

| 操作系统@运行（内核模式） | 硬件 | 程序（应用模式） |
|------------------------|------|----------------|
| 在进程列表上创建条目 | | |
| 为程序分配内存 | | |
| 将程序加载到内存中 | | |
| 根据argv设置程序栈 | | |
| 用寄存器/程序计数器填充内核栈 | | |
| 从陷阱返回 | 从内核栈恢复寄存器 | |
| | 转向用户模式 | |
| | 跳到main | 运行main |
| | | …… |
| | | 调用系统调用 |
| | 陷入操作系统 | |
| | 将寄存器保存到内核栈 | |
| | 转向内核模式 | |
| | 跳到陷阱处理程序 | |
| 处理陷阱 | | |
| 做系统调用的工作 | | |
| 从陷阱返回 | 从内核栈恢复寄存器 | |
| | 转向用户模式 | |
| | 跳到陷阱之后的程序计数器 | |
| | | ……从main返回 |
| 陷入（通过exit()） | | |
| 释放进程的内存 | | |
| 将进程从进程列表中清除 | | |

## 6.3 问题2：在进程之间切换

直接执行的下一个问题是实现进程之间的切换。如果操作系统没有在CPU上运行，那么操作系统显然没有办法采取行动。

### 关键问题
如何重获CPU的控制权？操作系统如何重新获得CPU的控制权，以便它可以在进程之间切换？

### 协作方式：等待系统调用

过去某些系统采用协作（cooperative）方式：
- 操作系统相信系统的进程会合理运行
- 运行时间过长的进程被假定会定期放弃CPU
- 进程通过进行系统调用将CPU控制权转移给操作系统
- 包括显式的yield系统调用，只是将控制权交给操作系统

**缺点**：如果某个进程（无论是恶意的还是充满缺陷的）进入无限循环，并且从不进行系统调用，会发生什么？那时操作系统能做什么？

### 非协作方式：操作系统进行控制

**解决方案**：时钟中断（timer interrupt）

时钟设备可以编程为每隔几毫秒产生一次中断：
1. 产生中断时，当前正在运行的进程停止
2. 操作系统中预先配置的中断处理程序会运行
3. 操作系统重新获得CPU的控制权
4. 可以停止当前进程，并启动另一个进程

### 保存和恢复上下文

如果决定进行切换，OS就会执行上下文切换（context switch）：
1. 为当前正在执行的进程保存一些寄存器的值（到它的内核栈）
2. 为即将执行的进程恢复一些寄存器的值（从它的内核栈）
3. 确保最后执行从陷阱返回指令时，继续执行另一个进程

**表6.3 受限直接执行协议（时钟中断）**

| 操作系统@启动（内核模式） | 硬件 |
|------------------------|------|
| 初始化陷阱表 | 记住以下地址：系统调用处理程序、时钟处理程序 |
| 启动中断时钟 | 启动时钟，每隔x ms中断CPU |

| 操作系统@运行（内核模式） | 硬件 | 程序（应用模式） |
|------------------------|------|----------------|
| | | 进程A…… |
| | 时钟中断 | |
| | 将寄存器（A）保存到内核栈（A） | |
| | 转向内核模式 | |
| | 跳到陷阱处理程序 | |
| 处理陷阱 | | |
| 调用switch()例程 | | |
| 将寄存器（A）保存到进程结构（A） | | |
| 将进程结构（B）恢复到寄存器（B） | | |
| 从陷阱返回（进入B） | 从内核栈（B）恢复寄存器（B） | |
| | 转向用户模式 | |
| | 跳到B的程序计数器 | |
| | | 进程B…… |

### 上下文切换代码示例

图6.1展示了xv6的上下文切换代码：

```assembly
# void swtch(struct context **old, struct context *new);
#
# Save current register context in old
# and then load register context from new.
.globl swtch
swtch:
  # Save old registers
  movl 4(%esp), %eax     # put old ptr into eax
  popl 0(%eax)           # save the old IP
  movl %esp, 4(%eax)     # and stack
  movl %ebx, 8(%eax)     # and other registers
  movl %ecx, 12(%eax)
  movl %edx, 16(%eax)
  movl %esi, 20(%eax)
  movl %edi, 24(%eax)
  movl %ebp, 28(%eax)

  # Load new registers
  movl 4(%esp), %eax     # put new ptr into eax
  movl 28(%eax), %ebp    # restore other registers
  movl 24(%eax), %edi
  movl 20(%eax), %esi
  movl 16(%eax), %edx
  movl 12(%eax), %ecx
  movl 8(%eax), %ebx
  movl 4(%eax), %esp     # stack is switched here
  pushl 0(%eax)          # return addr put in place
  ret                    # finally return into new ctxt
```

## 6.4 担心并发吗

一个重要问题：在系统调用期间发生时钟中断时会发生什么？处理一个中断时发生另一个中断，会发生什么？

答案是：操作系统必须关心这些情况，这正是本书第2部分关于并发的主题。

**解决方案**：
- 在中断处理期间禁止中断（disable interrupt）
- 开发复杂的加锁（locking）方案，保护对内部数据结构的并发访问

## 6.5 小结

我们已经描述了一些实现CPU虚拟化的关键底层机制，并将其统称为受限直接执行（limited direct execution）。

**基本思路**：让程序在CPU上运行，但首先确保设置好硬件，以便在没有操作系统帮助的情况下限制进程可以执行的操作。

**操作系统的工作**：
1. 首先设置陷阱处理程序并启动时钟中断
2. 只在受限模式下运行进程
3. 确保进程可以高效运行
4. 只在执行特权操作或独占CPU时间过长时才需要操作系统干预

至此，我们有了虚拟化CPU的基本机制。下一个主题是：在特定时间，我们应该运行哪个进程？

## 参考资料

[A79] "Alto User's Handbook" - Xerox Palo Alto Research Center, September 1979

[C+04] "Microreboot — A Technique for Cheap Recovery" - George Candea等, OSDI '04

[I11] "Intel 64 and IA-32 Architectures Software Developer's Manual" - Intel Corporation, January 2011

[K+61] "One-Level Storage System" - T. Kilburn等, IRE Transactions on Electronic Computers, April 1962

[L78] "The Manchester Mark I and Atlas: A Historical Perspective" - S. H. Lavington, Communications of the ACM, 21:1, January 1978

[M+63] "A Time-Sharing Debugging System for a Small Computer" - J. McCarthy等, AFIPS '63

[MS96] "lmbench: Portable tools for performance analysis" - Larry McVoy and Carl Staelin, USENIX Annual Technical Conference, January 1996

[M11] "macOS 9" - January 2011

[O90] "Why Aren't Operating Systems Getting Faster as Fast as Hardware?" - J. Ousterhout, USENIX Summer Conference, June 1990

[P10] "The Single UNIX Specification, Version 3" - The Open Group, May 2010

[S07] "The Geometry of Innocent Flesh on the Bone: Return-into-libc without Function Calls (on the x86)" - Hovav Shacham, CCS '07

## 作业（测量）

在这个作业中，你将测量系统调用和上下文切换的成本。

### 测量系统调用成本
相对容易。可以重复调用一个简单的系统调用（例如，执行0字节读取）并记下所花的时间。将时间除以迭代次数，就可以估计系统调用的成本。

**注意事项**：
- 考虑时钟的精确性和准确性
- 使用gettimeofday()或x86机器提供的rdtsc指令
- 测量gettimeofday()的连续调用，了解时钟的精确度

### 测量上下文切换成本
比较棘手。lmbench基准测试的实现方法：
1. 在单个CPU上运行两个进程
2. 在它们之间设置两个UNIX管道
3. 通过反复测量通信的成本来估计上下文切换的成本

**多CPU系统注意事项**：
- 确保上下文切换进程处于同一个处理器上
- 使用系统调用如sched_setaffinity()将进程绑定到特定处理器