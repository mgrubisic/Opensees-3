function [ ground_motion ] = fn_define_loads( output_dir, analysis, damp_ratio, node, dimension )
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here

% Write Loads File
file_name = [output_dir filesep 'loads.tcl'];
fileID = fopen(file_name,'w');

%% Load ground motion data
gm_seq_table = readtable(['inputs' filesep 'ground_motion_sequence.csv'],'ReadVariableNames',true);
ground_motion_seq = gm_seq_table(gm_seq_table.id == analysis.gm_seq_id,:);
ground_motion_table = readtable(['inputs' filesep 'ground_motion.csv'],'ReadVariableNames',true);

%% Define Gravity Loads (node id, axial, shear, moment)
fprintf(fileID,'pattern Plain 1 Linear {  \n');
if strcmp(dimension,'2D')
    for i = 1:length(node.id) 
        fprintf(fileID,'   load %d 0.0 -%f 0.0 \n', node.id(i), node.dead_load(i)*analysis.dead_load + node.live_load(i)*analysis.live_load);
    end
elseif strcmp(dimension,'3D')
    for i = 1:length(node.id) 
        fprintf(fileID,'   load %d 0.0 -%f 0.0 0.0 0.0 0.0 \n', node.id(i), node.dead_load(i)*analysis.dead_load + node.live_load(i)*analysis.live_load);
    end
else
    error('Number of Dimensions Not Recognized')
end
fprintf(fileID,'} \n');

% Write Gravity System Analysis
fprintf(fileID,'constraints Transformation \n');
fprintf(fileID,'numberer RCM \n'); % renumber dof's to minimize band-width (optimization)
fprintf(fileID,'system BandGeneral \n'); % how to store and solve the system of equations in the analysis
fprintf(fileID,'test EnergyIncr 0.00000001 6 \n'); % determine if convergence has been achieved at the end of an iteration step
fprintf(fileID,'algorithm Newton \n');
fprintf(fileID,'integrator LoadControl 0.1 \n');
fprintf(fileID,'analysis Static	 \n');
fprintf(fileID,'analyze 10 \n');
fprintf(fileID,'loadConst -time 0.0 \n');

%% Define Static Lateral Load Pattern
% fprintf(fileID,'pattern Plain 2 Linear { \n');
% node_force = 0; % Just turn off for now
% for i = 1:length(node.id)
%     fprintf(fileID,'  load %d %f 0.0 0.0 0.0 0.0 0.0 \n', node.id(i), node_force);
% end
% fprintf(fileID,'} \n');

%% Dynamic Analysis
% Define Seismic Excitation Load
% timeSeries Path $tag -dt $dt -filePath $filePath <-factor $cFactor> <-useLast> <-prependZero> <-startTime $tStart>
% pattern UniformExcitation $patternTag $dir -accel $tsTag <-vel0 $vel0> <-fact $cFactor>
if ground_motion_seq.eq_id_x ~= 0
    ground_motion.x = ground_motion_table(ground_motion_table.id == ground_motion_seq.eq_id_x,:);
    fprintf(fileID,'timeSeries Path 1 -dt %f -filePath %s/%s -factor 386. \n',ground_motion.x.eq_dt, ground_motion.x.eq_dir{1}, ground_motion.x.eq_name{1});
    fprintf(fileID,'pattern UniformExcitation 3 1 -accel 1 -fact %f \n',ground_motion_seq.x_ratio); 
end
if ground_motion_seq.eq_id_z ~= 0
    ground_motion.z = ground_motion_table(ground_motion_table.id == ground_motion_seq.eq_id_z,:);
    fprintf(fileID,'timeSeries Path 2 -dt %f -filePath %s/%s -factor 386. \n',ground_motion.z.eq_dt, ground_motion.z.eq_dir{1}, ground_motion.z.eq_name{1});
    fprintf(fileID,'pattern UniformExcitation 4 3 -accel 2 -fact %f \n',ground_motion_seq.z_ratio); 
end
if ground_motion_seq.eq_id_y ~= 0
    ground_motion.y = ground_motion_table(ground_motion_table.id == ground_motion_seq.eq_id_y,:);
    fprintf(fileID,'timeSeries Path 3 -dt %f -filePath %s/%s -factor 386. \n',ground_motion.y.eq_dt, ground_motion.y.eq_dir{1}, ground_motion.y.eq_name{1});
    fprintf(fileID,'pattern UniformExcitation 5 2 -accel 3 -fact %f \n',ground_motion_seq.y_ratio); 
end

% Define Damping based on eigen modes
fprintf(fileID,'set lambda [eigen -fullGenLapack 3] \n');
fprintf(fileID,'puts $lambda \n');
fprintf(fileID,'set pi 3.141593\n');
fprintf(fileID,'set i 0 \n');
fprintf(fileID,'foreach lam $lambda {\n');
fprintf(fileID,'    set i [expr $i+1] \n');
fprintf(fileID,'	set omega($i) [expr sqrt($lam)]\n');
fprintf(fileID,'	set period($i) [expr 2*$pi/sqrt($lam)]\n');
fprintf(fileID,'}\n');
fprintf(fileID,'puts $period(1) \n');
fprintf(fileID,'set alpha [expr 2*%d*(1-$omega(1))/(1/$omega(1) - $omega(1)/($omega(3)*$omega(3)))]\n', .005);
fprintf(fileID,'set beta [expr 2*%d - $alpha/($omega(3)*$omega(3))]\n', .005);
if strcmp(analysis.damping,'rayleigh')
    fprintf(fileID,'rayleigh $alpha 0 $beta 0 \n'); 
elseif strcmp(analysis.damping,'modal')
    fprintf(fileID,'modalDamping %d \n',.03);
    fprintf(fileID,'rayleigh 0 $beta 0 0 \n');
else
    error('Damping Type Not Recognized')
end


%% Close File
fclose(fileID);

end

