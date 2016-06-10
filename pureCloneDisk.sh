#!/usr/bin/python
# pureCloneDisk.sh
# Ben Steiner
# benjamin.r.steiner@gmail.com
# 06/09/16
# creates snapshots of specified luns and then clones them to a specified name

#suppress SSL warnings
import requests
requests.packages.urllib3.disable_warnings()

from time import gmtime, strftime, sleep

#variables
purefqdn = "<PURE ADDRESS>"
apikey = "<API KEY>"
volPrefix="tst"							#what the volumes to snapshot begin with. will eventually be passed as a parameter
volsToSnap=[]
snapsToCopy=[]
volEnvironment="envprod"				#what life cycle environment the snapshot is for. will eventually be passed as a parameter. is appended to the end of the snapshot name within the source volume.
clonePrefix="cln_"						#volumes created from snapshots will be named with this prefix
waitTime=10								#how long in seconds to wait between creating snapshots and then creating the volumes

from purestorage import purestorage

#connect to the array
print "Connecting to " + purefqdn
purearray = purestorage.FlashArray(target=purefqdn, api_token=apikey)

#prove that we're connected
purearray_info = purearray.get()
print "Connected to " + purearray_info['array_name'] + " Version " + purearray_info['version']

#get list of all volumes on the pure so the volume serial number can be found
pureVolumes = purearray.list_volumes()

#find the list of volumes to snapshot
for pureVolume in pureVolumes:
	if pureVolume['name'].startswith(volPrefix):
		volsToSnap.append(pureVolume['name'])

#get current time to put into the suffix of the snapshot
#so it can be identified easier
currentTime = strftime("%m%d%y%H%M%S")
snapSuffix = volEnvironment + currentTime

#create snapshots of volumes
purearray.create_snapshots(volsToSnap, suffix=snapSuffix)

#give the pure a chance to make the snapshots
print "Waiting "+ str(waitTime) +" seconds for snapshots to be created"
sleep(waitTime)

#get list of snapshots we just created
snapshots = purearray.list_volumes(snap=True)
for snapshot in snapshots:
        if snapshot['name'].endswith(snapSuffix):
                snapsToCopy.append(snapshot['name'])

#check and see if there are any snapshots
if not snapsToCopy:
        print "no snapshots found"
        exit()

#copy snapshots to new volumes
for copySnap in snapsToCopy:
	#strip timestamp off the end so the volume name is the same
	cleanVol = copySnap.partition(".")[0]
	#build destination volume name
	destVol = clonePrefix + cleanVol
	purearray.copy_volume(copySnap, destVol)
	#print copySnap, "cln_" + cleanVol


#disconnect from API
purearray.invalidate_cookie()
