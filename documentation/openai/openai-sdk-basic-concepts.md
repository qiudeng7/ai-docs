# OpenAI SDK 从网页AI视角学习指南

本文档以你熟悉的网页AI和Claude Code使用体验为起点，逐步介绍如何用SDK实现同样的功能。

## 学习目标

通过本文档，你将学会：
- 如何用SDK实现网页AI的基本对话功能
- 如何实现新会话、思考模式、联网等高级功能
- 如何让AI调用工具、访问文件等

## 知识基础

假设你已经具备：
1. 熟悉网页AI的基本操作（ChatGPT、Claude等）
2. 了解Claude Code的基本功能
3. 有基本的编程知识（Python/JavaScript）
4. 了解异步编程的基本概念

## 学习路径

### 1. 基础对话功能（网页AI的基础体验）

#### 1.1 从网页对话到SDK代码

**你在网页AI中的体验**：
```
你: 帮我写一个Python的Hello World程序
AI: 好的，这是一个简单的Python Hello World程序：
    print("Hello, World!")
```

**用SDK实现同样的对话**：

```python
from openai import OpenAI

# 1. 创建客户端（相当于打开网页AI）
client = OpenAI(
    api_key="你的API密钥",
    base_url="https://api.openai.com"  # 或者其他API服务
)

# 2. 发送消息（相当于在输入框打字并发送）
response = client.chat.completions.create(
    model="gpt-4",  # 选择AI模型
    messages=[
        {"role": "user", "content": "帮我写一个Python的Hello World程序"}
    ]
)

# 3. 获取回复（相当于看到AI的回答）
ai_response = response.choices[0].message.content
print(ai_response)
```

**关键理解**：
- `client.chat.completions.create()` 相当于点击"发送"按钮
- `messages` 数组就是你们的对话历史
- `response.choices[0].message.content` 就是AI的回答

#### 1.2 实现打字机效果（流式响应）

**网页AI的体验**：AI的回答是一个字一个字出现的，就像有人在打字

**用SDK实现打字机效果**：

```python
# 添加 stream=True 参数
response = client.chat.completions.create(
    model="gpt-4",
    messages=[
        {"role": "user", "content": "解释什么是机器学习"}
    ],
    stream=True  # 关键参数：启用流式响应
)

# 逐个字符接收AI的回答
full_response = ""
for chunk in response:
    # 每个chunk包含一小段文字
    delta = chunk.choices[0].delta

    if delta.content:
        # 累加收到的文字片段
        full_response += delta.content
        print(delta.content, end='', flush=True)  # 实时显示

print("\n完整回答:", full_response)
```

**这样你就能看到AI像打字一样逐字回答问题了！**

#### 1.3 多轮对话（保持上下文）

**网页AI的体验**：你可以基于之前的对话继续提问

**用SDK实现多轮对话**：

```python
# 对话历史（就像网页中的聊天记录）
messages = [
    {"role": "user", "content": "我叫张三"},
    {"role": "assistant", "content": "你好张三，很高兴认识你！"},
    {"role": "user", "content": "你还记得我的名字吗？"}
]

response = client.chat.completions.create(
    model="gpt-4",
    messages=messages  # 包含完整对话历史
)

print(response.choices[0].message.content)
# AI会回答：当然记得，你叫张三！
```

**理解要点**：
- 每次对话都要包含完整的历史记录
- `messages` 数组就是AI的"记忆"
- 越长的历史记录，消耗的token越多

### 2. 会话管理（新会话、历史记录）

#### 2.1 新会话 vs 延续会话

**网页AI的体验**：
- 点击"新对话"开始全新的会话
- 在旧对话中继续聊天保持上下文

**用SDK实现会话管理**：

