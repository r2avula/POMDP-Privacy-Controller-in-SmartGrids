% Returns a threshold that defines whether
% the specified appliance is in state 'on' or 'off'
function [threshold] = getThresholdDiffOnOff(applianceID) 
    
threshold_vector = [
        15;  % fridge
        15;  % freezer
        500; % microwave
        500; % dishwasher
        15;  % entertainment
        300; % kettle
        500; % stove
        15;  % coffee machine
        500; % washing machine
        300; % dryer
        15;  % lamp
        15;  % PC
        15;  % laptop
        15;  % TV
        15;  % Stereo
        5;   % Tablet
        5;   % Router
        5;   % Illuminated fountain
    ]; % stereo

     threshold = threshold_vector(applianceID,1);
end
