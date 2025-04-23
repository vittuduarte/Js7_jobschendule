#!/bin/bash

# Definir cores
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Sem cor

# Função para verificar o status do último comando e imprimir o resultado com cor
check_status() {
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Pass ✅${NC}"
  else
    echo -e "${RED}Fail ❌${NC}"
  fi
}

# Parar todos os contêineres
echo -n "[Parando todos os contêineres] "
sudo docker stop $(sudo docker ps -aq) >/dev/null 2>&1
check_status

# Remover todos os contêineres
echo -n "[Removendo todos os contêineres] "
sudo docker rm $(sudo docker ps -aq) >/dev/null 2>&1
check_status

# Remover todas as imagens
echo -n "[Removendo todas as imagens] "
sudo docker rmi $(sudo docker images -q) --force >/dev/null 2>&1
check_status

# Remover todos os volumes
echo -n "[Removendo todos os volumes] "
sudo docker volume rm $(sudo docker volume ls -q) >/dev/null 2>&1
check_status

# Remover todas as redes que não estão em uso
echo -n "[Removendo todas as redes não utilizadas] "
sudo docker network prune -f >/dev/null 2>&1
check_status

# Limpeza completa concluída
echo "Docker foi limpo completamente!"
