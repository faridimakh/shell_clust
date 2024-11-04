#!/bin/bash

# Define variables for master and worker nodes
MASTER_IP="ff@192.168.1.5"
SPARK_FILE="spark-2.4.0-bin-hadoop2.6.tgz" # Spark file name
JDK_FILE="jdk-8u172-linux-x64.tar.gz" # Spark file name
#-----------------------------------------------------------------------------------------------------------------
#install java
#-----------------------------------------------------------------
jdk_install() {
    # Define or retrieve INSTALL_DIR from the target server

    INSTALL_DIR=$(ssh "$1" 'echo "$HOME/spark_cluster"')
    # Ensure the JDK tarball exists before proceeding
    if [[ ! -f $JDK_FILE ]]; then
        echo "JDK archive not found."
        return 1
    fi

    # Create the directory on the remote server
    ssh "$1" << EOF
#        rm -rf "$INSTALL_DIR" && mkdir -p "$INSTALL_DIR/java"
        mkdir -p "$INSTALL_DIR/java"
EOF

    # Copy the JDK file to the remote server
    scp $JDK_FILE "$1:$INSTALL_DIR/java"

    # Install JDK on the remote server
    ssh "$1" << EOF
        cd "$INSTALL_DIR/java"
        if [[ -f $JDK_FILE ]]; then
            tar -xzf $JDK_FILE
            mv jdk1.* jdk
            rm $JDK_FILE

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
#---------------------------------------------------------
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
#-----------------------------------------------------------------------------------------------------------------
#install spark
#---------------------------------------------------------
# Function to install Apache Spark in the home directory
install_spark() {
    INSTALL_DIR=$(ssh "$1" 'echo "$HOME/spark_cluster"')

    if [[ ! -f $SPARK_FILE ]]; then
        echo "Spark archive $SPARK_FILE not found."
        return 1
    fi

    ssh "$1" << EOF
        mkdir -p "$INSTALL_DIR/spark"
EOF

    scp $SPARK_FILE "$1:$INSTALL_DIR" || {
        echo "Failed to copy Spark file to $1"
        return 1
    }

    ssh "$1" << EOF
        cd "$INSTALL_DIR"
        if [[ -f $SPARK_FILE ]]; then
            tar -xvf $SPARK_FILE -C spark --strip-components=1
            rm $SPARK_FILE

            if ! grep -q "export SPARK_HOME=$INSTALL_DIR/spark" ~/.bashrc; then
                SPARK_HOME="$INSTALL_DIR/spark"
                echo "export SPARK_HOME=$INSTALL_DIR/spark" >> ~/.bashrc
                echo "export PATH=\$SPARK_HOME/bin:\$SPARK_HOME/sbin:\$PATH" >> ~/.bashrc
                source ~/.bashrc
            fi
        else
            echo "Spark tarball not found after upload."
        fi
EOF
}

echo "Installing Spark on Master and Workers..."
install_spark "$MASTER_IP"
echo "Installing JDK on Master and Workers..."
jdk_install "$MASTER_IP"
#jdk_uninstall "$MASTER_IP"
