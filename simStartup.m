function path_to_sm_data = simStartup()
pathCell = regexp(path, pathsep, 'split');
test_dir = [pwd filesep 'util'];
onPath = any(strcmpi(test_dir, pathCell));

if (~onPath)        
    path(pathdef);
    addpath(genpath('util'));
    addpath(genpath('config'));    
end
path_to_sm_data = [pwd filesep 'data'];
rng(0,'twister');
end
