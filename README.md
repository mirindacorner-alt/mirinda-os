# 🍊 Mirinda OS

**Linux español con alma de Mirinda**

Mirinda OS es una distribución Linux basada en Ubuntu 24.04 LTS, optimizada para productividad y IA, con OpenClaw + DeepSeek V4 Pro preconfigurados.

## Ediciones

| Edición | Para | Escritorio | RAM mín. |
|---------|------|-----------|----------|
| **General** | PCs y servidores | Sin GUI (servidor) | 2 GB |
| **Surface 3** | Microsoft Surface 3 | XFCE ligero | 2 GB |

## Características

- 🧠 **OpenClaw V4 Pro** preinstalado — asistente IA personal
- ⚡ **BBR + ZRAM** — red y memoria optimizados
- 🔒 **Lynis 87+** — seguridad endurecida (UFW, fail2ban, SSH)
- 🎯 **CPU performance** — máximo rendimiento (General) o ahorro batería (Surface 3)
- 🇪🇸 **100% Español** — configuración en español de España
- 📊 **mirinda-health** — monitor de salud del sistema
- 🍊 **Branding** — MOTD, neofetch personalizado

## Instalación rápida

```bash
# General Edition
sudo bash scripts/setup.sh general

# Surface 3 Edition
sudo bash scripts/setup.sh surface3
```

## Comandos

```bash
mirinda-health      # Estado del sistema
mirinda-optimize    # Optimizar rendimiento
openclaw tui        # Abrir asistente IA
neofetch            # Info del sistema
```

## Estructura

```
mirinda-os/
├── scripts/
│   └── setup.sh          # Script de instalación
├── configs/               # Configuraciones del sistema
├── branding/              # Logos, temas, fondos
├── docs/                  # Documentación
└── README.md
```

## Requisitos

- Ubuntu 24.04 LTS (base)
- 2 GB RAM mínimo (4 GB recomendado)
- 10 GB disco libre
- Conexión a internet

## Licencia

MIT — Hecho con 🍊 y código en España 🇪🇸

*Mirinda OS es mantenido por la comunidad OpenClaw en España.*
