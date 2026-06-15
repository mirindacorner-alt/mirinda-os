#!/bin/bash
#╔══════════════════════════════════════════════════════════════╗
#║           MIRINDA OS — Setup Script v1.0                     ║
#║  Convierte Ubuntu 24.04 en Mirinda OS                       ║
#║  General Edition / Surface 3 Edition                        ║
#║  🍊 Hecho con naranjas y código en España 🇪🇸              ║
#╚══════════════════════════════════════════════════════════════╝

set -e

VERSION="1.0.0"
EDITION="${1:-general}"  # general | surface3
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="/var/log/mirinda-os-setup.log"

# Colors
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; O='\033[0;33m'
NC='\033[0m'; BOLD='\033[1m'

banner() {
    echo -e "${O}"
    echo "  ███╗   ███╗██╗██████╗ ██╗███╗   ██╗██████╗  █████╗ "
    echo "  ████╗ ████║██║██╔══██╗██║████╗  ██║██╔══██╗██╔══██╗"
    echo "  ██╔████╔██║██║██████╔╝██║██╔██╗ ██║██║  ██║███████║"
    echo "  ██║╚██╔╝██║██║██╔══██╗██║██║╚██╗██║██║  ██║██╔══██║"
    echo "  ██║ ╚═╝ ██║██║██║  ██║██║██║ ╚████║██████╔╝██║  ██║"
    echo "  ╚═╝     ╚═╝╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}Mirinda OS v${VERSION} — ${EDITION^} Edition${NC}"
    echo -e "  ${Y}Linux español con alma de Mirinda 🍊${NC}"
    echo ""
}

log() { echo -e "${G}[✓]${NC} $1" | tee -a "$LOG"; }
warn() { echo -e "${Y}[!]${NC} $1" | tee -a "$LOG"; }
err() { echo -e "${R}[✗]${NC} $1" | tee -a "$LOG"; exit 1; }
step() { echo -e "\n${B}━━━ $1 ━━━${NC}" | tee -a "$LOG"; }

# ── Check root ──
[[ $EUID -ne 0 ]] && err "Ejecuta como root: sudo bash $0 $EDITION"

banner
echo "Iniciando instalación de Mirinda OS ${EDITION^} Edition..."
echo "Log: $LOG"
sleep 2

# ═══════════════════════════════════════
# 1. SISTEMA BASE
# ═══════════════════════════════════════
step "1/8 · Sistema Base"

apt-get update -qq
apt-get upgrade -y -qq
apt-get install -y -qq \
    curl wget git htop neofetch lm-sensors \
    python3 python3-pip python3-venv \
    build-essential net-tools \
    tesseract-ocr poppler-utils \
    zram-tools sysfsutils \
    ufw fail2ban 2>/dev/null

log "Paquetes base instalados"

# ── Surface 3 Edition: paquetes ligeros ──
if [[ "$EDITION" == "surface3" ]]; then
    apt-get install -y -qq xfce4 xfce4-goodies lightdm
    log "XFCE4 instalado (Surface 3 ligero)"
fi

# ═══════════════════════════════════════
# 2. KERNEL & RENDIMIENTO
# ═══════════════════════════════════════
step "2/8 · Optimización de Rendimiento"

# BBR congestion control
cat > /etc/sysctl.d/99-mirinda-network.conf << 'SYSCTL'
# Mirinda OS — Network Optimization
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15
SYSCTL

# Memory optimization
cat > /etc/sysctl.d/99-mirinda-memory.conf << 'SYSCTL'
# Mirinda OS — Memory Optimization
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
SYSCTL

sysctl --system -q
log "BBR + Memory optimization activados"

# CPU Governor
if [[ "$EDITION" == "general" ]]; then
    echo "performance" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
    log "CPU Governor: performance"
else
    echo "powersave" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
    log "CPU Governor: powersave (Surface 3 ahorro batería)"
fi

# ZRAM
if [[ "$EDITION" == "surface3" ]]; then
    # More aggressive ZRAM for low-RAM devices
    echo "ALGO=zstd" > /etc/default/zramswap
    echo "PERCENT=75" >> /etc/default/zramswap
    systemctl restart zramswap 2>/dev/null || true
    log "ZRAM 75% activado (Surface 3)"
else
    echo "ALGO=zstd" > /etc/default/zramswap
    echo "PERCENT=50" >> /etc/default/zramswap
    systemctl restart zramswap 2>/dev/null || true
    log "ZRAM 50% activado"
fi

