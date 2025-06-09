#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Ensure script is run as root/sudo for installations
check_sudo() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script needs to be run with sudo or as root for installations."
        echo "Attempting to re-run with sudo..."
        sudo "$0" "$@" # Re-execute the script with sudo
        exit $?       # Exit with the status of the sudo command
    fi
}

# --- Installation Functions ---

install_docker() {
    if command_exists docker && command_exists docker-compose; then
        echo "Docker and Docker Compose already installed."
        docker --version
        docker-compose --version
        return
    fi

    echo "Installing Docker and Docker Compose..."
    if [[ "$OS_FAMILY" == "debian" ]]; then
        apt-get update
        apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin # docker-compose-plugin is v2
        # Also install docker-compose (v1) for compatibility if needed, or ensure scripts use 'docker compose'
        if ! command_exists docker-compose; then apt-get install -y docker-compose; fi


    elif [[ "$OS_FAMILY" == "rhel" ]]; then # Covers CentOS, RHEL, Fedora
        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        if ! command_exists docker-compose; then yum install -y docker-compose; fi
        systemctl start docker
        systemctl enable docker
    elif [[ "$OS_FAMILY" == "macos" ]]; then
        echo "On macOS, Docker Desktop (which includes Docker Compose) is recommended."
        echo "Please install it manually from https://www.docker.com/products/docker-desktop"
        echo "If you have Homebrew, you can try 'brew install docker docker-compose', but Docker Desktop is preferred."
        # brew install docker docker-compose # Uncomment if you want to try via brew
        if ! command_exists docker || ! command_exists docker-compose; then
             echo "Docker or Docker Compose not found after macOS instructions."
             # exit 1 # Exit if user doesn't install it
        fi
    else
        echo "Unsupported OS for Docker auto-installation: $OS_FAMILY. Please install manually."
        return 1
    fi
    
    # Add current user to docker group (if not root)
    if [ "$(id -u)" -ne 0 ] && [ -n "$SUDO_USER" ]; then
        usermod -aG docker "$SUDO_USER"
        echo "Added user $SUDO_USER to the docker group."
        echo "IMPORTANT: You may need to log out and log back in for this change to take effect,"
        echo "or run 'newgrp docker' in your current shell session."
    fi

    echo "Docker and Docker Compose installation attempted."
    docker --version
    if command_exists docker-compose; then docker-compose --version; fi
    if command_exists docker && docker compose version > /dev/null 2>&1; then docker compose version; fi
}

install_aws_cli() {
    if command_exists aws; then
        echo "AWS CLI already installed."
        aws --version
        return
    fi
    echo "Installing AWS CLI..."
    if [[ "$OS_FAMILY" == "debian" || "$OS_FAMILY" == "rhel" ]]; then
        # Using bundled installer for broader compatibility
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip -q awscliv2.zip # -q for quiet
        ./aws/install
        rm -rf awscliv2.zip aws
    elif [[ "$OS_FAMILY" == "macos" ]]; then
        curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
        installer -pkg AWSCLIV2.pkg -target /
        rm AWSCLIV2.pkg
    else
        echo "Unsupported OS for AWS CLI auto-installation: $OS_FAMILY. Please install manually."
        return 1
    fi
    echo "AWS CLI installation attempted."
    aws --version
    echo "IMPORTANT: Remember to configure AWS CLI with 'aws configure' using your credentials."
}

install_terraform() {
    if command_exists terraform; then
        echo "Terraform already installed."
        terraform version
        return
    fi
    echo "Installing Terraform..."
    TERRAFORM_VERSION="1.5.0" # Specify a recent version or make it dynamic
    ARCH=$(uname -m)
    if [ "$ARCH" == "x86_64" ]; then TF_ARCH="amd64"; fi
    if [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "arm64" ]; then TF_ARCH="arm64"; fi # For M1/M2 Macs or ARM servers

    if [[ "$OS_FAMILY" == "debian" || "$OS_FAMILY" == "rhel" ]]; then
        OS_LOWER="linux"
    elif [[ "$OS_FAMILY" == "macos" ]]; then
        OS_LOWER="darwin"
    else
        echo "Unsupported OS for Terraform auto-installation: $OS_FAMILY. Please install manually."
        return 1
    fi

    wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${OS_LOWER}_${TF_ARCH}.zip"
    unzip -q "terraform_${TERRAFORM_VERSION}_${OS_LOWER}_${TF_ARCH}.zip"
    mv terraform /usr/local/bin/
    rm "terraform_${TERRAFORM_VERSION}_${OS_LOWER}_${TF_ARCH}.zip"
    
    echo "Terraform installation attempted."
    terraform version
}

