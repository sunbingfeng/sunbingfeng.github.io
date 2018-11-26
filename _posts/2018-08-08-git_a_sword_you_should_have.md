---
layout: post
title:  "Git: A sword that every programmer should have"
date:   2018-08-08
excerpt: "Most used git tips"
image: "/images/git.png"
comments: true
tags: git tips
---


## Overview

Git is the best version control system that ever existed.

It's an effective tool every programmer should master, like a sword to a swordsman. If you can master it well, you will gain greater efficiency during your daily development.

In this post, we will not cover every aspects of git, but only basic concepts and some key scenarios in your work.


## Basic concepts

**repository** : a virtual storage of your project. It allows you to save versions of your code, which you can access when needed.

**working tree** : a single checkout of one version of the project. These files are pulled out of the compressed database in the Git directory and placed on disk for you to use or modify.

**staging area** : a file, generally contained in your Git directory, that stores information about what will go into your next commit. Its technical name in Git parlance is the “index”, but the phrase “staging area” works just as well.

![](https://git-scm.com/book/en/v2/images/areas.png) 

## Usage scenarios

### 0. Config with a remote repo

The first important thing you should know about git is the synchronization mechanism between local and remote repository. Operations you do before `git push` are only related to local repo. 

If you do not need to collaborate with others, and have not configure any remote repos yet, the local directory is just a local. Whenever you delete it by fault, such as `rm -rf *` command, it will impossible to recover it through any git version control methods.

So I suggest you store your projects through github or some other alternatives.

### 1. `git log`: view commit history

Git commit history may become very complicated when many people collabrate together and time goes on. You may possibly want to know what new changes have been imported in recent commits and when was a new API function imported for example.

Usage | Remarks
--------|------------
git log -\<n\> | Show only the last n commits	
git log -p | Show the difference (the patch output) introduced in each commit
git log --stat | Only show some abbreviated stats for each commit.
git log --graph | Display an ASCII graph of the branch and merge history beside the log output.
git log -S \<function name\> | Only show commits adding or removing code matching the string, *e.g.*, a function name

### 2. `git diff`: compare between files or commits

`git diff [options]` is an effective tool to compare two versions.

Usage | Remarks
------|---------
git diff | Show only changes that are still unstaged.
git diff --staged | Show changes added through `git add` command
git diff \<version_1\> \<version_2\> -- \<path\> | Show changes between two versions
git diff --check | Identifies possible whitespace errors and lists them for you.

### 3. `git commit --amend`: append to previous commit

Changing your most recent commit is probably the most common rewriting of history that you’ll
do. You’ll often want to do two basic things to your last commit: simply change the commit message,
or change the actual content of the commit by adding, removing and modifying files.

```viml
$ git commit -m 'initial commit'
$ git add forgotten_file
$ git commit --amend
```

You end up with a single commit — the second commit replaces the results of the first.

### 4. `git reset`: clean workspace with one command

```viml

# Does not touch the index file or the working tree at all (but resets the head to <commit>, just like all modes do)
$ git reset --soft <commit>

# Resets the index and working tree. Any changes to tracked files in the working tree since <commit> are discarded.
$ git reset --hard <commit>

```

### 5. `git stash`: save workspace and make a clean directory

There are situations where you were adding a new feature in your dev branch and not finished yet, but your leader asked you to fix a bug with high-level.

Thus, you have to save your current working space and migrate to a new fix branch. You can possibly add these changes and commit it rightly, but it's not recommended because it may be quite buggy. The perfect method to do it is to use `git stash` command.

```viml
# Normal usage, save working directory and index state
$ git stash

# If you specify --include-untracked or -u, 
# Git will include untracked files in the stash being created.
$ git stash -u

# Switch to other branch, and bla bla

# Reapply the changes to your files, but the file you staged before wasn’t restaged.
$ git stash apply

# Reapply the staged changes
$ git stash apply --index
```

### 6. `git rebase`: combine multi commits in your local repo to one, make a clean dev history

You are developing a new feature in a local dev branch. To the final end when you think you have finished it, you may have contributed many commits in this branch. These commits are half-done works, and you want to combine them to one commit, thus the dev branch will be cleaner.

How to do it? Use `git rebase`. Let's demonstrate it using a simple example.

Supposed that you are in c4 commit on dev branch, let me show you how to use `git rebase` to combine last 3 commits to 1.

![](http://oonn91xrt.bkt.clouddn.com/rebase.png)

Using following command:

```viml
$ git rebase -i HEAD~3
```
Change default pick commands to follows in following interactive prompt:

```viml
reword f7f3f6d c2
fixup 310154e c3
fixup a5f4a0d c4
# Rebase 710f0f8..a5f4a0d onto 710f0f8
#
# Commands:
# p, pick = use commit
# r, reword = use commit, but edit the commit message
# e, edit = use commit, but stop for amending
# s, squash = use commit, but meld into previous commit
# f, fixup = like "squash", but discard this commit's log message
# x, exec = run command (the rest of the line) using shell
#
# These lines can be re-ordered; they are executed from top to bottom.
#
# If you remove a line here THAT COMMIT WILL BE LOST.
#
# However, if you remove everything, the rebase will be aborted.
#
# Note that empty commits are commented out
```
Input your final message for this combined commit in later prompt: `c5`.

The final dev branch will look as follows, then you can merge it to master branch cleanly.

![](http://oonn91xrt.bkt.clouddn.com/rebase_2.png)

The end.

### 7. `git revert`: undo commits and retain history

When you contributed a mistake commit, and it may cause big trouble to your project, you need an emergency revert.

Under some situations, for example in your local dev branch, `git reset` can also revert HEAD to a history commit, but the afterwards commit records will lost forever. And even worser when some others have pushed new commits based on your mistake commit, thus it will be impossible to revert changes imported by that commit and retain afterwards changes.

But `git revert` can make it.

`git revert` is used to record some new commits to reverse the effect of some earlier commits (often only a faulty one).

### 8. `git checkout --ours/--theirs`: fix merge confict in a fast way

Fix merging conflicts is an annoy thing. Many times, you have to fix every confict line by line. Under some conditions, there is a fast way to handle it. The contents from a specific side of the merge can be checked out of the index by using --ours or --theirs

If you are in charge of some modules, and you are quite sure about your local changes to them, then you can ignore remote changes quickly through `git checkout --ours <file path>`. Similarly, using `git checkout --theirs <file path>`, you can checkout your local changes to modules that you are not in charge of, but imported by mistakes.


### 9. `git tag`: release managements

Whenever your project reaches a milestone, you can release it through creating a tag.

```viml
# create a full tag with detailed message
$ git tag -a v1.4 -m "my version 1.4"

# create a lightweight tag, with only checksum infomation.
$ git tag v1.4-lw

```

## Good practice

### Create shortcuts for commands used usually.

You could configure some useful shortcuts through `git config`.

For example, you can add an alias named `git st` to `git status`:

```viml
$ git config --global alias.st status
```

My global aliases are listed as follows, and you can take as a reference.

```viml
alias.ci=commit
alias.st=status
alias.lg=log --graph
alias.psrm=push origin master
alias.plrm=pull origin master
```

### Save and commit as frequently as possible

Git is fault-tolerant. 

Whenever you made a few changes that you thought valuable, please save and commit. Git has provided many useful tools to help you manage these middle commits. You can checkout, reset, rebase, revert and so on.

But please make sure your branch is clean and friendly before merge to master branch.

### Take care when you decide to rewrite history

Git uses snapshots to do version control, and usually you should not modify the history records to make the full history traceable.

But git indeed provides some powerful tools to go back to the history and change history.

Whenever you decide to rewrite history, please be careful and careful.

Quotes a paragraph from `Pro Git` book here:

>One of the cardinal rules of Git is that, since so much work is local within your clone, you have a great deal of freedom to rewrite your history locally. However, once you push your work, it is a different story entirely, and you should consider pushed work as final unless you have good reason to change it. In short, you should avoid pushing your work until you’re happy with it and ready to share it with the rest of the world.
>


## Appendix

**References**:

1. [git scm reference](https://git-scm.com/docs/)
2. [Pro Git 2nd Edition](https://git-scm.com/book/en/v2)
3. [atlassian tutorial](https://www.atlassian.com/git/tutorials/learn-git-with-bitbucket-cloud)


