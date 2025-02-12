function [ opts ] = gaussian_4d_simu( dico, range, fx,fy)

% This function simulates the four dimensional atoms (4 variational parameters)
%
% Inputs:
% disco - the type of atom.
% range - the 4D range of values of their mean and their variance.
% fx, fy- the spatial frequencies.

switch dico
    case '4dgaussian'   
        p_range = range;
        atom = @(usigxy) atom_4dgaussian(usigxy,fx,fy);
        datom = @(usigxy) datom_4dgaussian(usigxy,fx,fy);
        cplx = false;
        simu = @(k,SNR) signal(k,SNR,p_range,atom,cplx);
        
end

opts.cplx= cplx;
opts.p_range = p_range;
opts.atom = atom;
opts.datom = datom;
opts.simu = simu;
opts.test_grid = @(N) make_grid(N,p_range);

end


function A  = atom_4dgaussian(usigxy, x,y)

n_uxy = size(usigxy);
spec = [];

for ui = 1:n_uxy(2)
    
    % the mean values along 2 directions x,y.
    ux = usigxy(1,ui);
    uy = usigxy(2,ui);
    sigx = usigxy(3,ui);
    sigy = usigxy(4,ui);
    
    m = [ux, uy]';

    % the deviation values along 2 directions x,y.
    sig = [sigx, sigy]';

    % convert the polar coordinate elements to the cartesian coordinate.
    xy = cat(3,x,y);

    %
    % calculate the spectral density.
    %

    % subtract the mean values
    xym = bsxfun(@minus,xy,shiftdim(m,-2));

    % the reciprocal of sig times the xym
    rsigxym = bsxfun(@times,shiftdim(1./(sig),-2),xym);

    XY = sum(rsigxym.*rsigxym,3);

    spec0 = (1/(2*pi*nthroot(sigx*sigy,2)))*exp(-0.5*XY);

    spec0 = reshape(spec0,[],1);

    spec = [spec, spec0];

end

A = spec;
    
end


function A = datom_4dgaussian(usigxy, x,y)

n_uxy = size(usigxy);
dspec = [];

for ui = 1:n_uxy(2)
    
    % the mean values along 2 directions x,y.
    ux = usigxy(1,ui);
    uy = usigxy(2,ui);
    sigx = usigxy(3,ui);
    sigy = usigxy(4,ui);
    
    m = [ux, uy]';

    % the deviation values along 2 directions x,y
    sig = [sigx, sigy]';

    % convert the polar coordinate elements to the cartesian coordinate.

    xy = cat(3,x,y);

    %
    % calculate the spectral density.
    %

    % subtract the mean values
    xym = bsxfun(@minus,xy,shiftdim(m,-2));

    % the reciprocal of sig times the xym
    rsigxym = bsxfun(@times,shiftdim(1./(sig),-2),xym);

    XY = sum(rsigxym.*rsigxym,3);

    spec0 = (1/(2*pi*nthroot(sigx*sigy,2)))*exp(-0.5*XY);
    
    dux = (x -ux)*(1/(sigx));
    duy = (y -uy)*(1/(sigy));
    dsigx = -1/sqrt(sigx) +((x-ux).^2)*(1/nthroot(sigx,3/2));
    dsigy = -1/sqrt(sigy) +((y-uy).^2)*(1/nthroot(sigy,3/2));
    
    
    dspec0x = reshape(dux.*spec0,[],1);
    
    dspec0y = reshape(duy.*spec0,[],1);
    
    dspec0sigx = reshape(dsigx.*spec0,[],1);
    dspec0sigy = reshape(dsigy.*spec0,[],1);

    dspec0 = [dspec0x dspec0y dspec0sigx dspec0sigy];

    dspec = [dspec, dspec0];

end

A = dspec;

end


function G = make_grid( N , B )

if(nargin==0)
    N=100;
end

Bxy = B(:,:,1);
Bsigxy2 = B(:,:,2);

Gx = Bxy(1,1):(Bxy(2,1)-Bxy(1,1))/(N-1):Bxy(2,1);
Gy = Bxy(1,2):(Bxy(2,2)-Bxy(1,2))/(N-1):Bxy(2,2);

Gsigx = Bsigxy2(1,1):(Bsigxy2(2,1)-Bsigxy2(1,1))/(9-1):Bsigxy2(2,1);
Gsigy = Bsigxy2(1,2):(Bsigxy2(2,2)-Bsigxy2(1,2))/(9-1):Bsigxy2(2,2);

[X,Y, sigx, sigy] = ndgrid(Gx, Gy, Gsigx, Gsigy);

G =[reshape(X,1,[]);reshape(Y,1,[]);reshape(sigx,1,[]); reshape(sigy,1,[])];

end


function [param,coeff,y] = signal(k,SNR,p_range,atom,cplx)

paramx = rand(1,k)*0.4*(p_range(2,1,1)-p_range(1,1,1))+p_range(1,1,1);
paramy = rand(1,k)*0.4*(p_range(2,2,1)-p_range(1,2,1))+p_range(1,2,1);
sigx = rand(1,k)*(p_range(2,1,2)-p_range(1,1,2))+p_range(1,1,2);
sigy = rand(1,k)*(p_range(2,2,2)-p_range(1,2,2))+p_range(1,2,2);

param = [paramx; paramy; sigx; sigy];

if(cplx)
    coeff = randn(k,1)+1i*randn(k,1);
else
    coeff = randn(k,1) + 2;
end
y = atom(param)*coeff;
n = randn(size(y));
n = n/norm(n)*norm(y)*10^(-SNR/20);
y=y+n;

end
