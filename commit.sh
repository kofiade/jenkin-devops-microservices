#!/bin/bash

# Check if a commit message was provided
if [ -z "$1" ]; then
  echo "Error: Commit message required"
  echo "Usage: ./commit.sh 'Your commit message here'"
  exit 1
fi

# Stage all changes
echo "Staging all changes..."
git add .

# Commit with the provided message
echo "Committing changes with message: '$1'"
git commit -m "$1"

# Ensure you are on the main branch
echo "Switching to the main branch..."
git checkout main

# Pull latest changes to avoid conflicts
echo "Pulling the latest changes from origin/main..."
git pull origin main

# Push the committed changes to the main branch
echo "Pushing changes to origin/main..."
git push origin main

echo "Commit and push successful!"
