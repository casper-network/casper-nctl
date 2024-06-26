# NCTL setup

## Prerequisites

1. bash shell.
1. python3 + pip3.
1. [This repository](https://github.com/casper-network/casper-nctl) cloned into YOUR_WORKING_DIRECTORY.
1. The [casper-node repository](https://github.com/casper-network/casper-node) cloned into YOUR_WORKING_DIRECTORY.
1. The [casper-client-rs repository](https://github.com/casper-ecosystem/casper-client-rs) cloned into YOUR_WORKING_DIRECTORY.
1. The [casper-node-launcher repository](https://github.com/casper-network/casper-node-launcher) cloned into YOUR_WORKING_DIRECTORY.
1. The [casper-sidecar](https://github.com/casper-network/casper-sidecar) cloned into YOUR_WORKING_DIRECTORY.

### NOTE

Ensure you are checked out to the correct branch of each of the three repositories above.  Generally this will
be `dev` (or your working branch recently forked from `dev`) for casper-node and casper-client-rs, and `main` for
casper-node-launcher.

## Install prerequisites

```
# Supervisor - cross-platform process manager.
python3 -m pip install supervisor

# Utilities for config file parsing and generation.
python3 -m pip install toml tomlkit

# Rust toolchain and smart contracts - required by casper-node software.
cd YOUR_WORKING_DIRECTORY/casper-node
make setup-rs
```

## Extend .bashrc file to make NCTL commands available from terminal session

```
cd YOUR_WORKING_DIRECTORY/casper-nctl

cat >> $HOME/.bashrc <<- EOM

# ----------------------------------------------------------------------
# CASPER - NCTL
# ----------------------------------------------------------------------

# Activate NCTL shell.
. $(pwd)/activate

EOM
```

## Refresh bash session

```
. $HOME/.bashrc
```
## Compile it

```
nctl-compile
```