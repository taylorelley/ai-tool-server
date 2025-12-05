#!/bin/bash

############################################################
# AI Tool Server Stack - Backup Script
############################################################
# Creates a complete backup of all data and configuration
############################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="backup-$(date +%Y%m%d-%H%M%S)"
COMPRESS=${1:-true}  # Pass 'false' as first argument to skip compression

echo -e "${BLUE}=============================================="
echo "AI Tool Server Stack - Backup"
echo -e "==============================================${NC}"
echo ""

# Check if docker compose is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Error: docker not found${NC}"
    exit 1
fi

echo "Creating backup in: $BACKUP_DIR"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}Step 1: Stopping services...${NC}"
docker compose down

echo -e "${GREEN}✓${NC} Services stopped"
echo ""

echo -e "${BLUE}Step 2: Backing up volumes...${NC}"
if [ -d "volumes" ]; then
    cp -r volumes "$BACKUP_DIR/"
    echo -e "${GREEN}✓${NC} Volumes backed up"
else
    echo -e "${YELLOW}⚠${NC}  No volumes directory found"
fi
echo ""

echo -e "${BLUE}Step 3: Backing up configuration...${NC}"
if [ -f ".env" ]; then
    cp .env "$BACKUP_DIR/"
    echo -e "${GREEN}✓${NC} .env backed up"
else
    echo -e "${YELLOW}⚠${NC}  No .env file found"
fi

cp docker-compose.yaml "$BACKUP_DIR/"
echo -e "${GREEN}✓${NC} docker-compose.yaml backed up"

if [ -f "docker-compose.override.yml" ]; then
    cp docker-compose.override.yml "$BACKUP_DIR/"
    echo -e "${GREEN}✓${NC} docker-compose.override.yml backed up"
fi
echo ""

# Create backup metadata
cat > "$BACKUP_DIR/backup-info.txt" << EOF
Backup created: $(date)
Hostname: $(hostname)
User: $(whoami)
EOF

echo -e "${GREEN}✓${NC} Backup metadata created"
echo ""

# Compress backup if requested
if [ "$COMPRESS" = "true" ]; then
    echo -e "${BLUE}Step 4: Compressing backup...${NC}"
    tar -czf "${BACKUP_DIR}.tar.gz" "$BACKUP_DIR"
    rm -rf "$BACKUP_DIR"
    echo -e "${GREEN}✓${NC} Backup compressed: ${BACKUP_DIR}.tar.gz"
    FINAL_BACKUP="${BACKUP_DIR}.tar.gz"
else
    FINAL_BACKUP="$BACKUP_DIR"
fi
echo ""

echo -e "${BLUE}Step 5: Restarting services...${NC}"
docker compose up -d
echo -e "${GREEN}✓${NC} Services restarted"
echo ""

# Calculate backup size
if [ -f "${BACKUP_DIR}.tar.gz" ]; then
    SIZE=$(du -h "${BACKUP_DIR}.tar.gz" | cut -f1)
else
    SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
fi

echo -e "${GREEN}=============================================="
echo "✓ Backup completed successfully!"
echo -e "==============================================${NC}"
echo ""
echo "Backup location: $FINAL_BACKUP"
echo "Backup size: $SIZE"
echo ""
echo "To restore from this backup, run:"
echo "  ./scripts/restore.sh $FINAL_BACKUP"
echo ""