# ═══════════════════════════════════════
# 3. SEGURIDAD
# ═══════════════════════════════════════
step "3/8 · Seguridad (objetivo Lynis 87+)"

# UFW Firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw --force enable
log "Firewall UFW activado"

# Fail2ban
systemctl enable fail2ban
systemctl start fail2ban
log "Fail2ban activado"

# SSH hardening
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl reload sshd 2>/dev/null || true
log "SSH hardened"

# ═══════════════════════════════════════
# 4. NODE.JS
# ═══════════════════════════════════════
step "4/8 · Node.js"

if ! command -v node &>/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt-get install -y nodejs
fi
log "Node.js $(node -v) instalado"

# ═══════════════════════════════════════
# 5. OPENCLAW
# ═══════════════════════════════════════
step "5/8 · OpenClaw (Asistente IA)"

if ! command -v openclaw &>/dev/null; then
    curl -fsSL https://openclaw.ai/install.sh | bash
    log "OpenClaw instalado"
else
    log "OpenClaw ya instalado ($(openclaw --version 2>/dev/null || echo 'ok'))"
fi

# ═══════════════════════════════════════
# 6. BRANDING
# ═══════════════════════════════════════
step "6/8 · Branding Mirinda OS"

# MOTD
cat > /etc/motd << 'MOTD'

  🍊 Mirinda OS v1.0 — Linux con alma española
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Powered by OpenClaw + DeepSeek V4 Pro
  https://mirinda-os.github.io

MOTD

# Neofetch config
mkdir -p /etc/neofetch
cat > /etc/neofetch/config.conf << 'NEO'
print_info() {
    info title
    info underline
    info "OS" distro
    info "Host" model
    info "Kernel" kernel
    info "Uptime" uptime
    info "CPU" cpu
    info "Memory" memory
    info "Disk" disk
    info "Network" local_ip
    info "AI" "OpenClaw + DeepSeek V4 Pro"
}
NEO

# OS release
cat > /etc/mirinda-release << EOF
MIRINDA_OS_VERSION="${VERSION}"
MIRINDA_OS_EDITION="${EDITION}"
MIRINDA_OS_CODENAME="Naranja"
MIRINDA_OS_BASE="Ubuntu 24.04 LTS"
MIRINDA_OS_BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
MIRINDA_OS_ORIGIN="España 🇪🇸"
EOF

log "Branding Mirinda OS aplicado"

# ═══════════════════════════════════════
# 7. SERVICIOS
# ═══════════════════════════════════════
step "7/8 · Servicios del Sistema"

# System optimizer (cron)
cat > /usr/local/bin/mirinda-optimize << 'OPT'
#!/bin/bash
# Mirinda OS — System Optimizer (runs every 5 min)
echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null
sync; echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
OPT
chmod +x /usr/local/bin/mirinda-optimize

# Health monitor
cat > /usr/local/bin/mirinda-health << 'HEALTH'
#!/bin/bash
# Mirinda OS — Health Check
echo "🍊 Mirinda OS Health Report"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CPU: $(sensors 2>/dev/null | grep 'Core 0' | awk '{print $3}' || echo 'N/A')"
echo "RAM: $(free -h | awk '/Mem/{print $3"/"$2}')"
echo "Disk: $(df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}')"
echo "Uptime: $(uptime -p)"
echo "Load: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
echo "OpenClaw: $(openclaw --version 2>/dev/null || echo 'not installed')"
cat /etc/mirinda-release 2>/dev/null
HEALTH
chmod +x /usr/local/bin/mirinda-health

# Cron
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/mirinda-optimize >/dev/null 2>&1") | sort -u | crontab -

log "Servicios del sistema configurados"

# ═══════════════════════════════════════
# 8. FINALIZACIÓN
# ═══════════════════════════════════════
step "8/8 · Finalización"

# Version file
echo "$VERSION" > /etc/mirinda-version

# Cleanup
apt-get autoremove -y -qq
apt-get clean -qq

log "Limpieza completada"

echo ""
echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${G}  ✅ Mirinda OS v${VERSION} ${EDITION^} Edition — INSTALADO${NC}"
echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Ejecuta: mirinda-health    — Ver estado del sistema"
echo "  Ejecuta: openclaw tui      — Abrir OpenClaw"
echo "  Ejecuta: neofetch          — Info del sistema"
echo ""
echo -e "  ${Y}🍊 Hecho con naranjas y código en España 🇪🇸${NC}"
echo ""
