#!/bin/bash

# otimizar.sh
# Debian 13 Pós Instalação e Otimizações
# Autor: Bruno (Tijolaum)
# URL: https://github.com/bsoliveira

set -eE
trap 'fatal_error $LINENO "$BASH_COMMAND"' ERR

### Garantir execução como root
[ "$EUID" -ne 0 ] && { echo "Executar como root"; exit 1; }

### Arquivo de log
LOG_FILE="otimizacao.log"

### Cores
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

### Criar log
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

### Função de log
log_status() {
  local msg="$1"
  local status="$2"

  case "$status" in
    APLICADO) echo -e "$msg: ${GREEN}APLICADO${RESET}" ;;
    IGNORADO) echo -e "$msg: ${YELLOW}IGNORADO${RESET}" ;;
    ERRO)     echo -e "$msg: ${RED}ERRO${RESET}" ;;
  esac

  echo "$(date '+%F %T') - $msg: $status" >> "$LOG_FILE"
}

### Erro fatal
fatal_error() {
  local code=$?
  local line=$1
  local cmd=$2

  echo -e "\n${RED}ERRO GRAVE${RESET} na linha $line"
  echo "Comando: $cmd"

  {
    echo "$(date '+%F %T') - ERRO GRAVE"
    echo "Linha: $line"
    echo "Comando: $cmd"
    echo "Código: $code"
    echo "----------------------------------------"
  } >> "$LOG_FILE"

  echo "Log salvo em $LOG_FILE"
  exit "$code"
}

### Cabeçalho do log
{
  echo "===== Debian 13 Pós-Instalação ====="
  echo "Data: $(date)"
  echo "Host: $(hostname)"
  echo "==================================="
} >> "$LOG_FILE"


echo -e "${GREEN}"
echo -e "██████  ███████ ██████  ██  █████  ███    ██      ██ ██████ "                 
echo -e "██   ██ ██      ██   ██ ██ ██   ██ ████   ██     ███      ██"
echo -e "██   ██ █████   ██████  ██ ███████ ██ ██  ██      ██  █████ "
echo -e "██   ██ ██      ██   ██ ██ ██   ██ ██  ██ ██      ██      ██"
echo -e "██████  ███████ ██████  ██ ██   ██ ██   ████      ██ ██████ "                       
echo -e "${RESET}"
echo -e "${YELLOW}"
echo -e "Iniciando otimizações pós-instalação"
echo -e "-------------------------------------${RESET}"


### Repositórios Extras - Habilita os repositórios `contrib` e `non-free`
if [ -f /etc/apt/sources.list.bak ]; then
  log_status "Habilitar Repositórios Extras: configurado anteriormente" "IGNORADO"
else
  cp /etc/apt/sources.list /etc/apt/sources.list.bak

  sed -i -E '
  /^deb(-src)? / {
    / contrib /! s/\bmain\b/main contrib/
    / non-free /! s/\bcontrib\b/contrib non-free/
  }
  ' /etc/apt/sources.list

  log_status "Habilitar Repositórios Extras" "APLICADO"
fi


### Migra o APT para o formato Deb822
if [ -f /etc/apt/sources.list.d/debian.sources ]; then
  log_status "Modernizar Deb822: configurado anteriormente" "IGNORADO"
else
  apt modernize-sources -y
 
  log_status "Modernizar Deb822: configurado com sucesso" "APLICADO"
fi


### Atualizar Sistema
apt update
apt upgrade -y
apt autoremove -y
apt clean
log_status "Atualizar sistema" "APLICADO"


### Instala e configura o systemd-zram-generator
if [ -f /etc/systemd/zram-generator.conf ]; then
  log_status "ZRAM: configurado anteriormente" "IGNORADO"
else
  apt install -y zstd systemd-zram-generator
  cp configs/zram-generator.conf /etc/systemd/zram-generator.conf
  
  systemctl daemon-reload
  
  log_status "ZRAM: configurado com sucesso" "APLICADO"
fi

### Diminuir o tamanho do Initramfs 
if [ -f "/etc/initramfs-tools/initramfs.conf.bak" ]; then 
  log_status "INITRAMFS: configurado anteriormente" "IGNORADO" 
else 
  mv /etc/initramfs-tools/initramfs.conf /etc/initramfs-tools/initramfs.conf.bak 
  cp configs/initramfs.conf /etc/initramfs-tools/initramfs.conf 
  
  update-initramfs -u 
  
  log_status "INITRAMFS: configurado com sucesso" "APLICADO" 
fi

### Configura GRUB para uma inicialização mais limpa e silenciosa
if [ -f "/etc/default/grub.bak" ]; then 
  log_status "GRUB: configurado anteriormente" "IGNORADO" 
else 
  mv /etc/default/grub /etc/default/grub.bak 
  cp configs/grub /etc/default/grub 
  
  update-grub 
  
  log_status "GRUB: configurado com sucesso" "APLICADO" 
fi

### Habilitar o Serviço systemd para forçar o governor "performance" 
if [ ! -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors ]; then
  log_status "CPU-POWER: não aplicável - scaling_available_governors não encontrado" "IGNORADO"

elif [ -f /etc/systemd/system/cpupower.service ]; then
  log_status "CPU-POWER: configurado anteriormente" "IGNORADO"

else
  apt install -y linux-cpupower
  cp configs/cpupower.service /etc/systemd/system/
  
  systemctl start cpupower.service
  systemctl enable cpupower.service
  
  log_status "CPU-POWER: configurado com sucesso" "APLICADO"
fi


### Journald - diminui o tamanho dos arquivos de log
if [ -f /etc/systemd/journald.conf.bak ]; then
  log_status "journald: configurado anteriormente" "IGNORADO"

else
  mv /etc/systemd/journald.conf /etc/systemd/journald.conf.bak
  cp configs/journald.conf /etc/systemd/journald.conf
  
  systemctl restart systemd-journald
  
  log_status "journald: configurado com sucesso" "APLICADO"
fi


### Sincronização com a Hora Legal Brasileira NTP.br
if [ -f "/etc/systemd/timesyncd.conf.bak" ]; then 
  log_status "NTP.br: configurado anteriormente" "IGNORADO" 

else 
  mv /etc/systemd/timesyncd.conf /etc/systemd/timesyncd.conf.bak 
  cp configs/timesyncd.conf /etc/systemd/timesyncd.conf
  
  timedatectl set-ntp true 
  systemctl restart systemd-timesyncd 
  
  log_status "NTP.br: configurado com sucesso" "APLICADO" 
fi


### Sysctl TUNING DE KERNEL – DESKTOP / LAPTOP
if [ -f /etc/sysctl.d/99-custom.conf ]; then
  log_status "Sysctl: configurado anteriormente" "IGNORADO"

else
  cp configs/99-custom.conf /etc/sysctl.d/
  
  sysctl --system
  
  log_status "Sysctl: configurado com sucesso" "APLICADO" 
fi


### Desabilitar NetworkManager-wait-online
if systemctl is-active --quiet NetworkManager-wait-online.service; then
  systemctl stop NetworkManager-wait-online.service
  systemctl disable NetworkManager-wait-online.service
  systemctl mask NetworkManager-wait-online.service
  
  log_status "NetworkManager-wait-online: foi desabilitado com sucesso" "APLICADO" 

else
  log_status "NetworkManager-wait-online: não está habilitado" "IGNORADO"
fi


echo ""
echo "Concluído com sucesso!"
echo "Log: $LOG_FILE"
echo -e "${YELLOW}Recomendado reiniciar o sistema${RESET}"
