#!/bin/bash

# Script to install prerequisites for NYC Taxi Analysis project
# - Git
# - OpenJDK 1.8 (or a newer LTS if 8 is not easily available)
# - Apache Maven
# - Downloads Apache Hadoop (user must configure it manually)

echo "Starting prerequisite installation..."
echo "This script may ask for your sudo password for installations."

# Function to detect package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v brew &> /dev/null; then
        echo "brew"
    else
        echo "unknown"
    fi
}

PKG_MANAGER=$(detect_package_manager)

# --- Install Git ---
echo ""
echo "Checking for Git..."
if ! command -v git &> /dev/null; then
    echo "Git not found. Attempting to install..."
    case "$PKG_MANAGER" in
        apt) sudo apt-get update && sudo apt-get install -y git ;;
        yum) sudo yum install -y git ;;
        dnf) sudo dnf install -y git ;;
        brew) brew install git ;;
        *) echo "Unsupported package manager for Git. Please install Git manually." ;;
    esac
    if ! command -v git &> /dev/null; then
        echo "Git installation failed. Please install it manually."
        # exit 1 # Optionally exit if critical
    else
        echo "Git installed successfully."
    fi
else
    echo "Git is already installed."
fi
git --version

# --- Install JDK (OpenJDK 1.8 or newer LTS) ---
echo ""
echo "Checking for Java (JDK)..."
# Try to find an existing JAVA_HOME or java command
JAVA_CMD=$(command -v java)
if [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
    JAVA_CMD="$JAVA_HOME/bin/java"
elif ! command -v java &> /dev/null; then
    echo "Java not found. Attempting to install OpenJDK (preferably 1.8, or newer LTS)..."
    # Attempt to install OpenJDK 8 first, then 11 as a fallback for wider availability
    JDK_PACKAGE_8="openjdk-8-jdk"
    JDK_PACKAGE_11="openjdk-11-jdk" # Common LTS
    JDK_PACKAGE_17="openjdk-17-jdk" # Newer LTS
    
    INSTALLED_JDK=false
    for jdk_pkg in $JDK_PACKAGE_8 $JDK_PACKAGE_11 $JDK_PACKAGE_17; do
        echo "Trying to install $jdk_pkg..."
        case "$PKG_MANAGER" in
            apt) sudo apt-get update && sudo apt-get install -y $jdk_pkg && INSTALLED_JDK=true ;;
            yum) sudo yum install -y ${jdk_pkg/-jdk/} && INSTALLED_JDK=true ;; # yum often uses names like java-1.8.0-openjdk
            dnf) sudo dnf install -y java-1.8.0-openjdk-devel || sudo dnf install -y java-11-openjdk-devel || sudo dnf install -y java-17-openjdk-devel && INSTALLED_JDK=true ;; # More specific for dnf
            brew)
                if [[ "$jdk_pkg" == "$JDK_PACKAGE_8" ]]; then
                    brew tap adoptopenjdk/openjdk && brew install --cask adoptopenjdk8 && INSTALLED_JDK=true
                elif [[ "$jdk_pkg" == "$JDK_PACKAGE_11" ]]; then
                    brew install openjdk@11 && INSTALLED_JDK=true
                    echo "For openjdk@11, you might need to symlink it:"
                    echo "  sudo ln -sfn /usr/local/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk"
                elif [[ "$jdk_pkg" == "$JDK_PACKAGE_17" ]]; then
                     brew install openjdk@17 && INSTALLED_JDK=true
                     echo "For openjdk@17, you might need to symlink it:"
                     echo "  sudo ln -sfn /usr/local/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk"
                fi
                ;;
            *) echo "Unsupported package manager for JDK. Please install OpenJDK 1.8+ manually." ;;
        esac
        if $INSTALLED_JDK; then
            echo "$jdk_pkg (or equivalent) installed successfully."
            JAVA_CMD=$(command -v java) # Update java command path
            break
        fi
    done

    if ! $INSTALLED_JDK || ! command -v java &> /dev/null; then
        echo "JDK installation failed or Java not found in PATH. Please install OpenJDK 1.8+ manually and ensure JAVA_HOME is set."
        # exit 1
    fi
else
    echo "Java seems to be installed."
fi

