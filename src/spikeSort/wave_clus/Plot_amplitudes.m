function Plot_amplitudes(handles)

USER_DATA = get(handles.wave_clus_figure,'userdata');
par = USER_DATA{1};
classes = USER_DATA{6};
spikes = USER_DATA{2};

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

h_fig = 100;
figure(h_fig)
nclasses = max(classes);
nchannels = 4;
inputs = nchannels;
ls = size(spikes,2); % tetrodespike length
lch = ls/nchannels; % spike channel length
amps = zeros(ls,nchannels);
filename = par.filename;

% AMPLITUDES
for i=1:nchannels
    aux=[];
    eval(['aux = spikes(1:length(classes) ,' num2str(i-1) '*lch + 1 : i*lch );']);
    eval(['amps(1:length(classes),i) = max(aux,[],2);']);
end

% PLOTS
for i=1:inputs
    for j=i+1:inputs
        subplot(inputs,inputs,(i-1)*inputs+j)
        hold on
        for k=1:nclasses
            class_aux = find(classes==k);
            max_spikes = min(par.max_spikes,length(class_aux));
            % chatGPT
            % inside the k-loop, after class_aux is built
            if isempty(class_aux), continue, end          % skip empty labels
            
            colIdx = k;                                   % cluster-1 → row-1 (blue)
            % if k exceeds the palette length, wrap
            if colIdx > nColors
                colIdx = mod(colIdx-1, nColors) + 1;
            end
            
            pts = class_aux(1:max_spikes);
            plot(amps(pts,i), amps(pts,j), '.', ...
                 'Color', colors(colIdx,:), 'MarkerSize', 0.5);


            % % colIdx = mod(k-1, nColors) + 1;     % cluster-1 → row 1 (blue), wraps as needed
            % % % colIdx = mod(k-1, nColors-1) + 2;   % cluster-1 → blue row, wraps if needed
            % % pts    = class_aux(1:max_spikes);   % (was already defined)
            % % plot(amps(pts,i), amps(pts,j), '.', ...
            % %      'Color', colors(colIdx,:), ...
            % %      'MarkerSize', 0.5);
            % plot(amps(class_aux(1:max_spikes),i),amps(class_aux(1:max_spikes),j),['.' colors(k)],'markersize',.5)
            axis off
        end
    end
end

t5 = strcat(char(filename(1:end-4)) );
set(gcf,'numbertitle','off','name',t5,'menubar','none')

% SAVE FIGURE
set(gcf,'papertype','usletter','paperorientation','portrait','paperunits','inches')
set(gcf,'paperposition',[.25 .25 10.5 7.8])
eval(['print(h_fig,''-djpeg'',''fig2print_amp_' filename(1:end-4) ''')' ]);
