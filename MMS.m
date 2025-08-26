%%% M/M/S Queue Simulation Program

clear all; clc;

%% =========== Simulation  ================================================

simResult = [];
iter      = 0;

for pax = 100:100:1000

    %% ========= set variable =================================================

    PaxN       = pax; % number of pax

    avg_Flight_time_Of_UAM_min = 4.42;
    TurnAroundTime_min = 10;
    serviceTime_min    = avg_Flight_time_Of_UAM_min*2+TurnAroundTime_min*2;

    mu         = 1/serviceTime_min ; % service rate
    operation_H = 17;
    lambda = PaxN/(operation_H*60); % birth rate


    targetTime = 20; %maximum waiting time

    iter = iter + 1;

    %% =========== Generate Pax ===============================================

    intArrivalTime = round(exprnd(1/lambda, [1 PaxN]),0);
    % serviceTime    = round(exprnd(1/mu, [1 PaxN]),0);

    arrTimeWindow    = zeros(1,PaxN);
    arrTimeWindow(1) = intArrivalTime(1);

    % depTimeWindow    = zeros(1,PaxN);
    % depTimeWindow(1) = intArrivalTime(1) + serviceTime(1);

    for p = 2:PaxN

        arrTimeWindow(p) = arrTimeWindow(p-1) + intArrivalTime(p);
        %     depTimeWindow(p) = arrTimeWindow(p)   + serviceTime(p);

    end

    arrTimeWindow(arrTimeWindow>operation_H*60) = [];

    timeWindow      = arrTimeWindow';
    timeWindow(:,2) = [1:length(timeWindow)];
    stateWindow = cell(length(arrTimeWindow),1);
    stateWindow(:) = {'ARR'};
    stateWindow(:,2) = num2cell([1:length(stateWindow)]);


    %% =========== initialization ===============================================

    serverNum        = 1;
    availServer      = serverNum;
    Queue            = [];
    completeCustomer = 0;
    customer         = [];
    customer(:,1)    = [1:PaxN];
    
    %% =========== start Simulation ==============================================

    for t = 1:operation_H*60

        currentTime = t;

        [t, r] = sort(timeWindow(:,1));

        timeWindow(:,1) = t;
        timeWindow(:,2) = timeWindow(r, 2);

        stateWindow(:,1:2) = stateWindow(r,1:2);

        if sum(timeWindow(:,1)==currentTime)>0

            Idx = find(timeWindow(:,1)==currentTime);

            for i = 1:length(Idx)

                if strcmp(stateWindow(Idx(i),1), 'ARR')

                    if availServer > 0
                        % put into server, make service time
                        serviceTime = round(exprnd(1/mu));
                        depTime     = currentTime+serviceTime;

                        timeWindow(end+1,:)  = [depTime, timeWindow(Idx(i),2)];
                        stateWindow(end+1,:) = [{'DEP'}, stateWindow(Idx(i),2)];


                        %                     customer(Idx(i),1) = Idx(i);
                        customer(timeWindow(Idx(i),2),2) = currentTime;
                        customer(timeWindow(Idx(i),2),3) = serviceTime;
                        customer(timeWindow(Idx(i),2),4) = depTime;

                        availServer = availServer-1;
                    else
                        % put into Queue
                        newQueue         = [currentTime, timeWindow(Idx(i),2), currentTime]; %[arrTime, cusIdx, waitTime]
                        Queue            = [Queue; newQueue];

                        Queue(:,3)       = currentTime-Queue(:,1); %waitingTime update

                        if max(Queue(:,3))>targetTime

                            serverNum = serverNum + 1;

                            serviceTime = round(exprnd(1/mu));
                            depTime     = currentTime + serviceTime;

                            timeWindow(end+1,:)  = [depTime, Queue(1,2)];
                            stateWindow(end+1,:) = [{'DEP'}, Queue(1,2)];

                            %                         customer(Queue(1,2),1) = Queue(1,2);
                            customer(Queue(1,2),2) = Queue(1,1);
                            customer(Queue(1,2),3) = serviceTime;
                            customer(Queue(1,2),4) = depTime;

                            Queue(1,:)       = [];

                        end %if max(Queue(:,3))>targetTime

                    end %if availServer > 0

                else
                    % DEP case
                    completeCustomer = completeCustomer+1;

                    if ~isempty(Queue)

                        serviceTime = round(exprnd(1/mu));
                        depTime     = currentTime + serviceTime;

                        timeWindow(end+1,:)  = [depTime, Queue(1,2)];
                        stateWindow(end+1,:) = [{'DEP'}, Queue(1,2)];

                        customer(Queue(1,2),2) = Queue(1,1);
                        customer(Queue(1,2),3) = serviceTime;
                        customer(Queue(1,2),4) = depTime;

                        Queue(1,:)       = [];

                    else
                        availServer = availServer+1;

                    end %if ~isempty(Queue)

                end %if strcmp(stateWindow(Idx(i),1), 'ARR')

            end %for i = 1:length(Idx)

        end %if ~isempty((timeWindow(:,1)==currentTime))

    end %for t = 1:operation_H*60

%     completeCustomer
%     serverNum

    % calculate average waiting time, average service time

    % customer = [customerIdx, arrivalTime, serviceTime, departureTime]

    %% =========== set Result ===============================================

    customer(:,5) = customer(:,4) - (customer(:,2)+customer(:,3)); % waiting time
    customer(:,6) = customer(:,4) - customer(:,2); %system time

    avgWaitTime    = mean(customer(:,5));
    avgServiceTime = mean(customer(:,3));
    avgSystemTime  = mean(customer(:,6));

    iterResult     = [iter, PaxN, completeCustomer, serverNum, avgWaitTime, avgServiceTime, avgSystemTime];

    simResult      = [simResult; iterResult];

end