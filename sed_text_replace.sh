-------------------------------------------------------------------------
Linux SED Command
-------------------------------------------------------------------------
Current directory, non-recursive

Non-recursive means sed won’t change files in any subdirectories of the current folder.

Run this command to search all the files in your current directory and replace a given string.

// to replace 'foo' with 'bar'
$ sed -i -- 's/foo/bar/g' *

Here’s what each component of the command does:

-i will change the original, and stands for “in-place.”
s is for substitute, so we can find and replace.
foo is the string we’ll be taking away,
bar is the string we’ll use instead today.
g as in “global” means “all occurrences, please.”
* denotes all file types. (No more rhymes. What a tease.)

You can limit the operation to one file type, such as txt, by using:

sed -i -- 's/foo/bar/g' *.txt

Current directory and subdirectories, recursive

We can supplement sed with find to expand our scope to all the current folder’s subdirectories. This will include any hidden files.

find . -type f -exec sed -i 's/foo/bar/g' {} +

To ignore hidden files (such as .git) you can pass the negation modifier -not -path '*/\.*'.

find . -type f -not -path '*/\.*' -exec sed -i 's/foo/bar/g' {} +

This will exclude any file that has the string /. in its path.

Alternatively, you can limit the operation to file names that end in a certain extension, like Markdown:

find . -type f -name "*.md" -exec sed -i 's/foo/bar/g' {} +

Working with URLs: change the separator

In the case of needing to update a URL, the / separator in your strings will need escaping. It ends up looking like this…

find . -type f -exec sed -i 's/https:\/\/www.oldurl.com\/blog/https:\/\/www.newurl.com\/blog/g' {} +

You can avoid some confusion and mistakes by changing the separator to any non-conflicting character. The character that follows the s will be treated as the separator. In our case, using a , or _ would do. This doesn’t require escaping and is much more readable:

find . -type f -exec sed -i 's_https://www.oldurl.com/blog_https://www.newurl.com/blog_g' {} +



[oracle@tpldbdev:KCMCSD:backup_dmp]$ ls 20200109_MCS*
20200109_MCS_CTR_PROD.dmp  20200109_MCS_PDI_PROD.dmp  20200109_MCS_SMS_PROD.dmp
20200109_MCS_DHG_PROD.dmp  20200109_MCS_PMS_BI.dmp    20200109_MCS_TECHDBA.dmp
20200109_MCS_IDC.dmp       20200109_MCS_POLESTAR.dmp
20200109_MCS_IDC_MON.dmp   20200109_MCS_PSMON.dmp
[oracle@tpldbdev:KCMCSD:backup_dmp]$ ls 20200109_MCS_* | sed 's/20200109_MCS_\(.*\)/mv & \1 /'
mv 20200109_MCS_CTR_PROD.dmp CTR_PROD.dmp
mv 20200109_MCS_DHG_PROD.dmp DHG_PROD.dmp
mv 20200109_MCS_IDC.dmp IDC.dmp
mv 20200109_MCS_IDC_MON.dmp IDC_MON.dmp
mv 20200109_MCS_PDI_PROD.dmp PDI_PROD.dmp
mv 20200109_MCS_PMS_BI.dmp PMS_BI.dmp
mv 20200109_MCS_POLESTAR.dmp POLESTAR.dmp
mv 20200109_MCS_PSMON.dmp PSMON.dmp
mv 20200109_MCS_SMS_PROD.dmp SMS_PROD.dmp
mv 20200109_MCS_TECHDBA.dmp TECHDBA.dmp
[oracle@tpldbdev:KCMCSD:backup_dmp]$ ls 20200109_MCS_* | sed 's/20200109_MCS_\(.*\)/mv & \1 /' | sh

-- replace text in specific files
ls 20200109_MCS_* | sed -i 's/2020/2021/g'  

-----------------------------------------------------------------------------
Windows Powershell Command (like grep and sed)
-----------------------------------------------------------------------------
Today powershell saved me.

For grep there is:

get-content somefile.txt | where { $_ -match "expression"}

and for sed there is:

get-content somefile.txt | %{$_ -replace "expression","replace"}


