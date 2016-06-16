#!/usr/bin/python
# removeMaps.sh
# Ben Steiner
# 06/13/16
#
# If a volume declared in multipath.conf has been deleted or removed 
# from the server, this script will remove the alias 
#from multipath.conf, rescan the scsi bus and restart multipath.
#
#does not require pure python toolkit.



#suppress SSL warnings
import requests
requests.packages.urllib3.disable_warnings()

#import various python things we need
import os
import subprocess

#variables
#mpathconf = "/tmp/multipath.conf"
mpathconf = "/etc/multipath.conf"
perlScript = "cleanMultipath.pl"
confirmedVolumes = []
aliasLines = []

#remove any disks/luns that were removed from the host
os.system("sudo /usr/bin/rescan-scsi-bus.sh -r")

#gets list of volumes on the local system through multipath
getLocalVolumes = subprocess.Popen(['sudo', '/sbin/multipathd', 'show', 'maps', 'format', '\"%n\"'], stdout=subprocess.PIPE, universal_newlines=True)

#put local multipath volume list into an iterable format
localVolumes = (getLocalVolumes.communicate()[0].decode('utf-8')).splitlines()



#read in multipath.conf so we can find the removed disks and remove the entry from multipath
with open(mpathconf) as mpathorig:
	#gets rid of any silly blank lines in multipath.conf
	origMpathLines = mpathorig.readlines()
	#mpathLines = mpathorig.readlines()
	mpathLines = [l.strip() for l in origMpathLines if l.strip()]


#create a list of confirmed volumes that are still connected to the system
#and are in multipath.conf
for localVolume in localVolumes:
	#print localVolume
	#get rid of weird spaces from multipath output
        cleanVolume = (localVolume.strip()).lower()
	for line in mpathLines:
		if "alias" in line.lower():
			#print "looking at: " + cleanVolume
			if cleanVolume in line.lower():
				print "adding to confirmed volumes: " + cleanVolume
				confirmedVolumes.append(cleanVolume)

#check and see if there are any confirmed volumes
if not confirmedVolumes:
        print "no volumes found"
        exit()



#get a list of all mpath aliases in multipath.conf, including aliases that no longer exist
for line in mpathLines:
	cleanLine = (line.strip())
	if "alias" in line:
		tempAlias = cleanLine.split()
		strTempAlias = str(tempAlias[1])
		#aliasLines.append(tempAlias[1])
		aliasLines.append(strTempAlias.lower())

#check and see if there are mpath aliases
if not aliasLines:
        print "no mpath aliases found"
        exit()

#Creates a list of differences between confirmedVolumes and aliasLines. Any differences will be volumes that have been disconnected
#from this system. Found on http://stackoverflow.com/questions/16312730/comparing-two-lists-and-only-printing-the-differences-xoring-two-lists
mpathsToRemove = [i for i in aliasLines+confirmedVolumes if (aliasLines+confirmedVolumes).count(i)==1]

#check and see if there are entries to remove
if not mpathsToRemove:
        print "no mpath entries to remove"
        exit()



#calls cleanMultipath.pl perl script to clean up multipath.conf
for mpathToRemove in mpathsToRemove:
	#had to convert to a string in order for it to pass to the perl script correctly
	strmpathToRemove=str(mpathToRemove)
	print "removing " + strmpathToRemove
	process = subprocess.Popen(['sudo', perlScript, strmpathToRemove, mpathconf], stdout=subprocess.PIPE)
	process.wait()

#restart multipath so the new config will be in place
os.system("sudo /etc/init.d/multipathd restart")
					
					

#disconnect from API
purearray.invalidate_cookie()

