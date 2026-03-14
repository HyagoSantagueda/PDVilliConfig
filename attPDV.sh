#!/bin/bash

############################################################
#        ILLIMITAR - SOLUÇÕES INTEGRADAS                   #
# -------------------------------------------------------- #
#  SISTEMA DE GESTÃO E ATUALIZAÇÃO PDV                     #
############################################################

# Configurações do Repositório
REPO="HyagoSantagueda/PDVilliConfig"
PACOTE="pdv"

# Caminhos Originais
CAMINHO_INI="/opt/pdv/pdv.ini"
CAMINHO_TLS="/usr/lib/CONFITLS.INI"

# Caminhos de Backup
BACKUP_INI="$HOME/pdv.ini"
BACKUP_TLS="$HOME/CONFITLS.INI"

# Cores ILLIMITAR
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
NC='\033[0m'

# Função para configuração do TEF
configurar_tef() {
    echo -e "\n${AMARELO}==========================================${NC}"
    echo -e "${AMARELO}        CONFIGURAÇÃO ADICIONAL TEF         ${NC}"
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
    local tipo=$3
    
    if [ -z "$url" ] || [ "$url" == "null" ]; then
        echo -e "${VERMELHO}ERRO: Link da versão $tipo não encontrado.${NC}"
        sleep 3
        return
    fi

    echo -e "${AMARELO}Baixando versão $tipo: $versao...${NC}"
    wget -q --show-progress --no-cache -O pdv.deb "$url"
    
    if [ ! -s pdv.deb ]; then
        echo -e "${VERMELHO}ERRO: O download falhou.${NC}"
        sleep 3
        return
    fi

    echo -e "\n${VERDE}Versão $tipo ($versao) baixada com sucesso!${NC}"

    local tentativas=0
    while [ $tentativas -lt 2 ]; do
        read -p "Deseja instalar a versão $tipo agora? (s/N): " INSTALAR_AGORA
        
        if [[ "$INSTALAR_AGORA" =~ ^([sS])$ ]]; then
            echo -e "${AMARELO}Iniciando instalação da versão $tipo...${NC}"
            sudo ps aux | grep "/opt/pdv/pdv" | grep -v grep | awk '{print $2}' | xargs -r sudo kill -9 2>/dev/null
            sleep 1

            [ -f "$CAMINHO_INI" ] && cp "$CAMINHO_INI" "$BACKUP_INI"
            [ -f "$CAMINHO_TLS" ] && cp "$CAMINHO_TLS" "$BACKUP_TLS"

            sudo dpkg -i ./pdv.deb
            sudo apt-get install -f -y
            
            if [ -f "$BACKUP_INI" ]; then
                sudo mkdir -p /opt/pdv
                sudo cp "$BACKUP_INI" "$CAMINHO_INI"
                sudo chmod 666 "$CAMINHO_INI"
            fi

            if [ -f "$BACKUP_TLS" ]; then
                sudo cp "$BACKUP_TLS" "$CAMINHO_TLS"
                sudo chmod 666 "$CAMINHO_TLS"
            fi

            configurar_tef
            return
        else
            tentativas=$((tentativas + 1))
            if [ $tentativas -eq 1 ]; then
                echo -e "${AMARELO}Ok, aguardando 10 segundos...${NC}"
                sleep 10
            else
                echo -e "${VERMELHO}Instalação cancelada.${NC}"
                exit 0
            fi
        fi
    done
}

