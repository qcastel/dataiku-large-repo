#!/bin/bash

set -e


echo "Creating fileA.csv (99mb)"
dd if=/dev/urandom of=fileA.csv bs=1M count=99

echo "Creating fileB.bin (99mb)"
dd if=/dev/urandom of=fileB.bin bs=1M count=99

echo "Creating fileC.toto (99mb)"
dd if=/dev/urandom of=fileC.toto bs=1M count=99

echo "Creating fileD.csv (99mb)"
dd if=/dev/urandom of=fileD.csv bs=1M count=99

echo "Creating fileE.csv (99mb)"
dd if=/dev/urandom of=fileE.csv bs=1M count=99

git add .
git commit -m "Add large files with specific sizes"