```python
class ChatSession:
    def __init__(self, client, system_prompt="你是一个有用的AI助手"):
        self.client = client
        self.messages = [{"role": "system", "content": system_prompt}]

    def new_conversation(self):
        """开始新会话"""
        self.messages = [{"role": "system", "content": "你是一个有用的AI助手"}]
        print("✨ 新会话已开始")

    def chat(self, user_input):
        """发送消息并获取回复"""
        # 添加用户消息
        self.messages.append({"role": "user", "content": user_input})

        # 获取AI回复
        response = self.client.chat.completions.create(
            model="gpt-4",
            messages=self.messages
        )

        ai_response = response.choices[0].message.content

        # 添加AI回复到历史
        self.messages.append({"role": "assistant", "content": ai_response})

        return ai_response

    def get_history(self):
        """获取对话历史"""
        return self.messages.copy()

# 使用示例
client = OpenAI(api_key="your-key")
session = ChatSession(client)

# 第一次对话
print(session.chat("我叫李四"))  # AI会记住这个名字

# 继续对话
print(session.chat("我刚才告诉你什么名字？"))  # AI会回答：李四

# 开始新会话
session.new_conversation()
print(session.chat("我刚才告诉你什么名字？"))  # AI会说不记得
```

#### 2.2 会话持久化（保存和加载对话）

**保存对话历史到文件**：

```python
import json

def save_session(session, filename="chat_history.json"):
    """保存会话到文件"""
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(session.get_history(), f, ensure_ascii=False, indent=2)
    print(f"💾 对话已保存到 {filename}")

def load_session(client, filename="chat_history.json"):
    """从文件加载会话"""
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            messages = json.load(f)

        session = ChatSession(client)
        session.messages = messages
        print(f"📂 已从 {filename} 加载对话历史")
        return session
    except FileNotFoundError:
        print(f"❌ 文件 {filename} 不存在")
        return ChatSession(client)

# 使用示例
session = ChatSession(client)
session.chat("推荐几本Python入门书籍")
save_session(session)

# 稍后继续对话
loaded_session = load_session(client)
print(loaded_session.chat("刚才推荐的书中有哪本最适合初学者？"))
```

### 3. 高级功能（思考模式、联网、工具调用）

#### 3.1 思考模式（Reasoning）

**网页AI的体验**：某些AI会显示"正在思考..."的过程

**用SDK实现思考模式**：

```python
# 使用支持推理的模型（如DeepSeek Reasoner）
response = client.chat.completions.create(
    model="deepseek-reasoner",
    messages=[
        {"role": "user", "content": "解释量子计算的基本原理"}
    ],
    stream=True
)

reasoning_content = ""
final_content = ""

for chunk in response:
    delta = chunk.choices[0].delta

    if delta.reasoning_content:
        # AI正在思考
        reasoning_content += delta.reasoning_content
        print(f"🤔 思考中: {delta.reasoning_content}", end='')
    elif delta.content:
        # AI给出最终答案
        final_content += delta.content
        print(f"💡 回答: {delta.content}", end='')

print(f"\n\n完整思考过程:\n{reasoning_content}")
print(f"\n最终答案:\n{final_content}")
```

#### 3.2 联网功能（获取最新信息）

**网页AI的体验**：AI可以访问互联网获取最新信息

**用SDK实现联网功能**：

```python
import requests
from datetime import datetime

def search_web(query):
    """模拟网络搜索"""
    # 这里可以使用真实的搜索引擎API
    return f"搜索结果：关于'{query}'的最新信息（截至{datetime.now()}）"

def web_enhanced_chat(client, user_input):
    """带联网功能的对话"""

    # 1. 检查是否需要联网
    check_response = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "判断用户问题是否需要搜索最新信息。如果需要，回答'需要搜索'；否则回答'不需要搜索'"},
            {"role": "user", "content": user_input}
        ]
    )

    needs_search = "需要搜索" in check_response.choices[0].message.content

    messages = [{"role": "system", "content": "你是一个有帮助的AI助手"}]

    if needs_search:
        # 2. 执行网络搜索
        search_result = search_web(user_input)
        print(f"🌐 正在搜索: {user_input}")

        messages.append({
            "role": "system",
            "content": f"基于以下搜索信息回答用户问题：{search_result}"
        })

    # 3. 获取最终回答
    messages.append({"role": "user", "content": user_input})

    response = client.chat.completions.create(
        model="gpt-4",
        messages=messages
    )

    return response.choices[0].message.content

# 使用示例
print(web_enhanced_chat(client, "今天北京天气如何？"))  # 会触发搜索
print(web_enhanced_chat(client, "解释什么是Python？"))  # 不需要搜索
```

