function Compiler
    %[fileNameMinusExt pathName] = uigetfile({'.txt'},'MultiSelect','on');
    
    %[pathName fileName ext] = fileparts([pathName fileNameMinusExt{1}]);
    
    fileNames = {'Norm030_Tsp_Pud_morphoj_' 'Norm030_Tsp_Thn_morphoj_' 'Norm141_Tsp_Pud_morphoj_' 'Norm141_Tsp_Thn_morphoj_'};
    pathName = 'C:\Users\pouri\OneDrive\Documents\MCG\research\MATLAB\Compiler\';
    
    file = [pathName fileNames{1} '.txt'];
    cell = table2cell(readtable(file,'delimiter','\t','ReadVariableNames',false));
    
    %make coordinate compiled file and classifier compiled file
    for i = 1:length(fileNames)
        file = [pathName fileNames{i} '.txt'];
        cell = table2cell(readtable(file,'delimiter','\t','ReadVariableNames',false));
                      
        coordinateData{i} = cell(3:end,:);
                
        %remove all extraneous cells in classifierData
        keep = ~cellfun(@isempty,cell(1,:));
        classifierData{i} = cell([1,2],keep);
        
    end
    dataStruct = struct('coordinateData',coordinateData,'classifierData',classifierData);
    
    finalCell = compile_coordinateData(dataStruct,fileNames);
    compile_classifierData(dataStruct,fileNames,finalCell);
    
    
end


function finalCell = compile_coordinateData(dataStruct,fileNames)
    %initialize finalCell
    finalCell = dataStruct(1).coordinateData(1,:);
    finalCell{1,1} = 'Swallow ID';
    
    %for the number of videos
    for i = 1:length(dataStruct)
        
        %extract data from structure
        classifierData = dataStruct(i).classifierData;
        coordinateData = dataStruct(i).coordinateData;
        
        %remove extraneous frames
        firstFrame = str2double(classifierData{2,1});
        lastFrame = str2double(classifierData{2,7});
        relevantCoordinates = coordinateData(firstFrame+1:lastFrame+1,:); 
        columnLabels = coordinateData(1,:);
        coordinateData = vertcat(columnLabels,relevantCoordinates);
    
        %rename ID column
        [m n k] = size(coordinateData);
            
        for j = 1:m-1
            coordinateData{j+1,1} = [fileNames{i} num2str(j)];
        end
        
        %create finalCell
        finalCell = [finalCell;coordinateData(2:end,:)];
       
    end
    finalTable = cell2table(finalCell);
    formatOut = 'dd-mm-yy';
    date = datestr(now,formatOut);
    writetable(finalTable,['coordinates ' date '.txt'], 'Delimiter', '\t', 'WriteVariableNames', false);
end

function compile_classifierData(dataStruct, fileNames, finalCell)
    
    %create first column from compile_coordinateData function
    firstColumn = finalCell(:,1);
%     
%     [m n] = size(finalCell);
    secondColumn = {};
    for i = 1:length(dataStruct)
        %extract data from structure
        classifierData = dataStruct(i).classifierData;
        coordinateData = dataStruct(i).coordinateData;
        
        %create struct s that includes each classifier. i.e. s.start_frame
        %outputs start frame value.
        for j = 1:length(dataStruct(i).classifierData(1,:))
            s.(dataStruct(i).classifierData{1,j}) = str2double(dataStruct(i).classifierData{2,j});  
        end
        
        %calculate which frames are in each phase
        Frames_preO  = s.start_frame:(s.hold_position-1);
        Frames_O     = s.hold_position:(s.hyoid_burst-1);
        Frames_P     = s.hyoid_burst:(s.ues_closure-1);
        Frames_E     = s.ues_closure:s.at_rest;
        Frames_postE = (s.at_rest+1):s.end_frame;
        
        %swallowPhaseData(:,i) = cell(m-1,1);
        swallowPhaseData(Frames_preO,i)  = {'Pre-Oral Phase'};
        swallowPhaseData(Frames_O,i)     = {'Oral Phase'};
        swallowPhaseData(Frames_P,i)     = {'Pharyngeal Phase'};
        swallowPhaseData(Frames_E,i)     = {'Esophageal Phase'};
        swallowPhaseData(Frames_postE,i) = {'post-Esophageal Phase'};
        
        %get rid of blank cells created when start frame > 1 or when one
        %video's frames # is larger than others
        keep = ~cellfun(@isempty,swallowPhaseData(:,i));
        swallowPhaseData_no_blanks = swallowPhaseData(keep,i);
        
        %create second column
        secondColumn = [secondColumn;swallowPhaseData_no_blanks];
        
    end
  
    %add 'Swallow Phase' to top of second column
    secondColumn = [{'Swallow Phase'}; secondColumn];
    
    data = [firstColumn secondColumn];
    outputTable = GUI(data);
    
%     data = [firstColumn secondColumn];
%     data{1,100} = [];
%     t = uitable();
%     t.Data = data(2:end,:);
%     t.ColumnName = data(1,:);
%     t.ColumnEditable = true;
        
end

