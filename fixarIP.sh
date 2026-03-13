#!/bin/bash

# Cores ILLIMITAR
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
NC='\033[0m'

clear
echo -e "${AMARELO}======================================================"
echo "   SISTEMA DE CONFIGURAÇÃO DE IP ESTÁTICO - PDV v1.1"
echo -e "======================================================${NC}"

# --- Identificação do PDV ---
echo ""
echo "Digite o número do PDV (1 a 53) ou 'n' para sair:"
read -p "Número: " PDV

# Opção de saída
if [[ "$PDV" =~ ^([nN])$ ]]; then
    echo "Saindo da configuração de IP..."
    exit 0
fi

# --- Lógica de IP (PDV vs SYNC) ---
if [[ "$PDV" == "sync" ]]; then
    # Opção oculta para Servidor Sync
    IP_FINAL=171
    TIPO="SERVIDOR SYNC"
else
    # Validação do intervalo para PDVs normais
    if ! [[ "$PDV" =~ ^[0-9]+$ ]] || [ "$PDV" -lt 1 ] || [ "$PDV" -gt 53 ]; then
        echo -e "${VERMELHO}Erro: O número do PDV deve ser entre 1 e 53.${NC}"
        echo "Pressione qualquer tecla para sair..."
        read -n 1 -s
        exit 1
    fi
    IP_FINAL=$((200 + PDV))
    TIPO="PDV $PDV"
fi

# --- Detecção de Rede ---
INTERFACE=$(nmcli -t -f DEVICE,TYPE,STATE device | grep ":ethernet:connected" | cut -d: -f1 | head -n1)
[ -z "$INTERFACE" ] && INTERFACE=$(nmcli -t -f DEVICE,STATE device | grep ":connected" | cut -d: -f1 | head -n1)

GATEWAY=$(ip route | grep default | awk '{print $3}' | head -n1)
MASK_CIDR=$(ip -o -f inet addr show "$INTERFACE" | awk '{print $4}' | cut -d/ -f2)
[ -z "$MASK_CIDR" ] && MASK_CIDR="24"
NETWORK_PREFIX=$(echo "$GATEWAY" | cut -d. -f1-3)

if [ -z "$NETWORK_PREFIX" ]; then
    echo -e "${VERMELHO}Erro: Não foi possível detectar o Gateway. Verifique o cabo de rede.${NC}"
    echo "Pressione qualquer tecla para finalizar..."
    read -n 1 -s
    exit 1
fi

IP_ALVO="$NETWORK_PREFIX.$IP_FINAL"

echo -e "${AMARELO}Verificando se o IP $IP_ALVO ($TIPO) está disponível...${NC}"
IP_ATUAL=$(hostname -I | awk '{print $1}')
if [ "$IP_ATUAL" != "$IP_ALVO" ]; then
    if ping -c 1 -W 1 "$IP_ALVO" > /dev/null 2>&1; then
        echo -e "${VERMELHO}ERRO: O IP $IP_ALVO já está em uso! Operação cancelada.${NC}"
        echo "Pressione qualquer tecla para finalizar..."
        read -n 1 -s
        exit 1
    fi
fi

# --- Aplicação ---
echo "Configurando IP $IP_ALVO em $INTERFACE..."
CON_NAME=$(nmcli -t -f NAME,DEVICE connection show --active | grep "$INTERFACE" | cut -d: -f1 | head -n1)
[ -z "$CON_NAME" ] && CON_NAME=$(nmcli -t -f NAME connection show --active | head -n1)

nmcli connection modify "$CON_NAME" \
    ipv4.addresses "$IP_ALVO/$MASK_CIDR" \
    ipv4.gateway "$GATEWAY" \
    ipv4.dns "1.1.1.1,1.0.0.1" \
    ipv4.method manual

nmcli connection up "$CON_NAME" > /dev/null 2>&1

# --- Finalização ---
echo -e "\n${VERDE}IP FIXADO COM SUCESSO: $IP_ALVO ($TIPO)${NC}"
echo -e "${AMARELO}Pressione qualquer tecla para finalizar...${NC}"

read -n 1 -s

exit 0
