#!/bin/bash
#SBATCH --job-name=GNR_Converge           
#SBATCH --time=24:00:00                
#SBATCH --ntasks=1                     
#SBATCH --cpus-per-task=128             
#SBATCH --mem-per-cpu=2G               
#SBATCH --output=converge_log_%j.out        
#SBATCH --error=converge_log_%j.err         
#SBATCH --mail-type=END,FAIL           
#SBATCH --mail-user=your_email@ethz.ch 

module load matlab
matlab -nodisplay -nosplash -nodesktop -logfile "LIVE_CONVERGENCE_LOG.txt" -r "batch_convergence; exit"