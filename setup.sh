#!/bin/bash

# Function to install packages
install_packages() {
    for pkg in "$@"; do
        if yay -Ss "^${pkg}$" >/dev/null; then
            yay -S --noconfirm "$pkg"
        else
            echo "Package $pkg not found!"
            return 1
        fi
    done
    return 0
}

set_localectl() {
    # Set localectl
    read -p "Choose keyboard: [us/br] " keyboard
    if [[ "$keyboard" != "us" && "$keyboard" != "br" ]]; then
        echo "Invalid option. Please choose 'us' or 'br'."
        return 1
    fi
    localectl set-x11-keymap "$keyboard" "" "${keyboard}_intl"
}

# Main function
main() {
    # Set localectl
    set_localectl || return 1

    # Get Variables     
    read -p "Enter your name: " name
    read -p "Enter your email: " email
    read -p "Default editor: [vim, nano] " editor
    read -p "Want to generate ssh key? [Y,n] " ssh_key

    # Update packages
    echo "Updating packages..."
    sudo pacman -Syu --noconfirm

    # Install fonts
    echo "Installing fonts..."
    install_packages noto-fonts noto-fonts-emoji noto-fonts-cjk noto-fonts-extra || return 1

    # Install base packages
    echo "Installing base packages..."
    install_packages git zsh wget curl base-devel "$editor" || return 1

    git clone https://aur.archlinux.org/yay.git
    cd yay || return 1
    makepkg -si --noconfirm
    cd ..

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
    sudo groupadd docker
    sudo usermod -aG docker "$USER"
    newgrp docker

    # Optional packages
    declare -A packages_options
    packages_options=(
        [1]="brave-bin"
        [2]="firefox"
        [3]="microsoft-edge-dev-bin"
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

exit $RETVAL