# Loop Principal
while true; do
    clear
    echo -e "${AMARELO}############################################################${NC}"
    echo -e "${AMARELO}#        ILLIMITAR - SOLUÇÕES INTEGRADAS                   #${NC}"
    echo -e "${AMARELO}############################################################${NC}"
    echo "Buscando informações no GitHub..."

    # Captura Estável
    JSON_ESTAVEL=$(curl -sL "https://api.github.com/repos/$REPO/releases/tags/Estavel")
    VER_LATEST=$(echo "$JSON_ESTAVEL" | jq -r 'if .name == null or .name == "" then .tag_name else .name end' | tr -d 'v')
    URL_LATEST=$(echo "$JSON_ESTAVEL" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url' | head -n 1)

    # Captura Local
    VER_LOCAL=$(dpkg-query -W -f='${Version}' "$PACOTE" 2>/dev/null | xargs)
    [ "$VER_LATEST" == "null" ] && VER_LATEST="Não encontrada"

    clear
    echo -e "${AMARELO}############################################################${NC}"
    echo -e "${AMARELO}#        ILLIMITAR - SOLUÇÕES INTEGRADAS                   #${NC}"
    echo -e "${AMARELO}############################################################${NC}"
    echo -e "Versão Instalada:  [${VER_LOCAL:-${VERMELHO}Não encontrada${NC}}]"
    echo -e "Versão Estável:    [${VERDE}${VER_LATEST}${NC}]"
    echo ""
    echo -e "${VERDE}1) Validar/Instalar Versão Estável${NC}"
    echo -e "2) Sair"
    echo "==========================================="
    
    read -p "Escolha uma opção: " OPCAO

    case $OPCAO in
        1)
            if [ -z "$VER_LOCAL" ]; then
                instalar_pacote "$URL_LATEST" "$VER_LATEST" "ESTÁVEL"
            elif dpkg --compare-versions "$VER_LOCAL" "eq" "$VER_LATEST"; then
                echo -e "\n${AMARELO}AVISO: A versão estável ($VER_LATEST) já está instalada.${NC}"
                sleep 1
                configurar_tef
            elif dpkg --compare-versions "$VER_LOCAL" "gt" "$VER_LATEST"; then
                echo -e "${VERMELHO}\nSua versão atual ($VER_LOCAL) é superior à estável ($VER_LATEST).${NC}"
                echo -e "Entre em contato com o Suporte via Chat: ${VERDE}chat.pdv.moda${NC}"
                echo -e "Ou via Whatsapp: ${VERDE}(21) 99464-1819${NC}"
                echo -e "\n${AMARELO}Pressione qualquer tecla para sair...${NC}"
                read -n 1 -s
                exit 0
            else
                instalar_pacote "$URL_LATEST" "$VER_LATEST" "ESTÁVEL"
            fi
            ;;
        170) # BETA (OCULTO)
            echo -e "${AMARELO}Acessando canal BETA (Interno)...${NC}"
            JSON_BETA_REL=$(curl -sL "https://api.github.com/repos/$REPO/releases/tags/Beta")
            VER_BETA=$(echo "$JSON_BETA_REL" | jq -r 'if .name == null or .name == "" then .tag_name else .name end' | tr -d 'v')
            URL_BETA=$(echo "$JSON_BETA_REL" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url' | head -n 1)
            
            if [ "$VER_BETA" == "null" ]; then
                echo -e "${VERMELHO}Erro: Tag Beta não encontrada.${NC}"
                sleep 2
            else
                instalar_pacote "$URL_BETA" "$VER_BETA" "BETA"
            fi
            ;;
        171) # DOWNGRADE (OCULTO)
            echo -e "${VERMELHO}>>> MODO DOWNGRADE MANUAL <<<${NC}"
            read -p "Confirmar limpeza e downgrade para Estável $VER_LATEST? (s/N): " CONFIRM
            [[ ! "$CONFIRM" =~ ^([sS])$ ]] && continue
            
            [ -f "$CAMINHO_INI" ] && cp "$CAMINHO_INI" "$BACKUP_INI"
            [ -f "$CAMINHO_TLS" ] && cp "$CAMINHO_TLS" "$BACKUP_TLS"
            
            sudo ps aux | grep "/opt/pdv/pdv" | grep -v grep | awk '{print $2}' | xargs -r sudo kill -9 2>/dev/null
            sudo apt remove "$PACOTE" -y && sudo rm -rf /opt/pdv
            
            instalar_pacote "$URL_LATEST" "$VER_LATEST" "ESTÁVEL (Downgrade)"
            ;;
        2) exit 0 ;;
        *) sleep 1 ;;
    esac
done
