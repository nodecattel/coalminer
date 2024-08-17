#!/bin/bash
source ~/.profile

echo -e "\033[0;35m"
cat << "EOF"
         )        (      *    (       )     (     
   (  ( /(  (     )\ ) (  `   )\ ) ( /(     )\ )  
   )\ )\()) )\   (()/( )\))( (()/( )\())(  (()/(  
 (((_((_)((((_)(  /(_)((_)()\ /(_)((_)\ )\  /(_)) 
 )\___ ((_)\ _ )\(_)) (_()((_(_))  _((_((_)(_))   
((/ __/ _ (_)_\(_| |  |  \/  |_ _|| \| | __| _ \  
 | (_| (_) / _ \ | |__| |\/| || | | .` | _||   /  
  \___\___/_/ \_\|____|_|  |_|___||_|\_|___|_|_\  
                                                  

EOF
echo -e "Version 0.1.0 - Coal-Cli installer"
echo -e "Made by NodeCattel & All the credits to Coal-Digital\033[0m"

# Exit script if any command fails
set -e

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     OS_TYPE=Linux;;
    Darwin*)    OS_TYPE=Mac;;
    *)          OS_TYPE="UNKNOWN:${OS}"
esac

echo "Detected OS: $OS_TYPE"

# Install Rust and Cargo
echo -e "\033[0;35mInstalling Rust and Cargo...\033[0m"
curl https://sh.rustup.rs -sSf | sh -s -- -y

# Ensure Cargo is in the PATH
. "$HOME/.cargo/env"  # For sh/bash/zsh/ash/dash/pdksh
if [ "$SHELL" = "fish" ]; then
    source "$HOME/.cargo/env.fish"
fi

if [ "$OS_TYPE" == "Linux" ]; then
    # Update and upgrade the system
    echo -e "\033[0;35mUpdating and upgrading the system...\033[0m"
    sudo apt update
    sudo apt upgrade -y

    # Install required dependencies
    echo -e "\033[0;35mInstalling required dependencies...\033[0m"
    sudo apt install -y openssl pkg-config libssl-dev
elif [ "$OS_TYPE" == "Mac" ]; then
    # Install Homebrew if not installed
    if ! command -v brew &> /dev/null; then
        echo -e "\033[0;35mHomebrew not found. Installing Homebrew...\033[0m"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    echo -e "\033[0;35mInstalling required dependencies for Mac...\033[0m"
    brew install openssl pkg-config

    # Set environment variables for OpenSSL if necessary
    export PATH="/usr/local/opt/openssl/bin:$PATH"
    export LDFLAGS="-L/usr/local/opt/openssl/lib"
    export CPPFLAGS="-I/usr/local/opt/openssl/include"
else
    echo "Unsupported OS type: $OS_TYPE"
    exit 1
fi

# Check if Solana CLI is installed
if command -v solana &> /dev/null; then
    echo -e "\033[0;35mSolana CLI is already installed. Skipping installation.\033[0m"
else
    echo -e "\033[0;35mInstalling Solana CLI...\033[0m"
    sh -c "$(curl -sSfL https://release.solana.com/v1.18.20/install)"
    # Ensure Solana is in the PATH
    if [ "$OS_TYPE" == "Linux" ]; then
        PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.profile
        echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin/$PATH"' >> ~/.bashrc
        source ~/.profile
    elif [ "$OS_TYPE" == "Mac" ]; then
        PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin/$PATH"' >> ~/.profile
        echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin/$PATH"' >> ~/.zshrc
        source ~/.profile
    fi
fi

# Verify Solana CLI installation
if ! command -v solana &> /dev/null; then
    echo "Solana CLI installation failed or not found in PATH."
    exit 1
fi

# Create Solana keypair
if [ -f "$HOME/.config/solana/id.json" ]; then
    echo -e "\033[0;35mExisting wallet found. Skipping key generation.\033[0m"
else
    solana-keygen new
fi

# Prompt to select environment (mainnet or panda-optimized-cores)
echo -e "\033[0;35m"
read -p "Choose Solana network (m for mainnet official, p for panda-opti-cores): " env_choice
echo -e "\033[0m"  # Reset color
case "$env_choice" in
    [Mm]*)
        echo -e "\033[0;35mSwitching to 'mainnet'...\033[0m"
        solana config set --url https://api.mainnet-beta.solana.com
        REPO_URL="https://github.com/coal-digital/coal-cli"
        COAL_CLI_DIR="$HOME/coalminer/coal-cli"
        ;;
    [Pp]*)
        echo -e "\033[0;35mSwitching to 'panda-opti-cores'...\033[0m"
        REPO_URL="https://github.com/JustPandaEver/coal-cli.git"
        COAL_CLI_DIR="$HOME/coalminer/coal-cli-panda"
        ;;
    *)
        echo -e "\033[0;35mInvalid choice. Staying on current environment.\033[0m"
        exit 1
        ;;
