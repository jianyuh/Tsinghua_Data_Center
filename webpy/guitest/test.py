import os
import re


fromhost="compute"
tohost="compute2"


cmd="nova list --all-tenants | awk {'print $2'}"
str=os.popen(cmd).read().strip()
instanceIDgroup=re.split('\n',str)

migrationInstaceGroup=[]

for instanceID in instanceIDgroup:
    if instanceID=="":
        continue
    if instanceID=="ID":
        continue
    cmd="nova show "+instanceID+"|grep OS-EXT-SRV-ATTR:host| awk {'print $4'}"
    if os.popen(cmd).read().strip()==fromhost:
        migrationInstaceGroup.append(instanceID)


for instanceID in migrationInstaceGroup:
    print "test:",instanceID
    cmd="nova live-migration "+instanceID+" "+tohost
    print "migration result:",os.popen(cmd).read().strip()

print "finished"


