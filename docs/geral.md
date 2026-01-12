# Debian 13 – Script de Pós-Instalação e Otimizações

Script de pós-instalação para Debian 13, focado em desktops e laptops, com objetivo de melhorar desempenho.

## O que o script faz

### Repositórios Extras - `/etc/apt/`

Habilita os repositórios contrib e non-free para ter acesso a 
mais pacotes de software.

- Saiba mais em https://wiki.debian.org/SourcesList


### ZRAM - `/etc/systemd/zram-generator.conf`

Habilita o ZRAM oferece benefícios significativos, principalmente por 
criar um dispositivo de troca (swap) comprimido na memória RAM, o que 
melhora o desempenho do sistema ao reduzir drasticamente a necessidade 
de usar o disco rígido ou SSD como swap.

```text
[zram0]
zram-size = min(ram / 2, 4096) # 4096 = 4G
compression-algorithm = zstd
```

- Instala `systemd-zram-generator`
- Evita o uso de swap em disco
- Melhora responsividade em sistemas com pouca RAM
- Considere editar o arquivo e ajustar o _zram-size_ ao perfil do seu hardware
- Considere trocar o algoritimo de compressão em processadores fracos
- Saiba mais em https://wiki.debian.org/ZRam
- Github https://github.com/systemd/zram-generator

### CPU Frequency Scaling - `/etc/systemd/system/cpupower.service`

Habilita o Serviço systemd para forçar o governor "performance" em todos os 
núcleos da CPU indicado para desktops e notebooks ligados à tomada, onde 
desempenho é prioridade em relação à economia de energia.

```text
[Unit]
Description=Set all cores to performance governor
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/cpupower -c all frequency-set -g performance

[Install]
WantedBy=multi-user.target
```

- Habilita controle moderno de frequência da CPU
- Usa `linux-cpupower` com serviço
- Você deve editar o arquivo para melhor adquar ao perfil do seu hardware
- saiba mais em https://wiki.debian.org/CpuFrequencyScaling
- Outro otimo post em https://www.vivaolinux.com.br/dica/Regulando-velocidade-e-energia-gasta-pelos-processadores-Metodo-moderno-cpupower


### Sincronização de horário -`/etc/systemd/timesyncd.conf`

Sincronização com a Hora Legal: O NTP.br fornece acesso à Hora Legal 
Brasileira (HLB), que é a referência oficial de tempo no Brasil, sendo 
uma fonte confiável para seus dispositivos.

```text
[Time]
NTP=a.st1.ntp.br b.st1.ntp.br c.st1.ntp.br d.st1.ntp.br
```

- Compatível com _NTP.br_ orgão competente do Brasil
- Aplique somente se você deseja usar servidores nacionais
- Saiba mais em https://ntp.br/guia/linux/d


### Initramfs - `/etc/initramfs-tools/initramfs.conf`

Diminuir o tamanho do Initramfs é benéfico principalmente para
economizar espaço na partição /boot e, em sistemas embarcados ou com recursos 
limitados, reduzir o tempo de inicialização e o uso de RAM.


```text
MODULES=dep
COMPRESS=zstd
```

- Reduz tamanho do `initrd`
- Configura o modo _dep_ que tenta carregar os módulos necessários conforme sua máquina
- Ativa compressão com `zstd`
- Saiba mais em https://wiki.debian.org/initramfs
- GitHub: https://github.com/systemd/zram-generator


## GRUB - `/etc/default/grub`

Configurar o GRUB para proporcionar um "boot rápido" visualmente, suprimindo a maioria 
das mensagens do kernel durante a inicialização. Isso cria uma experiência de inicialização 
mais limpa e silenciosa.

```bash
GRUB_TIMEOUT=1
GRUB_TIMEOUT_STYLE=hidden
GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 systemd.show_status=auto rd.udev.log_level=3"
GRUB_TERMINAL=console
```

- 1 segundo boot praticamente imediato e ainda permite _Esc_ ift se precisar
- Logs ainda suficientes para debug básico
- Mensagens na tela apenas se algo atrasar
- A opção _console_ Mantém o boot simples
- Saiba mais em [Grub Simple-configuration](https://www.gnu.org/software/grub/manual/grub/grub.html#Simple-configuration)

### Journald - `/etc/systemd/journald.conf`

O journald diminui o tamanho dos arquivos de log automaticamente através de políticas 
de rotação e limite de espaço em disco, que são configuradas para evitar que os logs 
consumam demasiado espaço disponível no sistema. O script ajusta do armazemaneto de logs 
apropiado para uso desktop.

```text
SystemMaxUse=200M
SystemMaxFileSize=50M
MaxRetentionSec=1month
```

- Excelente para desktop
- Limita o total de logs persistentes
- Evita desgaste de SSD
- Facilita limpeza automática
- Garante que logs antigos não sobrevivam indefinidamente
- Saiba mais em https://wiki.archlinux.org/title/Systemd/Journal


### Ajustes de kernel (sysctl) - `/etc/sysctl.d/99-custom.conf` 

O kernel padrão do Linux é projetado para ser um sistema equilibrado e estável 
para uso geral, mas nem sempre é otimizado para todos os cenários de uso.

A realização de ajustes do kernel (via sysctl) em qualquer sistema Linux, possibilita 
a otimização de desempenho, segurança e personalização do comportamento do sistema operacional
para atender a necessidades específicas. 

```text
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 15
fs.inotify.max_user_watches = 524288
```

- Aplica ajustes comuns voltados para desktop
- Reduz micro travamentos
- Melhora a responsividade
- Saiba mais em https://wiki.archlinux.org/title/Sysctl


### Desativar o serviço `NetworkManager-wait-online.service`

O principal motivo para desabilitar o NetworkManager-wait-online.service é reduzir 
o tempo de inicialização do sistema, especialmente em desktops, notebooks ou máquinas 
virtuais que não dependem de recursos de rede para concluir o processo de boot. 

- Otimiza o tempo de boot para Desktop comum
- `Cuidado!` serviços como VPN e outros de rede no boot podem quebrar