#### 3.3 工具调用（Function Calling）

**网页AI的体验**：AI可以调用计算器、查询数据库等工具

**用SDK实现工具调用**：

```python
import math
import json
import requests

# 定义AI可以使用的工具
tools = [
    {
        "type": "function",
        "function": {
            "name": "calculate",
            "description": "执行数学计算",
            "parameters": {
                "type": "object",
                "properties": {
                    "expression": {
                        "type": "string",
                        "description": "要计算的数学表达式"
                    }
                },
                "required": ["expression"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "获取指定城市的天气",
            "parameters": {
                "type": "object",
                "properties": {
                    "city": {
                        "type": "string",
                        "description": "城市名称"
                    }
                },
                "required": ["city"]
            }
        }
    }
]

# 工具实现函数
def calculate(expression):
    """计算数学表达式"""
    try:
        # 安全的数学表达式求值（这里简化处理）
        result = eval(expression)
        return {"result": result}
    except:
        return {"error": "无法计算该表达式"}

def get_weather(city):
    """获取天气信息"""
    # 这里应该调用真实的天气API
    return {"city": city, "temperature": "25°C", "weather": "晴"}

def tool_assisted_chat(client, user_input):
    """带工具调用的对话"""

    messages = [
        {"role": "system", "content": "你是一个有帮助的AI助手，可以使用工具来回答问题"},
        {"role": "user", "content": user_input}
    ]

    response = client.chat.completions.create(
        model="gpt-4",
        messages=messages,
        tools=tools,  # 提供可用工具
        tool_choice="auto"  # 让AI自动选择工具
    )

    message = response.choices[0].message

    # 检查AI是否要调用工具
    if message.tool_calls:
        # 执行工具调用
        tool_results = []
        for tool_call in message.tool_calls:
            function_name = tool_call.function.name
            arguments = json.loads(tool_call.function.arguments)

            if function_name == "calculate":
                result = calculate(arguments["expression"])
            elif function_name == "get_weather":
                result = get_weather(arguments["city"])
            else:
                result = {"error": "未知工具"}

            tool_results.append({
                "tool_call_id": tool_call.id,
                "role": "tool",
                "name": function_name,
                "content": json.dumps(result)
            })

        # 将工具调用和结果加入对话
        messages.append(message)
        messages.extend(tool_results)

        # 获取基于工具结果的最终回答
        final_response = client.chat.completions.create(
            model="gpt-4",
            messages=messages
        )

        return final_response.choices[0].message.content

    else:
        # AI没有调用工具，直接回答
        return message.content

# 使用示例
print(tool_assisted_chat(client, "计算 123 * 456"))  # 会调用计算器工具
print(tool_assisted_chat(client, "北京今天天气如何？"))  # 会调用天气工具
print(tool_assisted_chat(client, "解释什么是机器学习"))  # 不会调用工具
```

#### 3.4 文件访问能力

**网页AI的体验**：AI可以读取和分析你上传的文件

**用SDK实现文件访问**：

