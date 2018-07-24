---
layout: post
title:  "awk: A Silver bullet you should have"
date:   2018-07-23
excerpt: "Intro to awk programming language"
image: "/images/sed-awk.jpg"
---

## Hello world
awk is a field-oriented pattern processing language with a C-style syntax. We can write our first awk script demonstrating a simple output of "Hello world".

```
echo "" | awk '{print "Hello world"}'
```

A basic awk command is of the following form:

```
awk options 'selection_criteria {action }' input-file > output-file
```
Available options:

```
-f program-file : Reads the AWK program source from the file 
                  program-file, instead of from the 
                  first command line argument.
-F fs            : Use fs for the input field separator
```

You can combine with cat/grep/sed and pipe operator to do more custom operations.

There are many situations where you have the requirements to parse info from original files.

As a software engineer you may often need to dive into log file to debug an issue.

As a data analysist, the first-hand data mined form internet may not be of the format you want, and you want to change it to yours.

## Log parser

Supposed that you get a log file which has thousands of lines and is not in a standard csv-like format(we subtract a segment of it below), you have to perform some analysis based on it.

```
I0713 10:40:47.478701  9083 xxxx.cpp:284] ================================>FPS: 7

I0713 10:43:36.649893 10353 xxxx.cpp:1121] *** DEBUG 5: in removeLostFeatures: invalid/processed feature #: 2/3
```

For example, you want to know about the FPS trends, and then draw a FPS-time graph. Also, you need to extract the invalid and processed features to a file for further process.

You may find it a little tough, and have no idea where to start with. But if you have a basic knowledge about awk, you may think it's so easy.

I give you a simple bash code to implement above task, and you can take a reference.

```
#!/usr/bin/env bash
  
base="${1%/*}/"
echo "working directory: $base"

cat "$@" | grep '>FPS' | awk '{print $NF}' > $base/FPS.txt

cat "$@" | grep 'DEBUG 5' | awk '{print $NF}' | awk 'BEGIN{FS="/"}{print $1, $2}' > $base/lostfeatures.txt

```

Therefore, it will produce two new files with csv-like format, and you can draw it with python or matlab easily.

Done!
## Format tranform

You are assigned a task to tranform every record in a csv file to comma seperated and filter out the records with zero heading or flag_h.

```
time x y heading flag_p flag_h
1531465177.6090000 800834.5063542 2499953.6377944 275.5880000 3 4
1531465177.7030001 800834.2666566 2499953.6450343 275.4430000 3 4
1531465177.7990000 800833.9966345 2499953.6953184 275.4430000 3 4
1531465177.8980000 800833.7414144 2499953.7120665 0.0000000 3 0
1531465178.0000000 800833.4716350 2499953.7638617 280.0000000 3 0
1531465178.0980000 800833.2220336 2499953.8329117 281.1000000 3 0
1531465195.9050000 800822.7892204 2500001.4433829 0.0000000 3 0
1531465196.0079999 800822.7826699 2500001.7420741 0.0000000 3 3
1531465196.1059999 800822.7694385 2500002.0436874 0.0000000 3 3
1531465196.1059999 800822.7694385 2500002.0436874 358.8210000 3 4
1531465196.2100000 800822.7527709 2500002.3459400 358.8210000 3 4
1531465196.2100000 800822.7527709 2500002.3459400 358.8210000 3 4
```

You can probably write a c++ program or python code to do this job, and I am definitely sure that it will work as expected. But I do not think it's the perfect solution.

Let me use awk instead.

```
#!/usr/bin/env bash
  
base="${1%/*}/"
echo "working directory: $base"

cat "$@" | awk -v OFS=, '(NR==1){$1 = $1;print;next} ($NF != 0 && $(NF-2) != 0){$1=$1;print}' > $base/filter_gps.txt> $base/filter.txt
```
Please note that the operation $1=$1 in it has no extra meaning except forcing the reconstruction of the record.

Output file:

```
time,x,y,heading,flag_p,flag_h
1531465177.6090000,800834.5063542,2499953.6377944,275.5880000,3,4
1531465177.7030001,800834.2666566,2499953.6450343,275.4430000,3,4
1531465177.7990000,800833.9966345,2499953.6953184,275.4430000,3,4
1531465196.1059999,800822.7694385,2500002.0436874,358.8210000,3,4
1531465196.2100000,800822.7527709,2500002.3459400,358.8210000,3,4
1531465196.2100000,800822.7527709,2500002.3459400,358.8210000,3,4
```
So cool is it!

## Conclusion

I listed two simple usage about awk, and revealed the great power of text processing with awk.

I will research more about it, and I absolutely believe that it's worth it.

## Appendix

Reference:

1.[ Greg Grothaus: why you should know just little awk](https://gregable.com/2010/09/why-you-should-know-just-little-awk.html)

2.[Jonathan Palardy: Why learn awk](https://blog.jpalardy.com/posts/why-learn-awk/)

3.[Advanced Bash-Scripting Guide](http://tldp.org/LDP/abs/html/awk.html)

4.[gawk](https://www.gnu.org/software/gawk/manual/gawk.html)