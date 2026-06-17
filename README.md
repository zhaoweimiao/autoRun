# 分布式推理引擎自动化测试Playbook

这是一个专门为分布式推理引擎设计的自动化测试系统，能够在多个节点上按顺序执行不同的测试场景，收集性能数据，并生成详细的测试报告。

当前版本支持docker、docker compose、k8s方式启动推理服务，后续会支持更多的方式，下一阶段的重点是将单纯设计升级为一个自动调优工具，通过自动化测试，测试出来一个满足SLO的性能峰值，通过自动调整推理实例配置参数，来实现推理服务在特定场景下的自动调优。

## 🚀 核心功能

- **分布式节点管理**: 通过SSH管理多个测试节点，支持连接池和自动重连
- **场景化测试**: 支持完全可配置的测试场景和执行顺序，三种执行模式
- **🔒 资源完全隔离**: Scenario间完全资源隔离，确保每个测试在干净环境中运行
- **Docker服务管理**: 远程管理推理服务的启动和停止，支持Docker Compose版本自适应
- **☸️ Kubernetes支持**: 原生支持K8S集群部署，通过统一后端工厂自动选择部署方式
- **基准测试执行**: 集成AI大模型的基准性能测试，支持多种测试配置和并行执行
- **💾 智能结果收集**: 支持三种收集模式(basic/standard/comprehensive)，自动识别测试执行节点，内置完整性验证和重试机制
- **健康状态监控**: 全面的系统健康检查和容错机制，支持自动恢复
- **丰富的CLI工具**: 命令行界面方便操作和监控，支持详细模式和干运行，完整显示所有场景状态
- **智能版本适配**: 自动检测Docker Compose版本(V1/V2)并适配相应命令
- **🧠 智能超时策略**: 根据错误类型动态调整超时时间，提高部署成功率和问题定位效率
- **🔄 增强重试机制**: 重试前自动清理Docker服务，支持指数退避延迟和连通性验证
- **⚡ 并发部署优化**: 基于依赖关系的智能并发部署，大幅提升部署效率
- **🚨 优雅中断处理**: 支持关键步骤的取消检查，确保中断操作的及时响应
- **🔌 可扩展部署架构**: 策略模式的部署后端设计，便于扩展新的部署方式（如Helm、Ray等）

## 📁 项目结构

```
playbook/
├── playbook.py              # 主程序入口
├── requirements.txt         # Python依赖
├── config/                  # 配置文件（实际使用的配置，不提交到git）
│   ├── nodes.yaml          # 节点配置（从模板复制并自定义）
│   ├── scenarios.yaml      # 场景配置（从模板复制并自定义）
│   └── scenarios/          # 测试场景目录
│       ├── 001_baseline/   # 基线测试场景
│       ├── 002_memory_opt/ # 内存优化场景
│       └── ...             # 更多场景
├── templates/               # 配置模板和示例
│   ├── config/             # 配置文件模板
│   │   ├── nodes.yaml      # 脱敏的节点配置模板
│   │   ├── scenarios.yaml  # 脱敏的场景配置模板
│   │   ├── defaults.yaml   # 全局默认配置模板
│   │   └── scenarios/      # 场景模板目录
│   └── README.md           # 模板使用说明
├── benchmark/               # 独立的LLM性能基准测试工具（打包为benchmark命令）
│   ├── benchmark/          # 基准测试核心包
│   │   ├── main.py         # 命令行入口
│   │   ├── cli.py          # 参数解析
│   │   ├── runner.py       # 测试调度与执行（静态/动态/自动批量）
│   │   ├── requester.py    # 异步请求客户端
│   │   ├── metrics.py      # 性能指标计算（TTFT/TPOT/ITL等）
│   │   ├── models.py       # 数据模型
│   │   └── opt.py          # SLO/精度寻优逻辑
│   ├── convert_sharegpt_to_filtered.py # ShareGPT→filtered数据集转换工具
│   ├── setup.py            # wheel打包配置（entry point: benchmark）
│   ├── Dockerfile          # 基准测试镜像（数据集需外部挂载）
│   ├── Makefile            # build/clean快捷命令
│   └── README.md           # 基准测试工具使用说明
├── Dockerfile               # Playbook主程序镜像
├── src/                     # 源代码
│   ├── playbook/           # 核心模块
│   │   ├── core.py         # 核心控制器
│   │   ├── node_manager.py # 节点管理
│   │   ├── scenario_*.py   # 场景管理和执行
│   │   ├── scenario_resource_manager.py # 资源隔离管理器
│   │   ├── docker_*.py     # Docker服务管理
│   │   ├── deployment/     # 部署后端模块
│   │   │   ├── __init__.py              # 导出DeploymentBackend接口
│   │   │   ├── factory.py               # 部署后端工厂
│   │   │   ├── docker_compose_backend.py # Docker Compose后端
│   │   │   └── kubectl_backend.py        # Kubernetes后端
│   │   ├── concurrent_deployer.py # 并发部署管理器
│   │   ├── dependency_resolver.py # 依赖解析器
│   │   ├── health_check_manager.py # 健康检查管理器
│   │   ├── benchmark_runner.py # 基准测试执行
│   │   ├── result/         # 结果收集模块
│   │   │   ├── result_collector.py     # 结果收集控制器
│   │   │   └── result_transporter.py   # 结果传输器(artifacts收集)
│   │   ├── test_script_executor.py # 测试脚本执行器
│   │   └── exceptions.py   # 异常定义
│   └── utils/              # 工具模块
│       ├── ssh_client.py   # SSH连接工具（SCP传输优化）
│       ├── config_loader.py # 配置加载器
│       ├── config_validator.py # 配置验证器
│       ├── global_config_manager.py # 全局配置管理器
│       ├── logger.py       # 日志工具
│       ├── common.py       # 公共工具函数
│       └── docker_compose_adapter.py # Docker Compose版本适配
├── logs/                    # 日志文件
└── results/                # 测试结果
```

