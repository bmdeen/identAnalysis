function [diffusion_map, Lambda, Psi, Ms, Phi, K_rw] = calcDiffusionMap(K,configParams)
% calculate diffusion map 
%
% Gal Mishne
%
% Modified by Ben Deen (8/2021): add t=0 option, to use spectral
% regularization for automatic determination of diffusion time t. Switched
% default options to t=0, fp normalization (i.e. alpha = .5).
% See https://www.pnas.org/content/pnas/suppl/2016/10/17/1608282113.DCSupplemental/pnas.201608282SI.pdf

dParams.normalization = 'fp';
dParams.t = 0;
dParams.verbose = 0;
dParams.plotResults = 0;
if exist('configParams','var') && isfield(configParams,'patchDim')
    dParams.maxInd = round(configParams.patchDim^2/4);
else
    dParams.maxInd = 4;
end
if exist('configParams','var')
    configParams = setParams(dParams, configParams);
else
    configParams = setParams(dParams,[]);
end

D = sum(K,2)+eps;

if strcmp(configParams.normalization, 'lb') % laplace-beltrami
    one_over_D = spdiags(1./D,0,size(K,1),size(K,2));
    K = one_over_D*K*one_over_D;
    
    D = sum(K,2);
elseif strcmp(configParams.normalization, 'fp') % fokker-planck
    one_over_D_sqrt = spdiags(1./sqrt(D),0,size(K,1),size(K,2));
    K = one_over_D_sqrt*K*one_over_D_sqrt;
    
    D = sum(K,2);
end

%% calculate eigen decomposition
one_over_D_sqrt = spdiags(sqrt(1./D),0,size(K,1),size(K,2));
% using symmetric matrix for calculation
Ms = one_over_D_sqrt * K * one_over_D_sqrt;
Ms = 0.5*(Ms + Ms');
% if ~issparse(Ms) && sum(Ms(:)==0)/numel(Ms)>0.75
%     Ms(Ms<1e-10) = 0;
%     Ms = sparse(Ms);
% end

if configParams.verbose
    disp('Calculating Eigen values and vectors');
end

options.disp = 0;
options.isreal = true;
options.issym = true;
% calculating first configParams.maxInd eigenvalues and vectors
if issparse(Ms)
    [v,lambda] = eigs(Ms,configParams.maxInd,'lm',options);
    Lambda     = diag(lambda);
    [Lambda,I] = sort(Lambda,'descend'); %eigs doesn't return the values sorted
    v          = v(:,I);
else
    [v,lambda] = eig(Ms);
    [lambda,I] = sort(diag(lambda),'descend'); %eigs doesn't return the values sorted
    Lambda = lambda(1:configParams.maxInd);
    v    = v(:,I(1:configParams.maxInd));
    
end

v        = v./ repmat(sqrt(sum(v.^2)),size(v,1),1);
Psi        = one_over_D_sqrt * v;
%Psi        = Psi./ repmat(sqrt(sum(Psi.^2)),size(Psi,1),1);
inds       = 2:length(Lambda); % disregarding first trivial eigenvalue
clear one_over_D_sqrt

% diffusion map
if configParams.t==0
    diffusion_map = (Psi./ repmat(sqrt(sum(Psi.^2)),size(Psi,1),1) .* ...
        repmat(Lambda'./(1-Lambda'),size(Psi,1),1));
else
    diffusion_map = (Psi./ repmat(sqrt(sum(Psi.^2)),size(Psi,1),1) .* ...
        repmat(Lambda'.^ configParams.t,size(Psi,1),1));
end
diffusion_map = diffusion_map(:,inds)';

if nargout >= 5
    D_mat = spdiags(D,0,size(K,1),size(K,2));
    Phi = D_mat * Psi;
end

if nargout == 6
    one_over_D = spdiags(1./D,0,size(K,1),size(K,2));
    K_rw = one_over_D*K;
end

% plotting results
if configParams.plotResults
    figure;
    plot(Lambda);
    title('\lambda');
    ylim([0 1])
    
    figure;
    scatter(1:size(Psi,1),diffusion_map(1,:))
    hold all
    scatter(1:size(Psi,1),diffusion_map(2,:))
    scatter(1:size(Psi,1),diffusion_map(3,:))
    title('Diffusion Map Coordinates');

    figure(101);
    scatter3(diffusion_map(1,:),diffusion_map(2,:),diffusion_map(3,:))
    title('Diffusion Map');
end
