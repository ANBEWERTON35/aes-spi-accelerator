cat << 'EOF' > "preparação synopsys"

#!/bin/bash
set -e

echo "=== [0/3] Carregando ambiente Synopsys ==="
source /Tools/synopsys-scripts/snps.sh

if [ "$1" == "syn" ]; then
    echo "=== Carregando PDK SAED32 ==="
    source /Tools/synopsys-scripts/load_saed32.sh
fi

make clean && make "$@"
EOF

chmod +x "preparação synopsys"