install_utility() {
    local tool_name="$1"
    local debian_pkg="$2"
    local rhel_pkg="$3"
    local macos_brew_pkg="$4"

    if command_exists "$tool_name"; then
        echo "$tool_name already installed."
        return
    fi
    echo "Installing $tool_name..."
    if [[ "$OS_FAMILY" == "debian" ]]; then
        apt-get update && apt-get install -y "$debian_pkg"
    elif [[ "$OS_FAMILY" == "rhel" ]]; then
        yum install -y "$rhel_pkg"
    elif [[ "$OS_FAMILY" == "macos" ]]; then
        brew install "$macos_brew_pkg"
    else
        echo "Unsupported OS for $tool_name auto-installation: $OS_FAMILY. Please install manually."
        return 1
    fi
    echo "$tool_name installation attempted."
}

install_java_maven() {
    JAVA_INSTALLED=false
    MAVEN_INSTALLED=false
    if command_exists java && java -version 2>&1 | grep -q "1.8\|11"; then # Check for Java 8 or 11
        echo "Java (compatible version) already installed."
        java -version
        JAVA_INSTALLED=true
    fi
    if command_exists mvn; then
        echo "Maven already installed."
        mvn -version
        MAVEN_INSTALLED=true
    fi

    if $JAVA_INSTALLED && $MAVEN_INSTALLED; then
        return
    fi

    echo "Installing Java and Maven..."
    if [[ "$OS_FAMILY" == "debian" ]]; then
        apt-get update
        if ! $JAVA_INSTALLED; then apt-get install -y openjdk-11-jdk; fi # Or openjdk-8-jdk
        if ! $MAVEN_INSTALLED; then apt-get install -y maven; fi
    elif [[ "$OS_FAMILY" == "rhel" ]]; then
        if ! $JAVA_INSTALLED; then yum install -y java-11-openjdk-devel; fi # Or java-1.8.0-openjdk-devel
        if ! $MAVEN_INSTALLED; then yum install -y maven; fi
    elif [[ "$OS_FAMILY" == "macos" ]]; then
        if ! $JAVA_INSTALLED; then brew install openjdk@11;
            # Symlink for macOS if installed via brew
            sudo ln -sfn /usr/local/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
            echo 'export PATH="/usr/local/opt/openjdk@11/bin:$PATH"' >> ~/.zshrc # or .bash_profile
            echo 'Please source your shell profile (e.g., source ~/.zshrc) or open a new terminal for Java path changes.'
        fi
        if ! $MAVEN_INSTALLED; then brew install maven; fi
    else
        echo "Unsupported OS for Java/Maven auto-installation: $OS_FAMILY. Please install manually."
        return 1
    fi
    echo "Java and Maven installation attempted."
    if command_exists java; then java -version; fi
    if command_exists mvn; then mvn -version; fi
}

install_python() {
    if command_exists python3 && command_exists pip3; then
        echo "Python 3 and pip3 already installed."
        python3 --version
        pip3 --version
        return
    fi
    echo "Installing Python 3 and pip3..."
    if [[ "$OS_FAMILY" == "debian" ]]; then
        apt-get update && apt-get install -y python3 python3-pip python3-venv
    elif [[ "$OS_FAMILY" == "rhel" ]]; then
        yum install -y python3 python3-pip
    elif [[ "$OS_FAMILY" == "macos" ]]; then
        brew install python3
    else
        echo "Unsupported OS for Python 3 auto-installation: $OS_FAMILY. Please install manually."
        return 1
    fi
    echo "Python 3 and pip3 installation attempted."
    if command_exists python3; then python3 --version; fi
    if command_exists pip3; then pip3 --version; fi
}


# --- OS Detection ---
OS_FAMILY=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID_LIKE" == *"debian"* || "$ID" == "debian" || "$ID" == "ubuntu" ]]; then
        OS_FAMILY="debian"
    elif [[ "$ID_LIKE" == *"rhel"* || "$ID_LIKE" == *"fedora"* || "$ID" == "centos" || "$ID" == "rhel" || "$ID" == "fedora" ]]; then
        OS_FAMILY="rhel"
    fi
elif [[ "$(uname)" == "Darwin" ]]; then
    OS_FAMILY="macos"
    if ! command_exists brew; then
        echo "Homebrew not detected on macOS. Please install it first from https://brew.sh/"
        # exit 1 # Exit if brew is essential for macOS steps
    fi
fi

if [ -z "$OS_FAMILY" ]; then
    echo "Could not determine OS family. Exiting."
    exit 1
fi
echo "Detected OS Family: $OS_FAMILY"

# --- Main Execution ---
check_sudo "$@" # Pass all arguments to the sudo'd script

echo "Starting prerequisite installation..."

install_utility "wget" "wget" "wget" "wget"
install_utility "zip" "zip unzip" "zip unzip" "zip" # unzip also useful
install_python
install_java_maven
install_docker
install_aws_cli
install_terraform


echo "---------------------------------------------------------------------"
echo "Prerequisite installation process finished."
echo "Please verify the output above for any errors or manual steps required."
echo " notamment:"
echo "  - For Docker: Log out and log back in, or run 'newgrp docker' if your user was added to the docker group."
echo "  - For AWS CLI: Run 'aws configure' to set up your credentials and default region."
echo "  - For Java on macOS (if installed via brew): Ensure PATH is updated (e.g. source ~/.zshrc or new terminal)."
echo "---------------------------------------------------------------------"
