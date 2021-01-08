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
data = zeros(length(diseaseLists),size(microbes,1),3);
diseaseCount = zeros(size(diseaseLists,1),4);
frequency = zeros(251,1);
frequency2 = zeros(1145,2);
for q = 1:size(diseaseLists)
    idxl = diseaseLists{q}(:,3);
    diseaseCount(q,1) = mean(diseaseLists{q}(:,1));
    diseaseCount(q,2) = size(diseaseLists{q},1);
    diseaseCount(q,3) = size(diseaseLists{q}(idxl == 1),1);
    diseaseCount(q,4) = -1*size(diseaseLists{q}(idxl == -1),1);
    for i = 1:diseaseCount(q,2)
        if(sum(diseaseLists{q}(i,3:4))==1)
            data(q,diseaseLists{q}(i,2),2) = 255;
        elseif(sum(diseaseLists{q}(i,3:4))==-1)
            data(q,diseaseLists{q}(i,2),1) = 255;
        end
        frequency2(diseaseLists{q}(i,2),1) = frequency2(diseaseLists{q}(i,2),1)+1;
        frequency2(diseaseLists{q}(i,2),2) = frequency2(diseaseLists{q}(i,2),2) + diseaseLists{q}(i,3);
    end
    frequency(diseaseCount(q,2)) = frequency(diseaseCount(q,2)) + 1;
end
figure(2)
bar(frequency); xlabel('Number of Microbes Associated');ylabel('Number of Disease')
title('Microbes Associated with Disease')
saveas(gcf,'FreqGraph.png')
figure(3)
bar(frequency2(:,1));xlabel('Number of Diseases Associated');ylabel('3')
figure(1)
imshow(data)
imwrite(data,'DataMatrix.png','PNG');

neurological = [135 2 217 235 201 185 226 27 137 103 244];
psychiatric = [1 198 28 219 145 25 26 24 174 98];

dList = cell(diseases(end).disease_id,1);
c = 1;
for i = 1:diseases(end).disease_id
    if(diseaseLists{c}(1) == i)
        dList{i} = diseaseLists{c};
        c = c+1;
    end
end
specifiedDiseases = neurological;
specifiedMicrobes = zeros(1145,1);
for i = specifiedDiseases
    for j = 1:size(dList{i},1)
        mic = dList{i}(j,2);
        if(1)
            specifiedMicrobes(mic) = specifiedMicrobes(mic) + 1;
        end
    end
end

for j = 1:1145
    if(j>1123)
        names(j,:) = ["" ""];
    else
        names(j,1) = string(j);
        names(j,2) = microbes(j).name;
        
    end
end
finalMatrix = [specifiedMicrobes frequency2(:,1)];
fin = [names specifiedMicrobes frequency2(:,1)];
ct = 1;
for i = 1:1145
    if(str2num(fin(i,3))~=0)
        fin2(ct,:) = fin(i,:);
        ct = ct + 1;
    end
end
finalProp = [specifiedMicrobes/size(specifiedDiseases,2) frequency2(:,1)/c];

% statistical testing:
fin_mat=fin2;
n_neuro=11;
n_diseases=236;
Z_critical=1.645;
correlation_results=[];
pos_tally=0;
neg_tally=0;
for i=1:1:181
   neuro_correlations=frequency2(i,2);
   total_correlations=str2num(fin_mat(i,4));
   p_neuro=abs(neuro_correlations/n_neuro);
   p_0=(total_correlations/n_diseases);
   Z_test=(p_neuro-p_0)*((p_0*(1-p_0)*(1/n_neuro))^(-1/2));
   if Z_test>Z_critical
       % FTR
       if neuro_correlations>2
           correlation_results=[correlation_results "1"]; % FTR
           pos_tally=pos_tally+(p_neuro/p_0);
       elseif neuro_correlations<(-2)
           correlation_results=[correlation_results "-1"]; % FTR
           neg_tally=neg_tally+(p_neuro/p_0);
       else
           correlation_results=[correlation_results "0"]; % FTR
       end
   else 
       % Reject
       correlation_results=[correlation_results "0"];
   end
end
risk_factor=(pos_tally/neg_tally)
correlation_results=(correlation_results).';
results=horzcat(fin_mat((1:end),(1:2)),correlation_results)

