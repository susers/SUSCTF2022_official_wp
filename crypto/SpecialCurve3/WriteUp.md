# 题目解析(wp)
本题考察有限域上圆锥曲线的离散对数求解，求解难度$e_3 < e_2 < e_1$。通过代码可以很容易发现这是一条满足$y^2=a x^2 - b x \mod p$的曲线，其上定义了一种新的点加法运算。通过自行推导或者搜索论文可以发现这是关于斜率$t$的单参数曲线，其加法原理是过原点作两点割线（两点相同为切线）的平行线与曲线相交得到新的一点，满足$t_3=\frac{t_1 t_2 +a}{t_1+t_2} \mod p$。简单测试可以发现三种曲线的阶分别为$p-1,p,p+1$，与解析几何中的三种圆锥曲线相类似。
接下来考虑三种曲线的离散对数。题目采用了自定义函数生成随机素数，在保证-1为$p$的非二次剩余（否则第三条曲线可能和第一条曲线类型相同）时使$p+1$光滑，因此可以通过Pohlig-Hellman算法求解离散对数得到$e_3$。由于sagemath对于该算法在自定义群上的支持存在问题，这里需要自行实现或者修改相关底层代码。
当$a=0$时，斜率$t$的加法满足$\frac{1}{t_3}=\frac{1}{t_1}+\frac{1}{t_2}$，变成了普通的有限域加法，可以通过求逆直接解离散对数，这和realworld2021的Homebrewed Curve一样。不过那里的无穷远点没有选择原点而显得不够直观。
当$k=1$时，$a$是$p$的二次剩余，令$\varphi(t)=\frac{t-\sqrt{a}}{t+\sqrt{a}}$，将有限域上的圆锥曲线群映射到有限域上的普通乘法群。之后可以通过cado-nfs或sagemath的log函数（底层调用pair）解离散对数。
For $e_3$, $p+1$ is smooth, you can use Pohlig-Hellman algorithm to discrete log. For $e_2$, let $\varphi(t)=\frac{1}{t}$, the point addition become ordinary addition in `GF(p)`. For $e_1$, let $\varphi(t)=\frac{t-\sqrt{a}}{t+\sqrt{a}}$, the point addition become ordinary multiplication in `GF(p)`, you can use cado-nfs to solve it.

# 解题脚本(exp)
solution.sage