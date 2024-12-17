# monikamanager
Console tool adressing your disk memory management.

# Functionalities
Is your disk space cluttered? You download the same files because you forgot that you already have them?
This is where monikamanager comes in handy!
With monikamanager you can:
1. detect copies of files in all directories in the specified path
2. list the biggest files in the specified path location.

# How to use?


# How it actually works?
Script creates .mm database  files  in  every  directory  that  is scanned.
Each  .mm file consists of the list of: filenames-modification‐Time-fileHash-fileSize. 
In order to properly find duplicates or list of biggest files it is obligatory to firstly perform the following operation:
--scan PATH (which creates the .mm files) and then it is possible to  perform the rest of the possible operations.
You can find the rest of the information in the man file. Run:
```bash
man monikamanager
```