```python
import os
from pathlib import Path

class FileAssistant:
    def __init__(self, client, workspace_dir="./workspace"):
        self.client = client
        self.workspace_dir = Path(workspace_dir)
        self.workspace_dir.mkdir(exist_ok=True)

    def get_available_files(self):
        """获取工作空间中的文件列表"""
        files = []
        for file_path in self.workspace_dir.rglob("*"):
            if file_path.is_file():
                relative_path = file_path.relative_to(self.workspace_dir)
                files.append(str(relative_path))
        return files

    def read_file(self, filename):
        """读取文件内容"""
        file_path = self.workspace_dir / filename
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return f.read()
        except FileNotFoundError:
            return f"错误：文件 {filename} 不存在"

    def write_file(self, filename, content):
        """写入文件"""
        file_path = self.workspace_dir / filename
        file_path.parent.mkdir(parents=True, exist_ok=True)
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return f"文件 {filename} 已保存"

    def chat_with_files(self, user_input):
        """可以访问文件的对话"""

        # 构建工具定义
        file_tools = [
            {
                "type": "function",
                "function": {
                    "name": "list_files",
                    "description": "列出工作空间中的所有文件",
                    "parameters": {"type": "object", "properties": {}}
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "read_file",
                    "description": "读取指定文件的内容",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "filename": {"type": "string", "description": "要读取的文件名"}
                        },
                        "required": ["filename"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "write_file",
                    "description": "创建或修改文件",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "filename": {"type": "string", "description": "文件名"},
                            "content": {"type": "string", "description": "文件内容"}
                        },
                        "required": ["filename", "content"]
                    }
                }
            }
        ]

        messages = [
            {"role": "system", "content": "你是一个可以访问和修改文件的AI助手。工作空间目录：" + str(self.workspace_dir)},
            {"role": "user", "content": user_input}
        ]

        response = self.client.chat.completions.create(
            model="gpt-4",
            messages=messages,
            tools=file_tools,
            tool_choice="auto"
        )

        message = response.choices[0].message

        # 处理工具调用
        if message.tool_calls:
            tool_results = []

            for tool_call in message.tool_calls:
                function_name = tool_call.function.name
                arguments = json.loads(tool_call.function.arguments)

                if function_name == "list_files":
                    result = {"files": self.get_available_files()}
                elif function_name == "read_file":
                    result = {"content": self.read_file(arguments["filename"])}
                elif function_name == "write_file":
                    result = {"message": self.write_file(arguments["filename"], arguments["content"])}
                else:
                    result = {"error": "未知工具"}

                tool_results.append({
                    "tool_call_id": tool_call.id,
                    "role": "tool",
                    "name": function_name,
                    "content": json.dumps(result, ensure_ascii=False)
                })

            # 继续对话
            messages.append(message)
            messages.extend(tool_results)

            final_response = self.client.chat.completions.create(
                model="gpt-4",
                messages=messages
            )

            return final_response.choices[0].message.content

        return message.content

# 使用示例
file_assistant = FileAssistant(client)

# 先创建一个示例文件
file_assistant.write_file("example.py", "print('Hello, World!')")

# 与文件进行对话
print(file_assistant.chat_with_files("工作空间中有哪些文件？"))
print(file_assistant.chat_with_files("读取 example.py 文件的内容"))
print(file_assistant.chat_with_files("创建一个新文件 notes.md，内容是今天的学习笔记"))
```

### 4. 实际项目应用（kube-ai中的实现）

现在我们知道了如何用SDK实现网页AI的各种功能，让我们看看如何在kube-ai项目中应用这些知识。

#### 4.1 kube-ai的核心架构

