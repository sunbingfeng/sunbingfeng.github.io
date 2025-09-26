---
toc: true
layout: post
title:  "Setup Your Pure VIM Dev Environment--Part I"
date:   2022-01-27
excerpt: "TMUX"
image: ""
comments: true
tags: tools vim
---

## Why `Tmux` is needed?<br>
During your daily work, it's quite common to open several windows to accomplish your tasks.<br>
If you don't use `Tmux` alike screen manager, it will be totally a nightmare.<br>

Following demonstrates a typical scene. You open a window to view the code project, and another one to build it. Apart from them, you can also open some other auxiliary windows, e.g, `htop` window, to watch the real-time CPU performance.

<a href="{{ site.url }}/images/tmux.webp" target="_blank"><img src="{{ site.url }}/images/tmux.webp"  alt="img" align="center"/></a>

What's more, if you are a DevOps engineer who should ssh to remote machine to do some developments, you will find `Tmux` useful. It offers you the mechanism to close the session temporarily without any concern, and reattach to it in an easy manner. `Tmux` will manage the sessions until your next access.

There are definitely other alternatives to `Tmux`, e.g, `screen`, and you can choose anyone as you like.
In this post, we mainly describe our settings based on `Tmux`.

## Setup<br>
Install `Tmux`:
```
sudo apt-get install tmux
```

Download the config repo to your home directory:
```
git clone --recursive git@github.com:sunbingfeng/tmux-config.git $HOME/.tmux
```

Set it as the default tmux configuration:
```
ln -s ~/.tmux/.tmux.conf ~/.tmux.conf
```

## Usage<br>

The default prefix/leader key is `Control+o`, and you can change it to your preference.

**Basic**:<br>
- `tmux` to create a new tmux session
- `tmux a` to attach to an existed session
- The prefix key must be typed before any commands
- `Control+o` then `?` to bring up list of key mappings

**Window managements**:<br>
- `Control+o` then `s` to show list of windows available
- `Control+o` then `f` to search window through keywords
- `Control+o` then `,` to rename current window
- `Control+o` then `&` to kill current window
- `Control+o` then `c` to create new window
- `Control+o` then `n` to goto the next window
- `Control+o` then `p` to goto the previous window
- `Control+o` then `Control+a` switch between current and last window
- `Control+o` then `[0-9]` to goto the numbered window

**Pane managements**:<br>
- `Control+o` then `v` to split horizontally
- `Control+o` then `b` to split vertically
- `Control+o` then `;` to switch between current and last pane
- `Control+o` then `h`,`j`,`k`,`l` to move left, down, up, right respectively as vim does
- `Control+o` then `z` to maximum/restore current pane
- `Control+o` then `x` to close current pane

**Copy&Paste**:<br>
We use `xclip` be default, so you should install it through:
```sudo apt-get install xclip```

- `Control+o` then `[` to enter copy mode
- Press `v` to select blocks, or `V` to select multiple lines, and then `y` to copy it to clipboard
- Goto where you want to paste, and press `i` to enter edit mode. Press `Control+o` then `]` to paste.

