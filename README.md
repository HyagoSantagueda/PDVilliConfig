# 🚀 ILLIMITAR - PDVilliConfig (v1.1)

> **Padronização e Automação para Terminais PDV em Linux Mint.**

O **PDVilliConfig** é uma solução de automação comercial desenvolvida pela **ILLIMITAR Soluções Integradas**. Este projeto foi criado para eliminar erros humanos e reduzir o tempo de implantação de novos terminais PDV, garantindo que cada máquina saia de fábrica com 100% de compatibilidade e performance.

---

## 🛠️ Recursos Principais

* **🔧 Gestão de Hardware (UDEV):** Configuração automática de permissões para impressoras térmicas (USB/LP), balanças e leitores de código de barras (TTY/ACM).
* **🔋 Performance e Energia:** Bloqueio total de suspensão de tela e hibernação, otimizado para as interfaces **Cinnamon, MATE e XFCE**.
* **🎨 Branding ILLIMITAR:** Aplicação automatizada de Identidade Visual, incluindo Wallpaper (capa) e ícone customizado no Menu Iniciar.
* **📡 Suporte Integrado:** Instalação do AnyDesk com inicialização automática e service mode ativo.
* **📦 Gestão de Software:** Módulo de atualização inteligente que gerencia versões estáveis e beta via GitHub API.
* **🌐 Rede Inteligente:** Script de fixação de IPv4 estático com lógica baseada no número do PDV (Cálculo: 200 + ID).
* **🖥️ Desktop Profissional:** Geração de atalhos confiáveis na Área de Trabalho com ícones oficiais e permissões validadas.

---

## 🚀 Como Utilizar (Instalação Rápida)

Para realizar a implantação completa em um terminal recém-formatado, abra o terminal do Linux Mint e execute o comando abaixo:

```bash
REAL_USER="user" && REAL_HOME="/home/$REAL_USER" && \
sudo apt update && sudo apt install git -y && \
sudo -u $REAL_USER rm -rf $REAL_HOME/.PDVilliConfig && \
sudo -u $REAL_USER git clone https://github.com/HyagoSantagueda/PDVilliConfig $REAL_HOME/.PDVilliConfig && \
cd $REAL_HOME/.PDVilliConfig && \
chmod +x *.sh && \
sudo ./configuracao_inicial.sh
```

------------------------------------------------------------
ESTRUTURA DO ECOSSISTEMA:
------------------------------------------------------------

1. configuracao_inicial.sh: Script Mestre. Coordena o setup visual.
2. attPDV.sh: Gerenciador de Versões. Faz download e instalação.
3. fixarIP.sh: Módulo de Rede. Configura IP Estático e DNS.
4. capa.png / logo.png: Ativos visuais de personalização.

------------------------------------------------------------
REQUISITOS E COMPATIBILIDADE:
------------------------------------------------------------

* Sistema Operacional: Linux Mint (Versões 20, 21 e 22).
* Ambientes: Cinnamon, MATE e XFCE.
* Usuário Requerido: user.

------------------------------------------------------------
AUTORIA E DESENVOLVIMENTO:
------------------------------------------------------------

* Hyago Santagueda - Desenvolvedor
* João Victor Moraes - Desenvolvedor

ILLIMITAR - Soluções Integradas © 2026 
Todos os direitos reservados.
============================================================
