# JEV 微信回复助手 · DeepSeek 生成 + JEV 排序

用于个人微信、朋友日常聊天。只识别屏幕当前可见的聊天区域，不读取微信数据库，不自动发送消息。

## 下载、编译与启动

适用于 Apple Silicon Mac，macOS 14 或以上，需要 Xcode Command Line Tools 和 Python 3。

```bash
git clone https://github.com/zhaoxinfeng619-hub/jev.git
cd jev
zsh build.sh
zsh test.sh
open 'JEV 微信助手.app'
```

也可以在编译后双击 `启动助手.command`。编译产物和缓存保存在本机，不提交到仓库。初次使用请在“模型设置”填写自己的 TypeSafe 与生成模型 Key，检查屏幕权限，再校准微信聊天区域。

仓库不附带 API Key、个人模型配置、聊天记录或截图。当前提供源码构建；macOS 14 使用兼容的毛玻璃风格，顶部与正文共用玻璃背景，并非 macOS 26 的原生 Liquid Glass 折射实现。真实模型效果仍需配置自己的有效 Key 后验证。

## 2026-10-09 界面更新

采用适配 macOS 14 的银白玻璃风格：原生 NSVisualEffectView 实时背景模糊、浅色圆角内容卡片、胶囊按钮与统一蓝色强调。设置页同步改为浅色圆角输入框。保留原有识别、生成、排序和复制流程；这是旧系统上的玻璃风格实现，并非 macOS 26 的原生 Liquid Glass 折射效果。透明程度随桌面背景和系统“降低透明度”设置变化。

## 回复流程

1. Apple Vision 在本机识别微信选定区域的文字及横向位置，按个人微信默认布局把靠左气泡标成“对方”、靠右气泡标成“我”，标题和时间不算消息。
2. 如果最后一条是“我”发的，或发言人无法确定，停止生成并提示核对区域。只有最后一条明确属于“对方”时，提取最新待回复消息。
3. DeepSeek 获得带“对方 / 我”标记的可见上下文，以及单独标出的最新对方消息，站在“我”的视角现场生成 4–6 条回复。
4. 程序校验 JSON、数量和长度，排除与近期建议完全重复的句子（忽略标点和空格）。提示词也要求避开同义套话，但语义去重不能保证。
5. JEV 对新候选进行选择，返回全部候选的真实概率，并独立判断意图、情绪和是否确有待回复消息；完整性判断不足时禁用复制。
6. 按占比显示候选，用户核对、复制并自行发送。占比是候选间的选择概率，不是对方接受或满意的成功率。

正式分析不再调用本地固定话术库。演示界面仍是明确标注的固定模拟数据，不调用模型。生成失败时显示错误，不回退为固定模板、不虚构概率。

只使用当前可见上下文；不跨聊天累积消息历史。近期最多 24 条建议留在当前进程内存，供下一次生成避开重复，退出后清空。截图只在内存中处理，不保存。左右位置识别不适用于复杂群聊、气泡被裁切或布局颠倒的情况；遇到不明位置不猜测发言人。

## 本地设置

打开“模型设置”，配置两个独立模型：

- TypeSafe/JEV：地址 `https://api.typesafe.ai/v1/systemone`，模型 `jev-latest`，填 TypeSafe Key。
- DeepSeek：预填地址 `https://api.deepseek.com/chat/completions`，模型 `deepseek-flash`，填 DeepSeek Key。模型名称可按自己的平台修改。预填名称依据本次读取的官方文档。

点击“测试连接”验证 JEV，点击“测试生成模型”用虚构聊天验证 DeepSeek，不发送真实微信内容。确认后点击“保存 Key”或“仅本次使用”。二者 Key 分开存储，不会把 TypeSafe Key 发给 DeepSeek。

持久 Key 在本机钥匙串；仅本次使用只在内存。普通读取不弹认证框，只有显式解锁已保存 Key 允许认证。其他配置保存在 `~/Library/Application Support/JEV-WeChat/settings.json`，旧版地址、模型、人设和裁剪区域继续兼容。

开始监听后，同一段 OCR 将依次发送至设置的生成服务与 JEV 服务。默认是 DeepSeek 和 TypeSafe。建议先核对窗口和区域，确保只包含本次聊天。

打开微信聊天窗口，校准包含标题与最近消息的区域，排除会话列表和输入框，再开始监听。文字连续稳定后触发生成。聊天变化时取消旧请求，旧结果不会覆盖新聊天。

## 权限和窗口

校准通过窗口元信息定位，不请求屏幕录制。实际读取使用 ScreenCaptureKit。拒绝访问时暂停，避免循环请求。保存、取消或关闭设置页只关闭设置页；关闭主侧栏或选择退出才退出应用。

开发版本采用临时签名，重编译会改变授权指纹。仅针对本应用重置屏幕授权后重新开启并按系统提示退出重开，可处理旧指纹记录。正式持续更新需要固定的代码签名身份，构建支持 `JEV_SIGNING_IDENTITY`。不要修改系统权限数据库或清除所有应用权限。

## 验证范围

已通过：双方交替发言、我最后发言、发言人不明、标题和时间过滤的方向判断；旧配置迁移、生成结果与重复校验、真实本机 OCR、模拟生成→动态 JEV 排序的完整 HTTP 链路、完整概率分布、认证错误处理，以及保存/取消/关闭设置页的 AppKit 生命周期测试。

尚需在本地填写有效 DeepSeek 与 TypeSafe Key 后，验证真实朋友聊天效果和实际模型延迟。模拟测试验证流程，不代表真实模型回复质量已验证。

## 开发

需要 Apple Silicon、macOS 14+、Xcode Command Line Tools 和 Python 3；运行时无第三方依赖。

执行 `./build.sh`，再执行 `./test.sh`。`JEV_BUILD_DIR` 可指定构建缓存目录，默认工作区 `work/jev-native-build`。本机模拟测试使用端口 18765，不访问真实模型或改动真实 Key。AppKit 保存测试使用持久化替身。

- `Sources/main.swift`：窗口、OCR、两模型流程、设置与测试入口。
- `Tests/mock_jev.py`：模拟生成接口及 TypeSafe 请求。
- `Tests/window_lifecycle.swift`：真实 AppKit 事件循环回归测试。

编译时的项目 VFS 覆盖用于绕过某些 CLT 安装中的重复 SwiftBridging 模块，不修改系统工具链。

官方接口参考：[DeepSeek](https://api-docs.deepseek.com/)、[TypeSafe API](https://docs.typesafe.ai/api)、[Choice 概率](https://docs.typesafe.ai/primitives/choice)。
