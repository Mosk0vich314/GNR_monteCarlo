Graphene Nanoribbon (GNR) Physics Simulator
This repository contains a high-performance Monte Carlo simulation engine designed to model the self-assembly and contact yield of Graphene Nanoribbons (GNRs) bridging nano-gap electrodes.

The engine evaluates complex film morphologies (Aligned vs. Polydomain), statistical ribbon lengths (Gamma distribution), spatial packing, defect densities, and realistic EBL manufacturing constraints (rounded electrode tips) to find optimal parameter windows for pristine device yields. It is heavily optimized for parallel execution on HPC clusters (e.g., ETH Zurich's Euler cluster).

📂 Repository File Manifest
1. 🧠 The Core Physics Engines
These are the heavy lifters that generate the geometries and compute the collision mathematics.

run_gnr_sweep.m: The primary 3D simulation engine. It takes a grid of physical parameters, spawns 128 parallel workers, places millions of GNRs, and detects valid electrical bridges. It saves the absolute probabilities of Pristine, Defective, Short Circuit, and Open Circuit events into SimulationData.mat.

run_convergence.m: A standalone physics engine designed strictly to run one specific parameter combination for tens of thousands of trials. It proves the statistical stability of the results by calculating the exact Binomial Standard Error of the Mean (SEM).

2. 🎛️ Master Controllers (Batch Scripts)
These scripts are used to define the parameter ranges and queue up massive jobs.

batch_master.m / batch_master_2.m: The main execution scripts. You define your 1D, 2D, or 3D parameter sweeps here. They automatically call the physics engine and subsequently trigger the convergence scripts when the sweep finishes.

auto_convergence.m: A "smart wrapper" script. It reads a completed 3D sweep folder, automatically extracts the exact parameters that yielded the highest target probability, and feeds them into the convergence engine.

batch_convergence.m: A monolithic rescue script. It scans your directory for old sweep data and automatically runs 50,000-trial convergence tests on their peak yields without requiring the original setup scripts.

3. 🚀 Cluster Submission Scripts (SLURM)
Bash scripts required to request supercomputer resources.

run_sim.sh / run_sim_2.sh: Submits batch_master.m to the cluster. Configured to request 128 CPU cores, 256GB RAM, and 72 hours of compute time. It runs MATLAB in headless mode.

run_convergence_sim.sh: Submits batch_convergence.m to the cluster for overnight statistical validation jobs.

4. 📊 Plotting & Visualization
Tools to interpret the massive .mat datasets.

plot_gnr_data.m: The core smart-plotter. It automatically detects if a dataset is 1D, 2D, or 3D. It generates contour plots, 3D volume slices, and dynamically calculates the "Open Circuit" failure risk.

generate_gnr_schematic.m: A physical rendering engine. It draws a 2D scale map of the electrodes, Voronoi domains, and GNRs. It color-codes the ribbons: Red (Target Pristine), Purple (Short Circuit), Blue/Green (Partial connection), and Yellow Stars (Defects).

plot_selected_runs.m: A highly useful UI tool. Run this locally to pop up a checklist menu of all your downloaded SimRun_ folders, allowing you to cherry-pick exactly which ones to plot.

batch_plot_all.m: A UI tool that simply runs the plotting engine on every single folder inside a selected directory.

extract_2d_slice.m: Utility to extract and plot a 2D cross-section at a specific fixed variable from a massive 3D sweep volume.

compare_convergence_runs.m: Takes multiple different convergence folders and plots their stability curves onto a single, colorblind-friendly graph for publication comparison.

5. 🛠️ Analysis & Sandboxing
analyze_gnr_results.m: A deep-dive text analyzer. Point it at a run folder, and it extracts the absolute peak yields, calculates safe manufacturing process windows, and generates a clean 00_Simulation_Parameters.txt log.

test.m: The local sandbox. Use this script on your laptop to do quick visual checks of the geometry (via generate_gnr_schematic) or to test tiny sweeps before pushing code to the supercomputer.

6. 👻 System & Ignored Files
*.asv: MATLAB autosave files. These are safely ignored by Git.

Thumbs.db: Windows thumbnail cache. Ignored by Git.

⚡ Quick Start for HPC (Euler)
Edit batch_master.m to define your desired physical sweeps.

Edit run_sim.sh and add your email address to the #SBATCH --mail-user= line.

Submit the job:

Bash
sbatch run_sim.sh
Monitor the live progress:

Bash
tail -f LIVE_MATLAB_LOG.txt