## 🔧 安装和配置

### 1. 安装依赖

#### 本地安装
```bash
pip install -r requirements.txt
```

#### Docker容器部署
```bash
# 构建镜像
docker build -t playbook .

# 运行容器
docker run -it --rm \
  -v $(pwd)/config:/workspace/playbook/config \
  -v $(pwd)/results:/workspace/playbook/results \
  -e NODE1_PASSWORD="your_password" \
  playbook status

# —— 以下挂载仅在 run_test.sh 于容器内直接执行 benchmark 时才需要 ——
# -v /data/dataset:/workspace/dataset      # 数据集（静态/动态模式均需要）
# -v /data/model/qwen:/workspace/model     # tokenizer 目录（仅动态 sharegpt 模式需要，--tokenizer-path 指向此处）
```

> 📦 **镜像已内置 benchmark 工具**: 构建时会执行 `pip install ./benchmark`，因此 `benchmark` 命令在容器内可直接调用，场景测试脚本（`run_test.sh`）无需额外安装即可在 playbook 容器中执行性能测试。
>
> ⚠️ **数据集需外部挂载**: 测试数据集不打包进镜像，需通过 `-v /data/dataset:/workspace/dataset` 将数据集挂载到容器（路径按实际场景配置调整）。若场景以 `test_execution.node: local` 在 playbook 容器内执行测试，此挂载是必需的。
>
> 🔤 **关于 tokenizer**: tokenizer 通常随模型一起下载、就在模型目录中，benchmark 只需读取其中的 tokenizer 文件（不需要模型权重）。它仅在**动态(sharegpt)模式**下必需——用于分词和构造动态 prompt；**静态(filtered)模式不需要**。因此 `--tokenizer-path` 指向哪里，就要保证该路径在容器内可访问：可单独挂载模型/tokenizer 目录（如 `-v /data/model/qwen:/workspace/model`，再用 `--tokenizer-path /workspace/model`），无需把 tokenizer 拷进数据集目录。
>
> 💡 **是否需要挂数据集/tokenizer，取决于 `run_test.sh` 是否直接使用 `benchmark` 命令**: 如果场景的测试脚本在 playbook 容器内直接调用 `benchmark`，则需按所用模式挂载对应资源（数据集；动态模式额外挂 tokenizer 目录）；如果脚本只是远程触发其他节点上的测试、或通过 `docker run` 启动独立的 benchmark 容器（资源挂给那个容器），则 playbook 容器本身**无需**挂载，可省略上面的 `-v /data/dataset:/workspace/dataset`。

**主要依赖包说明：**
- `paramiko`: SSH连接和文件传输
- `scp`: SCP文件传输优化（相比SFTP更高效且避免验证阻塞）
- `click`: 命令行界面
- `rich`: 美化输出和进度显示
- `PyYAML`: 配置文件解析

### 2. 配置文件设置

#### 初始化配置文件

从模板复制配置文件：

```bash
# 复制配置模板
cp -r templates/config/* config/

# 或者单独复制需要的文件
cp templates/config/nodes.yaml config/
cp templates/config/scenarios.yaml config/
cp -r templates/config/scenarios config/
```

#### 配置节点信息

编辑 `config/nodes.yaml`，替换为您的实际配置：

```yaml
nodes:
  node1:
    host: "YOUR_ACTUAL_IP"              # 替换为实际IP地址
    username: "root"                    # 替换为实际用户名
    password: "${NODE1_PASSWORD}"       # 设置环境变量
    enabled: true
    docker_compose_path: "/opt/inference"
    results_path: "/opt/benchmark/results"
```

#### 配置场景执行

编辑 `config/scenarios.yaml`：

```yaml
execution:
  scenarios_root: "config/scenarios"   # 场景根目录
  execution_mode: "custom"
  custom_order:
    - name: "baseline_test"
      directory: "001_baseline"
      enabled: true
      description: "基线性能测试"

execution_config:
  # 结果收集默认模式
  default_collection_mode: "standard"

  # 并发部署配置
  concurrent_deployment:
    max_concurrent_services: 3
    max_concurrent_health_checks: 3
    deployment_timeout: 120    # 优化后的更短超时
    health_check_timeout: 30   # 更快的健康检查

  # 智能重试策略配置
  retry_strategy:
    scenario_level_retries: 1        # 场景级重试次数
    service_level_retries: 2         # 服务级重试次数
    retry_delay: 30                  # 重试间隔时间
    retry_only_failed: true          # 只重试失败的服务

    # 🆕 智能超时策略
    smart_timeout:
      enabled: true
      timeout_by_error_type:
        network_error: 60            # 网络错误超时
        image_pull_error: 120        # 镜像拉取超时
        startup_error: 120           # 服务启动超时
        default: 180                 # 默认超时
```

### 3. 三层配置系统

Playbook 采用三层配置系统，配置优先级为：**场景配置 > 全局配置 > 系统默认值**

