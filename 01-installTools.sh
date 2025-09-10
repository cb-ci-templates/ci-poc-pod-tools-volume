#! /bin/sh

kubectl apply -f tools-volume-pvc.yml
kubectl exec -i tools-pod -- /bin/sh -c "$(cat <<'EOF'
echo "Starting process..."
date
echo "Hello from the tools command!"
yum install tar gzip
mkdir -p /tools/tools-linux/java/
cd /tools/tools-linux/java/
rm -fv *.tar.gz
curl -o java23.tar.gz https://download.java.net/java/GA/jdk23.0.2/6da2a6609d6e406f85c491fcb119101b/7/GPL/openjdk-23.0.2_linux-x64_bin.tar.gz
ls -la
chmod a+x *.tar.gz
tar -xvzf java23.tar.gz
export JAVA_HOME="/tools/tools-linux/java/jdk-23.0.2"
export PATH="$PATH:$JAVA_HOME/bin"
java --version




# --- Maven install (latest 3.x)
echo "Resolving latest Maven version..."
MAVEN_BASE_URL="https://downloads.apache.org/maven/maven-3/"

LATEST_MAVEN_VERSION=$(
  curl -fsSL "$MAVEN_BASE_URL" \
    | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+/' \
    | tr -d '/' \
    | sort -V \
    | tail -n1
)

echo "Latest Maven detected: $LATEST_MAVEN_VERSION"

MAVEN_TGZ="apache-maven-${LATEST_MAVEN_VERSION}-bin.tar.gz"
MAVEN_URL="https://dlcdn.apache.org/maven/maven-3/${LATEST_MAVEN_VERSION}/binaries/${MAVEN_TGZ}"

echo "Downloading Maven from: $MAVEN_URL"
curl -fL -o "$MAVEN_TGZ" "$MAVEN_URL"

echo "Extracting Maven..."
tar -xvzf "$MAVEN_TGZ" -C /tools/tools-linux/maven/

# set MAVEN_HOME to extracted dir
export MAVEN_HOME="/tools/tools-linux/maven/apache-maven-${LATEST_MAVEN_VERSION}"
export M2_HOME="/tools/tools-linux/maven/apache-maven-${LATEST_MAVEN_VERSION}"
export PATH="$MAVEN_HOME/bin:$PATH"
ls /tools/tools-linux/maven/
echo "Maven installed at: $MAVEN_HOME"
mvn -version

echo "All done ✅"

EOF
)"
