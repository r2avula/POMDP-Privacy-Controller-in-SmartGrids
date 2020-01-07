function [filename,fileExists] = findFileName(params,fileNamePrefix,paramName)
fileExists = 0;
endReached = 0;
file_idx=1;
while(~endReached)
    filename = strcat(fileNamePrefix,num2str(file_idx),'.mat');
    if exist(filename, 'file')
        file_idx=file_idx+1;
    else
        endReached = 1;
    end
end
endp1filename = filename;
while(~fileExists && file_idx>1)
    file_idx=file_idx-1;
    filename = strcat(fileNamePrefix,num2str(file_idx),'.mat');
    %     variableInfo = who('-file', filename);
    %     if ismember(paramName, variableInfo)
    out = load(filename,paramName);
    if(isfield(out,paramName) && isequaln(params,out.(paramName)))
        fileExists = 1;
    end
    %     end
end
if(~fileExists)
    filename = endp1filename;
end
end