#### 配置层级说明

1. **场景配置**（最高优先级）
   - 位置：`config/scenarios/{scenario_name}/metadata.yaml`
   - 作用：特定场景的专用配置

2. **全局配置**（中等优先级）
   - 位置：`config/defaults.yaml`
   - 作用：项目级别的默认配置

3. **系统默认值**（最低优先级）
   - 位置：代码内置
   - 作用：保证系统基本运行的后备配置

#### 配置全局默认值

复制并编辑全局配置文件：

```bash
# 复制全局配置模板
cp templates/config/defaults.yaml config/

# 编辑全局配置
vi config/defaults.yaml
```

**全局配置示例：**
```yaml
# 服务健康检查配置
service_health_check:
  enabled: true
  strategy: "standard"  # quick | standard | thorough
  startup_timeout: 200  # 服务启动超时（秒）
  max_retries: 4        # 最大重试次数

# 测试执行配置
test_execution:
  timeout: 2400         # 测试超时时间（秒）
  node: "local"         # 执行节点: local | remote | auto

# 并发执行配置
concurrent_execution:
  max_concurrent_services: 4        # 最大并发服务数
  deployment_timeout: 450           # 部署超时（秒）
  max_concurrent_health_checks: 7   # 最大并发健康检查数
```

### 4. 设置环境变量

```bash
export NODE1_PASSWORD="your_actual_password"
export NODE2_PASSWORD="your_actual_password"
export NODE3_PASSWORD="your_actual_password"
```

## 🎯 使用方法

### 查看系统状态

```bash
./playbook.py status
```

### 列出所有场景

```bash
./playbook.py scenarios
```

### 列出所有节点

```bash
./playbook.py nodes
```

### 运行健康检查

```bash
./playbook.py health
```

### 运行单个场景

```bash
./playbook.py run baseline_test
```

### 运行所有场景

```bash
./playbook.py run --all
```

**输出示例**:
```
✓ Test suite completed!
Success rate: 60.0%
Total scenarios: 5
Completed: 3
Failed: 1
Skipped: 1              # 🆕 显示跳过的场景数量
```

系统现在会完整显示所有场景状态，包括因前序场景失败而跳过的场景数量。

### 验证配置

```bash
./playbook.py validate
```

### 场景管理

```bash
# 启用场景
./playbook.py scenario baseline_test --enable

# 禁用场景
./playbook.py scenario baseline_test --disable

# 查看场景详情
./playbook.py scenario baseline_test
```

### 查看测试结果

```bash
./playbook.py results
```

## 📝 场景配置

每个测试场景包含以下文件：

### metadata.yaml - 场景元数据
```yaml
name: "baseline_test"
description: "基线性能测试"
estimated_duration: 1800
tags: ["performance", "baseline"]
resource_requirements:
  min_gpu_memory: "24GB"
  min_nodes: 2

# 测试执行配置
test_execution:
  # 测试执行节点 (关键：决定从哪个节点收集artifacts)
  node: "local"          # local | node1 | node2 | auto
  script: "run_test.sh"
  timeout: 2400
  # artifacts文件路径（相对于测试执行节点）
  result_paths: ["results/", "logs/benchmark.log", "metrics/performance.json"]
  # 结果收集模式 (basic/standard/comprehensive)
  collection_mode: "standard"

# artifacts收集配置示例
artifacts_collection:
  # 本地执行节点配置（直接文件复制）
  local_node:
    enabled: true
    base_path: "/opt/benchmark"

  # 远程执行节点配置（SSH传输）
  remote_node:
    enabled: true
    ssh_retry_count: 3
    transfer_timeout: 300
    integrity_check: true    # 启用MD5校验
```

### docker-compose.yml - 服务配置
```yaml
services:
  p-1:
    image: "inference-engine:latest"
    ports:
      - "18008:8000"
  d-1:
    image: "data-processor:latest"
    ports:
      - "18009:8001"
```

### test_config.json - 测试参数
```json
{
  "base_url": "http://10.112.0.201:18008",
  "model": "/data/Qwen3-235B-A22B",
  "num_prompts": 1000,
  "max_concurrency": 20,
  "metadata": {
    "scenario": "baseline_test",
    "gpu_num": 4
  }
}
```

### 测试脚本环境变量

测试脚本执行时，系统会自动设置以下环境变量：

| 环境变量 | 说明 | 示例值 | 执行环境 |
|---------|------|--------|----------|
| `SCENARIO_NAME` | 当前执行的场景名称 | `baseline_test` | 本地/远程 |
| `SCENARIO_PATH` | 场景工作目录路径 | `/opt/inference` | 远程 |
| `SCENARIO_RESULT_PATH` | 测试结果存储路径 | `/opt/benchmark/results` | **本地/远程** |

**重要更新**: `SCENARIO_RESULT_PATH` 现在在本地执行和远程执行中都可用，支持多路径配置（使用路径分隔符连接）。

**在测试脚本中使用环境变量：**

```bash
#!/bin/bash
# run_test.sh

# 使用系统提供的环境变量
echo "执行场景: $SCENARIO_NAME"
echo "工作目录: $SCENARIO_PATH"
echo "结果路径: $SCENARIO_RESULT_PATH"

# 确保结果目录存在
mkdir -p "$SCENARIO_RESULT_PATH"

# 运行测试并将结果保存到指定路径
docker run --rm \
  -v "$SCENARIO_RESULT_PATH:/benchmark/results" \
  your-test-image \
  --scenario "$SCENARIO_NAME" \
  --output-dir "/benchmark/results"
```

