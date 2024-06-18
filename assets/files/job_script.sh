#!/bin/bash
#SBATCH --output=logs/slurm.out
#SBATCH --error=logs/slurm.err
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --account=<your_project_name_or_number>
#SBATCH --partition=dev-g
#SBATCH --gpus-per-node=8
#SBATCH --time=02:00:00
#SBATCH --job-name=aifs

module load LUMI/23.09 partition/G

export SINGULARITYENV_LD_LIBRARY_PATH=/opt/ompi/lib:${EBROOTAWSMINOFIMINRCCL}/lib:/opt/cray/xpmem/2.4.4-2.3_9.1__gff0e1d9.shasta/lib64:${SINGULARITYENV_LD_LIBRARY_PATH}

# run run-pytorch.sh
srun --cpu-bind=map_cpu:49,57,17,25,1,9,33,41 \
singularity exec -B /pfs:/pfs \
	         -B /var/spool/slurmd,/opt/cray/,/usr/lib64/libcxi.so.1,/usr/lib64/libjansson.so.4 \
		 <full_path_to_container>.sif \
		 <full_path_to_job_script>run-pytorch.sh
