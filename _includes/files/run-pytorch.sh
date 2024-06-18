#!/bin/bash

# This script is meant to be executed by job_script.sh

aifsdir=<full_patj_to_aifs_repo>

# Printing GPU information to terminal once
if [ $SLURM_LOCALID -eq 0 ] ; then
    rocm-smi
fi
sleep 2

# MIOPEN needs some initialisation for the cache as the default location
# does not work on LUMI as Lustre does not provide the necessary features.
export MIOPEN_USER_DB_PATH="/tmp/$(whoami)-miopen-cache-$SLURM_NODEID"
export MIOPEN_CUSTOM_CACHE_DIR=$MIOPEN_USER_DB_PATH

if [ $SLURM_LOCALID -eq 0 ] ; then
    rm -rf $MIOPEN_USER_DB_PATH
    mkdir -p $MIOPEN_USER_DB_PATH
fi
sleep 2

# Optional! Set NCCL debug output to check correct use of aws-ofi-rccl (these are very verbose)
#export NCCL_DEBUG=INFO
export NCCL_DEBUG=WARN
export NCCL_DEBUG_SUBSYS=INIT,COLL

# Set interfaces to be used by RCCL.
# This is needed as otherwise RCCL tries to use a network interface it has
# no access to on LUMI.
export NCCL_SOCKET_IFNAME=hsn0,hsn1,hsn2,hsn3
export NCCL_NET_GDR_LEVEL=3

# Set ROCR_VISIBLE_DEVICES so that each task uses the proper GPU
#export ROCR_VISIBLE_DEVICES=1,2,3,4 #$SLURM_LOCALID

# Report affinity to check
echo "Rank $SLURM_PROCID --> $(taskset -p $$); GPU $ROCR_VISIBLE_DEVICES"

# Function to find an unused TCP port starting from a specified port number.
find_unused_port() {
    local port=$1
    while : ; do
        # Check if the port is in use
        if ! ss -tuln | grep -qE ":::$port|0.0.0.0:$port" ; then
            # Port is not in use
            echo $port
            break
        fi
        # Increment port by 1 and check again.
        ((port++))
    done
}

# fetches slurm nodelist

get_master_node() {
    # Get the first item in the node list
    first_nodelist=$(echo $SLURM_NODELIST | cut -d',' -f1)

    if [[ "$first_nodelist" == *'['* ]]; then
        # Split the node list and extract the master node
        base_name=$(echo "$first_nodelist" | cut -d'[' -f1)
        range_part=$(echo "$first_nodelist" | cut -d'[' -f2 | cut -d'-' -f1)
        master_node="${base_name}${range_part}"
    else
        # If no range, the first node is the master node
        master_node="$first_nodelist"
    fi

    echo "$master_node"
}



export MASTER_ADDR=$(get_master_node)
export MASTER_PORT=$(find_unused_port 29500)
export WORLD_SIZE=$SLURM_NPROCS
export RANK=$SLURM_PROCID

echo $MASTER_PORT
# CXI stuff
export CXI_FORK_SAFE=1
export CXI_FORK_SAFE_HP=1
export FI_CXI_DISABLE_CQ_HUGETLB=1

# Enable verbose hydra error outputs
export HYDRA_FULL_ERROR=1

python "$aifsdir"/<path_to_train_script>.py