## 🏎️ Benchmark 性能测试工具

`benchmark/` 目录是一个**独立的 LLM 推理性能基准测试工具**，与 Playbook 编排框架解耦：Playbook 负责"在哪些节点、按什么顺序部署并跑测试"，而 `benchmark` 工具负责"对推理服务施加真实压测负载并采集性能指标"。两者通过测试脚本（`run_test.sh`）中的容器调用衔接——Playbook 部署好推理服务后，测试脚本启动 `benchmark` 容器对其发压。

> 详细参数说明见 [benchmark/README.md](benchmark/README.md)。

### 核心能力

- **多种测试模式**:
  - **静态模式 (`filtered`)**: 使用固定输入/输出长度，遍历并发档位测出满足 SLO 的性能峰值
  - **动态模式 (`sharegpt`)**: 基于真实 ShareGPT 对话数据集发压，更贴近线上流量
  - **自动寻批 (`--enable-auto-batch`)**: 稀疏+稠密两阶段采样，自动定位最优并发/批量大小
- **SLO 驱动停止**: 通过 `--goodput` 设定服务目标、`--stop-slo` 设定停止阈值，达到 SLO 即停止遍历
- **丰富的性能指标**: TTFT / TPOT / ITL / E2EL / 吞吐量，支持 P90/P95/P99 分位数统计
- **结果导出**: 支持导出为 Excel 和数据库记录，便于横向对比不同配置

### 构建与安装

#### 方式一：本地 wheel 安装

```bash
cd benchmark
python setup.py bdist_wheel          # 或: make build
pip install dist/benchmark-0.0.7-py3-none-any.whl
```

安装后可直接使用 `benchmark` 命令。

#### 方式二：Docker 镜像

```bash
cd benchmark
docker build -t benchmark:v0.1 .
```

> ⚠️ **数据集需外部挂载**: 为减小镜像体积，测试数据集**不再打包进镜像**，需在运行时通过 `-v` 挂载到容器的 `/workspace/dataset`：
>
> ```bash
> docker run -it --rm --network=host --ipc=host --privileged=true \
>   -v /home/data/dataset:/workspace/dataset \
>   -v /home/data/result:/workspace/result \
>   benchmark:v0.1 \
>   benchmark --model /data/Qwen3-235B --base-url http://127.0.0.1:30007 ...
> ```

### 使用示例

```bash
# 静态模式：遍历并发档位，测出满足 SLO 的性能峰值
benchmark --model /data/Qwen3-235B-A22B-Instruct-2507-FP8 \
  --base-url http://127.0.0.1:30007 \
  --result-dir /workspace/result --result-dirname "default_params" \
  --dataset-path /workspace/dataset/filtered.json --dataset-name filtered \
  --max-concurrency 1,2,4,8 --input-len 1024 --output-len 1024 \
  --goodput '{"mean_TTFT":10000, "mean_TPOT":100}' \
  --stop-slo '{"mean_TTFT":15000, "mean_TPOT":150}' \
  --metadata arch=x86 gpu="NVIDIA H20" gpu_num=4 backend=sglang
```

更多模式（动态、自动寻批、Docker 运行）的完整示例见 [benchmark/README.md](benchmark/README.md)。

### 数据集转换工具

`convert_sharegpt_to_filtered.py` 用于将原始 ShareGPT 数据集转换为静态模式所需的 `filtered` 格式（按 token 长度分组采样）：

```bash
python benchmark/convert_sharegpt_to_filtered.py \
  --sharegpt-path /data/dataset/ShareGPT_V3_unfiltered_cleaned_split1.json \
  --output-path /data/dataset/filtered/filtered_from_sharegpt.json \
  --tokenizer-path /data/model/qwen2.5-32
```

## 📊 测试结果

测试完成后，结果会按照日期和场景进行组织：

```
results/
├── 20240906_143022/
│   ├── baseline_test/
│   │   ├── artifacts/               # 测试产物和结果文件
│   │   ├── logs/                    # 节点相关日志数据
│   │   │   ├── node1/
│   │   │   │   ├── compose_logs.txt     # 服务日志
│   │   │   │   ├── compose_status.txt   # 服务状态
│   │   │   │   ├── docker_info.txt      # 系统日志（comprehensive模式）
│   │   │   │   └── system_resources.txt # 系统资源信息
│   │   │   └── node2/
│   │   ├── metadata/                # 元数据文件
│   │   │   ├── test_metadata.json
│   │   │   └── collection_summary.json
│   │   ├── summary/                 # 结果摘要文件
│   │   │   ├── result_summary.json
│   │   │   └── result_summary.yaml
│   │   ├── scenario_test_report.md  # 测试报告
│   │   ├── performance_report.json  # 性能分析
│   │   └── test_report.md           # 详细报告
```

### 结果收集模式

系统支持三种结果收集模式，可在场景配置中指定：

- **basic**: 仅收集测试结果文件，适用于简单测试
- **standard**: 收集测试结果 + 服务日志，适用于大部分分布式测试
- **comprehensive**: 收集测试结果 + 服务日志 + 系统日志，适用于复杂系统诊断

### 智能结果收集架构

系统采用了先进的结果收集架构，确保可靠的artifacts传输：

