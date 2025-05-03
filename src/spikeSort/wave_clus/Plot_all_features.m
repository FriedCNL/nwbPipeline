function Plot_all_features(handles)

USER_DATA = get(handles.wave_clus_figure,'userdata');
par = USER_DATA{1};
inspk = USER_DATA{7};
classes = USER_DATA{6};

colors = [ ...
    0 0 1 ;  % 1  blue % don't need black first for aux! Otherwise it misindexes and repeats green on aux
    1 0 0 ;  % 2  red
    0 1 0 ;  % 3  green
    0.00 0.60 0.60 ;  % 4  teal  (dark cyan)
    0.70 0.70 0.00 ;  % 5  mustard (dark yellow)
    0.55 0.27 0.07 ;  % 6  brown
    0.50 0.00 0.50 ;  % 7  purple
    0.93 0.57 0.13 ;  % 8  orange
    0.40 0.55 0.65 ;  % 9  slate / gray-blue
    0.83 0.68 0.21 ;  % 10 gold
    0.30 0.30 0.30 ;  % 11 dark gray
    0.20 0.80 0.80 ; % 12 aqua-green
];
nColors = size(colors,1);

f1 = findobj('name', 'ProjectionsPlot');
if isempty(f1)
    f1 = figure('name', 'ProjectionsPlot');
else
    ch = get(f1,'children');
    delete(ch);
end
nclasses = max(classes);
inputs = min(size(inspk,2), 12);
for i=1:inputs
    for j=i+1:inputs
        ax(i,j) = subplot2(inputs, inputs, i, j, 'borderpct', .0001, 'parent', f1);
%         subplot(inputs,inputs,(i-1)*inputs+j)
        hold on
        for k=1:nclasses
            class_aux = find(classes==k);
            max_spikes = min(par.max_spikes, length(class_aux));
            inds = randsample(class_aux, max_spikes);
            % --- inside the innermost loop, replace the old plot call ---
            colIdx = mod(k, nColors-1);              % cluster-1 → blue row
            plot(inspk(inds,i), inspk(inds,j), '.', ...
                 'Color', colors(colIdx,:), 'MarkerSize', 0.5);

            % plot(inspk(inds,i), inspk(inds,j), ['.' colors(k)], 'markersize', .5) % old
%             plot(inspk(class_aux(1:max_spikes),i),inspk(class_aux(1:max_spikes),j),...
%                 ['.' colors(k)],'markersize',.5) % old old?
            axis off
        end
    end
end

pv = makePosVecFunction(2,2,.01,.01,.025);
f = uipanel('parent',f1,'units','normalized','position',pv(1,1,2,1));
syncBox = uicontrol('parent',f1,'units','normalized',...
    'position',pv(2,.25,2,.15),'style','checkbox','string','Sync','value',1);
cutOnThisButton = uicontrol('parent',f1,'units','normalized',...
    'position',pv(1,.25,1,.15),'style','pushbutton','string','cutOnTheseFeatures');
exploreProjections(f, ax, syncBox, cutOnThisButton);
