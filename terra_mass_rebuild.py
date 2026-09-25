import math, json, os, sys

if len(sys.argv) > 1 and sys.argv[1] in ("-h", "--help"):
    print("Prints a formatted list of every package to be pasted into the JSON build Terra workflow, for mass package rebuilds when making new branches/rebuilding frawhide.")
    print("Usage:   python3 mass_rebuild.py [--help | -h]")
    sys.exit(0)

os.system("""
commit=`git rev-list HEAD | tail -n 1`
git diff-index $commit --binary > a
git checkout $commit
git apply a
git add *
git commit -a -m aaaa
anda ci | sed -E 's/^build_matrix=//' > a
""")

build_matrix=json.load(open('a', 'r'))
f = open('mass_rebuild.txt', 'w+')
l = len(build_matrix)
times = math.ceil(l / 256)
for i in range(times):
  f.write(json.dumps(build_matrix[i*256:(i+1)*256],separators=(',', ':')) + '\n\n')
