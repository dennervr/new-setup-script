#!/bin/bash

# Function to install packages
install_packages() {
    for pkg in "$@"; do
        if yay -Qs "^${pkg}$" >/dev/null; then
            echo "Package $pkg already installed, skipping."
            continue
        fi
        if yay -Ss "^${pkg}$" >/dev/null; then
            yay -S --noconfirm "$pkg"
        else
            echo "Package $pkg not found!"
            return 1
        fi
    done
    return 0
}

install_yay() {
    if [command -v yay &> /dev/null]; then
        return 0
    fi

    sudo pacman -S yay --noconfirm 
}

# Main function
main() {
    # Get Variables
    read -p "Enter your name: " name
    read -p "Enter your email: " email
    read -p "Default editor: [vim, nano] " editor
    read -p "Want to generate ssh key? [Y,n] " ssh_key

    # Update packages
    echo "Updating packages..."
    sudo pacman -Syu --noconfirm

    # Install base packages
    echo "Installing base packages..."
    install_yay || return 1
    install_packages git zsh wget curl base-devel || return 1

    # Install fonts
    echo "Installing fonts..."
    install_packages noto-fonts noto-fonts-emoji noto-fonts-cjk noto-fonts-extra || return 1

    # Install development tools
    echo "Installing development tools..."
    install_packages docker visual-studio-code-bin beekeeper-studio-bin || return 1

    # Configure git
    git config --global user.name "$name"
    git config --global user.email "$email"
    git config --global core.editor "$editor"

    # Generate ssh key
    if [ "$ssh_key" == "y" ]; then
        ssh-keygen -f ~/.ssh/id_ed25519 -N "" -t ed25519 -C "$email"
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_ed25519
        cat ~/.ssh/id_ed25519.pub > ssh_key.log
    fi

    # Configure docker
    echo "Adding user to docker group..."  
    sudo usermod -aG docker "$USER"
    
    # Optional packages
    declare -A packages_options
    packages_options=(
        [1]="brave-bin"
        [2]="firefox"
        [3]="microsoft-edge-stable-bin"
        [4]="discord"
        [5]="spotify"
        [6]="steam"
        [7]="vlc"
    )

    read -p "Install optional packages? [Y,n] " option

    if [[ "$option" == "Y" || "$option" == "y" || "$option" == "" ]]; then
        for key in "${!packages_options[@]}"; do
            echo "$key-${packages_options[$key]}"
        done

        read -p "Select packages separated by space: [1 2 3]" -a options

        for option in "${options[@]}"; do
            echo "Installing ${packages_options[$option]}"
            install_packages "${packages_options[$option]}" || return 1
        done
    fi

    return 0
}

# Call the main function and capture its return value
main
RETVAL=$?

# Check the return value and print a success or error message
if [ $RETVAL -eq 0 ]; then
    echo "Script completed successfully!"
else
    echo "An error occurred during the execution of the script."
fi

if [ ! -z "$RETVAL" ]; then
    touch error.log
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Error executing the script, return value: $RETVAL" >> error.log
    echo "$(cat /var/log/pacman.log 2>&1)" >> error.log
fi

exit $RETVAL
