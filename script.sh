#!/bin/zsh

# Colors used: https://gist.github.com/JBlond/2fea43a3049b38287e5e9cefc87b2124
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project directories
MINIO_API_DIR="minio-api"
MINIO_UI_DIR="minio-ui"
NETWORK_NAME="minio_demo_network"

echo "${BLUE}======================================${NC}"
echo "${BLUE}  MinIO Demo - Startup Script${NC}"
echo "${BLUE}======================================${NC}\n"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "${RED}Error: Docker no está corriendo${NC}"
  echo "${YELLOW}Por favor inicia Docker Desktop y vuelve a intentar${NC}"
  exit 1
fi

# Create Docker network if it doesn't exist
echo "${BLUE}Verificando red Docker...${NC}"
if docker network inspect $NETWORK_NAME > /dev/null 2>&1; then
  echo "${GREEN}✓ Red '$NETWORK_NAME' ya existe${NC}"
else
  echo "${YELLOW}Creando red '$NETWORK_NAME'...${NC}"
  if docker network create $NETWORK_NAME > /dev/null 2>&1; then
    echo "${GREEN}✓ Red '$NETWORK_NAME' creada exitosamente${NC}"
  else
    echo "${RED}Error al crear la red Docker${NC}"
    exit 1
  fi
fi

# Build and start MinIO backend
echo "\n${BLUE}🚀 Iniciando Backend (MinIO + Spring Boot)...${NC}"
cd $MINIO_API_DIR || exit 1

if make recreate; then
  echo "${GREEN}✓ Backend iniciado correctamente${NC}"
else
  echo "${RED}Error al iniciar el backend${NC}"
  exit 1
fi

cd ..

# Build and start Frontend
echo "\n${BLUE}🚀 Iniciando Frontend (Angular + Nginx)...${NC}"
cd $MINIO_UI_DIR || exit 1

if make recreate; then
  echo "${GREEN}✓ Frontend iniciado correctamente${NC}"
else
  echo "${RED}Error al iniciar el frontend${NC}"
  cd ..
  exit 1
fi

cd ..

# Wait a moment for services to be ready
echo "\n${YELLOW}Esperando que los servicios estén listos...${NC}"
sleep 5

# Check if services are running
echo "\n${BLUE}Verificando estado de servicios...${NC}"
BACKEND_RUNNING=$(docker ps --filter "name=minio-backend" --format "{{.Names}}" 2>/dev/null)
FRONTEND_RUNNING=$(docker ps --filter "name=minio-frontend" --format "{{.Names}}" 2>/dev/null)
MINIO_RUNNING=$(docker ps --filter "name=minio" --format "{{.Names}}" 2>/dev/null | grep "^minio$")

if [[ -n "$BACKEND_RUNNING" && -n "$FRONTEND_RUNNING" && -n "$MINIO_RUNNING" ]]; then
  echo "${GREEN}✓ Todos los servicios están corriendo${NC}\n"
  
  echo "${GREEN}======================================${NC}"
  echo "${GREEN}  Sistema listo para usar!${NC}"
  echo "${GREEN}======================================${NC}\n"
  
  echo "${BLUE}URLs de acceso:${NC}"
  echo "  ${GREEN}Frontend:${NC}        http://localhost"
  echo "  ${GREEN}Backend API:${NC}     http://localhost:8089"
  echo "  ${GREEN}MinIO Console:${NC}   http://localhost:9101"
  echo "    ${YELLOW}Usuario:${NC}       minioadmin"
  echo "    ${YELLOW}Contraseña:${NC}    minioadmin\n"
  
  echo "${BLUE}Comandos útiles:${NC}"
  echo "  Ver logs backend:   ${YELLOW}docker logs -f minio-backend${NC}"
  echo "  Ver logs frontend:  ${YELLOW}docker logs -f minio-frontend${NC}"
  echo "  Ver logs MinIO:     ${YELLOW}docker logs -f minio${NC}"
  echo "  Detener todo:       ${YELLOW}docker-compose down${NC} (en cada directorio)\n"
else
  echo "${RED}Algunos servicios no iniciaron correctamente${NC}"
  echo "${YELLOW}Verifica los logs con: docker-compose logs${NC}"
  exit 1
fi
