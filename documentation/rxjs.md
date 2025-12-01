# RxJS 渐进式学习指南

> 基于官方文档和实战案例的 RxJS 学习教程

## 📚 学习大纲

这个教程将通过实际的代码例子，循序渐进地介绍 RxJS 的核心概念和最佳实践。

### 章节

1. **[入门：为什么需要 RxJS？](#1-入门为什么需要-rxjs)**
   - 从传统事件监听到 Observable 的思维转变
   - 理解 Observable 的核心价值

2. **[Observable 基础](#2-observable-基础)**
   - Observable 的生命周期
   - 手动创建 Observable
   - Subscribe 订阅机制

3. **[Operators：数据流的魔法](#3-operators数据流的魔法)**
   - 创建类操作符
   - 转换类操作符
   - 过滤类操作符
   - 组合类操作符

4. **[流控制：掌握节奏](#4-流控制掌握节奏)**
   - 时间控制操作符
   - 背压处理
   - 错误处理

5. **[实战案例](#5-实战案例)**
   - 搜索框防抖
   - 拖拽功能实现
   - WebSocket 数据流处理

---

## 1. 入门：为什么需要 RxJS？

### 传统的事件监听方式

```javascript
// 传统方式：直接监听点击事件
document.addEventListener('click', function(event) {
  console.log('点击了屏幕:', event.clientX, event.clientY);
});
```

### 用 RxJS 的方式

```javascript
// RxJS 方式：创建点击事件的数据流
import { fromEvent } from 'rxjs';

fromEvent(document, 'click').subscribe(event => {
  console.log('点击了屏幕:', event.clientX, event.clientY);
});
```

### 💡 RxJS 的优势

1. **函数式编程**：避免副作用，代码更可预测
2. **组合能力**：像处理数组一样处理事件流
3. **强大的操作符**：内置丰富的数据流处理工具
4. **异步管理**：统一处理各种异步操作

---

## 2. Observable 基础

### 2.1 Observable 的生命周期

```javascript
import { Observable } from 'rxjs';

// 创建一个 Observable
const myObservable = new Observable(subscriber => {
  subscriber.next(1);  // 发出值
  subscriber.next(2);  // 发出值
  subscriber.next(3);  // 发出值
  setTimeout(() => {
    subscriber.next(4);  // 1秒后发出值
    subscriber.complete(); // 完成
  }, 1000);
});

// 订阅 Observable
console.log('开始订阅...');
myObservable.subscribe({
  next: value => console.log('收到值:', value),
  error: err => console.error('出错了:', err),
  complete: () => console.log('完成了!')
});
```

**输出结果：**
```
开始订阅...
收到值: 1
收到值: 2
收到值: 3
// 1秒后...
收到值: 4
完成了!
```

### 2.2 常用的 Observable 创建方法

#### fromEvent - DOM 事件流
```javascript
import { fromEvent } from 'rxjs';

// 监听鼠标移动
const mouseMove$ = fromEvent(document, 'mousemove');
mouseMove$.subscribe(event => {
  console.log(`鼠标位置: ${event.clientX}, ${event.clientY}`);
});
```

#### from - 数组/迭代器转 Observable
```javascript
import { from } from 'rxjs';

const numbers$ = from([1, 2, 3, 4, 5]);
numbers$.subscribe(num => console.log(num));
// 输出: 1 2 3 4 5
```

#### interval - 定时器 Observable
```javascript
import { interval } from 'rxjs';

const timer$ = interval(1000); // 每秒发出一个递增的数字
timer$.subscribe(num => console.log(`秒数: ${num}`));
// 输出: 0 1 2 3...
```

---

## 3. Operators：数据流的魔法

Operators 是 RxJS 的核心，它们允许我们以函数式的方式处理数据流。

### 3.1 转换类操作符

#### map - 数据转换
```javascript
import { fromEvent, map } from 'rxjs';

fromEvent(document, 'click')
  .pipe(
    map(event => ({ x: event.clientX, y: event.clientY }))
  )
  .subscribe(position => {
    console.log('点击位置:', position);
  });
```

#### scan - 累积计算
```javascript
import { fromEvent, scan } from 'rxjs';

// 统计点击次数
fromEvent(document, 'click')
  .pipe(
    scan(count => count + 1, 0)
  )
  .subscribe(count => {
    console.log(`已点击 ${count} 次`);
  });
```

### 3.2 过滤类操作符

#### filter - 条件过滤
```javascript
import { fromEvent, filter } from 'rxjs';

fromEvent(document, 'click')
  .pipe(
    filter(event => event.clientX > 500) // 只处理屏幕右半边的点击
  )
  .subscribe(event => {
    console.log('右半屏点击:', event.clientX);
  });
```

#### take - 限制数量
```javascript
import { fromEvent, take } from 'rxjs';

// 只处理前3次点击
fromEvent(document, 'click')
  .pipe(take(3))
  .subscribe(event => {
    console.log('点击:', event.clientX);
  });
```

### 3.3 时间控制操作符

#### throttleTime - 节流
```javascript
import { fromEvent, throttleTime } from 'rxjs';

// 限制最多每500ms触发一次
fromEvent(document, 'mousemove')
  .pipe(
    throttleTime(500)
  )
  .subscribe(event => {
    console.log('鼠标移动:', event.clientX);
  });
```

#### debounceTime - 防抖
```javascript
import { fromEvent, debounceTime } from 'rxjs';

// 停止输入500ms后才触发
fromEvent(document.getElementById('search'), 'input')
  .pipe(
    debounceTime(500)
  )
  .subscribe(event => {
    console.log('搜索内容:', event.target.value);
  });
```

### 3.4 组合操作符

#### merge - 合并多个 Observable
```javascript
import { fromEvent, merge } from 'rxjs';

const click$ = fromEvent(document, 'click');
const keydown$ = fromEvent(document, 'keydown');

merge(click$, keydown$)
  .subscribe(event => {
    console.log('事件类型:', event.type);
  });
```

#### combineLatest - 组合最新值
```javascript
import { fromEvent, combineLatest } from 'rxjs';

const mouseMove$ = fromEvent(document, 'mousemove');
const keyPress$ = fromEvent(document, 'keypress');

combineLatest([mouseMove$, keyPress$])
  .subscribe(([mouseEvent, keyEvent]) => {
    console.log(`鼠标位置: ${mouseEvent.clientX}, 按键: ${keyEvent.key}`);
  });
```

---

## 4. 流控制：掌握节奏

### 4.1 错误处理

#### catchError - 捕获并处理错误
```javascript
import { throwError, catchError } from 'rxjs';

const errorObservable$ = throwError('出错了!');

errorObservable$.pipe(
  catchError(error => {
    console.log('捕获到错误:', error);
    return ['默认值1', '默认值2']; // 返回备用数据流
  })
).subscribe(value => {
  console.log('收到值:', value);
});
```

#### retry - 重试机制
```javascript
import { ajax } from 'rxjs/ajax';
import { retry, catchError } from 'rxjs';

// 尝试3次，失败后返回备用数据
const data$ = ajax('/api/data').pipe(
  retry(3),
  catchError(error => {
    console.log('API调用失败:', error);
    return of({ data: [] }); // 返回空数据
  })
);
```

### 4.2 订阅管理

#### 取消订阅
```javascript
import { interval, take } from 'rxjs';

const subscription = interval(1000).subscribe(num => {
  console.log('数字:', num);
});

// 5秒后取消订阅
setTimeout(() => {
  subscription.unsubscribe();
  console.log('已取消订阅');
}, 5000);
```

#### takeUntil - 条件取消
```javascript
import { fromEvent, interval, takeUntil } from 'rxjs';

const timer$ = interval(1000);
const stop$ = fromEvent(document.getElementById('stop'), 'click');

// 点击停止按钮时自动取消订阅
timer$.pipe(
  takeUntil(stop$)
).subscribe(num => {
  console.log('计时:', num);
});
```

---

## 5. 实战案例

### 5.1 搜索框防抖

```javascript
import { fromEvent, map, debounceTime, distinctUntilChanged, switchMap } from 'rxjs';
import { ajax } from 'rxjs/ajax';

const searchInput = document.getElementById('search');
const searchResults = document.getElementById('results');

fromEvent(searchInput, 'input')
  .pipe(
    map(event => event.target.value),
    debounceTime(300), // 300ms防抖
    distinctUntilChanged(), // 避免重复搜索
    switchMap(query => {
      if (query.length < 2) return of([]);
      return ajax.getJSON(`/api/search?q=${query}`);
    })
  )
  .subscribe({
    next: results => {
      displaySearchResults(results);
    },
    error: error => {
      console.error('搜索失败:', error);
      searchResults.innerHTML = '<p>搜索失败，请重试</p>';
    }
  });

function displaySearchResults(results) {
  searchResults.innerHTML = results
    .map(item => `<div>${item.title}</div>`)
    .join('');
}
```

### 5.2 拖拽功能

```javascript
import { fromEvent, map, takeUntil, mergeMap, switchMap } from 'rxjs';

const draggable = document.getElementById('draggable');
const mouseDown$ = fromEvent(draggable, 'mousedown');
const mouseMove$ = fromEvent(document, 'mousemove');
const mouseUp$ = fromEvent(document, 'mouseup');

mouseDown$.pipe(
  switchMap(startEvent => {
    const startX = startEvent.clientX;
    const startY = startEvent.clientY;
    const initialLeft = draggable.offsetLeft;
    const initialTop = draggable.offsetTop;

    return mouseMove$.pipe(
      map(moveEvent => ({
        left: initialLeft + moveEvent.clientX - startX,
        top: initialTop + moveEvent.clientY - startY
      })),
      takeUntil(mouseUp$)
    );
  })
).subscribe(position => {
  draggable.style.left = `${position.left}px`;
  draggable.style.top = `${position.top}px`;
});
```

### 5.3 WebSocket 数据流处理

```javascript
import { fromEvent, merge, of, timer } from 'rxjs';
import { map, filter, scan, retry, catchError } from 'rxjs';

class WebSocketClient {
  constructor(url) {
    this.url = url;
    this.socket = null;
    this.connection$ = this.createConnection();
  }

  createConnection() {
    return of(null).pipe(
      map(() => {
        this.socket = new WebSocket(this.url);
        return this.socket;
      }),
      retry(3), // 连接失败重试3次
      catchError(() => {
        console.error('WebSocket连接失败');
        return of(null);
      })
    );
  }

  messages() {
    return this.connection$.pipe(
      switchMap(socket => {
        if (!socket) return of();
        return fromEvent(socket, 'message').pipe(
          map(event => JSON.parse(event.data)),
          retry(3)
        );
      })
    );
  }

  send(data) {
    this.connection$.subscribe(socket => {
      if (socket && socket.readyState === WebSocket.OPEN) {
        socket.send(JSON.stringify(data));
      }
    });
  }

  close() {
    this.connection$.subscribe(socket => {
      if (socket) {
        socket.close();
      }
    });
  }
}

// 使用示例
const wsClient = new WebSocketClient('wss://example.com/socket');

wsClient.messages().pipe(
  filter(msg => msg.type === 'chat'),
  scan((messages, msg) => [...messages, msg.content], []),
  map(messages => messages.slice(-10)) // 只保留最近10条消息
).subscribe(recentMessages => {
  updateChatWindow(recentMessages);
});

function updateChatWindow(messages) {
  const chatDiv = document.getElementById('chat');
  chatDiv.innerHTML = messages.map(msg => `<div>${msg}</div>`).join('');
}
```

---

## 🎯 学习建议

1. **从简单开始**：先理解 Observable 的基本概念，再学习 Operators
2. **多练习**：尝试将现有的事件处理代码改写成 RxJS
3. **理解操作符**：每个操作符都有其特定用途，不要滥用
4. **注意性能**：合理使用 takeUntil、unsubscribe 等避免内存泄漏

## 🔗 相关资源

- [RxJS 官方文档](@references/rxjs/apps/rxjs.dev/content/)
- [RxJS 操作符决策树](@references/rxjs/apps/rxjs.dev/content/operator-decision-tree.yml)
- [Observable 官方指南](@references/rxjs/apps/rxjs.dev/content/guide/observable.md)
- [Operators 官方指南](@references/rxjs/apps/rxjs.dev/content/guide/operators.md)