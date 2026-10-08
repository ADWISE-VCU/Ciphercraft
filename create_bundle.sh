#!/bin/bash
set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

VERSION="$1"
BASE="io/github/andrewquijano/ciphercraft/$VERSION"

# Clean previous staging artifacts
rm -rf "$BASE"
rm -f bundle.zip
mkdir -p "$BASE"

# Expected artifacts
JAR="build/libs/ciphercraft-$VERSION.jar"
JAVADOC="build/libs/ciphercraft-$VERSION-javadoc.jar"
SOURCES="build/libs/ciphercraft-$VERSION-sources.jar"
POM="build/publications/mavenJava/pom-default.xml"

# Expected signatures
JAR_SIG="$JAR.asc"
JAVADOC_SIG="$JAVADOC.asc"
SOURCES_SIG="$SOURCES.asc"
POM_SIG="$POM.asc"

# Verify all artifacts and signatures exist
echo "Validating Maven Central artifacts..."

for file in \
    "$JAR" \
    "$JAVADOC" \
    "$SOURCES" \
    "$POM" \
    "$JAR_SIG" \
    "$JAVADOC_SIG" \
    "$SOURCES_SIG" \
    "$POM_SIG"; do

    if [ ! -f "$file" ]; then
        echo "ERROR: Expected artifact or signature does not exist: $file"
        echo "Check Gradle signing and the VERSION variable."
        exit 1
    fi

    echo "Found: $file"
done

# Copy JARs and their signatures
for file in "$JAR" "$JAVADOC" "$SOURCES"; do
    cp "$file" "$BASE/"
    cp "${file}.asc" "$BASE/"
done

# Copy POM and its signature
cp "$POM" "$BASE/ciphercraft-$VERSION.pom"
cp "$POM_SIG" "$BASE/ciphercraft-$VERSION.pom.asc"

# Generate checksums for artifacts (not signatures)
for file in "$BASE"/*; do
    echo "Processing file: $file"

    if [[ -f "$file" && ! "$file" =~ \.asc$ ]]; then
        echo "Generating hashes for: $file"
        sha1sum "$file" | awk '{print $1}' > "${file}.sha1"
        md5sum "$file" | awk '{print $1}' > "${file}.md5"
    else
        echo "Skipping signature file: $file"
    fi
done

# Verify that all four signatures were copied
echo "Verifying packaged signatures..."

SIGNATURE_COUNT=$(find "$BASE" -maxdepth 1 -type f -name '*.asc' | wc -l)

if [ "$SIGNATURE_COUNT" -ne 4 ]; then
    echo "ERROR: Expected 4 signatures, found $SIGNATURE_COUNT"
    exit 1
fi

echo "All 4 GPG signatures are present."

# Create Maven Central deployment bundle
zip -r bundle.zip io

echo ""
echo "Maven Central bundle created successfully: bundle.zip"
