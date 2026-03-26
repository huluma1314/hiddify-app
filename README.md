# Hiddify Custom Fork

这是 `huluma1314/hiddify-app` 的自用分支，用来适配我自己的节点格式和使用习惯。

项目上游：
- https://github.com/hiddify/hiddify-app

当前 fork 目标：
- 保持 `macOS / Android` 双端可用
- 支持导入特定的 `Shadowrocket socks + gost(ws)` 节点
- 在应用内直接管理分流规则，不必手改配置文件
- 让 fork 仓库自己的 GitHub Actions 也能产出 Android 安装包

## 已做改动

### 1. Shadowrocket / GOST 节点导入

已支持解析这类分享链接：

```text
socks://BASE64...?remarks=...&gost=BASE64JSON
```

当前已适配的变体：
- `socks + gost`
- `gost.route = ws`

导入后会自动转换为 Hiddify 可识别的本地配置，不需要手工改原始配置文件。

### 2. 规则页入口

已补上图形界面入口：

`设置 -> 路由 -> 规则`

现在可以在 App 内单独：
- 新增规则
- 编辑规则
- 删除规则
- 启用/停用规则
- 调整规则顺序
- 导入/导出规则

这些规则保存在应用自己的规则存储里，不要求你去手改 profile 配置文件。

### 3. Fork 仓库 CI 修复

已修复 fork 场景下的几个问题：
- 支持手动触发 CI
- 手动触发时上传构建产物
- 没有 Android 签名 secret 时回退到 debug 签名生成 APK
- 避免 fork 去回写上游 release 导致失败

## Android 安装包

这个 fork 的 Android 包通过 GitHub Actions 产出。

查看构建：
- https://github.com/huluma1314/hiddify-app/actions

下载方式：
1. 打开某次成功的 `CI` 运行
2. 在页面底部找到 `Artifacts`
3. 下载 `android-apk`
4. 解压后安装：
   - `Hiddify-Android-universal.apk`
   - 或 `Hiddify-Android-arm64.apk`

## 使用说明

如果你要测试我这次加的节点兼容：
- 直接导入 `socks://...&gost=...` 这一类节点
- 进入 `设置 -> 路由 -> 规则`
- 在规则页里单独增删改规则

## 说明

这个仓库不是 Hiddify 官方发行版，而是基于上游项目的个人定制分支。

如果你需要官方版本，请使用：
- https://github.com/hiddify/hiddify-app

## License / Attribution

本仓库基于上游项目：
- https://github.com/hiddify/hiddify-app

请同时阅读：
- [LICENSE.md](./LICENSE.md)

我保留了上游项目的署名与许可证要求，并在此基础上维护自己的定制改动。
