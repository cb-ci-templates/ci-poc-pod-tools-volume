#!/bin/sh

set -e

kubectl apply -f tools-volume-pvc.yml

# Send the remote script over STDIN to /bin/sh in the container
kubectl exec -i tools-pod -- /bin/sh <<'REMOTE_SCRIPT'
set -x

echo "Starting process..."
whoami
date
echo "Hello from the tools command!"

export HTTP_PROXY="http://squid-dev-proxy.squid.svc.cluster.local:3128"
export HTTPS_PROXY="$HTTP_PROXY"
export NO_PROXY="localhost,127.0.0.1,.svc,.cluster.local,.beescloud.com"
export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS=/bin/true
export TOOLS_DIR=/tools

export ASDF_DATA_DIR=${TOOLS_DIR}/asdf-data
export ASDF_DIR="${TOOLS_DIR}/.asdf"
export ASDF_TAG="v0.14.0"  # adjust as you like
export ASDF_CONFIG_FILE=${TOOLS_DIR}/.asdfrc
export ASDF_TOOL_VERSIONS_FILENAME=.tool-versions
export PATH=/tools/.asdf/bin

# --- prerequisites (best effort for common distros) ---
if command -v yum >/dev/null 2>&1; then
  yum install -y -q  tar git gzip unzip which
elif command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y git curl tar gzip unzip which ca-certificates
elif command -v apk >/dev/null 2>&1; then
  apk add --no-cache git curl tar gzip unzip which ca-certificates
fi

git config --global http.proxy  "$HTTPS_PROXY"
git config --global https.proxy "$HTTPS_PROXY"
git config --global user.name "First Example"
git config --global user.email "user@example.com"
git config --global --list

# --- install asdf (user-local) ---


if [ ! -d "$ASDF_DIR" ]; then
  git clone https://github.com/asdf-vm/asdf.git "$ASDF_DIR" --branch "$ASDF_TAG"
else
  git -C "$ASDF_DIR" fetch --tags
  git -C "$ASDF_DIR" checkout "$ASDF_TAG"
fi

# load asdf into this shell
. "$ASDF_DIR/asdf.sh" || true
[ -f "$ASDF_DIR/completions/asdf.bash" ] && . "$ASDF_DIR/completions/asdf.bash" || true


# see https://github.com/asdf-community
#  asdf plugin list all | grep java

# --- Java via asdf (Temurin) ---
if ! asdf plugin list | grep -q '^java$'; then
  asdf plugin add java https://github.com/halcyon/asdf-java.git
fi

# Prefer Temurin 23; fall back to Temurin 21 (LTS); else latest available
JAVA_VER="$(asdf latest java 'temurin-23' 2>/dev/null || true)"
[ -z "$JAVA_VER" ] && JAVA_VER="$(asdf latest java 'temurin-21' 2>/dev/null || true)"
[ -z "$JAVA_VER" ] && JAVA_VER="$(asdf latest java)"

echo "Installing Java: $JAVA_VER"
asdf install java "$JAVA_VER"
asdf global  java "$JAVA_VER"

# JAVA_HOME varies by distro; try both common layouts
JAVA_HOME="$(asdf where java)/libexec/openjdk"
[ -d "$JAVA_HOME" ] || JAVA_HOME="$(asdf where java)"
export JAVA_HOME
export PATH="$HOME/.asdf/shims:$HOME/.asdf/bin:$JAVA_HOME/bin:$PATH"

java -version

# --- Maven via asdf (latest) ---
# asdf plugin list all | grep maven
if ! asdf plugin list | grep -q '^maven$'; then
  asdf plugin add maven https://github.com/halcyon/asdf-maven.git
fi

MAVEN_VER="$(asdf latest maven)"
echo "Installing Maven: $MAVEN_VER"
asdf install maven "$MAVEN_VER"
asdf global  maven "$MAVEN_VER"

echo "Java HOME: $JAVA_HOME"
mvn -version

cp -f ~/${ASDF_TOOL_VERSIONS_FILENAME}  ${TOOLS_DIR}/${ASDF_TOOL_VERSIONS_FILENAME}
cat ${TOOLS_DIR}/${ASDF_TOOL_VERSIONS_FILENAME}
echo "All done"
REMOTE_SCRIPT
