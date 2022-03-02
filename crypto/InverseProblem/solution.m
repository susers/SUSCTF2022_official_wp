b=readmatrix('b.txt');
n=length(b);
d=0.25;
A=zeros(n);
for i=1:n
    for j=1:n
        A(i,j)=d/n*(d^2+((i-j)/n)^2)^(-1.5);
    end
end

x=['S'];y=['}'];
for i=2:n/2+1
    [U,S,V]=svd(A(i:n+1-i,i:n+1-i));
    k=sum(diag(S)>1e-14);
    xy=V(:,1:k)*inv(S(1:k,1:k))*U(:,1:k)'*(b(i:n+1-i)-A(i:n+1-i,1:i-1)*x-A(i:n+1-i,n+2-i:n)*y);
    x=[x;round(xy(1))];
    y=[round(xy(end));y];
end
flag=[x(1:end-1)',y'];
disp(flag);