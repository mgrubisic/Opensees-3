function [ node ] = fn_build_model( output_dir, node, element, story, joint, wall, hinge )
%UNTITLED6 Summary of this function goes here

%% Write TCL file
file_name = [output_dir filesep 'model.tcl'];
fileID = fopen(file_name,'w');

% Define the model (3 dimensions, 6 dof)
fprintf(fileID,'model basic -ndm 3 -ndf 6 \n');

% define nodes (inches)
for i = 1:length(node.id)
    fprintf(fileID,'node %d %f %f %f \n',node.id(i),node.x(i),node.y(i),node.z(i));
end

% set boundary conditions at each node (6dof) (fix = 1, free = 0)
for i = 1:length(node.id)
    fprintf(fileID,'fix %d %d %d %d %d %d %d \n',node.id(i),node.fix(i,1),node.fix(i,2),node.fix(i,3),node.fix(i,4),node.fix(i,5),node.fix(i,6));
end

% define nodal masses (horizontal) (k-s2/in)
for i = 1:length(node.id)
    fprintf(fileID,'mass %d %f 0. %f 0. 0. 0. \n',node.id(i), node.mass(i), node.mass(i));
end

% Linear Transformation
fprintf(fileID,'geomTransf PDelta 1 0 0 1 \n'); % Columns
fprintf(fileID,'geomTransf PDelta 2 0 0 1 \n'); % Beams (x-direction)
fprintf(fileID,'geomTransf PDelta 3 -1 0 0 \n'); % Girders (y-direction)
fprintf(fileID,'geomTransf PDelta 4 1 0 0 \n'); % Columns (y-direction)

% Define Elements (columns and beam)
% element elasticBeamColumn $eleTag $iNode $jNode $A $E $G $J $Iy $Iz $transfTag
if isfield(element,'id')
    for i = 1:length(element.id)
        fprintf(fileID,'element elasticBeamColumn %d %d %d %f %f %f %f %f %f %i \n',element.id(i),element.node_start(i),element.node_end(i),element.a(i),element.e(i),element.g(i),element.j(i),element.iy(i),element.iz(i),element.orientation(i));
    end
else
    element.id = 0;
end

% % Define Materials
% %uniaxialMaterial Elastic $matTag $E
% fprintf(fileID,'uniaxialMaterial Elastic 1 999999999. \n'); %Rigid Elastic Material
% 
% % Define Joints
% % element Joint3D %tag %Nx- %Nx+ %Ny- %Ny+ %Nz- %Nz+ %Nc %MatX %MatY %MatZ %LrgDspTag
% for i = 1:length(joint.id)
%     fprintf(fileID,'element Joint3D %i %i %i %i %i %i %i %i 1 1 1 0 \n',joint.id(i),joint.x_neg(i),joint.x_pos(i),joint.y_neg(i),joint.y_pos(i),joint.z_neg(i),joint.z_pos(i),joint.center(i));
% end

% Define Joints as rigid beam-column elements
if isfield(joint,'id')
    for i = 1:length(joint.id)
        fprintf(fileID,'element elasticBeamColumn %d %d %d 1000. 99999. 99999. 99999. 200000. 200000. 2 \n',joint.id(i)*10+1,joint.x_neg(i),joint.center(i));
        fprintf(fileID,'element elasticBeamColumn %d %d %d 1000. 99999. 99999. 99999. 200000. 200000. 2 \n',joint.id(i)*10+2,joint.center(i),joint.x_pos(i));
        fprintf(fileID,'element elasticBeamColumn %d %d %d 1000. 99999. 99999. 99999. 200000. 200000. 1 \n',joint.id(i)*10+3,joint.y_neg(i),joint.center(i));
        fprintf(fileID,'element elasticBeamColumn %d %d %d 1000. 99999. 99999. 99999. 200000. 200000. 1 \n',joint.id(i)*10+4,joint.center(i),joint.y_pos(i));
        fprintf(fileID,'element elasticBeamColumn %d %d %d 1000. 99999. 99999. 99999. 200000. 200000. 3 \n',joint.id(i)*10+5,joint.z_neg(i),joint.center(i));
        fprintf(fileID,'element elasticBeamColumn %d %d %d 1000. 99999. 99999. 99999. 200000. 200000. 3 \n',joint.id(i)*10+6,joint.center(i),joint.z_pos(i));
    end
end

% % Define Rigid Slabs
% for i = 1:length(story.id)
%     fprintf(fileID,'rigidDiaphragm 2 %s \n',num2str(story.nodes_on_slab{i}));
% end

% Define Walls Sections
if isfield(wall,'id')
    for i = 1:length(wall.id)
        element.id(end + 1) = element.id(end) + 1;
        %section ElasticMembranePlateSection $secTag $E $nu $h $rho
        fprintf(fileID,'section ElasticMembranePlateSection %i %f %f %f 0.0 \n',i,wall.e(i),wall.poisson_ratio(i),wall.thickness(i)); %Elastic Wall Section
        %element ShellMITC4 $eleTag $iNode $jNode $kNode $lNode $secTag
        fprintf(fileID,'element ShellMITC4 %i %i %i %i %i %i \n',element.id(end),wall.node_1(i),wall.node_2(i),wall.node_3(i),wall.node_4(i),i); % Model Wall as shell
    end
end

% Define Plastic Hinges
if isfield(hinge,'id')
    %uniaxialMaterial ElasticPP $matTag $E $epsyP
    fprintf(fileID,'uniaxialMaterial ElasticPP 1 1000000 0.5 \n'); % Elastic Perfectly Plastic Material
        
    for i = 1:length(hinge.id)
        element.id(end + 1) = element.id(end) + 1;
        %element zeroLength $eleTag $iNode $jNode -mat $matTag1 $matTag2 ... -dir $dir1 $dir2
        fprintf(fileID,'element zeroLength %i %i %i -mat 1 -dir 1 \n',element.id(end),hinge.node_1(i),hinge.node_2(i)); % Element Id for Hinge
    end
end

% Print model to file 
fprintf(fileID,'print -file %s/model.txt \n',output_dir);

% Close File
fclose(fileID);

end

