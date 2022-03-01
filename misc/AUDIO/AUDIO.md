### 题目：AUDIO 

内容：

Bin received a piece of song from his friend yesterday. The friend told him that something was hidden in the song. Bin had listened it and found the origin version. Could you help him crack the song and find the hidden secret?

难度：简单

WP:

灵感来自于主动降噪耳机。

会得到两段音频，一段是原版，另一段是和摩斯电码合成的。需要做的是将第一段音频反相在和第二段音频叠加，即可得到摩斯电码的波形。稍有难度的是需要对两端音频的幅度进行匹配。使用Adobe Audition 2021 测试，需要将合成音频幅度调高约6dB，或者将原音频幅度降低6dB。不建议降低，有可能会出现再次合成音杂音过大的情况。若出现波形不明显的情况，可适当调高再合成音频的幅度。

FLAG :SUSCTF{MASTEROFAUDIO}
