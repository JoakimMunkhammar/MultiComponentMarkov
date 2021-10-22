%                     MultiComponentNstate.m
%--------------------------------------------------------------
%                Dr. Joakim Munkhammar, PhD, 2021
%
% This code uses the multiple-component N-state Markov-chain 
% mixture distribution model published in:
%
% Munkhammar J., Widén J., A spatiotemporal Markov-chain 
% mixture distribution model of the clear-sky index, Solar 
% Energy, 179, 398-409, 2019.
%
% This code trains the model on time-series of two components 
% of global, beam and diffuse clear-sky index to generate two 
% correlated time-series of the components. 

clear

% Importing data on global, beam and diffuse clear-sky 
% indices, the data file "GHIBHIDHI_Synth_data.txt"
% is a mock-up synthetic data set for illustration of
% the model.
InputData = importdata('GHIBHIDHI_Synth_data.txt');

% Set the training data sets
GHITrain = InputData(1,:);
BHITrain = InputData(2,:);
DHITrain = InputData(3,:);

N=30; % N number of states
T=43680; % T number of output time-steps
Prob=0.0000000001; % P_b, base probability in transition matrix
All2(1,:) = BHITrain(:); % Assign the training time-series 1
All2(2,:) = DHITrain(:); % Assign the training time-series 2
for k=1:2 % Make State the discrete "state" double time-series
    State(:,k)=floor(N*All2(k,:)/max(All2(k,:)))+1;
    State(State(:,k)<1,k)=1;
    State(State(:,k)>N,k)=N;
end
P=zeros(N,N,N,N); % Initial setting of the transition matrix
for t=1:size(All2,2)-1 % Train the transition matrix P
    P(State(t,1),State(t,2),State(t+1,1),State(t+1,2)) = P(State(t,1),State(t,2),State(t+1,1),State(t+1,2))+1;
end
P=P+Prob*ones(N,N,N,N); % Add base probability to remove zero rows, columns and sub-matrices
NewState = zeros(T,2); % Initial settings
Statei(1:2) = State(1,1:2); % Initial settings
for t=1:T % The loop for creating double output time-series NewDist
    % Normalizing the transition matrix
    Pnew = squeeze(P(Statei(1),Statei(2),:,:))./sum(sum(squeeze(P(Statei(1),Statei(2),:,:))));
    Pnew2 = reshape(Pnew,[1,N^2]); % Reshaping the transition matrix
    Prow = zeros(N^2,1); % Initial setting of the CDF of the transition matrix
    for i=1:N^2 % Make a CDF of the transition matrix
        Prow(i+1) = sum(Pnew2(1:i));
    end
    position = find(Prow(:)<rand(1),1,'last'); % Sample from the CDF
    positionmat = zeros(N^2,1); % Initial setting
    positionmat(position) = 1; % Setting the matrix position
    positionmat = reshape(positionmat,[N,N]); % Reshaping the matrix
    [Statei(1),Statei(2)] = find(positionmat==1); % Express the sample as states   
    NewState(t,:) = Statei(:); % NewState is the new state at time t for each component
end
% Add the random uniform number (from each emission probability)
% NewDist(:,1) is the output time-series of the first component,
% NewDist(:,2) is the output time-series of the second component.
NewDist(:,1) = max(BHITrain)*(NewState(:,1)-1)/N+(1/N)*(max(BHITrain)-min(BHITrain))*rand(T,1);
NewDist(:,2) = max(DHITrain)*(NewState(:,2)-1)/N+(1/N)*(max(DHITrain)-min(DHITrain))*rand(T,1);

% Save the output time-series 
%save BHIDHI_synthetic_output.txt NewDist -ascii
