%% Download Disbiome database and stores as excel file
clear all; close all; clc;
% First sheet is experiments
% Second sheet is microbes
% Third sheet is diseases
% Fourth sheet is methods
% Fifth sheet is publications
% Sixth sheet is samples
% Seventh sheet is microbe information
% Eighth sheet is disease information

%% Step 1: Download Disbiome data as structures
experiments = jsondecode(urlread('https://disbiome.ugent.be:8080/experiment'));
microbes = jsondecode(urlread('https://disbiome.ugent.be:8080/organism'));
diseases = jsondecode(urlread('https://disbiome.ugent.be:8080/disease'));
methods = jsondecode(urlread('https://disbiome.ugent.be:8080/method'));
publications = jsondecode(urlread('https://disbiome.ugent.be:8080/publication'));
samples = jsondecode(urlread('https://disbiome.ugent.be:8080/sample'));

%% Step 2: Convert structures to cells for import to excel
experimentsNames = fieldnames(experiments)';
temp = struct2cell(experiments)';
experimentsCell = [experimentsNames; temp]; 

microbeNames = fieldnames(microbes)';
temp = struct2cell(microbes)';
microbesCell = [microbeNames; temp];

diseasesNames = fieldnames(diseases)';
temp = struct2cell(diseases)';
diseasesCell = [diseasesNames; temp];

methodsNames = fieldnames(methods)';
temp = struct2cell(methods)';
methodsCell = [methodsNames; temp];

publicationsNames = fieldnames(publications)';
temp = struct2cell(publications)';
publicationsCell = [publicationsNames; temp];

samplesNames = fieldnames(samples)';
temp = struct2cell(samples)';
samplesCell = [samplesNames; temp];

%% Step 3: Preprocess data for correlation of microbes to disease
% usefulData(1) - Disease ID
% usefulData(2) - organism ID
% usefulData(3) - qualitative outcome
usefulData = zeros(length(experiments),4);
for q = 1:length(experiments)
    usefulData(q,1) = experiments(q).disease_id;
    usefulData(q,2) = experiments(q).organism_id;
end

s1 = 'Elevated'; s2 = 'Reduced';
for q = 1:length(experiments)
    tf1 = strcmp(experiments(q).qualitative_outcome,s1);
    tf2 = strcmp(experiments(q).qualitative_outcome,s2);
    if tf1 == 1
        usefulData(q,3) = 1;
    elseif tf2 == 1
        usefulData(q,3) = -1;
    else
        usefulData(q,3) = 0;
    end
end

%% Step 4: Create dataset of microbes and associated information
% 1) Microbe ID
% 2) Total number of associated diseases
% 3) number of negative influences
% 4) number of positive influences

microbeLists = usefulData;
[~,~,Y] = unique(microbeLists(:,2)); 
microbeLists = accumarray(Y,1:size(microbeLists,1),[],@(r){microbeLists(r,:)});
for q = 1:length(microbeLists)
    microbeCount(q,1) = mean(microbeLists{q}(:,2));
    microbeCount(q,2) = size(microbeLists{q},1);
end
micidx = usefulData(:,2);
idx2 = usefulData(:,3);
microbeData = zeros(size(microbeCount,1),4);
microbeData(:,1:2) = microbeCount(:,:);
for i = 1:length(microbeData)
    mic = microbeData(i,1);
    upMics = (micidx == mic) & (idx2 == 1);
    downMics = (micidx == mic) & (idx2 == -1);
    microbeData(i,3) = sum(upMics); % number of up influences (bad influences)
    microbeData(i,4) = sum(downMics); % number of down influences (good influences)
end


%% Step 6: Create dataset of diseases and associated information
% 1) Disease ID
% 2) Total number of associated microbes
% 3) number of negative influences
% 4) number of positive influences
diseaseLists = usefulData; 
[~,~,Y] = unique(diseaseLists(:,1)); 
diseaseLists = accumarray(Y,1:size(diseaseLists,1),[],@(r){diseaseLists(r,:)});
for q = 1:length(diseaseLists)
    idxl = diseaseLists{q}(:,3);
    diseaseCount(q,1) = mean(diseaseLists{q}(:,1));
    diseaseCount(q,2) = size(diseaseLists{q},1);
    diseaseCount(q,3) = size(diseaseLists{q}(idxl == 1),1);
    diseaseCount(q,4) = size(diseaseLists{q}(idxl == -1),1);
end

%% Step 7: Save data in excel
filename = 'disbiome.xlsx';
xlswrite(filename,experimentsCell,1,'A1');
xlswrite(filename,microbesCell,2,'A1');
xlswrite(filename,diseasesCell,3,'A1');
xlswrite(filename,methodsCell,4,'A1');
xlswrite(filename,publicationsCell,5,'A1');
xlswrite(filename,samplesCell,6,'A1');
xlswrite(filename,microbeData,7,'B2');
xlswrite(filename,diseaseCount,8,'B2');
clc;

