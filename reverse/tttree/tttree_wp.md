## tttree

考点为去混淆+算法分析

### Step 1 

这里参考了[古月浪子]([Titvt (古月浪子) (github.com)](https://github.com/Titvt))大佬的一个混淆思路

#### 混淆1

重构序列

主要的混淆为通过将指令随机打乱再利用形如下式的花指令使得正常运行

``` 
push    rax
push    rax
pushfq
call   $+5
pop rax
add rax,xxxx
push rax
mov [rsp+10h], rax
popfq
pop rax
```

这里后面如果是`ret`，那么计算出的相对地址就会`push`到堆栈，`ret`之后相当于`jmp`到该地址

另一种情况则为后面是`jmp addr2`，那么完整指令则等价于`call addr2`（`addr1`则为`call`的返回地址）

可以先将所有的情况1，处理完毕后再处理情况2

#### 混淆2

`NOP`掉即可

```
push [rax|...]
pop  [rax|...] 
```

这里用IDApython构建脚本将语句重新连接起来就行

```python
import struct
start = 0x140001000
end = 0x14001C694

address_m = [0 for x in range(11)]
address_target = ['push    rax','push    rax','pushfq','call    $+5','pop     rax','add     rax,','mov     ','popfq','pop     rax','retn']

def check1():
    cnt = 0
    for i in range(9):
        if i == 5 or i == 6:
            cnt += GetDisasm(address_m[i]).find(address_target[i]) != -1
        else:
            cnt += GetDisasm(address_m[i]) == address_target[i]
    return cnt == 9

def check2(x,y):
    cnt = 0
    cnt += print_insn_mnem(x) == "push"
    cnt += print_insn_mnem(y) == "pop"
    cnt += print_operand(x,0) == print_operand(y,0)
    return cnt == 3

def check3():
    cnt = 0
    cnt += print_insn_mnem(address_m[0]) == "push"
    cnt += get_operand_type(address_m[0], 0) == o_imm
    return cnt == 2

def nop(u,v):
    patch_add = u
    while(patch_add < v):
        patch_byte(patch_add,0x90) 
        patch_add += 1

p = start
while p <= end:
    address_m[0] = p
    p = next_head(p)
    while print_insn_mnem(p) == "nop":
        p = next_head(p)
    if check2(address_m[0],p) == 1:
        p = next_head(p)
        nop(address_m[0],p)
    else:
        p = address_m[0]
    address_m[0] = p
    for i in range(1,11):
        address_m[i] = next_head(address_m[i-1])
    
    if check1() == 1:
        addri = get_operand_value(address_m[5], 1)
        addri += address_m[4]
        if address_target[9] == GetDisasm(address_m[9]):
            addri -= (address_m[0] + 5)
            patch_byte(address_m[0],0xE9)
            patch_dword(address_m[0]+1,addri & 0xffffffff)
            nop(address_m[0]+5,address_m[10])
            p = address_m[10]
        else:
            patch_byte(address_m[0],0x68)
            patch_dword(address_m[0]+1,addri & 0xffffffff)
            nop(address_m[0]+5,address_m[9])
            p = address_m[9]
    else:
        p = address_m[1]

p = start
while p <= end:   
    address_m[0] = p
    address_m[1] = next_head(p)
    if check3() == 1:
        addri = get_operand_value(address_m[0], 0) + 2 ** 32
        p = address_m[1]
        while print_insn_mnem(p) == "nop":
            p += 1
        if print_insn_mnem(p) == "jmp":
            addrj = struct.unpack('<I', get_bytes(p + 1, 4))[0] + p - address_m[0]
            addri -= p + 5
            if addri < 0:
                addri += 2 ** 32
            patch_byte(address_m[0], 0xe8)
            patch_dword(address_m[0]+1, addrj & 0xffffffff)
            patch_byte(p, 0xe9)
            p += 1
            patch_dword(p, addri)
            p += 4
    else:
        p = address_m[1]
    
print("Finish")
```



### Step 2

编译没有加任何优化，去混淆后可以很容易找到关键函数并理解逻辑

代码是很明显的平衡树`Treap`，这里主要运用了`Treap`作为平衡树，其中序遍历`val`有序(本题升序)，亦满足堆的性质，左右子节点`rnd`值与父节点有大小关系(本题小根堆)

`rand`生成函数是一个线性同余生成器，生成的`rnd`值为固定值，前32位为节点`val`参数，后32位作为`Treap`中的节点`priority`值

```c++
rnd = seed*48271%2147483647
```

- 生成函数混淆`flag`与组成树堆的`rand`值

- 后序遍历推中序遍历，重构树

- 后序遍历的最后一位对应的`rand`值一定为最小值，得到根节点对应的`ans`

- 推得左右子树的`id`

```python
from functools import reduce
A = [0x000000A2, 0x000000AF, 0x0000009D, 0x000000B7, 0x000000D2, 0x000000CB, 0x000000C7, 0x000000C6, 0x000000B0, 0x000000D5, 0x000000DA, 0x000000E3, 0x000000E6, 0x000000E8, 0x000000E9, 0x000000F3, 0x000000F4, 0x000000EF, 0x000000EE, 0x000000F7, 0x000000F9, 0x000000FF, 0x00000101, 0x000000F5, 0x00000109, 0x0000011F, 0x0000011A, 0x00000146, 0x00000124, 0x0000010F, 0x00000106, 0x000000DF]
B = [0x00000000000000A8, 0x0000000000000131, 0x0000000000000113, 0x0000000000000047, 0x000000000000009E, 0x000000000000003B, 0x000000000000003A, 0x00000000000000BF, 0x0000000000000092, 0x00000000000000F0, 0x0000000000000174, 0x00000000000000C3, 0x0000000000000289, 0x0000000000000104, 0x0000000000000260, 0x000000000000004D, 0x00000000000002FB, 0x000000000000009E, 0x0000000000000191, 0x0000000000000158, 0x000000000000007D, 0x000000000000004A, 0x00000000000001E9, 0x0000000000000101, 0x00000000000000D0, 0x00000000000000FC, 0x0000000000000070, 0x000000000000011F, 0x0000000000000345, 0x0000000000000162, 0x00000000000002A4, 0x0000000000000092]
C = [0x00000000000000AC, 0x00000000000000FD, 0x0000000000000247, 0x0000000000000115, 0x00000000000000D4, 0x00000000000002B5, 0x00000000000001FC, 0x000000000000028B, 0x000000000000014A, 0x000000000000004C, 0x000000000000008E, 0x00000000000000E9, 0x0000000000000055, 0x000000000000012C, 0x00000000000000F5, 0x00000000000000E3, 0x0000000000000081, 0x00000000000002E2, 0x00000000000001A8, 0x0000000000000117, 0x0000000000000152, 0x0000000000000101, 0x000000000000003A, 0x00000000000001D0, 0x00000000000000A8, 0x00000000000000CC, 0x0000000000000149, 0x0000000000000137, 0x0000000000000300, 0x00000000000001EC, 0x0000000000000276, 0x0000000000000247]
D = sorted(A)
E = [193,168,197,103,123,127,133,122,182,187,112,145,165,157,131,191,204,159,191,154,207,133,123,127,216,151,195,155,228,194,186,183]
ans = [0 for x in range(32)]
class TreeNode(object):
    def __init__(self, val=0, left=None, right=None, ans=0, idx=0):
        self.val = val
        self.left = left
        self.right = right
        self.ans = ans
        self.id = idx

def buildTree(inorder, postorder):
    if not postorder:
        return None
    root = TreeNode(postorder[-1])
    n = inorder.index(root.val)
    root.left = buildTree(inorder[:n],postorder[:n])
    root.right = buildTree(inorder[n+1:],postorder[n:-1])
    return root

def work(rt):
    if rt==None:
        return
    if rt.left != None:
        rt.left.id = (B[A.index(rt.val)] - rt.ans) // 23 - 1
        rt.left.ans = rt.left.val - E[rt.left.id]
    if rt.right != None:
        rt.right.id = (C[A.index(rt.val)] - rt.ans) // 23 - 1
        rt.right.ans = rt.right.val - E[rt.right.id]
    ans[rt.id] = chr(rt.ans)
    work(rt.left)
    work(rt.right)

root = buildTree(D,A)
root.ans = 100
root.id = 4
work(root)
flag = 'SUSCTF{' + reduce(lambda x, y: x + y, ans) + '}'
print(flag)
```



### 可以略过的题外话

第一次给正式比赛出题，水平有限...感到很抱歉

欣赏了各位大佬的wp，许多大佬的脚本和解题思路都让我受益良多，其中不乏有手撕汇编的强者

祝愿各位大佬日后把把AK，我们SUS也将百尺竿头更进一步，期待未来更好的遇见