clear all; clc;
experiments = jsondecode(urlread('https://disbiome.ugent.be:8080/experiment'));
microbes = jsondecode(urlread('https://disbiome.ugent.be:8080/organism'));
diseases = jsondecode(urlread('https://disbiome.ugent.be:8080/disease'));
methods = jsondecode(urlread('https://disbiome.ugent.be:8080/method'));
publications = jsondecode(urlread('https://disbiome.ugent.be:8080/publication'));
samples = jsondecode(urlread('https://disbiome.ugent.be:8080/sample'));

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

diseaseLists = usefulData; 
[~,~,Y] = unique(diseaseLists(:,1)); 
diseaseLists = accumarray(Y,1:size(diseaseLists,1),[],@(r){diseaseLists(r,:)});
c = 1;
for q = 1:length(diseaseLists)
    if(size(diseaseLists{q},1)==1)%size(diseaseLists{c},1) == 1
        idxl = diseaseLists{q}(:,3);
        diseaseCount(c,1) = mean(diseaseLists{q}(:,1));
        %diseaseCount(c,2) = size(diseaseLists{q},1);
        diseaseCount(c,2) = size(diseaseLists{q}(idxl == 1),1);
        diseaseCount(c,3) = -1*size(diseaseLists{q}(idxl == -1),1);
        diseaseCount(c,4) = diseaseLists{q}(1,2);
        c = c+1;
    end
end
numOfDiseases = size(diseaseCount,1);
image = zeros(numOfDiseases,numOfDiseases,3);
data = zeros(numOfDiseases+1);
image(:,:) = 255;

for i = 1:numOfDiseases
    data(1,i+1) = diseaseCount(i,1);
    data(i+1,1) = diseaseCount(i,4);
    data(i+1,i+1) = sum(diseaseCount(i,2:3));
    if(data(i+1,i+1) == 1)
        image(i,i,1) = 0;
    elseif(data(i+1,i+1) == -1)
        image(i,i,2) = 0;
    end
end

fullIm = repelem(image,5,5);
imshow(fullIm)
imwrite(fullIm,'OneByOne.png','PNG');