#!/bin/bash

# reverter.sh
# Debian 13 Reverter Otimizações
# Autor: Bruno (Tijolaum)
# URL: https://github.com/bsoliveira

set -eE
trap 'fatal_error $LINENO "$BASH_COMMAND"' ERR

### Garantir execução como root
[ "$EUID" -ne 0 ] && { echo "Executar como root"; exit 1; }

### Arquivo de log
LOG_FILE="reversao.log"

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


echo -e "${RED}"
echo -e "██████  ███████ ██████  ██  █████  ███    ██      ██ ██████ "                 
echo -e "██   ██ ██      ██   ██ ██ ██   ██ ████   ██     ███      ██"
echo -e "██   ██ █████   ██████  ██ ███████ ██ ██  ██      ██  █████ "
echo -e "██   ██ ██      ██   ██ ██ ██   ██ ██  ██ ██      ██      ██"
echo -e "██████  ███████ ██████  ██ ██   ██ ██   ████      ██ ██████ "                       
echo -e "${RESET}"
echo -e "${YELLOW}"
echo -e "Revertendo otimizações"
echo -e "-------------------------------------${RESET}"


### Revertendo sources.list
if [ -f /etc/apt/sources.list.bak  ]; then
  mv /etc/apt/sources.list.bak  /etc/apt/sources.list 
  apt update

  log_status "Revertendo sources.list: revertido com sucesso" "APLICADO"
  
else
  log_status "Revertendo sources.list: nada a fazer" "IGNORADO"
fi

### Remover systemd-zram-generator
if [ -f /etc/systemd/zram-generator.conf ]; then
  swapoff -a
  apt purge systemd-zram-generator -y
  rm /etc/systemd/zram-generator.conf  
  systemctl daemon-reload

  log_status "ZRAM: removido com sucesso" "APLICADO"

else
  log_status "ZRAM: nada a fazer" "IGNORADO"
fi


### Reverter initramfs.conf
if [ -f "/etc/initramfs-tools/initramfs.conf.bak" ]; then 
  mv /etc/initramfs-tools/initramfs.conf.bak /etc/initramfs-tools/initramfs.conf  
  update-initramfs -u 
  
  log_status "INITRAMFS: revertido com sucesso" "APLICADO" 

else 
  log_status "INITRAMFS: nada a fazer" "IGNORADO" 
fi


### Reverter GRUB
if [ -f "/etc/default/grub.bak" ]; then 
  mv /etc/default/grub.bak /etc/default/grub
  update-grub 
  
  log_status "GRUB: revertido com sucesso" "APLICADO" 

else 
  log_status "GRUB: nada a fazer" "IGNORADO" 
fi


### Reverter CPU-POWER
if [ -f /etc/systemd/system/cpupower.service ]; then
  systemctl stop cpupower.service
  systemctl disable cpupower.service  
  apt purge linux-cpupower -y
  rm /etc/systemd/system/cpupower.service
  systemctl daemon-reload

  log_status "CPU-POWER: revertido com sucesso" "APLICADO"

else
  log_status "CPU-POWER: nada a fazer" "IGNORADO"
fi


### Reverter Journald
if [ -f /etc/systemd/journald.conf.bak ]; then
  mv /etc/systemd/journald.conf.bak /etc/systemd/journald.conf
  systemctl restart systemd-journald

  log_status "journald: revertido com sucesso" "APLICADO"

else
  log_status "journald: nada a fazer" "IGNORADO"
fi

### Reverter timesyncd
if [ -f "/etc/systemd/timesyncd.conf.bak" ]; then 
  mv /etc/systemd/timesyncd.conf.bak /etc/systemd/timesyncd.conf  
  systemctl restart systemd-timesyncd 

  log_status "NTP.br: revertido com sucesso" "APLICADO" 

else   
  log_status "NTP.br: nada a fazer" "IGNORADO" 
fi

### Reverter Sysctl
if [ -f /etc/sysctl.d/99-custom.conf ]; then
  rm /etc/sysctl.d/99-custom.conf
  sysctl --system
  
  log_status "Sysctl: revertido com sucesso" "APLICADO" 

else
  log_status "Sysctl: nada a fazer" "IGNORADO"
fi
 

### Habilitar NetworkManager-wait-online
if systemctl is-active --quiet NetworkManager-wait-online.service; then
  log_status "NetworkManager-wait-online: está habilitado" "IGNORADO"

else
  systemctl unmask NetworkManager-wait-online.service
  systemctl enable NetworkManager-wait-online.service 
  systemctl start NetworkManager-wait-online.service
  
  log_status "NetworkManager-wait-online: foi habilitado com sucesso" "APLICADO" 
fi


echo ""
echo "Concluído com sucesso!"
echo "Log: $LOG_FILE"
echo -e "${YELLOW}Recomendado reiniciar o sistema${RESET}"
