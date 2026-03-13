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
REPO_PATH="/home/$USER_NAME/.PDVilliConfig"

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
# ANYDESK (CORREÇÃO PARA NÃO QUEDAR CONEXÃO)
############################################
echo -e "\n${AMARELO}>>> Verificando AnyDesk...${NC}"
# Apenas instala/atualiza se não estiver presente. Não remove para não derrubar o suporte.
sudo apt install anydesk -y 
sudo systemctl enable anydesk
# Não reiniciamos o serviço via systemctl se ele já estiver rodando para não cair a conexão
if ! systemctl is-active --quiet anydesk; then
    sudo systemctl start anydesk
fi

############################################
# FERRAMENTAS DE REDE E UTILITÁRIOS
############################################
echo -e "\n${AMARELO}>>> Instalando ferramentas de suporte...${NC}"
sudo apt install net-tools ssh jq -y

############################################
# IDENTIDADE VISUAL ILLIMITAR (CORRIGIDO)
############################################
echo -e "\n${AMARELO}>>> Aplicando identidade visual ILLIMITAR...${NC}"
mkdir -p /home/$USER_NAME/imagens_sistema
chown $USER_NAME:$USER_NAME /home/$USER_NAME/imagens_sistema

cp $REPO_PATH/capa.png $CAPA_PATH 2>/dev/null
cp $REPO_PATH/logo.png $LOGO_PATH 2>/dev/null
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/imagens_sistema
chmod 644 $CAPA_PATH $LOGO_PATH

case "$DESKTOP_ENV" in
    *"cinnamon"*)
        sudo -u $USER_NAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
        gsettings set org.cinnamon.desktop.background picture-uri "file://$CAPA_PATH"
        
        MENU_JSON="/home/$USER_NAME/.config/cinnamon/spices/menu@cinnamon.org/0.json"
        if [ -f "$MENU_JSON" ]; then
            sed -i 's|"value": ".*symbolic"|"value": "'$LOGO_PATH'"|' "$MENU_JSON"
            sed -i 's|"value": "linuxmint-logo-ring"|"value": "'$LOGO_PATH'"|' "$MENU_JSON"
            chown $USER_NAME:$USER_NAME "$MENU_JSON"
        fi
        ;;
    *"mate"*)
        sudo -u $USER_NAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
        gsettings set org.mate.background picture-filename "$CAPA_PATH"
        ;;
    *"xfce"*)
        sudo -u $USER_NAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
        bash -c '
            for prop in $(xfconf-query -c xfce4-desktop -p /backdrop -l | grep last-image); do
                xfconf-query -c xfce4-desktop -p "$prop" -s "'$CAPA_PATH'"
            done
        '
        ;;
esac

############################################
# INSTALAÇÃO PDV 
############################################
echo -e "\n${VERDE}>>> Iniciando Instalador PDV ILLIMITAR...${NC}"
if [ -f "./attPDV.sh" ]; then
    chmod +x ./attPDV.sh
    sudo ./attPDV.sh
else
    echo -e "${VERMELHO}Erro: attPDV.sh não encontrado!${NC}"
fi

############################################
# CRIAR ATALHOS NA ÁREA DE TRABALHO
############################################
echo -e "\n${AMARELO}>>> Criando atalhos...${NC}"
DT_PATH=$(sudo -u $USER_NAME xdg-user-dir DESKTOP)

# Atalho PDV
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

# Atalho AnyDesk
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

# Atalho Calculadora
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

############################################
# PERGUNTA FINAL: CONFIGURAÇÃO DE IP (PDV)
############################################
echo -e "\n${AMARELO}==========================================${NC}"
read -p "Este terminal é um PDV e precisa de IP fixo? (s/N): " IS_PDV

if [[ "$IS_PDV" =~ ^([sS])$ ]]; then
    if [ -f "$REPO_PATH/fixarIP.sh" ]; then
        chmod +x "$REPO_PATH/fixarIP.sh"
        "$REPO_PATH/fixarIP.sh"
    fi
fi

echo -e "\n${VERDE}==========================================${NC}"
echo -e "${VERDE}        CONFIGURAÇÃO ILLIMITAR CONCLUÍDA!  ${NC}"
echo -e "${VERDE}==========================================${NC}"
