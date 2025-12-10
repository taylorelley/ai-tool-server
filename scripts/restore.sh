#!/bin/bash

############################################################
# AI Tool Server Stack - Restore Script
############################################################
# Restores data and configuration from a backup
############################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=============================================="
echo "AI Tool Server Stack - Restore"
echo -e "==============================================${NC}"
echo ""

# Check if docker compose is available
if ! docker compose version &> /dev/null; then
    echo -e "${RED}✗ Error: 'docker compose' command not found${NC}"
    echo ""
    echo "Please ensure Docker Compose is installed and available."
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

# Check if backup path provided
if [ -z "$1" ]; then
    echo -e "${RED}✗ Error: No backup path provided${NC}"
    echo ""
    echo "Usage: $0 <backup-path>"
    echo ""
    echo "Examples:"
    echo "  $0 backup-20240101-120000.tar.gz"
    echo "  $0 backup-20240101-120000"
    exit 1
fi

BACKUP_PATH=$1

# Check if backup exists
if [ ! -e "$BACKUP_PATH" ]; then
    echo -e "${RED}✗ Error: Backup not found: $BACKUP_PATH${NC}"
    exit 1
fi

# Warn user about data loss
echo -e "${YELLOW}⚠  WARNING: This will replace all current data!${NC}"
echo ""
echo "Current data will be backed up to: volumes.backup-$(date +%Y%m%d-%H%M%S)"
echo ""
read -p "Are you sure you want to continue? (yes/NO): " -r
echo ""

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Restore cancelled."
    exit 0
fi

echo -e "${BLUE}Step 1: Stopping services...${NC}"
docker compose down
echo -e "${GREEN}✓${NC} Services stopped"
echo ""

echo -e "${BLUE}Step 2: Backing up current data...${NC}"
if [ -d "volumes" ]; then
    BACKUP_CURRENT="volumes.backup-$(date +%Y%m%d-%H%M%S)"
    mv volumes "$BACKUP_CURRENT"
    echo -e "${GREEN}✓${NC} Current volumes backed up to: $BACKUP_CURRENT"
else
    echo -e "${YELLOW}⚠${NC}  No existing volumes directory"
fi

if [ -f ".env" ]; then
    cp .env ".env.backup-$(date +%Y%m%d-%H%M%S)"
    echo -e "${GREEN}✓${NC} Current .env backed up"
fi
echo ""

# Extract or copy backup
TEMP_DIR=""
if [[ "$BACKUP_PATH" == *.tar.gz ]]; then
    echo -e "${BLUE}Step 3: Extracting backup...${NC}"
    TEMP_DIR="temp-restore-$(date +%s)"
    mkdir -p "$TEMP_DIR"
    tar -xzf "$BACKUP_PATH" -C "$TEMP_DIR"
    # Find the backup directory inside
    BACKUP_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "backup-*" | head -1)
    if [ -z "$BACKUP_DIR" ]; then
        BACKUP_DIR="$TEMP_DIR/$(basename "$BACKUP_PATH" .tar.gz)"
    fi
    echo -e "${GREEN}✓${NC} Backup extracted"
else
    BACKUP_DIR="$BACKUP_PATH"
    echo -e "${BLUE}Step 3: Using uncompressed backup${NC}"
    echo -e "${GREEN}✓${NC} Backup ready"
fi
echo ""

echo -e "${BLUE}Step 4: Restoring volumes...${NC}"
if [ -d "$BACKUP_DIR/volumes" ]; then
    cp -r "$BACKUP_DIR/volumes" .
    echo -e "${GREEN}✓${NC} Volumes restored"
else
    echo -e "${RED}✗ Error: No volumes directory in backup${NC}"
    # Cleanup
    [ -n "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
    exit 1
fi
echo ""

echo -e "${BLUE}Step 5: Restoring configuration...${NC}"
if [ -f "$BACKUP_DIR/.env" ]; then
    cp "$BACKUP_DIR/.env" .
    echo -e "${GREEN}✓${NC} .env restored"
fi

if [ -f "$BACKUP_DIR/docker-compose.yaml" ]; then
    # Only restore if user confirms
    echo -e "${YELLOW}⚠${NC}  Found docker-compose.yaml in backup"
    read -p "Restore docker-compose.yaml? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "$BACKUP_DIR/docker-compose.yaml" .
        echo -e "${GREEN}✓${NC} docker-compose.yaml restored"
    fi
fi

if [ -f "$BACKUP_DIR/docker-compose.override.yml" ]; then
    cp "$BACKUP_DIR/docker-compose.override.yml" .
    echo -e "${GREEN}✓${NC} docker-compose.override.yml restored"
fi
echo ""

# Show backup info if available
if [ -f "$BACKUP_DIR/backup-info.txt" ]; then
    echo -e "${BLUE}Backup Information:${NC}"
    cat "$BACKUP_DIR/backup-info.txt"
    echo ""
fi

echo -e "${BLUE}Step 6: Starting services...${NC}"
docker compose up -d
echo -e "${GREEN}✓${NC} Services started"
echo ""

# Cleanup temporary directory
if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi

echo -e "${GREEN}=============================================="
echo "✓ Restore completed successfully!"
echo -e "==============================================${NC}"
echo ""
echo "Services are starting. Check status with:"
echo "  docker compose ps"
echo "  docker compose logs -f"
echo ""
