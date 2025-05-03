function mark_clusters_temperature_diagram(handles, newData)
% MARK CLUSTERS IN TEMPERATURE DIAGRAM
% EM: added 'newData' as a var. When we're loading new data, clear the plot
% and make the diagram, but no need to do so for data that's already been
% loaded.

[tree, clustering_results] = getUserData([5, 10]);

% handles.min_clus = clustering_results(1,5);
temperature = tree(clustering_results(1,1)+1,2);

if ~exist('newData','var')||isempty(newData)
    newData = 0;
end

% creates cluster-temperature vector to plot in the temperature diagram
nclasses = max(clustering_results(clustering_results(:,2)<1000, 2));
if nclasses == 0
    return
end

clustering_results(:, 2) = shrinkClassIndex(clustering_results(:, 2));
clustering_results(:, 4) = shrinkClassIndex(clustering_results(:, 4));

% if length(unique(clustering_results(:,2))) < nclasses
% i=1;
% while i<= nclasses
%     if sum(clustering_results(:,2)==i)==0
%         indsToSubtract = clustering_results(:,2)>i;
%         clustering_results(indsToSubtract,[2 4]) = clustering_results(indsToSubtract,[2 4]) - 1;
%         nclasses = nclasses-1;
%     else
%         i=i+1;
%     end
% end
% end

for i=1:nclasses
    ind = find(clustering_results(:,2)==i);
    classgui_plot(i) = clustering_results(ind(1),2);
    class_plot(i) = clustering_results(ind(1),4);
    temp_plot(i) = clustering_results(ind(1),3);
end

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
% colors = ['b' 'r' 'g' 'c' 'm' 'y' 'b' 'r' 'g' 'c' 'm' 'y' 'b' 'k' 'b' 'r' 'g' 'c' 'm' 'y' 'b' 'r' 'g' 'c' 'm' 'y' 'b' 'k' 'b' 'r' 'g' 'c' 'm' 'y' 'b' 'r' 'g' 'c' 'm' 'y' 'b'];
nColors = size(colors,1);

% draw temperature diagram and mark clusters
handles.par.num_temp = min(handles.par.num_temp,size(tree,1));
if newData
    cla(handles.temperature_plot);
end
hold(handles.temperature_plot,'on')
switch handles.par.temp_plot
    case 'lin'
        % draw diagram
        set(handles.temperature_plot,'ColorOrder',colors,'ColorOrderIndex',1)
        plot(handles.temperature_plot,[handles.par.mintemp handles.par.maxtemp-handles.par.tempstep],[handles.par.min.clus2 handles.par.min.clus2],'k:',...
            handles.par.mintemp+(1:handles.par.num_temp)*handles.par.tempstep, ...
            tree(1:handles.par.num_temp,5:size(tree,2)),[temperature temperature],[1 tree(1,5)],'k:')
        % mark clusters
        hold on
        for i=1:length(class_plot)
            colIdx = mod(i-1, nColors)+1; % JS added
            tree_clus = tree(temp_plot(i),4+class_plot(i));
            tree_temp = tree(temp_plot(i)+1,2);
            plot(handles.temperature_plot,tree_temp,tree_clus,'.', ...
                'Color', colors(colIdx,:), ...%'color',num2str(colors(classgui_plot(i))),...
                'MarkerSize',20);
            % text(tree_temp,tree_clus,num2str(classgui_plot(i)));
        end
        hold off

    case 'log'
        if newData
        % draw diagram
        set(handles.temperature_plot,'ColorOrder',colors,'ColorOrderIndex',1)
        semilogy([handles.par.mintemp handles.par.maxtemp-handles.par.tempstep], ...
           [handles.min_clus handles.min_clus],'k:',...
           handles.par.mintemp+(1:handles.par.num_temp)*handles.par.tempstep, ...
           tree(1:handles.par.num_temp,5:size(tree,2)),[temperature temperature],[1 tree(1,5)],'k:',...
           'parent',handles.temperature_plot)
       set(handles.temperature_plot,'yscale','log')
       end
       % mark clusters
       hold on
       for i=1:length(class_plot)
           try
           colIdx = mod(i-1, nColors)+1; % JS added
           tree_clus = tree(temp_plot(i),4+class_plot(i));
           tree_temp = tree(temp_plot(i)+1,2);
           semilogy(tree_temp,tree_clus,'.',...
               'Color', colors(colIdx,:), ...%'color',num2str(colors(classgui_plot(i))),...
               'MarkerSize',20, ...
               'parent',handles.temperature_plot);
           % text(tree_temp,tree_clus,num2str(classgui_plot(i)));
           end
       end
       hold off
end
xlim(handles.temperature_plot, [0 handles.par.maxtemp])
xlabel('Temperature');
set(handles.min_clus_edit, 'string', handles.min_clus);

if strcmp(handles.par.temp_plot, 'log')
    set(get(handles.temperature_plot,'ylabel'),'vertical','Cap');
else
    set(get(handles.temperature_plot,'ylabel'),'vertical','Baseline');
end
ylabel('Clusters size');
handles.setclus = 0;
