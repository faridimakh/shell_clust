#!/bin/bash

# Define variables for master and worker nodes
MASTER_IP="ff@192.168.1.5"

# Function to install Java in the home directory

jdk_install() {
    # Define or retrieve INSTALL_DIR from the target server

    INSTALL_DIR=$(ssh "$1" 'echo "$HOME/spark_cluster"')
    # Ensure the JDK tarball exists before proceeding
    if [[ ! -f jdk-8u172-linux-x64.tar.gz ]]; then
        echo "JDK archive not found."
        return 1
    fi

    # Create the directory on the remote server
    ssh "$1" << EOF
#        rm -rf "$INSTALL_DIR" && mkdir -p "$INSTALL_DIR/java"
        mkdir -p "$INSTALL_DIR/java"
EOF

    # Copy the JDK file to the remote server
    scp jdk-8u172-linux-x64.tar.gz "$1:$INSTALL_DIR/java"

    # Install JDK on the remote server
    ssh "$1" << EOF
        cd "$INSTALL_DIR/java"
        if [[ -f jdk-8u172-linux-x64.tar.gz ]]; then
            tar -xzf jdk-8u172-linux-x64.tar.gz
            mv jdk1.* jdk
            rm jdk-8u172-linux-x64.tar.gz

            # Backup .bashrc if it hasn't been done already
            [ ! -f ~/.bashrc_backup ] && cp ~/.bashrc ~/.bashrc_backup

            # Set JAVA_HOME and update PATH
            JAVA_HOME="$INSTALL_DIR/java/jdk"
            echo "export JAVA_HOME=$INSTALL_DIR/java/jdk" >> ~/.bashrc
            echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
            source ~/.bashrc

        else
            echo "JDK tarball not found after upload."
        fi
EOF
}
#----------------------------------------------------------------------------------
jdk_uninstall() {
    # Define or retrieve INSTALL_DIR from the target server
    INSTALL_DIR=$(ssh "$1" 'echo "$HOME/spark_cluster"')

    # Check if the JDK directory exists on the remote server and proceed with uninstallation
    ssh "$1" << EOF
        if [[ -d "$INSTALL_DIR/java" ]]; then
            echo "Removing JDK directory..."
            rm -rf "$INSTALL_DIR/java" && echo "JDK directory removed."
        else
            echo "JDK directory not found."
        fi

        # Remove JAVA_HOME export and JDK path from .bashrc
        if grep -q "export JAVA_HOME=" ~/.bashrc; then
            sed -i '/export JAVA_HOME=/d' ~/.bashrc
            sed -i 's|$INSTALL_DIR/java/jdk/bin:||' ~/.bashrc && echo "Removed JAVA_HOME and JDK path from .bashrc."
            source ~/.bashrc
        else
            echo "JAVA_HOME not found in .bashrc."
        fi

        echo "JDK uninstallation complete. Restart shell session to apply changes."
EOF
}



echo "Installing JDK on Master and Workers..."
jdk_install "$MASTER_IP"
#jdk_uninstall "$MASTER_IP"