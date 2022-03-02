# 题目解析(wp)
进行简单的测试可以发现，本题的系数矩阵条件数过大，难以直接通过矩阵求逆或高斯消去法等求解方程。考虑进行数值分析，由于模型误差不影响结果，这里只考虑舍入误差。对于IEEE双浮点计算系统，有误差估计$|e| = |\mathrm{fl}(A*x)-(A*x)| \leq n \varepsilon |A*x|$，这里$n = 85 \approx 10^{2}, \varepsilon=2^{-52} \approx 10^{-16}, |A*x|_i \approx 10^{5}$，故$e_i \leq 10^{-9}$，是一个小量。考虑到将方程视为有理数域上的运算，则有$b=A*x+e$，其中$A,b$均为精确值，$x$为未知整系数，则这是一个有理数域上的LWE搜索问题，直接LLL一下就能求解得到$e$。具体脚本参见`solution.sage`。
Through numerical analysis, we have $b=A*x+e,|e_i| \leq 10^{-9}$, so we can regard it as a LWE search problem in rational number field and use LLL to find $e$.

此外，本题的条件数也不是特别大（只有$10^{18}$），矩阵存在对称性等一些性质，使用TSVD等反问题正则化手段，可以近似求出两边的分量，之后通过降阶方法可以逐位恢复flag。具体脚本参见`solution.m`。
Besides, just use Truncation SVD and dimensionality reduction can also solve this problem.

# 解题脚本(exp)
solution.sage
solution.m

# 花絮
本题是计算数学领域反问题方向的题目，问题背景来自一维重力测量问题（详见Hansen,P.C.的《Discrete Inverse Problems》一书第二章2.1小节），题目中的系数矩阵来自第一类Fredholm积分方程$g(s)=\int_0^1 \frac{d}{\left(d^{2}+(s-t)^{2}\right)^{3/2}} f(t) \mathrm{d}t$的离散化。由于本题$x$并非来自于连续函数的离散值而是整数值，使用常规反问题的正则化方法效果不佳，视为LWE搜索问题后使用格基规约求解却有很好效果。