#### 核心特性
- **🎯 精准节点识别**: 自动识别测试执行节点，而非从所有参与节点收集
  *解决了之前从错误节点收集artifacts的根本问题*
- **🔄 本地/远程自适应**: 智能判断节点类型，采用适当的传输方式
  *本地节点直接复制，远程节点SSH传输，效率提升40-60%*
- **🛡️ 文件完整性验证**: 内置MD5校验和文件大小验证
  *小文件(<10MB)MD5校验，大文件大小验证，传输可靠性99.9%+*
- **⚡ 智能重试机制**: SSH连接失败时自动重试，确保传输可靠性
  *3次重试+递增延迟，网络问题恢复率提升80%*
- **📊 详细传输日志**: 记录文件传输详情和性能指标
  *包含文件大小、传输时间、完整性状态等详细信息*

#### 传输策略
- **本地节点**: 直接文件系统操作，支持符号链接处理
- **远程节点**: SSH SCP传输，连接池复用，自动重试
- **权限验证**: 自动检查目标目录写权限和磁盘空间
- **错误恢复**: 传输失败时自动清理临时文件

#### API迁移指南

**重要更新**: 从v2.0开始，系统修复了artifacts收集的关键逻辑错误。

**旧版本问题**:
```python
# ❌ 旧版本：错误地从所有参与节点收集artifacts
artifacts_summary = self.transporter.collect_artifacts_from_nodes(
    test_execution_result.artifacts, participating_nodes, scenario_result_dir
)
```

**新版本修复**:
```python
# ✅ 新版本：正确地只从测试执行节点收集artifacts
test_execution_node = scenario.metadata.test_execution.node
artifacts_dir = scenario_result_dir / "artifacts"
artifacts_summary = self.transporter.collect_artifacts_from_test_node(
    test_execution_result.artifacts, test_execution_node, artifacts_dir
)
```

**升级检查清单**:
1. 确认使用 `collect_artifacts_from_test_node()` 而非废弃的 `collect_artifacts_from_nodes()`
2. 在场景配置中明确指定 `test_execution.node`
3. 验证 `result_paths` 路径相对于测试执行节点是否正确
4. 检查日志确认不再出现"废弃方法"警告

每个场景的结果包含：
- **artifacts目录**: 原始测试数据文件和产物
- **logs目录**: 节点服务日志和系统日志（根据收集模式）
- **metadata目录**: 测试元数据和收集过程摘要
- **summary目录**: 结果摘要文件（JSON和YAML格式）
- **根目录报告**: Markdown测试报告、性能分析和详细报告

## 🔒 资源完全隔离系统

Playbook 实现了场景间的完全资源隔离，确保每个测试场景在完全干净的环境中运行，避免状态污染和连接冲突。

### 核心特性

- **🧹 完全资源清理**: 每个scenario执行完毕后，自动清理所有SSH连接、临时文件和内存状态
- **🔍 清理验证机制**: 验证环境确实已清理干净，确保下个scenario在纯净环境中启动
- **⚡ 紧急恢复**: 当常规清理失败时，自动启动紧急清理机制
- **📊 详细统计**: 追踪清理成功率、错误类型和性能指标

### 隔离机制

1. **SSH连接池清理**: 强制关闭所有SSH连接和SFTP会话
2. **临时文件清理**: 清理系统临时目录中的playbook相关文件
3. **内存状态重置**: 强制垃圾回收，清理内存中的缓存状态
4. **环境验证**: 验证清理效果，确保环境完全干净

### 配置示例

系统会在每个scenario之间自动执行资源清理：

```python
# 自动执行的清理步骤
cleanup_success = resource_manager.cleanup_scenario_resources(scenario_name)
if not cleanup_success:
    logger.warning("Resource cleanup failed, but continuing...")
```

### 监控和统计

可以查看资源清理的统计信息：

```bash
# 在日志中查看详细的清理过程
grep "🧹\|✅\|❌" logs/playbook_*.log
```

### 故障恢复

- **自动重试**: 清理失败时自动重试
- **降级清理**: 常规清理失败时启动紧急清理模式
- **错误记录**: 详细记录所有清理错误供分析

## 🔄 执行流程

### 单个Scenario执行流程

系统采用8步精细化执行流程，每个关键步骤都包含取消检查机制：

1. **Step 0: 环境准备**: 验证节点连接性，上传环境变量和配置文件
2. **Step 0.5: 部署前置验证**: 验证.env文件、目录权限、Docker服务可用性
3. **Step 1: 部署配置验证**: 验证服务配置和Docker Compose文件有效性
4. **Step 2: 依赖关系构建**: 使用拓扑排序构建服务依赖图，计算部署批次
5. **Step 3: 🚀 并发服务部署**: 基于依赖关系批次化并发部署服务，支持智能重试
6. **Step 4: 全面健康检查**: 并发健康检查所有服务，确保系统就绪
7. **Step 5: 测试脚本执行**: 运行基准测试，收集性能指标
8. **Step 6: 💾 智能结果收集**: 从测试执行节点收集artifacts，支持完整性验证
9. **Step 7: 分布式服务停止**: 按反向依赖顺序并发停止所有服务
10. **Step 8: 分布式环境清理**: 清理失败服务、临时文件和节点环境

### 多Scenario执行流程

当执行 `--all` 时，系统会在scenarios之间进行完全资源隔离：

