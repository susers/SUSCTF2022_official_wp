题目：Tanner

难度：简单

内容：There is a special graph which describe one check matrix, find out where is the hint and what is the flag.

WP:	灵感来自于通信编码里的校验矩阵（要求miscer有一定的搜索能力和学习其他领域知识的能力）

$cH^T=0$

根据Tanner图可以写成校验矩阵
$$
H=\begin{bmatrix}
1&1&1&1&0&0&0&0&0&0\\
1&0&0&0&1&1&1&0&0&0\\
0&1&0&0&1&0&0&1&1&0\\
0&0&1&0&0&1&0&1&0&1\\
0&0&0&1&0&0&1&0&1&1\\
\end{bmatrix}
$$

本题需要写个脚本跑出所有的码字并根据提示将所有满足的码字进行二进制相加并进行sha256操作可得结果,所有码字之和为32*1023=32736即111111111100000，flag为sha256(111111111100000)。由于英文hint原因，对各位师傅解题产生理解麻烦表示抱歉。

脚本（matlab）：

```matlab
H=[1 1 1 1 0 0 0 0 0 0  ; 1 0 0 0 1 1 1 0 0 0 ; 0 1 0 0 1 0 0 1 1 0; 0 0 1 0 0 1 0 1 0 1;0 0 0 1 0 0 1 0 1 1];
A=[];
tt=zeros(10,1);
for i=0:(2^10-1)
    A=bitget(i,10:-1:1);
    if mod(A*H.',2)==0
        tt=tt+A';
    end
r=9;
kk=0;
for j = 1:size(tt,1)
    kk=kk+tt(j)*power(2,r);
    r=r-1;
end
disp(kk);
end
```



FLAG：SUSCTF{c17019990bf57492cddf24f3c c3be588507b2d567934a101d4de2fa6d606b5c1}