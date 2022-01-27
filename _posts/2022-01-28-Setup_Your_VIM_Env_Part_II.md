---
layout: post
title:  "Setup Your Pure VIM Dev Environment--Part II"
date:   2022-01-28
excerpt: "VIM SETUP"
image: ""
comments: true
tags: Y-2022 vim configuration tools summary
---

##Install Vim configurations<br>
We have uploaded our vim configurations to ![repo](https://github.com/sunbingfeng/dot-vim), and you can install with following script:
```shell
$ wget -qO - https://raw.github.com/sunbingfeng/dot-vim/master/setup.sh | bash
```

##Usage<br>

###**Basic**<br>
- Leader key is set to `,`, and you can change it to any character as you like
- `:`: input a command manually
- `,+h:`: show history vim commands, and it can boost the input speed of command

###**NERDTree: the file explorer**<br>
A typical NERDTree workspace contains a manager pane, and several file panes.<br>
Following is my blog project opened through NERDTree:
<a href="{{ site.url }}/images/nerdtree_split.webp" target="_blank"><img src="{{ site.url }}/images/nerdtree_split.webp"  alt="img" height="200px" align="center"/></a>

Some key mappings used with high frequency:<br>
- ',+n': toggle NERDTree pane
- ',+v': open NERDTree pane and the cursor focuses on current file
- ',+tn': switch to the next tab
- ',+tp': switch to the previous tab
- 'Control+h/j/k/l': switch between different panes

When the cursor is at the NERDTree pane, you can:<br>
- Press `?` to show list of quick help
- Press `j`, `k` to navigate down/up through files, and press `Enter` to open it in current active pane
- 'i': open the file under cursor in a vertical split pane
- 's': open the file under cursor in a horizontal split pane
- 't': open the file under cursor in a new tab

You can also press `m` at the NERDTree pane to toggle the menu:
<a href="{{ site.url }}/images/nerdtree_menu.webp" target="_blank"><img src="{{ site.url }}/images/nerdtree_menu.webp"  alt="img" height="200px" align="center"/></a>

Thus, you can copy/move/delete file according to the tips.

###**File navigation**<br>
###**Bookmark management**<br>

###**Search globally**<br>

###**Code formatting**<br>

###**View code changes**<br>
