#!/usr/bin/env bash

# Script to generate Ansible role documentation
# Usage: ./scripts/generate-ansible-docs.sh

set -euo pipefail

echo "📚 Generating Ansible role documentation..."

# Create docs directory if it doesn't exist
mkdir -p docs/ansible

# Generate documentation for each role
for role in ansible/roles/*; do
  if [ -d "$role" ]; then
    role_name=$(basename "$role")
    echo "📝 Processing role: $role_name"
    
    # Create role documentation file
    doc_file="docs/ansible/role-${role_name}.md"
    
    # Start documentation
    echo "# Ansible Role: $role_name" > "$doc_file"
    echo "" >> "$doc_file"
    
    # Add description if available
    if [ -f "$role/README.md" ]; then
      echo "## Description" >> "$doc_file"
      echo "" >> "$doc_file"
      cat "$role/README.md" >> "$doc_file"
      echo "" >> "$doc_file"
    fi
    
    # Add metadata
    if [ -f "$role/meta/main.yml" ]; then
      echo "## Metadata" >> "$doc_file"
      echo "" >> "$doc_file"
      echo "\`\`\`yaml" >> "$doc_file"
      cat "$role/meta/main.yml" >> "$doc_file"
      echo "\`\`\`" >> "$doc_file"
      echo "" >> "$doc_file"
    fi
    
    # Add tasks
    if [ -f "$role/tasks/main.yml" ]; then
      echo "## Tasks" >> "$doc_file"
      echo "" >> "$doc_file"
      echo "\`\`\`yaml" >> "$doc_file"
      cat "$role/tasks/main.yml" >> "$doc_file"
      echo "\`\`\`" >> "$doc_file"
      echo "" >> "$doc_file"
    fi
    
    # Add handlers
    if [ -f "$role/handlers/main.yml" ]; then
      echo "## Handlers" >> "$doc_file"
      echo "" >> "$doc_file"
      echo "\`\`\`yaml" >> "$doc_file"
      cat "$role/handlers/main.yml" >> "$doc_file"
      echo "\`\`\`" >> "$doc_file"
      echo "" >> "$doc_file"
    fi
    
    # Add usage
    echo "## Usage" >> "$doc_file"
    echo "" >> "$doc_file"
    echo "\`\`\`yaml" >> "$doc_file"
    echo "- hosts: all" >> "$doc_file"
    echo "  roles:" >> "$doc_file"
    echo "    - $role_name" >> "$doc_file"
    echo "\`\`\`" >> "$doc_file"
    echo "" >> "$doc_file"
    
    echo "✅ Generated documentation for $role_name: $doc_file"
  fi
done

echo "📚 Ansible role documentation generated successfully!"
echo "📁 Documentation available in: docs/ansible/"