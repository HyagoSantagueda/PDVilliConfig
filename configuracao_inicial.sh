#!/bin/bash

############################################################
#        ILLIMITAR - SOLUÇÕES INTEGRADAS                   #
# -------------------------------------------------------- #
#  SCRIPT DE CONFIGURAÇÃO INICIAL DE TERMINAL PDV          #
#                                                          #
#  Idealizado e Desenvolvido por:                          #
#  Hyago Santagueda & João Victor Moraes                   #
############################################################

# Variáveis de Ambiente
USER_NAME="user"
USER_ID=$(id -u $USER_NAME)
CAPA_PATH="/home/$USER_NAME/imagens_sistema/capa.png"
LOGO_PATH="/home/$USER_NAME/imagens_sistema/logo.png"
REPO_PATH="/home/$USER_NAME/PDVilliConfig"

# Cores para feedback
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
NC='\033[0m'

clear
echo -e "${AMARELO}############################################################${NC}"
echo -e "${AMARELO}#        ILLIMITAR - SOLUÇÕES INTEGRADAS                   #${NC}"
echo -e "${AMARELO}############################################################${NC}"
echo -e "${VERDE}Iniciando configuração do terminal...${NC}"
sleep 1

# Detecta a interface gráfica atual
DESKTOP_ENV=$(sudo -u $USER_NAME echo $XDG_CURRENT_DESKTOP | tr '[:upper:]' '[:lower:]')
echo -e "${AMARELO}>>> Ambiente detectado: $DESKTOP_ENV${NC}"

############################################
# ATUALIZAÇÃO DE REPOSITÓRIOS
############################################
echo -e "\n${AMARELO}>>> Atualizando base de pacotes...${NC}"
sudo apt update

############################################
# CONFIGURAR ENERGIA E TELA (MULTI-AMBIENTE)
############################################
echo -e "\n${AMARELO}>>> Configurando gerenciamento de energia e tela...${NC}"

case "$DESKTOP_ENV" in
    *"cinnamon"*)
        sudo -u $USER_NAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
        bash -c '
            gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-ac 0
            gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-battery 0
            gsettings set org.cinnamon.desktop.session idle-delay 0
            gsettings set org.cinnamon.desktop.screensaver lock-enabled false
            gsettings set org.cinnamon.settings-daemon.plugins.power lock-on-suspend false
        '
        ;;
    *"mate"*)
        sudo -u $USER_NAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
        bash -c '
            gsettings set org.mate.power-manager sleep-display-ac 0
            gsettings set org.mate.screensaver idle-activation-enabled false
            gsettings set org.mate.screensaver lock-enabled false
        '
        ;;
    *"xfce"*)
        sudo -u $USER_NAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
        bash -c '
            xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0
            xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-sleep -s 0
            xfconf-query -c xfce4-screensaver -p /saver/enabled -s false
        '
        ;;
    *)
        echo -e "${VERMELHO}Ambiente desconhecido. Configurações de energia ignoradas.${NC}"
        ;;
esac
echo "Configuração de energia finalizada."

############################################
# GRUPOS E PERMISSÕES USB (UDEV)
############################################
echo -e "\n${AMARELO}>>> Aplicando permissões de usuários e hardware...${NC}"
for grupo in lp tty dialout; do
    sudo usermod -aG $grupo $USER_NAME
done

echo 'KERNEL=="lp*", MODE="0777"' | sudo tee /etc/udev/rules.d/99-printer.rules > /dev/null
echo 'KERNEL=="ttyS*", MODE="0777"' | sudo tee /etc/udev/rules.d/99-serial-s.rules > /dev/null
echo 'KERNEL=="ttyACM*", MODE="0777"' | sudo tee /etc/udev/rules.d/99-serial-acm.rules > /dev/null
sudo udevadm control --reload-rules && sudo udevadm trigger

sudo chmod -Rf 777 /dev/usb/lp* 2>/dev/null
sudo chmod -Rf 777 /dev/ttyS* 2>/dev/null
sudo chmod -Rf 777 /dev/ttyACM* 2>/dev/null
echo "Permissões de hardware aplicadas."

############################################
# ANYDESK
############################################
echo -e "\n${AMARELO}>>> Configurando Anydesk para suporte remoto...${NC}"
sudo apt remove anydesk -y 2>/dev/null
sudo apt install anydesk -y
sudo systemctl enable anydesk
sudo systemctl start anydesk 
echo "full@time15" | sudo anydesk --set-password
echo "Anydesk configurado."

############################################
# FERRAMENTAS DE REDE E UTILITÁRIOS
############################################
echo -e "\n${AMARELO}>>> Instalando ferramentas de suporte (Net-tools, SSH, JQ)...${NC}"
sudo apt install net-tools ssh jq -y
echo "Instalação de ferramentas finalizada."

############################################
# IDENTIDADE VISUAL ILLIMITAR (MULTI-AMBIENTE)
############################################
echo -e "\n${AMARELO}>>> Aplicando identidade visual ILLIMITAR...${NC}"
mkdir -p /home/$USER_NAME/imagens_sistema

# Copiando ambas as imagens
cp $REPO_PATH/capa.png /home/$USER_NAME/imagens_sistema/ 2>/dev/null
cp $REPO_PATH/logo.png /home/$USER_NAME/imagens_sistema/ 2>/dev/null
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/imagens_sistema

case "$DESKTOP_ENV" in
    *"cinnamon"*)
        # Aplica a CAPA como fundo
        sudo -u $USER_NAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
        gsettings set org.cinnamon.desktop.background picture-uri "file://$CAPA_PATH"
        
        # Aplica a LOGO no ícone do Menu
        MENU_JSON="/home/$USER_NAME/.config/cinnamon/spices/menu@cinnamon.org/0.json"
        if [ -f "$MENU_JSON" ]; then
            sudo -u $USER_NAME sed -i 's|"value": "linuxmint-logo-ring-symbolic"|"value": "'$LOGO_PATH'"|' "$MENU_JSON"
        fi
        ;;
    *"mate"*)
        # Aplica a CAPA como fundo
        sudo -u $USER_NAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
        gsettings set org.mate.background picture-filename "$CAPA_PATH"
        ;;
    *"xfce"*)
        # Aplica a CAPA como fundo
        sudo -u $USER_NAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
        bash -c '
            for prop in $(xfconf-query -c xfce4-desktop -p /backdrop -l | grep last-image); do
                xfconf-query -c xfce4-desktop -p "$prop" -s "'$CAPA_PATH'"
            done
        '
        ;;
esac
echo "Capa e Logo configuradas para $DESKTOP_ENV."

############################################
# INSTALAÇÃO PDV 
############################################
echo -e "\n${VERDE}>>> Iniciando Instalador PDV ILLIMITAR...${NC}"
sleep 1
if [ -f "./attPDV.sh" ]; then
    sudo ./attPDV.sh
else
    echo -e "${VERMELHO}Erro: attPDV.sh não encontrado!${NC}"
fi

echo -e "\n${VERDE}==========================================${NC}"
echo -e "${VERDE}       CONFIGURAÇÃO ILLIMITAR CONCLUÍDA!  ${NC}"
echo -e "${VERDE}==========================================${NC}"
