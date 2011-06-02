function varargout = first(varargin)
%FIRST   Returns the first value that matches a condition in a matrix
%[a1,ind] = first(A,cond,dim,start)
%  or     ind = first(cond,dim,start)
%  or     ind = first(cond,dim)
%  or     ind = first(cond)
%
% A slightly nicer version of find(cond,1,'first');
%
%Returns the first element of A and the index in which cond is true,
%operating across dim dimension.  Or, if only a logical array is passed,
%returns just the index in which cond is true.  Operates on columns
%normally, unless dim is passed.  If cond is not true at any point in the
%column, returns ind = 0 and a1 = NaN.  Or, if A had only one column,
%returns an empty matrix.
%
% See also LAST

% Mercurial revision hash: $Revision$ $Date$
% See https://bitbucket.org/tytell/matlab_variables/overview
% Copyright (c) 2011, Eric Tytell <tytell at jhu dot edu>

if (ischar(varargin{1}) && ismember(varargin{1},{'find','logical'}))
    method = varargin{1};
    varargin = varargin(2:end);
else
    method = '';
end;

narg = length(varargin);

dim = 1;
start = 1;
if (narg == 4)
    ismat = true;
    [A,cond,dim,start] = varargin{:};
elseif (narg == 3) 
    if (numel(varargin{2}) == 1)
        ismat = false;
        [cond,dim,start] = varargin{:};
    else
        ismat = true;
        [A,cond,dim] = varargin{:};
    end;
elseif (narg == 2)
    if (numel(varargin{2}) == 1)
        ismat = false;
        [cond,dim] = varargin{:};
    else
        ismat = true;
        [A,cond] = varargin{:};
    end;
else
    cond = varargin{1};
    ismat = false;
end;

if (isempty(cond)),
    varargout = cell(1,nargout);
    return;
end;

%check to see if we have same-size vector inputs, one a row vector and
%one a column
if (ismat && (ndims(cond) == 2) && (ndims(A) == 2) && ...
        any(size(A) == 1) && any(size(cond) == 1) && ...
        (numel(A) == numel(cond)) && any(size(cond) ~= size(A))),
    cond = cond';
end;

if (ismat && ((ndims(cond) ~= ndims(A)) || any(size(cond) ~= size(A)))),
    error('The condition matrix must have the same size as A.');
end;

if (~ismat && (nargout == 2))
    error('Cannot return values without A');
end;

%check to see if we have a row vector, and, if so, operate across the
%columns
if ((ndims(cond) == 2) && (size(cond,1) == 1))
    dim = 2;
end;

%permute and reshape so that we have a 2D matrix with the dimension of
%interest first
szorig = size(cond);
pmt = [dim 1:dim-1 dim+1:ndims(cond)];

n = size(cond,dim);
N = prod(szorig(pmt(2:end)));

cond = permute(cond,pmt);
cond = reshape(cond,[n N]);

if (ismat)
    A = permute(A,pmt);
    A = reshape(A,[n N]);
end;

%handle start indices
if (start ~= 1)
    cond = cond(start:end,:);
    if (ismat)
        A = A(start:end,:);
    end;
end;

%check for rows vs columns
if (N == 1)
    %for one column, the builtin function find is always fastest
    ind = find(cond(start:end),1,'first');
    
    if (ismat)
        f = A(ind);
    end;
elseif (strcmp(method,'find') || (isempty(method) && (n > 1000)))
    %if the number of rows is large, find tends to be fastest
    if (ismat)
        if (nargout == 2)
            [f,ind] = first0valind(A,cond);
            ind = ind + start - 1;
        else
            f = first0val(A,cond);
        end;
    else
        ind = first0ind(cond);
    end;
else
    %for fewer rows, using the vectorized logical array operation seems to
    %be fastest
    if (ismat)
        if (nargout == 2)
            [f,ind] = first1valind(A,cond);
            ind = ind + start - 1;
        else
            f = first1val(A,cond);
        end;
    else
        ind = first1ind(cond);
        ind = ind + start - 1;
    end;
end;
        
if (nargout == 2),
    varargout = {f,ind};
elseif (ismat),
    varargout = {f};
else
    varargout = {ind};
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% first functions based on the builtin find function
function ind = first0ind(cond)

N = size(cond,2);

ind = zeros(1,N);
for k = 1:N,
    ind1 = find(cond(:,k), 1,'first');
    if (~isempty(ind1))
        ind(k) = ind1;
    end;
end;

function val = first0val(A,cond)

N = size(cond,2);
if (isa(A,'double') || isa(A,'single'))
    val = NaN(1,N);
else
    val = zeros(1,N,class(A));
end;

for k = 1:N,
    ind1 = find(cond(:,k), 1,'first');
    if (~isempty(ind1))
        val(k) = A(ind1,k);
    end;
end;


function [val,ind] = first0valind(A,cond)

N = size(cond,2);
if (isa(A,'double') || isa(A,'single'))
    val = NaN(1,N);
else
    val = zeros(1,N,class(A));
end;

ind = zeros(1,N);
for k = 1:N,
    ind1 = find(cond(:,k), 1,'first');
    if (~isempty(ind1))
        ind(k) = ind1;
        val(k) = A(ind1,k);
    end;
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% first functions based on vectorized logical array manipulations
function ind = first1ind(cond)

N = size(cond,2);

cond = cond & [true(1,N); ~cond(1:end-1,:)];

num = cumsum(cond);
isfirst = cond & (num == 1);

ind = zeros(1,N);
[r,c] = find(isfirst);

ind(c) = r;


function val = first1val(A,cond)

N = size(cond,2);

cond = cond & [true(1,N); ~cond(1:end-1,:)];

num = cumsum(cond);
isfirst = cond & (num == 1);

if (isa(A,'double') || isa(A,'single'))
    val = NaN(1,N);
else
    val = zeros(1,N,class(A));
end;
val(any(isfirst)) = A(isfirst);


function [val,ind] = first1valind(A,cond)

N = size(cond,2);

cond = cond & [true(1,N); ~cond(1:end-1,:)];

num = cumsum(cond);
isfirst = cond & (num == 1);

if (isa(A,'double') || isa(A,'single'))
    val = NaN(1,N);
else
    val = zeros(1,N,class(A));
end;
val(any(isfirst)) = A(isfirst);

ind = zeros(1,N);
[r,c] = find(isfirst);

ind(c) = r;
