#!/usr/bin/env bash
# Instalador del kit para Google Antigravity (Mac / Linux / Git Bash)
# Uso: bash instalar.sh            (agrega --legacy para copiar tambien a ~/.gemini/antigravity/skills)
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
SRC="$KIT/gemini"; G="$HOME/.gemini"; C="$G/config"; F="$(date +%Y-%m-%d-%H%M)"

read -rp "Nombre de tu marca o estudio: " MARCA
read -rp "Tu dominio (ej. miestudio.cl): " DOMINIO
read -rp "Correo de trabajo publico: " CORREO
read -rp "Usuario de git: " GITUSER

mkdir -p "$C/rules" "$C/skills" "$G/memoria"
[ -f "$G/GEMINI.md" ] && cp "$G/GEMINI.md" "$G/GEMINI.md.bak-$F" && echo "Respaldo GEMINI.md.bak-$F"
[ -n "$(ls -A "$C/rules" 2>/dev/null)" ] && cp -r "$C/rules" "$C/rules.bak-$F"

cp "$SRC/GEMINI.md" "$G/GEMINI.md"
cp -r "$SRC/config/rules/." "$C/rules/"
cp -r "$SRC/config/skills/." "$C/skills/"
if [ "${1:-}" = "--legacy" ]; then mkdir -p "$G/antigravity/skills"; cp -r "$SRC/config/skills/." "$G/antigravity/skills/"; fi
[ -f "$G/memoria/leads.md" ] || printf '# Leads y clientes\n\n| Fecha | Lead | Que pidio | Estado | Proximo seguimiento |\n|---|---|---|---|---|\n' > "$G/memoria/leads.md"

FILES=("$G/GEMINI.md" "$C"/rules/*.md "$C/skills/guardar-estado/SKILL.md" "$C/skills/propuesta-visual/SKILL.md" "$C/skills/cerebro/SKILL.md")
rep() { [ -n "$2" ] || return 0; for f in "${FILES[@]}"; do DE="$1" A="$2" perl -pi -e 's/\Q$ENV{DE}\E/$ENV{A}/g' "$f"; done; }
rep '<contacto@tu-dominio.com>' "$CORREO"
rep '<tu-dominio.com>' "$DOMINIO"
rep '<TU_MARCA>' "$MARCA"
rep '<tu-marca>' "$GITUSER"
echo "Listo: $(ls -d "$C"/skills/*/ | wc -l) skills. Reinicia Antigravity y lee README.md."
