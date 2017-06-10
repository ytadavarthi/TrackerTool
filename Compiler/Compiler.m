function Compiler
    %[fileNameMinusExt pathName] = uigetfile({'.txt'},'MultiSelect','on');
    
    %[pathName fileName ext] = fileparts([pathName fileNameMinusExt{1}]);
    
    fileNames = {'Norm030_Tsp_Pud_morphoj_' 'Norm030_Tsp_Thn_morphoj_' 'Norm141_Tsp_Pud_morphoj_' 'Norm141_Tsp_Thn_morphoj_'};
    pathName = 'C:\Users\pouri\OneDrive\Documents\MCG\research\MATLAB\Tracker\DRG2017\Compiler\';
    
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
        
        %remove extraneous frames if first and last frame are indicated:
        if isempty(classifierData{2,1}) && isempty(classifierData{2,7})
            
        elseif isempty(classifierData{2,1}) && ~isempty(classifierData{2,7})
            firstFrame = 2;
            lastFrame = str2double(classifierData{2,7});
            relevantCoordinates = coordinateData(firstFrame+1:lastFrame+1,:); 
            columnLabels = coordinateData(1,:);
            coordinateData = vertcat(columnLabels,relevantCoordinates);
            
        elseif isempty(classifierData{2,7}) && ~isempty(classifierData{2,1})
            firstFrame = str2double(classifierData{2,1});
            relevantCoordinates = coordinateData(firstFrame+1:end,:); 
            columnLabels = coordinateData(1,:);
            coordinateData = vertcat(columnLabels,relevantCoordinates);
            
        else
            firstFrame = str2double(classifierData{2,1});
            lastFrame = str2double(classifierData{2,7});
            relevantCoordinates = coordinateData(firstFrame+1:lastFrame+1,:); 
            columnLabels = coordinateData(1,:);
            coordinateData = vertcat(columnLabels,relevantCoordinates);
        end
    
        %rename ID column
        [m n k] = size(coordinateData);
            
        for j = 1:m-1
            coordinateData{j+1,1} = [fileNames{i} num2str(j)];
        end
        
        %create finalCell
        finalCell = [finalCell;coordinateData(2:end,:)];
       
    end
    finalTable = cell2table(finalCell);
    formatOut = 'dd-mm-yy HH-MM';
    date = datestr(now,formatOut);
    writetable(finalTable,['coordinates ' date '.txt'], 'Delimiter', '\t', 'WriteVariableNames', false);
end

function compile_classifierData(dataStruct, fileNames, finalCell)
    
    %Create GUI for use-input independent variables
    [~, outputData] = GUI(fileNames);

    %create first column from compile_coordinateData function
    firstColumn = finalCell(:,1);
%     
%     [m n] = size(finalCell);
    secondColumn = {};
    classifierColumns = {};
    for i = 1:length(dataStruct)
        %extract data from structure
        classifierData = dataStruct(i).classifierData;
        coordinateData = dataStruct(i).coordinateData;
        
        %create struct s that includes each classifier. i.e. s.start_frame
        %outputs start frame value.
        for j = 1:length(dataStruct(i).classifierData(1,:))
            s.(dataStruct(i).classifierData{1,j}) = str2double(dataStruct(i).classifierData{2,j});  
        end
        
        %calculate which frames are in each phase.
        Frames_preO  = s.start_frame:(s.hold_position-1);
        Frames_O     = s.hold_position:(s.hyoid_burst-1);
        Frames_P     = s.hyoid_burst:(s.ues_closure-1);
        Frames_E     = s.ues_closure:s.at_rest;
        Frames_postE = (s.at_rest+1):s.end_frame;
        
        if isempty(s.at_rest) || s.at_rest > s.end_frame
            Frames_E = s.ues_closure:s.end_frame;
        end
        
        %swallowPhaseData(:,i) = cell(m-1,1);
        swallowPhaseData(Frames_preO,i)  = {'Pre-Oral Transport'};
        swallowPhaseData(Frames_O,i)     = {'Oral Transport'};
        swallowPhaseData(Frames_P,i)     = {'Pharyngeal Stage'};
        swallowPhaseData(Frames_E,i)     = {'Esophageal Stage'};
        swallowPhaseData(Frames_postE,i) = {'Post-Esophageal Stage'};
        
        %get rid of blank cells created when start frame > 1 or when one
        %video's frames # is larger than others
        keep = ~cellfun(@isempty,swallowPhaseData(:,i));
        swallowPhaseData_no_blanks = swallowPhaseData(keep,i);
        
        %create second column
        secondColumn = [secondColumn;swallowPhaseData_no_blanks];
        
        %finds the independent variables inputted by user into uitable and
        %repeats them for every frame, creating extra long column.
        ind_vars = outputData(1+i,2:end);
        %[m n] = size(coordinateData);
        long_col_of_ind_vars = repmat(ind_vars,[length(swallowPhaseData_no_blanks),1]);
        classifierColumns = [classifierColumns;long_col_of_ind_vars];
    end
  
    %add 'Swallow Phase' to top of second column
    secondColumn = [{'Swallow Stage'}; secondColumn];
    
    %add classifier titles to classifierColumns
    classifierColumns = [outputData(1,2:end);classifierColumns];
    
    finalTable = cell2table([firstColumn secondColumn classifierColumns]);
    
    %write table with correct filename
    formatOut = 'dd-mm-yy HH-MM';
    date = datestr(now,formatOut);
    writetable(finalTable,['Classifiers ' date '.txt'], 'Delimiter', '\t', 'WriteVariableNames', false);
        
end

