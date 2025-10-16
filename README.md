# Surge DevNet L1 Scripts

This directory contains streamlined scripts for deploying and managing Surge DevNet L1 - a private Ethereum testnet optimized for Surge development and testing.

## Overview

The Surge DevNet L1 scripts provide a simplified interface to deploy and manage a private Ethereum testnet with the following components:

- **Execution Layer**: Nethermind client
- **Consensus Layer**: Lighthouse client  
- **Block Explorer**: Blockscout with frontend
- **Transaction Tools**: Spamoor for load testing
- **Monitoring**: Built-in health checks

## Platform Support

### Supported Operating Systems

| Platform | Status | Notes |
|----------|--------|-------|
| **Linux** | ✅ Fully Supported | Recommended for production use |
| **macOS** | ✅ Fully Supported | Intel and Apple Silicon (M1/M2) |
| **Windows** | ⚠️ Limited Support | Requires WSL2 or Docker Desktop |

## Prerequisites

Before using these scripts, ensure you have the following installed:

1. **Docker** - [Installation Guide](https://docs.docker.com/get-docker/)
2. **Kurtosis CLI** - [Installation Guide](https://docs.kurtosis.com/install)
3. **curl** - For health checks
4. **jq** - For JSON parsing

### Verify Installation

```bash
# Check if all dependencies are available
docker --version
kurtosis version
curl --version
jq --version
```

## Scripts

### 1. Deploy Script (`deploy-surge-devnet-l1.sh`)

Deploys a new Surge DevNet L1 instance.

#### Basic Usage

```bash
# Interactive deployment (recommended for first-time users)
./deploy-surge-devnet-l1.sh

# Command-line deployment
./deploy-surge-devnet-l1.sh --environment local --mode silence
```

#### Options

| Option | Values | Description |
|--------|--------|-------------|
| `--environment` | `local`, `remote` | Deployment environment |
| `--mode` | `silence`, `debug` | Output verbosity |
| `-h`, `--help` | - | Show help message |

#### Deployment Modes

**Local Deployment** (Default)
- Services accessible via `127.0.0.1`
- Ideal for local development and testing

**Remote Deployment**
- Services accessible via machine's IP address
- Suitable for shared development environments
- Automatically detects and configures machine IP

#### Output Modes

**Silence Mode** (Default)
- Minimal output during deployment
- Shows progress indicators and final status

**Debug Mode**
- Verbose Kurtosis output
- Useful for troubleshooting deployment issues

### 2. Remove Script (`remove-surge-devnet-l1.sh`)

Safely removes Surge DevNet L1 and cleans up all resources.

#### Basic Usage

```bash
# Interactive removal with confirmation
./remove-surge-devnet-l1.sh

# Force removal without confirmation
./remove-surge-devnet-l1.sh --force
```

#### Options

| Option | Description |
|--------|-------------|
| `-f`, `--force` | Skip confirmation prompt |
| `-h`, `--help` | Show help message |

## Service Endpoints

After successful deployment, the following services will be available:

| Service | Endpoint | Description |
|---------|----------|-------------|
| **Execution Layer RPC** | `http://127.0.0.1:32003` | JSON-RPC API for blockchain interactions |
| **Execution Layer WS** | `ws://127.0.0.1:32004` | WebSocket API for real-time updates |
| **Consensus Layer API** | `http://127.0.0.1:33001` | Beacon Chain API |
| **Block Explorer** | `http://127.0.0.1:36005` | Blockscout web interface |
| **Transaction Spammer** | `http://127.0.0.1:34000` | Spamoor load testing interface |

> **Note**: Port numbers may vary between deployments. The actual endpoints are displayed after successful deployment.

## Usage Examples

### Quick Start

```bash
# 1. Deploy with default settings
./deploy-surge-devnet-l1.sh

# 2. Wait for deployment to complete
# 3. Use the displayed endpoints to interact with your network

# 4. When finished, remove the network
./remove-surge-devnet-l1.sh
```

### Development Workflow

```bash
# Deploy in debug mode for development
./deploy-surge-devnet-l1.sh --environment local --mode debug

# Test your application against the network
curl -X POST http://127.0.0.1:32003 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# Clean up when done
./remove-surge-devnet-l1.sh --force
```

### Remote Access Setup

```bash
# Deploy for remote access
./deploy-surge-devnet-l1.sh --environment remote --mode silence

# Services will be accessible via your machine's IP
# Example: http://192.168.1.100:36005 (Block Explorer)
```

## Network Configuration

The network is configured via `network_params.yaml`. Key settings include:

- **Participants**: 4 nodes (1 EL + 1 CL each)
- **Clients**: Nethermind (EL) + Lighthouse (CL)
- **Network ID**: Custom private network
- **Genesis**: Pre-funded accounts for testing

## Troubleshooting

### Common Issues

**1. Port Conflicts**
```bash
# Check if ports are in use
netstat -tulpn | grep :32003

# Solution: Stop conflicting services or use different ports
```

**2. Docker Issues**
```bash
# Restart Docker daemon
sudo systemctl restart docker

# Clean up Docker resources
docker system prune -f
```

**3. Kurtosis Issues**
```bash
# Clean up Kurtosis resources
kurtosis clean -a

# Check Kurtosis status
kurtosis enclave ls
```

**4. Network Not Starting**
```bash
# Deploy in debug mode to see detailed logs
./deploy-surge-devnet-l1.sh --mode debug

# Check individual service logs
kurtosis service logs surge-devnet el-1-nethermind-lighthouse
```

### Health Checks

The deploy script automatically performs health checks:

- **Execution Layer**: Verifies sync status via JSON-RPC
- **Consensus Layer**: Checks beacon node sync status
- **Overall Status**: Reports network readiness

### Manual Health Check

```bash
# Check execution layer
curl -X POST http://127.0.0.1:32003 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'

# Check consensus layer
curl http://127.0.0.1:33001/lighthouse/syncing
```

## Advanced Usage

### Custom Configuration

1. Modify `network_params.yaml` for custom network settings
2. Deploy with your configuration:
   ```bash
   ./deploy-surge-devnet-l1.sh --environment local --mode debug
   ```

### Multiple Networks

```bash
# Deploy multiple instances with different enclave names
# (Requires manual modification of ENCLAVE_NAME in scripts)
kurtosis run --enclave surge-devnet-1 . --args-file network_params.yaml
kurtosis run --enclave surge-devnet-2 . --args-file network_params.yaml
```

### Monitoring

Access the following for network monitoring:

- **Blockscout**: Real-time block explorer
- **Spamoor**: Transaction load testing
- **Direct RPC**: Custom monitoring via JSON-RPC calls

## Support

For issues and questions:

1. **Check logs**: Use debug mode for detailed output
2. **Verify setup**: Ensure all prerequisites are installed
3. **Clean environment**: Use remove script and try again
4. **Contact team**: Reach out to the Surge development team

## Contributing

When modifying these scripts:

1. Follow the existing code style and patterns
2. Test both local and remote deployment modes
3. Verify cleanup functionality
4. Update this README for any new features

---

**Happy testing with Surge DevNet L1!** 🚀