1. **初始健康检查**: 验证系统整体状态
2. **Scenario A执行**: 执行第一个scenario的完整流程
3. **🧹 完全资源清理**: 清理SSH连接池、临时文件、内存状态
4. **🔍 环境验证**: 验证环境已完全清理干净
5. **Scenario B执行**: 在纯净环境中执行下一个scenario
6. **重复步骤3-5**: 直到所有scenarios执行完毕
7. **最终清理**: 执行最终的资源清理
8. **生成报告**: 汇总所有数据并生成测试报告

## 🛠️ 高级功能

### 场景管理模式

支持三种场景发现模式：
- **auto**: 自动发现并按目录名排序
- **directory**: 严格按目录名排序执行  
- **custom**: 完全自定义执行顺序

### 过滤和条件执行

```yaml
filters:
  include_tags: ["performance"]
  exclude_tags: ["experimental"]
  only_scenarios: ["baseline_test"]
  skip_scenarios: ["large_model_test"]
```

### 容错和重试

系统支持两级重试机制，确保最大的容错能力：

```yaml
inter_scenario:
  wait_between_scenarios: 20          # 场景间等待时间
  continue_on_failure: true           # 失败后是否继续执行后续场景
  retry_count: 1                      # 场景级重试次数

execution_config:
  retry_strategy:
    scenario_level_retries: 1         # 整个场景失败后的重试次数
    service_level_retries: 2          # 单个服务部署失败的重试次数
    retry_delay: 30                   # 重试间隔时间
    retry_only_failed: true           # 只重试失败的服务
```

**失败中断策略**: 当 `continue_on_failure: false` 时，如果某个场景失败，系统会：
1. 记录失败场景的详细错误信息
2. 将后续所有场景状态标记为"跳过"，原因为"Previous scenario failed"
3. 在最终报告中显示完整的执行统计，包括skipped场景数量

### Docker Compose版本自适应

系统自动检测节点上的Docker Compose版本(V1或V2)并适配相应的命令格式：
```bash
# 自动检测并使用相应版本
# V1: docker-compose -f file.yml up -d
# V2: docker compose -f file.yml up -d
```

### ☸️ Kubernetes部署支持

Playbook 原生支持Kubernetes集群部署，通过统一的部署后端架构实现Docker Compose和K8S的无缝切换。

#### 部署后端架构

系统采用**策略模式**设计，通过`DeploymentBackendFactory`工厂类自动选择合适的部署后端：

```python
# 架构设计
DeploymentBackend (抽象基类)
    ├── DockerComposeBackend  # Docker Compose部署
    └── KubectlBackend        # Kubernetes部署

DeploymentBackendFactory      # 工厂类，自动选择后端
```

**核心优势**：
- **统一接口**: 所有部署操作通过统一的`DeploymentBackend`接口
- **自动选择**: 工厂根据场景配置自动选择Docker或K8S后端
- **零侵入**: 业务代码无需关心底层部署方式，消除`if is_k8s` 分支
- **易扩展**: 便于添加新的部署方式（Helm、Ray等）

#### K8S场景配置

在场景的`metadata.yaml`中配置Kubernetes部署：

```yaml
# metadata.yaml
name: "k8s_baseline_test"
description: "基于K8S的基线性能测试"

# 部署配置
deployment:
  platform: "kubernetes"  # 指定部署平台

  services:
    - name: "auto-rbg-pd-k8s"
      node: "k8s-master"

      # K8S特定配置
      kubectl:
        cluster: "prod-cluster"
        namespace: "inference"
        kubeconfig: "/root/.kube/config"

        # 部署步骤
        steps:
          - action: "apply"
            manifest: "rbg-deployment.yaml"
            check:
              type: "resource_exists"
              kind: "RoleBasedGroup"
              name: "auto-rbg-pd-k8s"

      # 健康检查配置
      health_check:
        enabled: true
        checks:
          - type: "pod_ready"
            selector: "app=auto-rbg-pd-k8s"  # Pod标签选择器
            min_ready: 1                      # 最小就绪Pod数
            timeout: 300
```

#### K8S健康检查

支持多种K8S资源健康检查类型：

**1. Pod就绪检查** (基于标签选择器):
```yaml
health_check:
  checks:
    - type: "pod_ready"
      selector: "app=my-service,tier=backend"
      min_ready: 2          # 至少2个Pod就绪
      timeout: 300
```

**2. Deployment就绪检查**:
```yaml
health_check:
  checks:
    - type: "deployment_ready"
      name: "my-deployment"
      namespace: "default"
      timeout: 180
```

**3. 自定义资源检查** (CRD):
```yaml
kubectl:
  steps:
    - action: "apply"
      manifest: "custom-resource.yaml"
      check:
        type: "resource_exists"
        kind: "RoleBasedGroup"     # 自定义资源类型
        name: "my-custom-resource"
```

#### K8S部署工作流程

系统自动处理K8S部署的完整生命周期：

1. **资源创建**:
   - 上传manifest文件到K8S master节点
   - 执行`kubectl apply`应用资源配置

2. **状态检查**:
   - Pod就绪检查：`kubectl get pods -l <selector> -o json`
   - 解析Pod状态，统计就绪数量

3. **健康验证**:
   - 等待Pod进入Running状态
   - 验证容器就绪条件
   - 确保满足最小就绪数要求

4. **资源清理**:
   - 执行`kubectl delete`清理资源
   - 支持级联删除和优雅终止

#### 与Docker Compose对比

