function varargout = xyzvec(x,y,z,varargin)

switch nargin,
    case 1,
        varargin = {x};
    case 2,
        varargin = {x,y};
    case 3,
        varargin = {x,y,z};
    otherwise
        varargin = [x y z varargin];
end;

if ((nargin >= 3) && all(cellfun(@isnumeric,varargin(1:3))))
    [x,y,z] = deal(varargin{1:3});
    tovec = true;
    p = 4;
elseif ((nargin >= 2) && all(cellfun(@isnumeric,varargin(1:2))))
    [x,y] = deal(varargin{1:2});
    z = [];
    tovec = true;
    p = 3;
elseif ((nargin >= 1) && isnumeric(varargin{1}))
    X = varargin{1};
    tovec = false;
    p = 2;
end;

% opt = parsevarargin(opt,varargin(p:end),p);

if (tovec)
    n = numel(x);
    
    x = reshape(x,[1 n]);
    y = reshape(y,[1 n]);
    if (isempty(z))
        X = cat(1,x,y);
    else
        z = reshape(z,[1 n]);
        X = cat(1,x,y,z);
    end;
    varargout = {X};
else
    sz = size(X);
    Xp = cell(1,size(X,1));
    for i = 1:size(X,1),
        Xp{i} = squeeze(X(i,:,:));
        Xp{i} = reshape(Xp{i},sz(2:end));
    end;
    varargout = Xp;
end;
