#!/bin/bash

############################################################
#        ILLIMITAR - SOLUÇÕES INTEGRADAS                   #
# -------------------------------------------------------- #
#  SISTEMA DE GESTÃO E ATUALIZAÇÃO PDV                     #
#                                                          #
#  Desenvolvido por: Hyago Santagueda & João Victor Moraes #
############################################################

# Configurações do Novo Repositório
REPO="HyagoSantagueda/PDVilliConfig"
PACOTE="pdv"
CAMINHO_INI="/opt/pdv/pdv.ini"
BACKUP_INI="$HOME/pdv.ini"

# Cores ILLIMITAR
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
NC='\033[0m'

# Função para configuração do TEF
configurar_tef() {
    echo -e "\n${AMARELO}==========================================${NC}"
    echo -e "${AMARELO}       CONFIGURAÇÃO ADICIONAL TEF         ${NC}"
    echo -e "${AMARELO}==========================================${NC}"
    read -p "Possui TEF? (s/N): " POSSUI_TEF
    
    if [[ "$POSSUI_TEF" =~ ^([sS])$ ]]; then
        echo "------------------------------------------"
        echo "Configurando TLS..."
        echo "Copiando bibliotecas para /usr/lib..."
        sudo cp -r /opt/pdv/lib/* /usr/lib
        echo "Abrindo configuração TLS..."
        sudo nano /usr/lib/CONFITLS.INI
    fi
    
    echo "------------------------------------------"
    echo -e "${AMARELO}Limpando arquivos temporários...${NC}"
    rm -f pdv.deb
    
    echo -e "${VERDE}Processo finalizado com sucesso! Fechando terminal...${NC}"
    sleep 2
    exit 0
}

# Função para realizar a instalação
instalar_pacote() {
    local url=$1
    local versao=$2
    
    if [ -z "$url" ] || [ "$url" == "null" ]; then
        echo -e "${VERMELHO}ERRO: Link de download não encontrado.${NC}"
        sleep 3
        return
    fi

    echo -e "${AMARELO}Baixando versão: $versao...${NC}"
    rm -f pdv.deb
    wget -q --show-progress --no-cache -O pdv.deb "$url"
    
    if [ ! -s pdv.deb ]; then
        echo -e "${VERMELHO}ERRO: O download falhou.${NC}"
        sleep 3
        return
    fi

    # PKILL SELETIVO: Mata o binário sem derrubar este script
    echo "Encerrando processos do executável PDV..."
    sudo ps aux | grep "/opt/pdv/pdv" | grep -v grep | awk '{print $2}' | xargs -r sudo kill -9 2>/dev/null
    sleep 1

    echo "------------------------------------------"
    if [ -f "$CAMINHO_INI" ]; then
        echo "Fazendo backup do pdv.ini em $BACKUP_INI..."
        cp "$CAMINHO_INI" "$BACKUP_INI"
    fi

    chmod 644 pdv.deb
    echo "Instalando..."
    sudo dpkg -i ./pdv.deb
    sudo apt-get install -f -y
    
    if [ -f "$BACKUP_INI" ]; then
        echo "Restaurando pdv.ini..."
        sudo mkdir -p /opt/pdv
        sudo cp "$BACKUP_INI" "$CAMINHO_INI"
        sudo chmod 666 "$CAMINHO_INI"
    fi

    configurar_tef
}

# Loop Principal do Menu
while true; do
    clear
    echo -e "${AMARELO}############################################################${NC}"
    echo -e "${AMARELO}#        ILLIMITAR - SOLUÇÕES INTEGRADAS                   #${NC}"
    echo -e "${AMARELO}############################################################${NC}"
    echo "Buscando informações na maquina e no GitHub..."

    # Captura das versões no novo repositório
    JSON_LATEST=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest")
    VER_LATEST=$(echo "$JSON_LATEST" | grep -m 1 '"tag_name":' | cut -d'"' -f4 | tr -d 'v')
    URL_LATEST=$(echo "$JSON_LATEST" | grep "browser_download_url" | grep ".deb" | head -n 1 | cut -d'"' -f4)

    JSON_BETA=$(curl -sL "https://api.github.com/repos/$REPO/releases")
    VER_BETA=$(echo "$JSON_BETA" | grep -m 1 '"tag_name":' | cut -d'"' -f4 | tr -d 'v')
    URL_BETA=$(echo "$JSON_BETA" | grep "browser_download_url" | grep ".deb" | head -n 1 | cut -d'"' -f4)

    VER_LOCAL=$(dpkg-query -W -f='${Version}' "$PACOTE" 2>/dev/null | xargs)

    clear
    echo -e "${AMARELO}############################################################${NC}"
    echo -e "${AMARELO}#        ILLIMITAR - SOLUÇÕES INTEGRADAS                   #${NC}"
    echo -e "${AMARELO}############################################################${NC}"
    echo -e "Versão Instalada:  [${VER_LOCAL:-${VERMELHO}Não encontrada${NC}}]"
    echo ""
    echo -e "${VERDE}1) Instalar Versão Estável (${VER_LATEST:-...})${NC}"
    echo -e "2) Sair"
    echo "==========================================="
    
    read -p "Escolha uma opção: " OPCAO

    case $OPCAO in
        1)
            [ "$VER_LATEST" == "$VER_LOCAL" ] && read -p "Reinstalar mesma versão? (s/N): " RESP && [[ ! "$RESP" =~ ^([sS])$ ]] && continue
            instalar_pacote "$URL_LATEST" "$VER_LATEST"
            ;;
        170) # GATILHO OCULTO BETA
            echo -e "${AMARELO}Acessando instalação Beta...${NC}"
            instalar_pacote "$URL_BETA" "$VER_BETA"
            ;;
        171) # GATILHO OCULTO DOWNGRADE
            echo -e "${VERMELHO}>>> MODO DOWNGRADE / LIMPEZA TOTAL (ILLIMITAR) <<<${NC}"
            
            echo "Baixando versão estável para restauração..."
            rm -f pdv.deb
            wget -q --show-progress --no-cache -O pdv.deb "$URL_LATEST"
            
            if [ ! -s pdv.deb ]; then
                echo -e "${VERMELHO}ERRO no download. Operação abortada.${NC}"
                sleep 2
                continue
            fi

            read -p "Confirmar limpeza total e downgrade para $VER_LATEST? (s/N): " CONFIRM
            [[ ! "$CONFIRM" =~ ^([sS])$ ]] && continue

            # Executa a limpeza apenas após a confirmação
            sudo ps aux | grep "/opt/pdv/pdv" | grep -v grep | awk '{print $2}' | xargs -r sudo kill -9 2>/dev/null
            sleep 1

            [ -f "$CAMINHO_INI" ] && cp "$CAMINHO_INI" "$BACKUP_INI"
            sudo apt remove "$PACOTE" -y
            sudo rm -rf /opt/pdv
            
            chmod 644 pdv.deb
            sudo dpkg -i ./pdv.deb
            sudo apt-get install -f -y
            [ -f "$BACKUP_INI" ] && { sudo mkdir -p /opt/pdv; sudo cp "$BACKUP_INI" "$CAMINHO_INI"; sudo chmod 666 "$CAMINHO_INI"; }
            configurar_tef
            ;;
        2) exit 0 ;;
        *) sleep 1 ;;
    esac
done
