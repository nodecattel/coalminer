#!/bin/bash

echo -e "\033[0;35m"
cat << "EOF"
         )        (      *    (       )     (     
   (  ( /(  (     )\ ) (  `   )\ ) ( /(     )\ )  
   )\ )\()) )\   (()/( )\))( (()/( )\())(  (()/(  
 (((_((_)((((_)(  /(_)((_)()\ /(_)((_)\ )\  /(_)) 
 )\___ ((_)\ _ )\(_)) (_()((_(_))  _((_((_)(_))   
((/ __/ _ (_)_\(_| |  |  \/  |_ _|| \| | __| _ \  
 | (_| (_) / _ \ | |__| |\/| || | | .` | _||   /  
  \___\___/_/ \_\|____|_|  |_|___||_|\_|___|_|_\  COAL-CLI V2 - Upgrade script
                                                 
EOF
echo -e "Upgrading COAL CLI\033[0m"

# Exit script if any command fails
set -e

# Prompt to select environment (mainnet or panda-optimized-cores)
echo -e "\033[0;35m"
read -p "Choose Solana network (m for mainnet, p for panda-opti-cores): " env_choice
echo -e "\033[0m"  # Reset color
case "$env_choice" in
    [Mm]*)
        echo "Switching to 'mainnet'..."
        solana config set --url https://api.mainnet-beta.solana.com
        REPO_URL="https://github.com/coal-digital/coal-cli"
        COAL_CLI_DIR="$HOME/coalminer/coal-cli"
        ;;
    [Pp]*)
        echo "Switching to 'panda-opti-cores'..."
        solana config set --url https://api.mainnet-beta.solana.com
        REPO_URL="https://github.com/JustPandaEver/coal-cli.git"
        COAL_CLI_DIR="$HOME/coalminer/coal-cli-panda"
        ;;
    *)
        echo "Invalid choice. Staying on current environment."
        exit 1
        ;;
esac

# Determine the default branch name
DEFAULT_BRANCH=$(git ls-remote --symref "$REPO_URL" HEAD | awk '/^ref:/ {print $2}' | sed 's/refs\/heads\///')

# Clone or update COAL-CLI from source
if [ -d "$COAL_CLI_DIR" ]; then
    echo "Updating COAL-CLI repository..."
    cd $COAL_CLI_DIR
    git remote set-url origin "$REPO_URL"
    git fetch origin
    
    # Handle divergent branches
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    BASE=$(git merge-base @ @{u})
    
    if [ $LOCAL = $REMOTE ]; then
        echo "Already up to date."
    elif [ $LOCAL = $BASE ]; then
        echo "Local branch is behind, pulling changes..."
        git pull origin $DEFAULT_BRANCH
    elif [ $REMOTE = $BASE ]; then
        echo "Your local changes aren't in the remote repository."
        echo "Do you want to discard your local changes and sync with the latest code? [y/N]"
        read reset_choice
        if [[ "$reset_choice" =~ ^[Yy]$ ]]; then
            git reset --hard origin/$DEFAULT_BRANCH
        else
            echo "Keeping your local changes. Exiting."
            exit 1
        fi
    else
        echo "Local and remote branches have different changes."
        echo "Do you want to reset your changes to match the remote branch? [y/N]"
        read divergence_choice
        if [[ "$divergence_choice" =~ ^[Yy]$ ]]; then
            git reset --hard origin/$DEFAULT_BRANCH
        else
            echo "Keeping your local changes. Exiting."
            exit 1
        fi
    fi
else
    echo "Cloning COAL-CLI repository..."
    mkdir -p $(dirname $COAL_CLI_DIR)
    git clone --branch $DEFAULT_BRANCH "$REPO_URL" $COAL_CLI_DIR
    cd $COAL_CLI_DIR
fi

# Additional steps for mainnet
if [[ "$env_choice" =~ [Mm] ]]; then
    echo "Setting up additional repository for mainnet..."
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
echo "Building COAL-CLI..."
cargo build --release

# Move the binary to the appropriate location
cp target/release/coal $HOME/.cargo/bin/coal
echo "Coal CLI has been installed from source and updated to the latest version."

# Print the current installed version of Coal CLI
echo "The current installed version of Coal CLI is:"
coal --version
echo -e "\033[0;35m by NodeCattel\033[0m"

# Give execution permission to coal.sh
COAL_SH_PATH="$HOME/coalminer/coal.sh" # Update with the actual path
if [ -f "$COAL_SH_PATH" ]; then
    chmod +x "$COAL_SH_PATH"
    echo "Executable permissions set for coal.sh."
else
    echo "coal.sh does not exist at $COAL_SH_PATH. Please make sure it's in the correct location."
fi

# Optionally prompt the user to run coal.sh for further setup
read -p "Do you wish to start mining? [Y/n] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Starting mining with the latest coal-cli"
    cd $(dirname "$COAL_SH_PATH") # Change directory to where coal.sh is located
    ./coal.sh mine
else
    echo -e "Upgrade complete. You can start mining manually by running ./coal.sh mine."
fi