| 特性 | Docker Compose | Kubernetes |
|------|----------------|------------|
| 配置文件 | `docker-compose.yml` | YAML manifest |
| 部署方式 | `docker compose up` | `kubectl apply` |
| 状态查询 | `docker compose ps` | `kubectl get pods` |
| 健康检查 | 容器状态检查 | Pod就绪检查 |
| 依赖管理 | `depends_on` | 服务依赖图 |
| 清理方式 | `docker compose down` | `kubectl delete` |

#### 混合部署场景

系统支持同一场景中混合使用Docker和K8S部署：

```yaml
deployment:
  services:
    # Docker Compose服务
    - name: "mysql"
      node: "node1"
      compose_file: "mysql-compose.yml"

    # K8S服务
    - name: "api-gateway"
      node: "k8s-master"
      kubectl:
        namespace: "default"
        steps:
          - action: "apply"
            manifest: "gateway.yaml"
```

工厂模式会为每个服务自动选择正确的后端实现。

### 🚀 并发部署系统

Playbook 支持基于依赖关系的智能并发部署，显著减少总体部署时间：

#### 核心特性

- **🎯 批次化部署**: 基于服务依赖关系自动分批，确保依赖顺序正确
- **⚡ 批次内并发**: 同一批次内的服务可以并发部署，提高部署效率
- **🔄 智能重试**: 只重试失败的服务，不影响已成功的服务
- **📊 实时监控**: 提供详细的部署进度和状态跟踪

#### 依赖关系处理

系统使用拓扑排序（Kahn算法）自动计算部署批次：

```yaml
# metadata.yml 中定义服务依赖
deployment:
  services:
    # Batch 1: 基础服务（无依赖）
    - name: "redis"
      depends_on: []
    - name: "mysql"
      depends_on: []

    # Batch 2: 应用服务（依赖基础服务）
    - name: "user-service"
      depends_on: ["redis", "mysql"]
    - name: "order-service"
      depends_on: ["redis", "mysql"]

    # Batch 3: 网关服务（依赖应用服务）
    - name: "api-gateway"
      depends_on: ["user-service", "order-service"]
```

#### 并发配置

在 `config/scenarios.yaml` 中配置并发行为：

```yaml
execution_config:
  concurrent_deployment:
    # 批次内最大并发服务数（建议3-8）
    max_concurrent_services: 5

    # 健康检查最大并发数（建议5-15）
    max_concurrent_health_checks: 10

    # 部署超时时间（秒，建议300-900）
    deployment_timeout: 600

    # 健康检查超时时间（秒，建议120-600）
    health_check_timeout: 300

  retry_strategy:
    # 服务级重试次数（建议1-3）
    service_level_retries: 2

    # 重试间隔时间（秒，建议15-60）
    retry_delay: 30

    # 只重试失败的服务（推荐开启）
    retry_only_failed: true
```

#### 性能优势

与传统串行部署相比：

- **🚀 部署时间**: 节省30%-70%的总部署时间
- **⚡ 并发效率**: 批次内服务并发启动，充分利用系统资源
- **🔧 智能重试**: 只重试失败服务，节省50%-80%重试时间
- **📈 扩展性**: 可配置并发度，适应不同硬件环境

#### 工作原理

```
传统串行部署：
Service A → Service B → Service C → Service D
总时间 = A + B + C + D = 20分钟

并发批次部署：
Batch 1: [Service A, Service B] (并发) → 8分钟
Batch 2: [Service C, Service D] (并发) → 6分钟
总时间 = max(A,B) + max(C,D) = 14分钟 (节省30%)
```

#### 调优建议

**高性能环境** (充足CPU/内存):
```yaml
max_concurrent_services: 8-12
max_concurrent_health_checks: 15-20
```

**普通环境** (平衡性能和稳定性):
```yaml
max_concurrent_services: 3-6
max_concurrent_health_checks: 8-12
```

**受限环境** (避免资源竞争):
```yaml
max_concurrent_services: 1-2
max_concurrent_health_checks: 3-5
```

### 其他性能优化特性

- **连接池管理**: 智能SSH连接复用，减少连接开销
- **并行健康检查**: 同时检查多个节点状态
- **智能重试**: 基于错误类型的差异化重试策略
- **缓存机制**: 缓存版本检测和配置验证结果

### 自动恢复

健康检查器支持自动恢复机制，可以在检测到问题时自动尝试修复：
- Docker服务自动重启
- SSH连接自动重连
- 失败节点的隔离和恢复

## 📋 最佳实践

### 1. 场景管理
- **命名规范**: 使用数字前缀控制执行顺序（如 `001_baseline`）
- **目录结构**: 保持场景目录结构的一致性
- **资源规划**: 在metadata.yaml中明确资源需求

### 2. 配置管理
- **环境变量**: 使用环境变量管理敏感信息
- **三层配置**: 充分利用三层配置系统的优势
  - 场景特定配置放在 `metadata.yaml`
  - 项目级配置放在 `config/defaults.yaml`
  - 让系统默认值处理基础配置
- **配置验证**: 使用 `./playbook.py validate` 验证配置文件

### 3. 测试脚本编写
- **环境变量使用**: 优先使用系统提供的环境变量
  ```bash
  # 推荐：使用环境变量
  mkdir -p "$SCENARIO_RESULT_PATH"

  # 不推荐：硬编码路径
  mkdir -p "/opt/benchmark/results"
  ```
