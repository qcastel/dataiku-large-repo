#!/bin/bash

set -e

REPO=big-repo

mkdir "$REPO"
cd "$REPO"

git init

echo "Creating fileA.csv (1GB)"
dd if=/dev/urandom of=fileA.csv bs=1M count=1024

echo "Creating fileB.bin (500MB)"
dd if=/dev/urandom of=fileB.bin bs=1M count=500

echo "Creating fileC.toto (2GB)"
dd if=/dev/urandom of=fileC.toto bs=1M count=2048

echo "Creating fileD.csv (1GB)"
dd if=/dev/urandom of=fileD.csv bs=1M count=1024

echo "Creating fileE.csv (1.5GB)"
dd if=/dev/urandom of=fileE.csv bs=1M count=1536

git add .
git commit -m "Add large files with specific sizes"
