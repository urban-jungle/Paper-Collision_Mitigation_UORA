close all;

tic;


Sta_num = 10:10:200;

ocw_val = [8, 256;];

final_result1 = CM_UORA(8,256);
toc;

results = {'Idle RU', 'Success of RU', 'Collision ratio of RU', 'Access ratio of Station', 'Success ratio of Station', 'Collision ratio of Station', 'Avg Throughput', 'Throughput(Mbps)', "Jain's Fairness", 'Channel Efficiency'};
ylim_val = [
    [0 1];
    [0 1];
    [0.1 0.7];
    [0 1];
    [0 1];
    [0.4 0.9];
    [0 10];
    [12 20];
    [0.9 1];
    [0 0.4];
];
colors = {'r', 'b', 'k'};

for i = 1:9
    figure;
    hold on;
    plot(final_result1(1, Sta_num, i), strcat(colors{1}, '-x'));
    ylim(ylim_val(i,:));
    xlabel('단말 수');
    ylabel(results{i});
    legend(['CM UORA (', num2str(ocw_val(1, 1)), ',', num2str(ocw_val(1, 2)), ')']); 
    xlim ([1, 20]);
    xticks(1:length(Sta_num));
    xticklabels(Sta_num);
    grid on;
    hold off;
end

toc;