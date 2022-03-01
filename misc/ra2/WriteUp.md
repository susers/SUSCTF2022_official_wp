# 题目解析(wp)
在文件夹内搜索ctf或flag字样，发现题目相关文件在mods/rv/maps/ctf-01文件夹下，根据游戏相关信息可以轻松在游戏内找到flag。
Search string "ctf" or "flag" in the folder, you will find the relevant files are all in mods/rv/maps/ctf-01. Flag can be easily found in the game using these relevant information.

## 最简解法(The fastest solution)
进入游戏，打开OpenRA自带的地图编辑器，搜索oc233制作的地图并打开，在地图中间下方找到flag。
launch game -> Extras -> Map Editor -> search "oc233" -> open and find the flag

## Modder解法(The modder's solution)
使用红警的shp编辑器（如OS SHP Builde），分析mods/rv/maps/ctf-01/cgla10_b.shp得到flag。
Analyse the mods/rv/maps/ctf-01/cgla10_b.shp using shp editor like "OS SHP Builde" to get the flag.

## 高玩解法(The gamer's solution)
按游戏提示依次完成任务，最终在地图上发现flag。示例：https://www.bilibili.com/video/bv1Su411D7h3
Just follow the task description.

# 花絮
本题整体任务参照星际争霸2的“亡者之夜”任务，其中两个突变因子参考“暗无天日”和“核弹打击”。由于时间关系，本题还有攻击波次之类的东西没有仔细做。此外，由于出题人是青铜菜狗，本题潜力也没有完全挖掘，可能有的高玩会不尽兴。考虑到需要的一些素材，本题使用的是红警2的改版尤里的复仇，也许以后授权开放了可以弄个红警3的日冕mod玩玩（手动滑稽）。