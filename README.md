Graphene Nanoribbon (GNR) Nematic Physics Simulator
This repository contains a high-performance Monte Carlo simulation engine to model GNR self-assembly and contact yield across nano-gap electrodes. It evaluates varying film morphologies, ribbon statistics, and manufacturing constraints to identify optimal parameter windows.

📂 Repository Scripts & Usage Guide
1. 🧠 Core Physics Engines
These functions do the heavy lifting and are generally called by other scripts rather than run manually.

run_gnr_sweep.m: The primary 3D simulation engine. It is called by passing the sweep variables and their ranges as arguments. Saves results to SimulationData.mat.

run_convergence.m: A targeted engine for high-trial statistical runs. Computes the Binomial Standard Error of the Mean (SEM) for a specific set of parameters.

2. 🎛️ Master Controllers (Batch Scripts)
Scripts used to define parameter ranges and queue simulation jobs.

batch_master.m / batch_master_2.m: Open in MATLAB, edit the parameter arrays (e.g., 10:5:30) inside the run_gnr_sweep function calls, and save. Run via SLURM on the cluster.

auto_convergence.m: Run programmatically by passing a folder name: auto_convergence('SimRun_...', 50000). It finds the peak yield in that folder and runs a convergence test.

batch_convergence.m: Run directly in the command window or via SLURM. It scans the current directory, finds completed SimRun_ folders without convergence data, and automatically processes them.

3. 🚀 Cluster Submission Scripts (SLURM)
Bash scripts to request compute resources on the Euler cluster.

run_sim.sh / run_sim_2.sh: Open the file and update #SBATCH --mail-user= with your email. Submit the job by typing sbatch run_sim.sh in the terminal.

run_convergence_sim.sh: Update the email and submit by typing sbatch run_convergence_sim.sh to run the mass convergence script.

4. 📊 Plotting & Visualization
Interactive tools to interpret .mat datasets.

sweep_info.m: Type sweep_info in the MATLAB command window. A file picker will open; select a run folder to print all available sweep dimensions and values to the console.

plot_gnr_data.m: Run with specific cross-sections using Name-Value pairs: plot_gnr_data('SimRun_...', true, 'slice_x', 20, 'slice_y', 30).

generate_gnr_schematic.m: Called internally by other scripts to render 2D physical layouts of the ribbons and electrodes.

plot_selected_runs.m: Type plot_selected_runs in the command window. Select your main downloads directory, then check the boxes for the specific runs you want to plot.

batch_plot_all.m: Type batch_plot_all. Select a parent directory, and it will sequentially generate plots for every SimRun_ folder inside it.

compare_convergence_runs.m: Type compare_convergence_runs. Use the UI to select multiple convergence runs to overlay them onto a single stability graph.

5. 🛠️ Analysis & Sandboxing
Tools for extracting hard data and testing physics constraints.

analyze_gnr_results.m: Type analyze_gnr_results in the command window. Select a folder to extract peak yields, safe manufacturing windows, generate a parameter log (00_Simulation_Parameters.txt), and plot a 1D sensitivity curve based on a UI prompt.

test.m: The local sandbox. Open in MATLAB, adjust parameters in the script, highlight the specific block of code, and press F9 to quickly test geometric limits visually before submitting long jobs.

6. 👻 System Files
.gitignore: Blocks massive data folders and logs from tracking.

*.asv / Thumbs.db: Editor autosaves and system caches. Ignored by Git.