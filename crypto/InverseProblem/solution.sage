import numpy as np

def gravity(n,d=0.25):
    A=np.zeros([n,n])
    for i in range(n):
        for j in range(n):
            A[i,j]=d/n*(d**2+((i-j)/n)**2)**(-1.5)
    return A

b=np.loadtxt('b.txt')
n=len(b)
b=vector(QQ,b.tolist())
A=matrix(QQ,gravity(n).tolist())
M=block_matrix(QQ,[[A,zero_matrix(n,1)],[matrix(b),matrix([1e-16])]])
L=M.LLL()
x=A\(b-L[0][:-1])
flag=bytes(x).decode()
print(flag)