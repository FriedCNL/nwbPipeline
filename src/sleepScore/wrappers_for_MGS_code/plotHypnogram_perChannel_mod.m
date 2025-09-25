function plotHypnogram_perChannel(macroCSC, samplingRate, figureName)
% plot spectrogram for selected electrodes

params.lowCut = .5;
params.highCut = 30;
params.ds_SR = 200;
scaling_factor_delta_log = 2*10^-4 ; % Additive Factor to be used when computing the Spectrogram on a log scale

figure('Name', figureName, 'NumberTitle', 'off', 'visible','off');
% set(gcf, 'PaperUnits', 'centimeters', 'PaperPosition', [0.2 0.2 21 30]); % this size is the maximal to fit on an A4 paper when printing to PDF
set(gcf, 'PaperUnits', 'centimeters', 'PaperPosition', [0.2 0.2 40 30]);

set(gcf, 'PaperOrientation', 'portrait');
set(gcf, 'Units', 'centimeters', 'Position', get(gcf, 'paperPosition')+[1 1 0 0]);
colormap('jet');
set(gcf, 'DefaultAxesFontSize', 20);
axes('position', [0.1,0.5,0.8,0.4])

flimits = [0 30];
macroCSC(isnan(macroCSC)) = 0;
data_ds = downsample_signal(macroCSC, samplingRate, params.ds_SR);
clear macroCSC;
%[b,a]=ellip(2,0.1,40,[params.lowCut params.highCut]*2/params.ds_SR);
%filteredBlock=filtfilt(b,a,data_ds);
window = 30*params.ds_SR;
[~,F,T,P]  = spectrogram(data_ds, window, 0.8*window, [0.5:0.2:flimits(2)], params.ds_SR, 'yaxis');
clear data_ds;
P = P/max(max(P));
P = (10*log10(abs(P+scaling_factor_delta_log)))';
P = [P(:,1) P P(:,end)];
T = [0 T T(end)+1];
P = imgaussfilt(P',3);

imagesc(T,F,P,[-40,-5]);axis xy;
xlimits = [0 T(end)];
xticks = 1:(60*60):T(end);
for i = 1:length(xticks)
    xlabel_str{i} = num2str(floor((xticks(i)/(60*60))));
end

yticks = 0:5:30;
axis([xlimits flimits])
set(gca,'xtick',xticks,'XTickLabel', xlabel_str)
colorbar
axis([get(gca,'xlim'), [0.5,30]])
set(gca,'ytick', [0.5,10,20,30])
YLIM = get(gca,'ylim');

hold all;

xlabel('t (hr)')
ylabel('f (Hz)')
title(extractAfter(figureName, 'ANALYSIS'));

axes('position',[0.1,0.1,0.8,0.2])

start_time = datenum('2017/10/21 00:00:00');
hh = round(diff([T(1), T(end)])/(60*60));
if hh >= 1
    mm = round(diff([T(1), T(end)])/60 - hh*60);
else
    hh = 0;
    mm = round(diff([T(1), T(end)])/60);
end
end_time = datenum(sprintf('2017/10/21 %02d:%02d:00', hh, mm));

xData = linspace(start_time,end_time,length(T));
ah = imagesc(xData, F, P, [-40,-5]); axis xy;
axis([get(gca,'xlim'),[0.5,20]])
set(gca,'ytick',[0.5,10,20])
datetick('x','HH:MM PM','keeplimits')
% set(gca,'xtick',linspace(start_time,end_time,4))
colorbar

saveas(gca, figureName);
close(gcf);

PPT_FIG = 0;
if PPT_FIG
    newA4figure(figureName)
    set(gcf,'DefaultAxesFontSize',28);
    axes('position',[0.1,0.4,0.8,0.3])
    imagesc(T,F,P,[-40,-5]);axis xy;
    hold on
    xlimits = [0 T(end)];
    xticks = 0:(60*60):T(end);
    
    set(gca,'xtick','')
    set(gca,'fontsize',28)
    XLIM = get(gca,'xlim');
    axis([get(gca,'xlim'),[0.5,30]])
    set(gca,'xtick',xticks(2:2:end),'xticklabels',{'11:00pm','03:00am','05:00am','07:00am'})
    set(gca,'ytick',[0.5,10,20])
    YLIM = get(gca,'ylim');
    ylabel('f (Hz)')
    xlabel('')
    title('')
    box off
    colorbar
    if isfield(EXP_DATA,'stimTiming')
    plot(EXP_DATA.stimTiming.validatedTTL_NLX/(1000)',YLIM(2)*0.9,'w.','markersize',10)
    end
    
    axes('position',[0.1,0.2,0.8,0.03])
    set(gca,'fontsize',28)
    if isfield(EXP_DATA,'stimTiming')
    plot(EXP_DATA.stimTiming.validatedTTL_NLX/(1000)',1,'r.','markersize',24)
    end
    
    set(gca,'xlim',XLIM)
    set(gca,'xtick',xticks(2:2:end),'xticklabels',{'11:00pm','03:00am','05:00am','07:00am'})
    set(gca,'ytick','')
    
    % PrintActiveFigs('C:\Maya\Dropbox\Conferences - Posters\2018\SFN 2018\poster\dataSets_for_Figures');
    
end