if [ -n "$JAVA_CMD" ]; then
    $JAVA_CMD -version
    echo "JAVA_HOME is currently set to: $JAVA_HOME"
    echo "If this is not OpenJDK 1.8+, please adjust your JAVA_HOME to point to a compatible JDK."
else
    echo "Could not determine Java version. Please verify your JDK installation."
fi


# --- Install Maven ---
echo ""
echo "Checking for Maven..."
if ! command -v mvn &> /dev/null; then
    echo "Maven not found. Attempting to install..."
    case "$PKG_MANAGER" in
        apt) sudo apt-get update && sudo apt-get install -y maven ;;
        yum) sudo yum install -y maven ;;
        dnf) sudo dnf install -y maven ;;
        brew) brew install maven ;;
        *) echo "Unsupported package manager for Maven. Please install Maven manually." ;;
    esac
    if ! command -v mvn &> /dev/null; then
        echo "Maven installation failed. Please install it manually."
        # exit 1
    else
        echo "Maven installed successfully."
    fi
else
    echo "Maven is already installed."
fi
mvn -version

# --- Download Apache Hadoop (e.g., 3.3.6) ---
HADOOP_VERSION="3.3.6" # Specify desired Hadoop 3.3.x version
HADOOP_URL="https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"
HADOOP_DIR_NAME="hadoop-${HADOOP_VERSION}"
DOWNLOAD_TARGET_DIR="$HOME/hadoop_downloads" # Or /opt or other preferred location
INSTALL_TARGET_DIR="$HOME/hadoop" # Or /opt/hadoop

echo ""
echo "Checking for Hadoop..."
if [ ! -d "$INSTALL_TARGET_DIR/$HADOOP_DIR_NAME" ]; then
    echo "Hadoop ${HADOOP_VERSION} not found in $INSTALL_TARGET_DIR. Attempting to download and extract..."
    mkdir -p "$DOWNLOAD_TARGET_DIR"
    mkdir -p "$INSTALL_TARGET_DIR"
    
    echo "Downloading Hadoop ${HADOOP_VERSION} from $HADOOP_URL..."
    if command -v curl &> /dev/null; then
        curl -L -o "$DOWNLOAD_TARGET_DIR/hadoop-${HADOOP_VERSION}.tar.gz" "$HADOOP_URL"
    elif command -v wget &> /dev/null; then
        wget -O "$DOWNLOAD_TARGET_DIR/hadoop-${HADOOP_VERSION}.tar.gz" "$HADOOP_URL"
    else
        echo "Neither curl nor wget found. Cannot download Hadoop. Please download manually."
        # exit 1
    fi

    if [ -f "$DOWNLOAD_TARGET_DIR/hadoop-${HADOOP_VERSION}.tar.gz" ]; then
        echo "Extracting Hadoop to $INSTALL_TARGET_DIR..."
        tar -xzf "$DOWNLOAD_TARGET_DIR/hadoop-${HADOOP_VERSION}.tar.gz" -C "$INSTALL_TARGET_DIR"
        if [ -d "$INSTALL_TARGET_DIR/$HADOOP_DIR_NAME" ]; then
            echo "Hadoop ${HADOOP_VERSION} extracted to $INSTALL_TARGET_DIR/$HADOOP_DIR_NAME"
            echo "IMPORTANT: Hadoop has been downloaded and extracted but NOT configured."
            echo "You MUST configure it manually. Set HADOOP_HOME, update PATH, and configure files in $INSTALL_TARGET_DIR/$HADOOP_DIR_NAME/etc/hadoop."
            echo "Example environment variables to add to your .bashrc or .zshrc:"
            echo "  export HADOOP_HOME=$INSTALL_TARGET_DIR/$HADOOP_DIR_NAME"
            echo "  export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin"
            echo "Also ensure JAVA_HOME is correctly set in \$HADOOP_HOME/etc/hadoop/hadoop-env.sh"
        else
            echo "Hadoop extraction failed."
            # exit 1
        fi
    else
        echo "Hadoop download failed."
        # exit 1
    fi
else
    echo "Hadoop directory $INSTALL_TARGET_DIR/$HADOOP_DIR_NAME already exists. Assuming Hadoop is present."
    echo "If you need to reinstall or use a different version, please remove this directory first."
fi

echo ""
echo "Prerequisite installation/check script finished."
echo "Please review the output and manually address any issues or required configurations, especially for Hadoop."