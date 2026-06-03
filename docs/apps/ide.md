# IDE 与编辑器手册

## 工具分工

| 工具 | 主要用途 |
|------|----------|
| JetBrains Toolbox | IntelliJ IDEA、PyCharm、WebStorm 等 IDE 管理 |
| Visual Studio Code | 通用轻量编辑器 |
| VSCodium | 无遥测 VS Code 变体 |
| Cursor | AI 原生编辑器 |
| Zed / ZedG | 高性能编辑器 |
| HBuilderX | 小程序和特定前端生态 |
| CotEditor | macOS 原生轻量文本编辑 |

## JetBrains

建议优先用 JetBrains 账号同步：

```text
Settings Sync
Keymap
Plugins
Code Style
```

需要迁移的本地路径：

```text
~/Library/Application Support/JetBrains/
```

## VS Code / VSCodium

优先使用 Settings Sync。手动迁移路径：

```text
~/Library/Application Support/Code/User/
~/Library/Application Support/VSCodium/User/
```

建议维护：

```text
settings.json
keybindings.json
extensions.json
```

仓库提供公开模板：

```text
configs/vscode/settings.json.example
configs/vscode/extensions.txt.example
```

扩展清单只记录可公开扩展 ID，不保存账号同步状态。需要手动安装时：

```bash
while read -r extension; do
  [[ -z "$extension" || "$extension" == \#* ]] && continue
  code --install-extension "$extension"
done < configs/vscode/extensions.txt.example
```

## Cursor / Zed

Cursor 适合 AI 辅助编辑，Zed 适合轻量高性能编辑。

注意：

- 不要把编辑器私有 token 提交到仓库。
- 插件列表可记录，登录态不迁移。
- 大型 Java 项目仍优先 IntelliJ IDEA。

## 默认编辑器

当前 `configs/zsh/zshrc` 使用：

```zsh
export EDITOR="code --wait"
export VISUAL="$EDITOR"
```

如果主力换成其他编辑器，修改 `configs/zsh/zshrc` 后重新执行：

```bash
cp configs/zsh/zshrc ~/.zshrc
source ~/.zshrc
```
