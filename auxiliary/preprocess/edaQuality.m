clear; clc;

%% Define paths.
rawPath = 'C:\Users\Bianca Yukari\Desktop\Social_Stressor\dataset\raw\';
goodParticipants = [];
%% Analyse each participant data 
for participant = 1:29
    if participant < 10
        edaPath = [rawPath, 'subject-00', num2str(participant), '\eda\subject-00', num2str(participant), '.eda'];
    else
        edaPath = [rawPath, 'subject-0', num2str(participant), '\eda\subject-0', num2str(participant), '.eda'];
    end
    
    data = load(edaPath, '-mat');
    %% Plot current participant graphic 
    figure;
    plot(data.edamove.eda.t, data.edamove.eda.data);
    xlabel('Tempo (s)');
    ylabel('EDA');
    title(['Séries temporais de EDA - Participante ', num2str(participant)]);
    
   %% Accept data or not
    a = input("Accept this participant s data? (s/n): ", 's');
    if strcmpi(a, 's')
        goodParticipants = [goodParticipants, participant];
    end
    
end

