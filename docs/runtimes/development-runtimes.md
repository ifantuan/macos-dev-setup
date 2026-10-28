# 开发运行时手册

默认版本统一维护在 `configs/runtimes/versions.sh`：Zulu Java 8.0.492、Python 3.12.16、Node.js 当前 LTS。环境变量 `JAVA_VERSION`、`PYTHON_VERSION`、`NODE_VERSION` 可覆盖这些值，已有项目仍以自身版本要求为准。脚本独立执行各语言阶段，失败会汇总为非零退出码，不再把缺少命令或 Maven 安装失败报告为成功。

## Java

默认策略：

- 默认 JDK 使用 Zulu 8，版本为 `8.0.492-zulu`。
- 新项目或工具链按需补充 17 / 21。
- Maven、Gradle 由 SDKMAN 管理。

验证：

```bash
java -version
mvn -v
gradle -v
```

建议迁移：

```text
~/.m2/settings.xml
~/.m2/toolchains.xml
~/.gradle/gradle.properties
```

项目建议：

```text
.sdkmanrc
pom.xml
build.gradle
```

## Python

默认策略：

- 默认用 pyenv 安装和设置全局 Python 解释器。
- 项目用 `.python-version` 固定版本。
- uv 管项目虚拟环境和依赖安装，也可按需安装预编译解释器。
- pipx 管全局 CLI。
- 不使用系统 Python 做项目环境。

验证：

```bash
pyenv versions
python --version
uv --version
pipx --version
```

项目建议：

```bash
pyenv global 3.12.16
pyenv local 3.12.16
uv venv
source .venv/bin/activate
```

建议文件：

```text
.python-version
pyproject.toml
.venv/
```

## 前端

默认策略：

- fnm 管 Node.js。
- pnpm 作为主包管理器。
- pnpm 由 Homebrew 安装，不依赖 Corepack；脚本会实际检查 Node.js 和 pnpm 版本。
- bun 用于支持 Bun 的项目、脚本或工具。
- 项目用 `.node-version` 固定版本。

验证：

```bash
fnm --version
node -v
npm -v
pnpm -v
bun -v
```

项目建议：

```text
.node-version
package.json
pnpm-lock.yaml
```

## Rust

Rust 不是主开发语言，但很多现代 CLI 依赖 Rust 生态。需要开发 Rust 时再安装：

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
rustup default stable
```

验证：

```bash
rustc --version
cargo --version
```
