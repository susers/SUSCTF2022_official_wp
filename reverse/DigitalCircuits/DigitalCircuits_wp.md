##[数电]
程序为python打包的exe文件，用pyinstxtractor.py和uncompyle6处理后，可以得到python源代码，python版本为3.7

程序从与或逻辑的层级实现了tea加密，下为各函数的原始名
f1--AND（一位与逻辑）
f2--OR（一位或逻辑）
f3--NOT（一位取反）
f4--XOR（一位异或）
f5--FULLADDER（全加器）
f6--ADD（32位数加法）
f7--LEFT（32位数左移）
f8--RIGHT（32位数右移）
f9--XXOR（32位数异或）
f10--en_tea（tea加密）

解密脚本：
```C
#include<stdio.h>
#include<stdint.h>

void teaen(uint32_t* v,uint32_t* k){
    uint32_t v0=v[0],v1=v[1],sum=0,i;
    uint32_t delta=0x9e3779b9;
    uint32_t k0=k[0],k1=k[1],k2=k[2],k3=k[3];
    for(i=0;i<32;i++){
        sum+=delta;
        v0+=((v1<<4)+k0)^(v1+sum)^((v1>>5)+k1);
        v1+=((v0<<4)+k2)^(v0+sum)^((v0>>5)+k3);
    }
    v[0]=v0;
    v[1]=v1;
}

void teade(uint32_t* v,uint32_t* k){
    uint32_t v0=v[0],v1=v[1],sum,i;
    uint32_t delta=0x9e3779b9;
    sum=32*delta;
    uint32_t k0=k[0],k1=k[1],k2=k[2],k3=k[3];
    for(i=0;i<32;i++){
        v1-=((v0<<4)+k2)^(v0+sum)^((v0>>5)+k3);
        v0-=((v1<<4)+k0)^(v1+sum)^((v1>>5)+k1);
        sum-=delta;
    }
    v[0]=v0;
    v[1]=v1;   
}
int main(){
    uint32_t enc[8]={0x3e8947cb,0xcc944639,0x31358388,0x3b0b6893,0xda627361,0x3b2e6427};
    uint32_t k[4]={17477, 16708, 16965, 17734};
    int i;
    for(i=0;i<8;i+=2){
        teade(&enc[i],k);
    }
    printf("%s",enc);
    return 0;
}
```
输出：fvBXQdEarcbvhBPxcOA8Ag6J
由于小端存储，故flag为：
SUSCTF{XBvfaEdQvbcrxPBh8AOcJ6gA}
