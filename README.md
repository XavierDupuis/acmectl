# acmectl

Small POSIX shell tool to list and remove entries from traefik acme.json.

Requirements:
- jq
- POSIX shell (bash recommended)

## Important
It's recommended to stop Traefik before modifying or replacing acme.json to avoid race conditions and overwritten changes.

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

## Usage (and expected output)
### List entries
```
❯ acmectl list /path/to/acme.json

Certificates in /path/to/acme.json:
  - resolver1:subdomainA.domain.com
  - resolver1:subdomainB.domain.com
  - resolver2:subdomainC.anotherdomain.com
```

### Remove entries
```
❯ acmectl remove /path/to/acme.json --domains subdomainA.domain.com subdomainC.anotherdomain.com

Will remove the following entries:
- resolver1:subdomainA.domain.com
- resolver2:subdomainC.anotherdomain.com
Updated file written. Backup: ./path/to/bak.20260108-223512.acme.json
```

### Remove entries (interactive)
```
❯ acmectl remove acme-test.json

Found the following certificate entries:
   1) resolver1:subdomainA.domain.com
   2) resolver1:subdomainB.domain.com
   3) resolver2:subdomainC.anotherdomain.com

Enter numbers to delete (comma-separated, ranges allowed, e.g. 1,3-5), or 'q' to cancel: 2
Selected for deletion:
  - subdomainB.domain.com
Proceed? (y/N): y
Will remove the following entries:
- resolver1:subdomainB.domain.com
Updated file written. Backup: ./path/to/bak.20260108-223512.acme.json
```

## Testing
```bash
chmod +x tests/*.sh tests/suites/suite*.sh
```
### Run all tests
```bash
./tests/run.sh
```

### Run a specific suite
```bash
./tests/suites/suite-***.sh
```