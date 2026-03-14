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
REPO_PATH="/home/$USER_NAME/.PDVilliConfig"
CAPA_PATH="$REPO_PATH/capa.png"
LOGO_PATH="$REPO_PATH/logo.png"

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
esac

############################################
# GRUPOS E PERMISSÕES USB (UDEV)
############################################
echo -e "\n${AMARELO}>>> Aplicando permissões de hardware...${NC}"
for grupo in lp tty dialout; do
    sudo usermod -aG $grupo $USER_NAME
done

echo 'KERNEL=="lp*", MODE="0777"' | sudo tee /etc/udev/rules.d/99-printer.rules > /dev/null
echo 'KERNEL=="ttyS*", MODE="0777"' | sudo tee /etc/udev/rules.d/99-serial-s.rules > /dev/null
echo 'KERNEL=="ttyACM*", MODE="0777"' | sudo tee /etc/udev/rules.d/99-serial-acm.rules > /dev/null
sudo udevadm control --reload-rules && sudo udevadm trigger

############################################
# ANYDESK (MANTÉM CONEXÃO ATIVA)
############################################
echo -e "\n${AMARELO}>>> Verificando AnyDesk...${NC}"
sudo apt install anydesk -y 
sudo systemctl enable anydesk
if ! systemctl is-active --quiet anydesk; then
    sudo systemctl start anydesk
fi

############################################
# FERRAMENTAS DE REDE E UTILITÁRIOS
############################################
echo -e "\n${AMARELO}>>> Instalando ferramentas de suporte...${NC}"
sudo apt install net-tools ssh jq -y

############################################
# IDENTIDADE VISUAL ILLIMITAR (REVISADO)
############################################
echo -e "\n${AMARELO}>>> Aplicando identidade visual ILLIMITAR...${NC}"

chown -R $USER_NAME:$USER_NAME $REPO_PATH
chmod -R 755 $REPO_PATH

case "$DESKTOP_ENV" in
    *"cinnamon"*)
        # Aplica Wallpaper
        sudo -u $USER_NAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
        gsettings set org.cinnamon.desktop.background picture-uri "file://$CAPA_PATH"
        
        MENU_JSON="/home/$USER_NAME/.config/cinnamon/spices/menu@cinnamon.org/0.json"
        if [ -f "$MENU_JSON" ]; then
            echo "Ajustando Menu Cinnamon..."
            # 1. Primeiro Desabilita a customização (Reset)
            sudo -u $USER_NAME sed -i 's|"use-custom-label": { "type": "checkbox", "value": true }|"use-custom-label": { "type": "checkbox", "value": false }|' "$MENU_JSON"
            
            # 2. Injeta os novos valores (Logo e Texto)
            sudo -u $USER_NAME sed -i 's|"custom-icon": { "type": "icon-chooser", "value": ".*" }|"custom-icon": { "type": "icon-chooser", "value": "'$LOGO_PATH'" }|' "$MENU_JSON"
            sudo -u $USER_NAME sed -i 's|"custom-label": { "type": "entry", "value": ".*" }|"custom-label": { "type": "entry", "value": "ILLIMITAR" }|' "$MENU_JSON"
            
            # 3. Habilita novamente para forçar o sistema a ler o novo ícone
            sudo -u $USER_NAME sed -i 's|"use-custom-label": { "type": "checkbox", "value": false }|"use-custom-label": { "type": "checkbox", "value": true }|' "$MENU_JSON"
            
            # 4. Reinicia o Cinnamon em background para aplicar visualmente
            sudo -u $USER_NAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
            cinnamon --replace > /dev/null 2>&1 &
            sleep 2
        fi
        ;;
    *"mate"*)
        sudo -u $USER_NAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
        gsettings set org.mate.background picture-filename "$CAPA_PATH"
        ;;
    *"xfce"*)
        sudo -u $USER_NAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
        bash -c 'for prop in $(xfconf-query -c xfce4-desktop -p /backdrop -l | grep last-image); do xfconf-query -c xfce4-desktop -p "$prop" -s "'$CAPA_PATH'"; done'
        ;;
esac

############################################
# INSTALAÇÃO PDV (CAMINHO REVISADO)
############################################
echo -e "\n${AMARELO}==========================================${NC}"
read -p "Deseja iniciar a instalação do Navegador PDV agora? (s/N): " INSTALL_NAV

if [[ "$INSTALL_NAV" =~ ^([sS])$ ]]; then
    echo -e "\n${VERDE}>>> Iniciando Instalador PDV ILLIMITAR...${NC}"
    # Verificamos no diretório atual (.) e também no REPO_PATH por segurança
    if [ -f "./attPDV.sh" ]; then
        chmod +x ./attPDV.sh
        sudo ./attPDV.sh
    elif [ -f "$REPO_PATH/attPDV.sh" ]; then
        chmod +x "$REPO_PATH/attPDV.sh"
        sudo "$REPO_PATH/attPDV.sh"
    else
        echo -e "${VERMELHO}Erro: attPDV.sh não encontrado no diretório atual nem em $REPO_PATH!${NC}"
    fi
else
    echo -e "${AMARELO}>>> Instalação do Navegador PDV pulada.${NC}"
fi

############################################
# PERGUNTA FINAL: CONFIGURAÇÃO DE IP (PDV)
############################################
echo -e "\n${AMARELO}==========================================${NC}"
read -p "Este terminal é um PDV e precisa de IP fixo? (s/N): " IS_PDV

if [[ "$IS_PDV" =~ ^([sS])$ ]]; then
    if [ -f "$REPO_PATH/fixarIP.sh" ]; then
        chmod +x "$REPO_PATH/fixarIP.sh"
        "$REPO_PATH/fixarIP.sh"
    else
        echo -e "${VERMELHO}Erro: Script fixarIP.sh não encontrado em $REPO_PATH!${NC}"
    fi
fi

############################################
# CRIAR ATALHOS NA ÁREA DE TRABALHO
############################################
echo -e "\n${AMARELO}>>> Criando atalhos na Área de Trabalho...${NC}"
DT_PATH=$(sudo -u $USER_NAME xdg-user-dir DESKTOP)

cat <<EOF > "$DT_PATH/pdv.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Navegador PDV
Comment=Sistema PDV ILLIMITAR
Exec=/opt/pdv/pdv
Icon=/opt/pdv/icon.png
Terminal=false
Categories=Office;
EOF

cat <<EOF > "$DT_PATH/anydesk.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=AnyDesk
Comment=Suporte Remoto ILLIMITAR
Exec=/usr/bin/anydesk
Icon=anydesk
Terminal=false
Categories=Network;RemoteAccess;
EOF

cat <<EOF > "$DT_PATH/calculadora.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Calculadora
Exec=gnome-calculator
Icon=accessories-calculator
Terminal=false
EOF

chown $USER_NAME:$USER_NAME "$DT_PATH"/*.desktop
chmod +x "$DT_PATH"/*.desktop

if [[ "$DESKTOP_ENV" == *"cinnamon"* ]]; then
    sudo -u $USER_NAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
    gio set "$DT_PATH"/*.desktop metadata::trusted true 2>/dev/null
fi

echo -e "\n${VERDE}==========================================${NC}"
echo -e "${VERDE}        CONFIGURAÇÃO ILLIMITAR CONCLUÍDA!  ${NC}"
echo -e "${VERDE}==========================================${NC}"