esac

# Determine the default branch name
DEFAULT_BRANCH=$(git ls-remote --symref "$REPO_URL" HEAD | awk '/^ref:/ {print $2}' | sed 's/refs\/heads\///')

# Clone or update COAL-CLI from source
if [ -d "$COAL_CLI_DIR" ]; then
    echo -e "\033[0;35mUpdating COAL-CLI repository...\033[0m"
    cd $COAL_CLI_DIR
    git remote set-url origin "$REPO_URL"
    git fetch origin
    git checkout $DEFAULT_BRANCH
    git pull origin $DEFAULT_BRANCH
else
    echo -e "\033[0;35mCloning COAL-CLI repository...\033[0m"
    mkdir -p $(dirname $COAL_CLI_DIR)
    git clone --branch $DEFAULT_BRANCH "$REPO_URL" $COAL_CLI_DIR
    cd $COAL_CLI_DIR
fi

# Additional steps for mainnet
if [[ "$env_choice" =~ [Mm] ]]; then
    echo -e "\033[0;35mSetting up additional repository for mainnet...\033[0m"
    cd $HOME/coalminer
    if [ -d "$HOME/coalminer/coal" ]; then
        cd coal
        git remote set-url origin https://github.com/coal-digital/coal
        git fetch origin
        git checkout master
    else
        git clone https://github.com/coal-digital/coal
        cd coal
        git checkout master
    fi
    cd $COAL_CLI_DIR
fi

# Build the COAL-CLI binary
echo -e "\033[0;35mBuilding COAL-CLI...\033[0m"
cargo build --release

# Move the binary to the appropriate location
cp target/release/coal $HOME/.cargo/bin/coal
echo -e "\033[0;35mCoal CLI has been installed from source and updated to the latest version.\033[0m"

# Print the current installed version of Coal CLI
echo -e "\033[0;35mThe current installed version of Coal CLI is:\033[0m"
coal --version
echo -e "\033[0;35mby NodeCattel\033[0m"

# Give execution permission to coal.sh
COAL_SH_PATH="$HOME/coalminer/coal.sh" # Update with the actual path
if [ -f "$COAL_SH_PATH" ]; then
    chmod +x "$COAL_SH_PATH"
    echo -e "\033[0;35mExecutable permissions set for coal.sh.\033[0m"
else
    echo -e "\033[0;35mcoal.sh does not exist at $COAL_SH_PATH. Please make sure it's in the correct location.\033[0m"
fi

# Optionally prompt the user to run coal.sh for further setup
read -p "Do you wish to continue with setting up coal.sh? [Y/n] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo -e

 "\033[0;35mProceeding with coal.sh setup...\033[0m"
    cd $(dirname "$COAL_SH_PATH") # Change directory to where coal.sh is located
    ./coal.sh mine
else
    echo -e "\033[0;35mSetup aborted. Run coal.sh manually to complete setup.\033[0m"
fi
