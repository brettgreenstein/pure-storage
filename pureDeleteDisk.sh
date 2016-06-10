#!/usr/bin/python
# pureDeleteDisk.sh
# Ben Steiner
# benjamin.r.steiner@gmail.com
# 06/09/16
# removes assigned hosts of volumes created from snapshots. deletes the snapshotted volume and eradicates the volume
# STILL MISSING THE REMOVAL OF MULTIPATH ALIAS

#suppress SSL warnings
import requests
requests.packages.urllib3.disable_warnings()

from time import gmtime, strftime, sleep

#variables
purefqdn = "<PURE ADDRESS>"				#fqdn of the pure array
apikey = "<API KEY>"					#api key of user defined in pure array
hostname = "<HOST NAME IN PURE>"		#this is the name of the host in the pure array
cloneString = "cln_"					#volumes starting with this prefix are targeted
volPrefix=cloneString +"tst" 			
volsToDelete=[]
snapsToDelete=[]
volEnvironment="envprod"				#what life cycle environment the snapshot is for. will eventually be passed as a parameter. is appended to the end of the snapshot name within the source volume.

#import pure storage toolkit
from purestorage import purestorage

#connect to the array
print "Connecting to " + purefqdn
purearray = purestorage.FlashArray(target=purefqdn, api_token=apikey)

#prove that we're connected
purearray_info = purearray.get()
print "Connected to " + purearray_info['array_name'] + " Version " + purearray_info['version']

#get list of all volumes on the pure
pureVolumes = purearray.list_volumes()

#find the list of volumes to delete
for pureVolume in pureVolumes:
	if pureVolume['name'].startswith(volPrefix):
		volsToDelete.append(str(pureVolume['name']))

#check to see if there are things to actually delete
if not volsToDelete:
	print "No volumes found, exiting"
	exit()

#gets just snapshots into its own array
pureSnapVolumes = purearray.list_volumes(snap=True)

#finds list of snapshots for each volume
for snapVolume in pureSnapVolumes:
	for cloneVolume in volsToDelete:
		#print cloneVolume, snapVolume['source']
		if snapVolume['source'] in cloneVolume:
			if volEnvironment in snapVolume['name']:
				#now we have a list of snapshots that are part of the target environment
				#that will be put into an array
				snapsToDelete.append(str(snapVolume['name']))


#unassociate from host and delete the targeted volumes that are based on the targeted snapshots
for volToDelete in volsToDelete:
	purearray.disconnect_host(hostname, volToDelete)
	purearray.destroy_volume(volToDelete)
	purearray.eradicate_volume(volToDelete)
	print "destroying " + volToDelete
	

for snapToDelete in snapsToDelete:
	purearray.destroy_volume(snapToDelete)
	purearray.eradicate_volume(snapToDelete)
	print "destroying " + snapToDelete


#disconnect from API
purearray.invalidate_cookie()