```typescript
// kube-ai中的主要组件
class KubeAI {
    private openai: OpenAI;
    private workspace: AIWorkspace;
    private gitManager: GitManager;

    constructor() {
        this.openai = new OpenAI({
            apiKey: process.env.OPENAI_API_KEY
        });
        this.workspace = new AIWorkspace();
        this.gitManager = new GitManager();
    }

    async startNewConversation(userRequest: string): Promise<void> {
        // 1. 创建新分支
        const branchName = `feature/${Date.now()}`;
        await this.gitManager.createBranch(branchName);

        // 2. 开始AI对话
        const conversation = this.workspace.createConversation();

        // 3. 构建专业提示词
        const systemPrompt = `
        你是一个专业的Kubernetes专家。
        请根据用户的需求生成标准的Kubernetes YAML配置文件。
        所有配置文件都应该遵循K8s最佳实践。
        `;

        // 4. 定义AI工具
        const tools = [
            {
                name: "create_k8s_deployment",
                description: "创建Kubernetes Deployment",
                parameters: {
                    name: { type: "string", description: "应用名称" },
                    image: { type: "string", description: "Docker镜像" },
                    replicas: { type: "number", description: "副本数量" }
                }
            },
            {
                name: "create_k8s_service",
                description: "创建Kubernetes Service",
                parameters: {
                    name: { type: "string", description: "服务名称" },
                    type: { type: "string", description: "服务类型" },
                    port: { type: "number", description: "端口" }
                }
            },
            {
                name: "commit_changes",
                description: "提交文件更改到Git",
                parameters: {
                    message: { type: "string", description: "提交信息" }
                }
            }
        ];

        // 5. 执行AI对话
        await this.executeAIConversation(conversation, systemPrompt, userRequest, tools);
    }

    private async executeAIConversation(
        conversation: AIConversation,
        systemPrompt: string,
        userRequest: string,
        tools: any[]
    ): Promise<void> {
        const messages = [
            { role: "system", content: systemPrompt },
            { role: "user", content: userRequest }
        ];

        const response = await this.openai.chat.completions.create({
            model: "gpt-4",
            messages: messages,
            tools: tools,
            tool_choice: "auto",
            stream: true
        });

        let fullResponse = "";
        let currentToolCall = null;

        for await (const chunk of response) {
            const delta = chunk.choices[0].delta;

            // 处理内容流
            if (delta.content) {
                fullResponse += delta.content;
                // 实时更新UI显示AI正在思考
                this.updateUI({ type: "thinking", content: fullResponse });
            }

            // 处理工具调用
            if (delta.tool_calls) {
                for (const toolCall of delta.tool_calls) {
                    if (toolCall.function) {
                        await this.executeTool(toolCall.function);
                    }
                }
            }
        }

        // 保存对话历史
        conversation.addMessage("assistant", fullResponse);
    }

    private async executeTool(functionCall: any): Promise<void> {
        const { name, arguments: args } = functionCall;

        switch (name) {
            case "create_k8s_deployment":
                const deploymentYaml = this.generateDeploymentYAML(args);
                await this.workspace.writeFile("deployment.yaml", deploymentYaml);
                await this.gitManager.add("deployment.yaml");
                break;

            case "create_k8s_service":
                const serviceYaml = this.generateServiceYAML(args);
                await this.workspace.writeFile("service.yaml", serviceYaml);
                await this.gitManager.add("service.yaml");
                break;

            case "commit_changes":
                await this.gitManager.commit(args.message);
                this.updateUI({ type: "git_committed", message: args.message });
                break;
        }
    }
}
```

#### 4.2 实时UI更新

```typescript
// 前端UI更新逻辑
function updateUI(update: any) {
    switch (update.type) {
        case "thinking":
            document.getElementById("ai-thinking").textContent = update.content;
            break;

        case "file_created":
            document.getElementById("file-list").innerHTML +=
                `<div class="file-item">✅ ${update.filename}</div>`;
            break;

        case "git_committed":
            document.getElementById("git-status").textContent = `✅ ${update.message}`;
            break;

        case "yaml_generated":
            // 实时更新YAML编辑器
            monacoEditor.setValue(update.content);
            break;
    }
}
```

## 学习资源和实验

### 实验代码结构

```bash
lab/openai-sdk/
├── basic-chat.py          # 基础对话功能
├── session-management.py  # 会话管理
├── tools-demo.py         # 工具调用示例
├── file-assistant.py     # 文件访问功能
└── kube-ai-demo.ts       # kube-ai核心逻辑
```

### 快速开始

1. **安装依赖**：
```bash
pip install openai python-dotenv
```

2. **配置API密钥**：
```bash
export OPENAI_API_KEY="your-api-key"
```

3. **运行基础示例**：
```bash
python lab/openai-sdk/basic-chat.py
```

### 实践练习

1. **基础练习**：实现一个简单的聊天机器人
2. **进阶练习**：添加会话历史管理
3. **高级练习**：实现工具调用功能
4. **项目实践**：为kube-ai添加新的AI工具

## 总结

通过从网页AI的熟悉体验出发，我们学习了：

1. **基础对话**：`client.chat.completions.create()` 实现网页聊天
2. **流式响应**：`stream=True` 实现打字机效果
3. **会话管理**：`messages` 数组维护对话历史
4. **高级功能**：工具调用实现计算、搜索、文件访问
5. **实际应用**：在kube-ai中构建专业的K8s配置助手

现在你已经具备了用SDK实现网页AI所有功能的能力！下一步就是根据具体需求，设计属于你自己的AI应用了。