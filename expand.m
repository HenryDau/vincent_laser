function out=expand(one,two)
out=[];
if isempty(two), 
    out=one;
else
  for i=1:length(one);
    out=[out;one(i)*ones(size(two,1),1) two];
    two=flipud(two);
  end;
end;