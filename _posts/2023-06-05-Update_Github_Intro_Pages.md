---
toc: true
layout: post
title:  "自动更新Github个人介绍页"
date:   2023-06-05
excerpt: "王婆卖瓜系列"
image: ""
comments: true
toc: true
tags: tips
---

最近逛到一篇博客，题目叫[Use GitHub Actions to Make Your GitHub Profile Dynamic](https://www.bengreenberg.dev/posts/2023-04-09-github-profile-dynamic-content/)，介绍如何基于Github的action hook快速更新自己的Github介绍页内容。看完蠢蠢欲动，然后我也来了一个照猫画虎，直接开干。

原理很简单：

1. 在自己的个人介绍页对应repo的README中开辟一个#级标题，比如：`### Recent Blog Posts`，后续的更新操作即是直接替换该部分的内容
2. 然后添加同步脚本以及对应的Github action，先直接拿来主义，把逻辑功能架起来再说
3. 同步脚本是基于ruby的，步骤也很清晰：
  - 利用`nokogiri`抓取个人Blog中最新的5篇Posts，包括：标题以及对应post的URL，生成Post列表
  - 基于正则表达式直接替换原先README中的对应内容
  - 最后，调用Github的`Octokit`，提交相应的改动
  
操作的确很简单，但是也有需要注意的地方：

1. `nokogiri`抓取是通过css样式来筛选的，你需要根据blog中post的样式做相应的修改。

具体一点，原先作者的[blog](https://www.bengreenberg.dev/blog/)给post卡片设置的样式如下所示：

<img src="{{ site.url }}/images/2023-06/bengreenberg_css.png"  alt="img" align="center" class="center_img" />

因此其通过`posts = parsed_page.css('.flex.flex-col.rounded-lg.shadow-lg.overflow-hidden')`就可以提取到所有的posts。

2. 正则表达式查找原README中的待匹配项，你需要根据你的README的内容稍微调整。

具体一点，原作者采用的regex如下：

```
posts_regex = /### Recent Blog Posts\n\n[\s\S]*?(?=<\/td>)/m
```

原因即是其`### Recent Blog Posts`标题是放在`table`中的，其需要利用table的结束标记`<\td>`来确定替换的边界。


好了，说了这么多，感觉都像是废话，尤其是对于搞ruby-rails的人来说。最后放一个效果图吧

<img src="{{ site.url }}/images/2023-06/my_github_profile.png"  alt="img" align="center" class="center_img" />

🎉🎉🎉🎉🎉🎉🎉🎉

