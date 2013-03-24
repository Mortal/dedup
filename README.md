Deduplication via hardlinks
===========================

This is a Perl script to deduplicate files given the output from `diff -qsr
DIR1 DIR2`.

All errors and messages are printed to stderr.

When the script is run with `-h`, it prints usage information.

When the script is run with `-n`, it outputs a shell script to stdout
containing calls to `cp -l` which indicate the deduplication to be done.

When the script is run with `-f`, it performs the deduplication (via `unlink`
and `link`; it does not call `cp` itself).

When the script is run with `-v`, it explains why deduplication is not
performed: either because both files have the same inode number (already
deduplicated), or both have more than one hardlink already (odd case).

Example usage
-------------

```sh
$ mkdir a                                       # First, set up folders a and b
$ echo file 1 > a/1                             # with similar contents
$ echo file 2 > a/2
$ cp -r a b
$ echo file 3 > a/3
$ echo file 4 > b/4
$ echo file 5a > a/5
$ echo file 5b > b/5
$ echo file 6 > a/6
$ cp -l a/6 b/6
$ diff -qsr a b                                 # This is the input to dedup.pl
Files a/1 and b/1 are identical
Files a/2 and b/2 are identical
Only in a: 3
Only in b: 4
Files a/5 and b/5 differ
Files a/6 and b/6 are identical
$ diff -qsr a b | perl dedup.pl -nv               # Dry run
a/6 and b/6 have identical inode numbers; skipping
cp -l 'a/1' 'b/1'
cp -l 'a/2' 'b/2'
$ diff -qsr a b | perl dedup.pl -fv               # Perform deduplication
a/6 and b/6 have identical inode numbers; skipping
cp -l 'a/1' 'b/1'
cp -l 'a/2' 'b/2'
$ diff -qsr a b | perl dedup.pl -fv               # Perform deduplication again
a/1 and b/1 have identical inode numbers; skipping
a/2 and b/2 have identical inode numbers; skipping
a/6 and b/6 have identical inode numbers; skipping
```

Author
------

Written by Mathias Rav on March 24, 2013.

License
-------

If you would like to use this project in a free and open source software stack,
let me know via a message on GitHub and I will slam on the license you need.
