# acmectl

Small POSIX shell tool to list and remove entries from traefik acme.json.

Requirements:
- jq
- POSIX shell (bash recommended)

Usage:
  acmectl list /path/to/acme.json
  acmectl remove /path/to/acme.json
  acmectl remove /path/to/acme.json --domains domain1 domain2 --dry-run

## Install 
### Quick
```bash
curl -fsSL https://raw.githubusercontent.com/XavierDupuis/acmectl/main/install.sh | sudo bash
```
### Manual
```bash
curl -LO https://github.com/XavierDupuis/acmectl/raw/main/src/acmectl
sudo install -m 0755 acmectl /usr/local/bin/acmectl
```
