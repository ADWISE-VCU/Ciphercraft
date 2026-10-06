#!/bin/bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

VERSION="$1"
BASE="io/github/andrewquijano/ciphercraft/$VERSION"

mkdir -p "$BASE"

# Expected artifacts
JAR="build/libs/ciphercraft-$VERSION.jar"
JAVADOC="build/libs/ciphercraft-$VERSION-javadoc.jar"
SOURCES="build/libs/ciphercraft-$VERSION-sources.jar"
POM="build/publications/mavenJava/pom-default.xml"
POM_SIG="$POM.asc"

# Fail if Gradle produced the wrong version
for file in "$JAR" "$JAVADOC" "$SOURCES" "$POM"; do
  if [ ! -f "$file" ]; then
    echo "ERROR: Expected artifact does not exist: $file"
    echo "The build may have produced the wrong version."
    exit 1
  fi
done

# Signature is required for Maven Central
if [ ! -f "$POM_SIG" ]; then
  echo "ERROR: Missing POM signature: $POM_SIG"
  echo "Was SIGNING_KEY configured?"
  exit 1
fi

# Copy only the exact expected artifacts
cp "$JAR" "$BASE/"
cp "$JAVADOC" "$BASE/"
cp "$SOURCES" "$BASE/"

cp "$POM" "$BASE/ciphercraft-$VERSION.pom"
cp "$POM_SIG" "$BASE/ciphercraft-$VERSION.pom.asc"

for file in "$BASE"/*; do
  echo "Processing file: $file"

  if [[ -f "$file" && ! "$file" =~ \.asc$ ]]; then
    echo "Generating hashes for: $file"
    sha1sum "$file" | awk '{print $1}' > "${file}.sha1"
    md5sum "$file" | awk '{print $1}' > "${file}.md5"
  else
    echo "Skipping file: $file"
  fi
done

zip -r bundle.zip io