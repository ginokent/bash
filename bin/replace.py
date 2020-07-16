#!/usr/bin/env python
import argparse,re,sys
# opts
p = argparse.ArgumentParser()
p.add_argument("-r", "--replace", action="store_true")
p.add_argument("-b", "--before",  dest="before")
p.add_argument("-a", "--after",   dest="after")
p.add_argument("-f", "--file",    dest="file")
if len(sys.argv) <= 1:
    p.print_help()
    exit(1)
args = p.parse_args()
# replace
with open(args.file, 'r') as fr:
    before=fr.read()
    after=re.sub(r"%s" % args.before, args.after, before, flags=re.DOTALL)
    if args.replace:
        with open(args.file, 'w') as fw:
            fw.write(after)
    else:
        sys.stdout.write(after)
