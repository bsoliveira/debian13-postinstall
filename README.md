# Debian 13 – Script de Pós-Instalação e Otimizações

Script de pós-instalação para Debian 13, focado em desktops e laptops, com objetivo de melhorar o desempenho.

- Habilita repositórios contrib e non-free
- Ativa ZRAM
- Configura CPU frequency scaling - modo desempenho
- Reduz tamanho do initramfs
- Otimiza o tempo de boot no GRUB
- Limita tamanho dos registros logs do journald
- Aplica ajustes de sysctl voltados a desktop


## Como usar

```bash
git clone git@github.com:bsoliveira/debian13-postinstall.git
cd debian13-postinstall
sudo chmod +x otimizar.sh
sudo ./otimizar.sh
```

## Testes após a execução

```bash
sudo zramctl
sudo cpupower frequency-info
sudo timedatectl status
sudo systemctl status cpupower.service
sudo systemctl status NetworkManager-wait-online.service
```

## Informações de como reverter

Utilize o `reverter.sh` para reverter as otimizações

```bash
sudo chmod +x reverter.sh
sudo ./reverter.sh
```

## Avisos importantes

Este repositório é destinado a **desktops** e foi validado em uma **instalação limpa do Debian 13**.

As alterações aplicadas buscam manter-se o mais próximo possível do padrão da instalação, adotando apenas ajustes mininos, seguros e amplamente recomendados. Para melhores resultados, revise os arquivos em `configs` e personalize-os de acordo com seu hardware e cenário de uso. Leia a [Documentação](docs/geral.md) para maiores detalhes.

- O script modifica arquivos críticos do sistema
- Arquivos `.bak` são criados em suas respectivas pastas antes de cada alteração
- A desativação do **wait-online** é indicada apenas para desktop
- O arquivo de log `otimizacao.log` é gerado no final

### Arquivos modificados:
- /etc/apt/sources.list
- /etc/initramfs-tools/initramfs.conf
- /etc/default/grub
- /etc/systemd/journald.conf
- /etc/systemd/timesyncd.conf

### Arquivos criados:
- /etc/systemd/zram-generator.conf 
- /etc/systemd/system/cpupower.service
- /etc/sysctl.d/99-custom.conf 
