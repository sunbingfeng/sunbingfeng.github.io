---
layout: post
title:  "Setup Your Pure VIM Dev Environment--Part II"
date:   2022-01-28
excerpt: "VIM SETUP"
image: ""
comments: true
tags: Y-2022 vim configuration tools summary
---

## Install Vim Configurations<br>
We have uploaded our vim configurations to [repo](https://github.com/sunbingfeng/dot-vim), and you can install with following script:
```shell
$ wget -qO - https://raw.github.com/sunbingfeng/dot-vim/master/setup.sh | bash
```

## Usage<br>

### Basic<br>
- Leader key is set to `,`, and you can change it to any character as you like
- `:`: input a command manually
- `,+h:`: show history vim commands, and it can boost the input speed of command

### NERDTree: the File Explorer<br>
A typical NERDTree workspace contains a navigation pane, and several file panes.<br>
Following is my blog project opened through NERDTree:<br>

<a href="{{ site.url }}/images/nerdtree_split.webp" target="_blank"><img src="{{ site.url }}/images/nerdtree_split.webp"  alt="img" height="400px" align="center"/></a>

Some key mappings used with high frequency:<br>
- `,+n`: toggle NERDTree pane
- `,+v`: open NERDTree pane and the cursor focuses on current file
- `,+tn`: switch to the next tab
- `,+tp`: switch to the previous tab
- `Control+h/j/k/l`: switch between different panes

When the cursor is at the NERDTree pane, you can:<br>
- Press `?` to show list of quick help
- Press `j`, `k` to navigate down/up through files, and press `Enter` to open it in current active pane
- `i`: open the file under cursor in a vertical split pane
- `s`: open the file under cursor in a horizontal split pane
- `t`: open the file under cursor in a new tab

You can also press `m` at the NERDTree pane to toggle the menu:

<a href="{{ site.url }}/images/nerdtree_menu.webp" target="_blank"><img src="{{ site.url }}/images/nerdtree_menu.webp"  alt="img" height="400px" align="center"/></a>

Thus, you can copy/move/delete file according to the tips.

### Easy Navigation<br>
Modern IDEs provide many useful shortcuts to make you code easier, e.g., `goto definition`, `goto file`, etc.<br>
If Vim can't do that, it definitely will drop out. However, basic Vim doesn't have these features. Luckily, we can realize these functions through plugins, e.g., `FZF` in our configuration.

**High Frequency Usage**<br>
- `Control+p`: search file by name<br>
<img src="{{ site.url }}/images/fzf_goto_file.webp"  alt="img" height="400px" align="center"/>
- `Control+g`: search symbols at global range<br>
<a href="{{ site.url }}/images/fzf_search_symbols.webp" target="_blank"><img src="{{ site.url }}/images/fzf_search_symbols.webp"  alt="img" height="400px" align="center"/></a>
- `Control+f`: list symbols in current file, and you can view functions/members easily. Mote that you should create tags first according to tips in [README](https://github.com/sunbingfeng/dot-vim/blob/master/README.md)<br>
<a href="{{ site.url }}/images/fzf_list_tags.webp" target="_blank"><img src="{{ site.url }}/images/fzf_list_tags.webp"  alt="img" height="400px" align="center"/></a>
- `,+b`: list opened buffers, and previous accessed file will be at the highest priority. You can press `Enter` to switch back and forward.
- `,hh`: list history accessed files

**Bookmark Management**<br>
You can also bookmark at where you add a `TODO`, or the line of code you want to access quickly later.<br>

<a href="{{ site.url }}/images/bookmark.webp" target="_blank"><img src="{{ site.url }}/images/bookmark.webp"  alt="img" height="400px" align="center"/></a>
- `mm`: toggle bookmark at current line
- `mc`: clear all bookmarks
- `ma`: list all bookmarks

### Pure Coding
The charm of Vim is that it provides you the probability to focus on the pure coding, and it definitely will make you happier.<br>
In Vim, key shortcuts are everything. If you master them well, you can almost do everything getting rid of mouse. Not only can it boost your coding efficiency, but also avoid wrist and finger pain caused by heavy mouse use. These are huge advantages over other alternatives.<br>
**Coding with ease**<br>
There are many tutorials related to Vim, e.g, [1], and actually it's impossible to give you an entire introduction in a few words. You can google yourself, and I only list some basics here:<br>
- `h/j/k/l`: [**normal mode**]move left/down/up/right
- `Control+u/d`: [**normal mode**]page scroll up/down
- `i/a/o/s`: enter edition mode; `jk`: exit edition mode
- `u`: undo edition; `Control+r`: redo; `Control+s`: save

**Beautify Your Code**<br>
It's nearly impossible to write a totally formatted code with just manual typing, so we need the tools to assist us.<br>
We use `clangformat` to beautify our c++ code with specified style, and `yapf` on python code.<br>
- `,cf`: format your code with configured style, e.g., `google` style for .cpp files

**View Code Changes**<br>
- `[c`: take you to previous modified place
- `]c`: take you to next modified place
- `,hu`: revert your specified change quickly and one by one

That's all, hope you have a nice journey to work with pure Vim environment!

## Reference<br>
- [1] [Learn Vim For the Last Time: A Tutorial and Primer.](https://danielmiessler.com/study/vim/)

