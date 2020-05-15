% speaker_reco_demo
% Created by A. Alexander, EPFL
% Modified by J. Richiardi
% Modified by S. Yanushkevich

%ENCM 509 Lab Project Winter 2020
%Modified by Mitchell Newell
%UCID: 30006529

%define the number of Gaussian invariants - could be modified
prompt = 'Input the desired number of Gaussian invariants: ';
No_of_Gaussians = input(prompt);
if isempty(No_of_Gaussians)
    disp("No number of gaussians specified. Using default value of 10");
    No_of_Gaussians = 10;
end

%define the file format of the database audio files
prompt = 'Input the file format extension of the input data(i.e. .wav): ';
file_format = input(prompt, 's');
if isempty(file_format)
    disp("No file format specified. Using default format of .wav");
    file_format = ".wav";
end

%Define the size of the test data database
prompt = 'Input the desired size of the training database (between 1-3): ';
No_of_Training_Data = input(prompt);
if isempty(No_of_Training_Data)
    disp("No number of training data specified. Using default value of 3");
    No_of_Training_Data = 3;
end

%The number of test data inputs which is equivalent to the number of
%training data inputs
No_of_Test_Data = No_of_Training_Data;


%Reading in the data 
%Use wavread from matlab 
disp('-------------------------------------------------------------------');
disp('                    Speaker recognition Demo');
disp('                    using GMM');
disp('-------------------------------------------------------------------');

%-----------reading in the training data----------------------------------
for i = 1:No_of_Training_Data
    audioFileName = sprintf("../Database/TrainingData/0%d_train%s", i, file_format);
    [training_data, fs] = audioread(audioFileName);
    trainingData{i} = {training_data, fs};
end

%------------reading in the test data-----------------------------------
for i = 1:No_of_Test_Data
    audioFileName = sprintf("../Database/TestingData/0%d_test%s", i, file_format);
    [testing_data, fs] = audioread(audioFileName);
    testData{i} = {testing_data, fs};
end

disp('Completed reading taining and testing data (Press any key to continue)');
pause;

%-------------feature extraction------------------------------------------
for i = 1:No_of_Training_Data
    trainingFeatures{i} = melcepst(trainingData{i}{1}, trainingData{i}{2});
end
     
disp('Completed feature extraction for the training data (Press any key to continue)');
pause;

for i = 1:No_of_Test_Data
    testingFeatures{i} = melcepst(testData{i}{1}, testData{i}{2});
end

disp('Completed feature extraction for the testing data (Press any key to continue)');
pause;

%-------------training the input data using GMM-------------------------
%training input data, and creating the models required
disp('Training models with the input data (Press any key to continue)');
pause;

for i = 1:No_of_Training_Data
    [mu_train,sigma_train,c_train]=gmm_estimate((trainingFeatures{i})', No_of_Gaussians);
    trainingModels{i} = {mu_train,sigma_train,c_train};
    message = sprintf('Completed Training Speaker %d model (Press any key to continue)', i);
    disp(message);
    pause;
end

disp('Completed Training ALL Models  (Press any key to continue)');

pause;
%-------------------------testing against the input data-------------- 

%testing against the models
for i = 1:No_of_Training_Data
    for j = 1:No_of_Test_Data
        [lYM,lY] = lmultigauss((testingFeatures{j})', trainingModels{i}{1}, ...
            trainingModels{i}{2}, trainingModels{i}{3});
        A(i,j) = mean(lY);
    end
end

disp('Results in the form of confusion matrix for comparison');
disp('Each column i represents the test recording of Speaker i');
disp('Each row i represents the training recording of Speaker i');
disp('The diagonal elements corresponding to the same speaker');
disp('-------------------------------------------------------------------');
A
disp('-------------------------------------------------------------------');
% confusion matrix in color
figure; imagesc(A); colorbar;

%------------reading in the probe file names-----------------------------------
No_of_Probe_files = 1;
inputProbeFile = 'Y';
while inputProbeFile == 'Y' || inputProbeFile == 'y'
    %Define the file format of the input data
    prompt = 'Input the title of the probe sample file (with the extension): ';
    probeSample = input(prompt, 's');
    while(isempty(probeSample))
         prompt = 'Input was determined to be empty. Input the title of the probe sample file (with the extension): ';
         probeSample = input(prompt, 's');
    end
    
    probeSampleFiles{No_of_Probe_files} = probeSample;
    prompt = 'Would you like to include another probe sample file [Y/N]: ';
    inputProbeFile = input(prompt, 's');
    while(isempty(inputProbeFile))
         prompt = 'Input was determined to be empty. Would you like to include another probe sample file [Y/N]: ';
         inputProbeFile = input(prompt, 's');
    end
    testInput1 = 'Y';
    testInput2 = 'y';
    strCmp1 = strcmp(inputProbeFile, testInput1);
    strCmp2 = strcmp(inputProbeFile, testInput2);
    cmp = strCmp1 || strCmp2;
    if cmp == 0
        break;
    end
    No_of_Probe_files = No_of_Probe_files + 1;
end

%------------reading in the probe data-----------------------------------
for i = 1:No_of_Probe_files
    audioFileName = sprintf("../Database/ProbeData/%s", probeSampleFiles{i});
    %audioFileName = probeSampleFiles{i};
    [probe_data, fs] = audioread(audioFileName);
    probeData{i} = {probe_data, fs};
end
disp('Completed reading probe data (Press any key to continue)');
pause;

%-------------feature extraction------------------------------------------
for i = 1:No_of_Probe_files
    probeFeatures{i} = melcepst(probeData{i}{1}, probeData{i}{2});
end

disp('Completed feature extraction for the probe data (Press any key to continue)');
pause;

%-------------------------testing against the probe data-------------- 
%testing probe data against the training models
for i = 1:No_of_Training_Data
    for j = 1:No_of_Probe_files
        [lYM,lY] = lmultigauss((probeFeatures{j})', trainingModels{i}{1}, ...
            trainingModels{i}{2}, trainingModels{i}{3});
        B(i,j) = mean(lY);
    end
end

disp('Results in the form of confusion matrix for comparison');
disp('Each column i represents the probe recording of a speaker (not in the database)');
disp('Each row i represents the training recording model of a speaker');
disp('-------------------------------------------------------------------');
B
disp('-------------------------------------------------------------------');
% confusion matrix in color
figure; imagesc(B); colorbar;

%-------------------------Comparing confusion matices and calculating error rates--------------
falseMatches = 0;
for i = 1: No_of_Training_Data
    for j =  1:No_of_Test_Data
        if j == 1
            authenticMatchScore{i} = A(i, j);
        end
        if A(i, j) >= authenticMatchScore{i}
            authenticMatchScore{i} = A(i, j);
        end
    end
    for k = 1:No_of_Probe_files
        if B(i, k) >= authenticMatchScore{i}
            falseMatches = falseMatches + 1;
        end
    end
end

No_of_trials = No_of_Probe_files * No_of_Training_Data;
FalseMatchRate = falseMatches / No_of_trials;
TrueMatchRate = 1 - FalseMatchRate;
disp("The number of false accepts is: " + falseMatches);
disp("The calculated FAR is: " + FalseMatchRate);
disp("The true match rate is calculated to be: " + TrueMatchRate);