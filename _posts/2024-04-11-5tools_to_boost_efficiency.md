---
toc: true
layout: post
title:  "5个提升Linux开发效率的工具"
date:   2024-04-11
excerpt: "吐血推荐"
image: ""
comments: true
toc: true
tags: Y-2024 tips
---

## Tmux

熟悉我的朋友都知道我离不开Tmux。日常工作，不可避免的需要开启多窗口来完成不同的任务。这种情况下，如果每新建一个任务，你就重开一个终端窗口，那么你将会被这众多的终端窗口整得晕头转向，你的工作效率势必也不会太好。
那么终端复用器就是用来解决这个问题的，其中Tmux（terminal multiplexer）是众多复用器中的佼佼者。

其允许用户创建、管理和控制多个会话。每个会话都可以包含多个窗口，而且这些会话即使在用户断开连接后也会继续运行。而这些所有的窗口都可以共用一个终端窗口，是不是很有效的解决了你的问题?
除了解决窗口复用的问题以外，Tmux还可以实现很多其他的功能，比如：脚本自动化，这里就不展开介绍了，有兴趣的可以自行研究。

详情可以参阅我之前写过的一篇[关于Tmux的文章][tmux_intro].

**安装**:wrench: :`sudo apt-get install tmux`


## Vim&fzf.vim
Vim我就不介绍了，如果你正在使用Linux, 那么肯定避免不了和他打交道。尤其是对于喜欢用Vim来开发的朋友们，我多说一个字都是多余的。
那fzf.vim呢，就是Vim众多插件中的一员，其可以帮助我们提升Vim开发效率。

<script src="https://asciinema.org/a/653606.js" id="asciicast-653606" async="true"></script>

详情可以参阅我之前写过的一篇[关于Vim的文章][vim_intro].

## [fzf][fzf]
fzf是终端上的一个超级巨无霸工具，能够帮助你快速的管理文件、书签，读取操作历史，管理进程等等。除了其自身包含的功能外，其还可以跟其他的工具深度配置和集成。最关键的一点是，它超级快！
目前我在Vim的开发环境下深度依赖fzf.vim，而其就是基于fzf的一个vim插件。除此之外，在终端中，使用频次最高的两个功能：模糊查找文件以及快速调出历史命令。

<script src="https://asciinema.org/a/653604.js" id="asciicast-653604" async="true"></script>

**安装**:wrench: :详情参阅fzf官方[安装说明][fzf_install]

## [ranger][ranger_github]
如果你的工作目录特别的庞大且层级特别的深，如何快速的导航到你想要访问的文件或者文件夹路径？不断的`cd`吗？那不行，效率太低下了。
ranger就是一个可以提升你的文件访问效率的工具。其提供了一个分栏导航界面，支持类Vim的快捷键操作。对于文件，其支持快速预览。到达你想要访问的文件夹后，按`q`退出ranger，即可以立即切换到该路径。

<script src="https://asciinema.org/a/653582.js" id="asciicast-653582" async="true"></script>

**安装**:wrench: :`pip install ranger-fm`

## [zoxide][zoxide_github]
日常工作，不可避免的需要在不同的文件夹路径之间切换。如果你还在用传统的`cd`命令，那么你就太out了。快来升级一下吧，zoxide就是一个支持文件夹路径记忆和模糊搜索的工具，其能够成百上千倍的提升cd效率。

<script src="https://asciinema.org/a/653578.js" id="asciicast-653578" async="true"></script>

**安装**:wrench: :zoxide的官方github上有详细的[安装说明][zoxide_install]，这里不赘述。

[tmux_intro]: <https://www.bingfeng.tech/blog/Setup_Your_VIM_Env/>
[vim_intro]: <https://www.bingfeng.tech/blog/Setup_Your_VIM_Env_Part_II/>
[fzf]: <https://github.com/junegunn/fzf>
[fzf_install]: <https://github.com/junegunn/fzf?tab=readme-ov-file#installation>
[ranger_github]: <https://github.com/ranger/ranger>
[zoxide_github]: <https://github.com/ajeetdsouza/zoxide>
[zoxide_install]: <https://github.com/ajeetdsouza/zoxide?tab=readme-ov-file#installation>

