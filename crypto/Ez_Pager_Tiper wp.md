# Ez_Pager_Tiper

## 预期解：

审计generator只有lfsr2或lfsr1^lfsr2两种输出，模式的选择由magic的二进制位决定

所以说，其实是Paper Tiger: )

通过已知的部分文段可以分析文本格式以“Date: yyyy-mm-dd”作为开头，日期信息由文件名称b64decode得到。利用已知明文密文对，可以恢复lfsr的内部状态

利用Problem1恢复mask2。在Problem2中考虑对seed3进行爆破，根据lfsr2的流与密钥流整合得到lfsr1的流，进而恢复其信息。将文本解密，通过明文格式筛选得到flag

**SUSCTF{Thx_f0r_y0uR_P4ti3nce_:)_GoodLuck!_1bc9b80142c24fef610b8d770b500009}**

## 非预期解：

看过师傅们的wp，发现大多师傅都是利用lfsr2的脆弱性进行爆破恢复，思路基本相同

部分师傅的思路中考虑到lfsr1^lfsr2也是线性运算，对于该流可以使用至多64+12=76bit的lfsr即可产生

已知明文中b'Date: yyyy-mm-dd\r\n'共18*8bit，需要额外爆破8bit得到足够长度的流，以进行攻击