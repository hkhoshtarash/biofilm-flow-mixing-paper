clear
close all
clc

T = 10;
kb = k_final;

time  = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 32, 34, 38, 42, 46, 50, 54 ...
    60, 66, 72, 80, 86, 96, 104, 114, 126, 138, 150, 166 ...
    182, 198, 218, 238, 262, 286, 314, 344, 378, 414, 454, 498 ...
    546, 598, 656, 718, 788, 864, 946, 1038, 1138, 1246, 1366, 1498, 1642, 1800];

% Loop through and load each .mat file
for i = 1:length(time)
    filename = sprintf('C_cut_T%d.mat', time(i));
    load(filename);
end
load('Muv_cut.mat')

V0 = mean(mean(nonzeros(Ufx_cut)));
d0 = 400*10^-6;

ta = d0/V0;

Nt = length(time);

S = size(C_cut_T2);
Nx = S(1);
Ny = S(2);
[Y,X] = meshgrid(1:Ny,1:Nx);
X = X *8.3978*10^-6;
Y = Y *8.3978*10^-6;

L0 = 0.44*Ny*8.3978*10^-6;

L = zeros(Nt,1);

for  i = 1:Nt


T = eval(sprintf('C_cut_T%d', time(i)));
cl = contour(X, Y, T, [0.5 0.5], 'k', 'LineWidth', 1.5);
if ~isempty(cl)
dl = contourlengths(cl);
L(i) = sum(dl); % 0.5 isoline length

end
 


end


L_star = (L )/L0;


figure(1)
set(gcf, 'Position', [500, 300, 850, 700]); % Set the figure size and position
scatter(time(:)/ta,L_star(:),60,'red','filled')
ax = gca;
ax.YAxis.Scale ="log";
ax.XAxis.Scale ="log";
xlabel('$t/t_a$','FontSize',22,'Interpreter','latex') % Adjust font style and size here
ylabel('$L^{*}(t)$','FontSize',22,'Interpreter','latex') % Adjust font style and size here

ylim([-5*10^-1 2*10^1])
xlim([10^-1 1000])
grid on
ax = gca;
ax.Box = 'on';
ax.LineWidth = 1.5;
ax.XAxis.LineWidth = 2;
ax.YAxis.LineWidth = 2;


f = gcf;
exportgraphics(f,'L_growth_T12_kb11.png','Resolution',600);

L_save = zeros(length(time),2);

L_save(:,1) = L_star;
L_save(:,2) = time/ta;
L_save(:,3) = time;

Lt_T10_U = L_save;
save('Lt_T10_U.mat','Lt_T10_U')





function [clen dx_iso dy_iso dl_iso] = contourlengths(a);
len = zeros(1,10000);    % Create a matrix to hold the length of each contour line
lev = len;  % Create another matrix of the same size to hold the corresponding level
linenum = 1;
k = 0;
v = a(2,1);
while linenum <= length(a)
    k = k+1;
    lev(k) = a(1,linenum);  % lev(k) is the level value for the contour line #linenum
    v = a(2,linenum);    % v is the number of vertices at the level lev(k)
    for i = 1:v-1
       dx = a(1,linenum+i)-a(1,linenum+i+1);
       dy = a(2,linenum+i)-a(2,linenum+i+1);
       d = sqrt(dx^2 + dy^2);
       len(k) = len(k) + d;  % Increment the length of the contour line by the distance between the two vertices
       dl_is(i,k)=d;
       dx_is(i,k)=dx;
       dy_is(i,k)=dy;
    end
    linenum = linenum+v+1;  % Move on to the next contour line
end
clen = len(1:k)';
dl_iso=dl_is;
dx_iso=dx_is;
dy_iso=dy_is;
end

