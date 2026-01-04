#!/bin/bash
# TERMINAL HEIST - GitHub Labels Creation Script
# Run this BEFORE create_issues.sh to set up required labels
# Usage: ./create_labels.sh

set -e

REPO="SapphireBeehiveStudios/godot-example"

echo "Creating labels for $REPO..."

# Create labels (will fail silently if they already exist)
gh label create "epic" --description "Epic/milestone issue" --color "7057ff" --repo "$REPO" 2>/dev/null || echo "Label 'epic' already exists"
gh label create "P0" --description "Priority 0 - Must have for MVP" --color "d73a4a" --repo "$REPO" 2>/dev/null || echo "Label 'P0' already exists"
gh label create "P1" --description "Priority 1 - Should have" --color "fbca04" --repo "$REPO" 2>/dev/null || echo "Label 'P1' already exists"

echo "Labels created successfully!"
