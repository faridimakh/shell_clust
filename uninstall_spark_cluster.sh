#!/bin/bash

# Define variables for master and worker nodes
MASTER_IP="192.168.1.5"
#WORKER1_IP="192.168.1.6"
#WORKER2_IP="192.168.1.7"
# Uninstall Spark and remove configurations on each node
uninstall_spark() {
  INSTALL_DIR=$(ssh "$1" 'echo "$HOME/spark_cluster"')
  ssh "$1" << EOF
    # Remove Spark directory
    rm -rf $INSTALL_DIR

    # Remove Spark environment variables from .bashrc
    cp ~/.bashrc_backup ~/.bashrc
    # Reload .bashrc to apply changes
    source ~/.bashrc
EOF
}

# Stop Spark processes on each node if they are running
stop_spark_processes() {
  ssh "$1" << EOF
    # Stop any running Spark processes
    /opt/spark/sbin/stop-master.sh || true
    /opt/spark/sbin/stop-worker.sh || true
EOF
}

echo "Stopping Spark processes on Master and Workers..."
#TODO:
#stop_spark_processes "$MASTER_IP"
#stop_spark_processes "$WORKER1_IP"
#stop_spark_processes "$WORKER2_IP"

#TODO:
echo "Uninstalling Spark on Master and Workers..."
uninstall_spark "$MASTER_IP"
#uninstall_spark "$WORKER1_IP"
#uninstall_spark "$WORKER2_IP"

echo "Spark cluster uninstallation complete."
