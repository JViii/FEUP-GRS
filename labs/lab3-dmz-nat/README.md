# Setup

## Configure targets

1. Copy setup directory to config VM (vm-A)

        ./scp-setup.sh
1. ssh into vm-A
1. Run script to setup target VMs

        cd setup && chmod +x setup.sh && ./setup.sh

## Proxmox after rollback

### vm-A

- Add `vmbr0` and `vmbr4`

### vm-B and vm-C

- Rename `vmbr1` to `vmbr4`
- Add `vmbr1` (client-net) `vmbr2` (server-net) and `vmbr3` (public-net)