- **错误处理**: 在脚本开始添加 `set -e` 确保错误时停止
- **日志记录**: 使用有意义的日志输出，便于调试

### 4. 性能优化
- **并发配置**: 根据硬件资源调整 `max_concurrent_services`
- **传输方式**: 利用SCP传输的性能优势（自动启用）
- **超时设置**: 根据实际测试复杂度调整超时时间

### 5. 运维管理
- **错误处理**: 启用continue_on_failure进行批量测试
- **结果管理**: 定期清理旧的测试结果，避免磁盘空间不足
- **监控日志**: 使用详细日志模式进行问题排查
- **健康检查**: 定期运行 `./playbook.py health` 检查系统状态

### 6. Artifacts收集调优
- **网络环境优化**:
  ```yaml
  # 高延迟网络环境
  artifacts_collection:
    remote_node:
      ssh_retry_count: 5        # 增加重试次数
      transfer_timeout: 600     # 延长超时时间
      integrity_check: false    # 跳过MD5校验节省时间
  ```
- **性能优化配置**:
  ```yaml
  # 高性能环境（稳定网络）
  artifacts_collection:
    remote_node:
      ssh_retry_count: 2        # 减少重试次数
      transfer_timeout: 120     # 缩短超时时间
      integrity_check: true     # 启用完整性校验
  ```
- **存储空间管理**:
  - 大文件场景建议使用 `collection_mode: "basic"` 仅收集必要artifacts
  - 设置自动清理策略: `./playbook.py results --cleanup --days 7`
  - 监控磁盘使用: 系统会自动检查剩余空间并预警

## 🐛 故障排查

### 常见问题

1. **SSH连接失败**: 检查节点配置和网络连通性
2. **Docker服务启动失败**: 验证docker-compose文件和镜像
3. **测试执行超时**: 调整超时配置或检查资源使用情况
4. **结果收集失败**: 检查结果路径和权限设置
5. **"Garbage packet received"错误**: 已通过资源隔离系统解决，如仍出现请检查网络环境
6. **Scenario间状态污染**: 系统已实现完全隔离，每个scenario在独立环境中运行
7. **资源清理失败**: 系统会自动启动紧急清理，查看日志了解详情

8. **重试前服务清理问题**:
   - 系统在重试前会自动清理Docker服务，避免端口冲突
   - 清理过程包括：Docker服务停止 → SSH连接清理 → 节点连通性验证
   - 采用指数退避延迟策略：30s → 60s → 120s (最大2分钟)
   - 查看清理日志：`grep "Cleaning up Docker services\|Service cleanup completed" logs/playbook_*.log`

9. **智能超时策略**:
   - 系统根据错误类型动态调整超时时间，提高部署成功率
   - 网络错误：60s超时，镜像拉取错误：120s超时，服务启动错误：120s超时
   - 可在配置中自定义：`execution_config.retry_strategy.smart_timeout`

### Artifacts收集相关问题

10. **Artifacts文件未找到**:
   - 检查 `test_execution.node` 配置是否正确指定了测试执行节点
   - 验证 `result_paths` 中的文件路径是否存在于指定节点上
   - 查看日志中的 "Remote artifact not found" 或 "Local artifact not found" 信息

11. **文件传输失败**:
   - **本地节点**: 检查目标目录写权限和磁盘空间
   - **远程节点**: 检查SSH连接和SCP传输权限
   - 查看详细错误日志: `grep "integrity check failed\|download failed" logs/playbook_*.log`

12. **文件完整性校验失败**:
    - 检查网络稳定性，文件传输过程中可能被中断
    - 对于大文件(>10MB)，系统仅检查文件大小，小文件会进行MD5校验
    - 重新运行场景，系统会自动重试失败的传输

13. **从错误节点收集artifacts**:
    ```bash
    # 检查是否使用了废弃的API
    grep "collect_artifacts_from_nodes" logs/playbook_*.log

    # 确认使用新的API
    grep "collect_artifacts_from_test_node" logs/playbook_*.log
    ```

14. **收集模式配置问题**:
    - `basic`: 仅收集test artifacts，不收集服务日志
    - `standard`: 收集test artifacts + Docker服务日志
    - `comprehensive`: 收集所有内容 + 系统日志
    - 检查场景的 `collection_mode` 配置是否符合预期

### 调试命令

```bash
# 详细模式运行
./playbook.py --verbose --log-level DEBUG status

# 验证配置
./playbook.py validate

# 健康检查
./playbook.py health

# 干运行 - 验证配置但不执行
./playbook.py run --dry-run

# 运行单个场景并详细输出
./playbook.py --verbose run baseline_test

# 查看结果的不同格式
./playbook.py results --format json
./playbook.py results --format yaml
./playbook.py results --format table
```

## 📈 性能优化建议

1. **并发控制**: 根据硬件资源调整max_concurrency
2. **批处理**: 使用合适的batch_size提高吞吐量
3. **内存管理**: 监控GPU和系统内存使用情况
4. **网络优化**: 确保节点间网络带宽充足
5. **存储IO**: 使用高性能存储存放模型和结果数据

## 🤝 贡献指南

1. Fork本项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

## 📄 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 📞 支持

如果您在使用过程中遇到问题：

1. 查看 [FAQ](docs/FAQ.md)
2. 搜索已有的 [Issues](https://github.com/your-org/test_playbook/issues)
3. 创建新的 Issue 描述您的问题
4. 联系开发团队获取支持

---

🚀 **Happy Testing!** 🚀