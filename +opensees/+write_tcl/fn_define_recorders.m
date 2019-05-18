function [ ] = fn_define_recorders( write_dir, dimension, node, element, joint, hinge, analysis, hinge_grouping )
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here

% Define File Type to Write to
if analysis.write_xml
    file_type = '-xml';
    file_ext = 'xml';
else
    file_type = '-file';
    file_ext = 'txt';
end

% Write Recorder File
file_name = [write_dir, filesep 'recorders.tcl'];
fileID = fopen(file_name,'w');

fprintf(fileID,'puts "Defining Recorders ..." \n');

if ~analysis.summit
    fprintf(fileID,'setMaxOpenFiles 2000 \n');
end

%% Dynamic Recorders
if analysis.type == 1 
    % Define Node recorders
    for i = 1:height(node)
        if strcmp(dimension,'2D')
            if node.record_disp(i)
                fprintf(fileID,'recorder Node %s %s/nodal_disp_%s.%s -time -node %i -dof 1 disp \n', file_type, write_dir, num2str(node.id(i)), file_ext, (node.id(i)));
            end
            if node.record_accel(i)
                fprintf(fileID,'recorder Node %s %s/nodal_accel_%s.%s -time -node %i -dof 1 accel \n', file_type, write_dir, num2str(node.id(i)), file_ext, (node.id(i)));
            end
        elseif strcmp(dimension,'3D')
            if node.record_disp(i)
                fprintf(fileID,'recorder Node %s %s/nodal_disp_%s.%s -time -node %i -dof 1 3 disp \n', file_type, write_dir, num2str(node.id(i)), file_ext, (node.id(i)));
            end
            if node.record_accel(i)
                fprintf(fileID,'recorder Node %s %s/nodal_accel_%s.%s -time -node %i -dof 1 3 accel \n', file_type, write_dir, num2str(node.id(i)), file_ext, (node.id(i)));
            end
        end
    end
    
    % Nodal Reaction Recorders
    base_nodes = node.id(node.y == 0);
    fprintf(fileID,'recorder Node %s %s/nodal_base_reaction_x.%s -time -node %s -dof 1 reaction \n', file_type, write_dir, file_ext, num2str(base_nodes'));
    if strcmp(dimension,'3D')
        fprintf(fileID,'recorder Node %s %s/nodal_base_reaction_z.%s -time -node %s -dof 3 reaction \n', file_type, write_dir, file_ext, num2str(base_nodes'));
    end

    % Define Element Recorders
    % recorder Element <-file $fileName> <-time> <-ele ($ele1 $ele2 ...)> <-eleRange $startEle $endEle> <-region $regTag> <-ele all> ($arg1 $arg2 ...)
    for i = 1:height(element)
        if strcmp(dimension,'2D')
            fprintf(fileID,'recorder Element %s %s/element_force_%s.%s -time -ele %i localForce \n', file_type, write_dir, num2str(element.id(i)), file_ext, element.id(i));
        else
            fprintf(fileID,'recorder Element %s %s/element_force_%s.%s -time -ele %i localForce \n', file_type, write_dir, num2str(element.id(i)), file_ext, element.id(i));
        end
    end
    
    % Hinges
    if analysis.nonlinear ~= 0 && ~isempty(hinge)
        % Rotational Hinges x direction - primary
        hinge_ids = element.id(end) + hinge.id(strcmp(hinge.ele_direction,'x') & strcmp(hinge.direction,'primary') & strcmp(hinge.type,'rotational'));
        if ~isempty(hinge_ids)
            fprintf(fileID,'recorder Element %s %s/hinge_moment_x.%s -time -ele %s -dof 6 force \n', file_type, write_dir, file_ext, num2str(hinge_ids'));
            fprintf(fileID,'recorder Element %s %s/hinge_rotation_x.%s -time -ele %s deformation \n', file_type, write_dir, file_ext, num2str(hinge_ids'));
        end
        if strcmp(dimension,'3D')
            % Rotational Hinges x direction - oop
            hinge_ids = element.id(end) + hinge.id(strcmp(hinge.ele_direction,'x') & strcmp(hinge.direction,'oop') & strcmp(hinge.type,'rotational'));
            if ~isempty(hinge_ids)
                fprintf(fileID,'recorder Element %s %s/hinge_moment_x_oop.%s -time -ele %s -dof 4 force \n', file_type, write_dir, file_ext, num2str(hinge_ids'));
                fprintf(fileID,'recorder Element %s %s/hinge_rotation_x_oop.%s -time -ele %s deformation \n', file_type, write_dir, file_ext, num2str(hinge_ids'));
            end
            
            % Rotational Hinges z direction - oop
            hinge_ids = element.id(end) + hinge.id(strcmp(hinge.ele_direction,'z') & strcmp(hinge.direction,'oop') & strcmp(hinge.type,'rotational'));
            if ~isempty(hinge_ids)
                fprintf(fileID,'recorder Element %s %s/hinge_moment_z_oop.%s -time -ele %s -dof 6 force \n', file_type, write_dir, file_ext, num2str(hinge_ids'));
                fprintf(fileID,'recorder Element %s %s/hinge_rotation_z_oop.%s -time -ele %s deformation \n', file_type, write_dir, file_ext, num2str(hinge_ids'));
            end

            % Shear Hinges z direction 
            hinge_ids = element.id(end) + hinge.id(strcmp(hinge.ele_direction,'z') & strcmp(hinge.direction,'primary') & strcmp(hinge.type,'shear'));
            if ~isempty(hinge_ids)
                fprintf(fileID,'recorder Element %s %s/hinge_shear_z.%s -time -ele %s -dof 3 force \n', file_type, write_dir, file_ext, num2str(hinge_ids'));
                fprintf(fileID,'recorder Element %s %s/hinge_deformation_z.%s -time -ele %s deformation \n', file_type, write_dir, file_ext, num2str(hinge_ids'));
            end
        end
    end
    
%% Pushover and Cyclic Recorders
elseif analysis.type == 2 || analysis.type == 3 
    % Nodal Displacement Recorders
    if strcmp(analysis.pushover_direction,'x')
        for i = 1:height(node)
            if node.record_disp(i)
                fprintf(fileID,'recorder Node %s %s/nodal_disp_x_%s.%s -time -node %i -dof 1 disp \n', file_type, write_dir, num2str(node.id(i)), file_ext, (node.id(i)));
            end
        end
        for i = 1:height(element)
            fprintf(fileID,'recorder Element %s %s/element_force_x_%s.%s -time -ele %i localForce \n', file_type, write_dir, num2str(element.id(i)), file_ext, element.id(i));
        end
    elseif strcmp(analysis.pushover_direction,'z')
        for i = 1:height(node)
            if node.record_disp(i)
                fprintf(fileID,'recorder Node %s %s/nodal_disp_z_%s.%s -time -node %i -dof 3 disp \n', file_type, write_dir, num2str(node.id(i)), file_ext, (node.id(i)));
            end
        end
        for i = 1:height(element)
            fprintf(fileID,'recorder Element %s %s/element_force_z_%s.%s -time -ele %i localForce \n', file_type, write_dir, num2str(element.id(i)), file_ext, element.id(i));
        end
    end
    
    % Nodal Reaction Recorders
    base_nodes = node.id(node.y == 0);
    if strcmp(analysis.pushover_direction,'x')
        fprintf(fileID,'recorder Node %s %s/nodal_base_reaction_x.%s -time -node %s -dof 1 reaction \n', file_type, write_dir, file_ext, num2str(base_nodes'));
    elseif strcmp(analysis.pushover_direction,'z')
        fprintf(fileID,'recorder Node %s %s/nodal_base_reaction_z.%s -time -node %s -dof 3 reaction \n', file_type, write_dir, file_ext, num2str(base_nodes'));
    end
    
    % Hinges
    if analysis.nonlinear ~= 0 && ~isempty(hinge)
        if strcmp(analysis.pushover_direction,'x')
            % Rotational Hinges x direction - primary
            hinge_ids = element.id(end) + hinge.id(strcmp(hinge.ele_direction,'x') & strcmp(hinge.direction,'primary') & strcmp(hinge.type,'rotational'));
            if ~isempty(hinge_ids)
                fprintf(fileID,'recorder Element %s %s/hinge_moment_x.%s -time -ele %s -dof 6 force \n', file_type, write_dir, file_ext, num2str(hinge_ids'));
                fprintf(fileID,'recorder Element %s %s/hinge_rotation_x.%s -time -ele %s deformation \n', file_type, write_dir, file_ext, num2str(hinge_ids'));
            end
        elseif strcmp(analysis.pushover_direction,'z')
            % Rotational Hinges x direction - oop
            hinge_ids = element.id(end) + hinge.id(strcmp(hinge.ele_direction,'x') & strcmp(hinge.direction,'oop') & strcmp(hinge.type,'rotational'));
            if ~isempty(hinge_ids)
                fprintf(fileID,'recorder Element %s %s/hinge_moment_x_oop.%s -time -ele %s localForce \n', file_type, write_dir, file_ext, num2str(hinge_ids'));
                fprintf(fileID,'recorder Element %s %s/hinge_rotation_x_oop.%s -time -ele %s deformation \n', file_type, write_dir, file_ext, num2str(hinge_ids'));
            end
            
            % Rotational Hinges z direction - oop
            hinge_ids = element.id(end) + hinge.id(strcmp(hinge.ele_direction,'z') & strcmp(hinge.direction,'oop') & strcmp(hinge.type,'rotational'));
            if ~isempty(hinge_ids)
                fprintf(fileID,'recorder Element %s %s/hinge_moment_z_oop.%s -time -ele %s -dof 6 force \n', file_type, write_dir, file_ext, num2str(hinge_ids'));
                fprintf(fileID,'recorder Element %s %s/hinge_rotation_z_oop.%s -time -ele %s deformation \n', file_type, write_dir, file_ext, num2str(hinge_ids'));
            end

            % Shear Hinges z direction 
            hinge_ids = element.id(end) + hinge.id(strcmp(hinge.ele_direction,'z') & strcmp(hinge.direction,'primary') & strcmp(hinge.type,'shear'));
            if ~isempty(hinge_ids)
                fprintf(fileID,'recorder Element %s %s/hinge_shear_z.%s -time -ele %s -dof 3 force \n', file_type, write_dir, file_ext, num2str(hinge_ids'));
                fprintf(fileID,'recorder Element %s %s/hinge_deformation_z.%s -time -ele %s deformation \n', file_type, write_dir, file_ext, num2str(hinge_ids'));
            end
        end
    end
end

%% Joints
% if ~isempty(joint)
%     fprintf(fileID,'recorder Element %s %s/joint_force_all.%s -time -ele %s force \n', file_type, write_dir, file_ext, num2str(joint.id' + 10000));
%     fprintf(fileID,'recorder Element %s %s/joint_deformation_all.%s -time -ele %s deformation \n', file_type, write_dir, file_ext, num2str(joint.id' + 10000));
% end

%% Movie Recorders
if analysis.play_movie
    fprintf(fileID,'recorder display "Displaced shape" 10 10 500 500 -wipe \n');
    fprintf(fileID,'prp 200.0 50.0 50.0; \n');
    fprintf(fileID,'vup 0.0 1.0 0.0; \n');
    if strcmp(dimension,'2D')
        fprintf(fileID,'vpn 0.0 0.0 1.0; \n');
    else
        fprintf(fileID,'vpn 0.4 0.25 1; \n');
    end
    %     fprintf(fileID,'viewWindow -1000 1000 -1000 1000 \n');
    fprintf(fileID,'display 1 5 %f \n',analysis.movie_scale);
end

if ~analysis.suppress_outputs
    fprintf(fileID,'puts "Defining Recorders Complete" \n');
end

% Close File
fclose(fileID);

end

