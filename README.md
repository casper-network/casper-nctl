# nctl

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Documentation](https://img.shields.io/badge/docs-casper.network-informational)](https://docs.casper.network)

> CLI application to setup & control multiple local Casper networks

**nctl** stands for **n**[etwork|ode] **c**on**t**ro**l**. It simplifies the setup and management of local Casper test networks, enabling developers, validators, and evaluators to spin up and control multiple nodes for testing and development purposes.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Multi-node Network Setup** - Quickly spin up local networks with multiple validator nodes
- **Network Control** - Start, stop, and manage network nodes with simple commands
- **Test Automation** - Deploy contracts, submit transactions, and test scenarios locally
- **Asset Management** - Manage accounts, keys, and network assets
- **Chain Inspection** - View blocks, transactions, and network state

## Requirements

- **python3** + pip
- **make**
- **cargo** (Rust toolchain)
- **bash**
- **jq** (JSON parsing utility)

Plus the requirements to build [casper-node](https://github.com/casper-network/casper-node#pre-requisites-for-building)

## Quick Start

### 1. Clone Required Repositories

```bash
# Clone nctl
git clone https://github.com/casper-network/casper-nctl.git
cd casper-nctl

# Clone dependencies (in the same parent directory)
cd ..
git clone https://github.com/casper-network/casper-node.git
git clone https://github.com/casper-ecosystem/casper-client-rs.git
git clone https://github.com/casper-network/casper-node-launcher.git
git clone https://github.com/casper-network/casper-sidecar.git
```

### 2. Activate nctl

```bash
cd casper-nctl
source activate
```

### 3. Compile and Setup Network

```bash
# Compile network binaries
nctl-compile

# Setup network assets (creates a 5-node network)
nctl-assets-setup

# Start the network
nctl-start
```

### 4. Verify Network Status

```bash
# View network status
nctl-view-chain-state-root-hash

# View node status
nctl-view-node-status node=1
```

## Documentation

For detailed information, please refer to the following documentation:

- **[Setup Guide](docs/setup.md)** - Complete installation and configuration instructions
- **[Commands Reference](docs/commands.md)** - Full list of available nctl commands
- **[Usage Guide](docs/usage.md)** - Detailed usage examples and workflows

## Who Uses nctl?

nctl is used by the CSPR network community, including:

- **Developers** - Testing smart contracts and dApps locally
- **Validators** - Testing node operations and network scenarios
- **Evaluators** - Assessing network behavior and performance
- **Contributors** - Developing and testing casper-node changes

## Contributing

Contributions are welcome! Please see our [Contributing Guidelines](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md).

If you discover a security vulnerability, please review our [Security Policy](SECURITY.md).

## License

This project is licensed under the [Apache License 2.0](LICENSE).

