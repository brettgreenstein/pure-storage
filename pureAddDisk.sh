#!/usr/bin/python
# pureAddDisk.sh
# Ben Steiner
# benjamin.r.steiner@gmail.com
# 06/08/16
#
# This script connects to a pure storage array and discovers all volumes
# that are attached to the host object in the array. If a new volume has been
# added, the script will create a multipath alias for the new volume
# that is named the same as it is on the pure array.
#
# Requires pure python toolkit, sg3_utils, python
# has 0 error checking!



#suppress SSL warnings
import requests
requests.packages.urllib3.disable_warnings()

#import various python things we need
import os
import subprocess
#import shutil

#variables
purefqdn = "<PURE ADDRESS>"
apikey = "<API KEY>"
hwid = "3624a9370"						#HWID that multipathd uses to identify pure storage. might be different for you
hostname = "<HOST NAME IN PURE>"		#this is the name of the host in the pure array
mpathtmp = "/tmp/multipathtmp.conf"
mpathconf = "/etc/multipath.conf"
searchfor = "multipaths"
pureHostVolumes = []
pureVolumes = []

from purestorage import purestorage

#connect to the array
print "Connecting to " + purefqdn
purearray = purestorage.FlashArray(target=purefqdn, api_token=apikey)


purearray_info = purearray.get()
print "Connected to " + purearray_info['array_name'] + " Version " + purearray_info['version']


#get list of volumes attached to host on the pure.
pureHostVolumes = purearray.list_host_connections(hostname)

#get list of all volumes on the pure so the volume serial number can be found
pureVolumes = purearray.list_volumes()

#rescan scsi bus for new luns
os.system("sudo /usr/bin/rescan-scsi-bus.sh")

#refresh multipath
os.system("sudo /sbin/multipath -v2")

#gets list of volumes on the local system through multipath
getLocalVolumes = subprocess.Popen(['sudo', '/sbin/multipathd', 'show', 'maps', 'format', '\"%n\"'], stdout=subprocess.PIPE, universal_newlines=True)

#put local multipath volume list into an iterable format
localVolumes = getLocalVolumes.communicate()[0].decode('utf-8')


#match up pureHostVolume with pureVolume. ending up with a list of volume names that are attached to the host and serial number
#valid fields for pureVolume are source, serial, size, name, and created
for pureVolume in pureVolumes:
	#finding the serial numbers of connected volumes from the pure
	#valid fields for pureHostVolume are vol, name, hgroup and lun
	for pureHostVolume in pureHostVolumes:
		if pureVolume['name'] == pureHostVolume['vol']:
			#print pureHostVolume['vol'], pureVolume['serial']
			#find volumes that are added locally with the default name of the serial number
			for mpath in localVolumes.splitlines():
				#get rid of space characters and converts to lower case
				cleanMpath = (mpath.strip()).lower()
				#multipath puts a vendor identifier of some type before the serial number of the volume. pure's appears to be 3624a9370
				#at least that is what it was on both of our m20's. i set this equal to the hwid variable
				#append the identifier to the front of the string to find its entry in multipath
				#converts to lower case so it will match cleanMpath
				volString = (hwid + pureVolume['serial']).lower()
				#find any local mpath aliases that match the mpathString
				if cleanMpath  == volString:
                			print "Found new volume", pureVolume['name'], "with a size of", pureVolume['size'], "bytes. Created on", pureVolume['created'], "serial number", pureVolume['serial']
					#now that we found a new volume, create a new multipath.conf alias

					#this part reads in the existing multipath.conf line by line. It creates a temp file and write out 
					#multipath.conf line by line until it finds the "multipaths" section. When the script finds 
					#multipaths (the searchfor variable), it inserts the new alias configuration for the new volume.
					#the temp file, with the new alias information, is then copied over the original multipath.conf
					with open(mpathconf) as mpathorig:
						with open(mpathtmp, 'w') as mpathnew:
							lines = mpathorig.readlines()
							for line in lines:
								mpathnew.write(line)
								if line.startswith(searchfor):
									mpathnew.write("multipath {" + "\n")
									mpathnew.write("		no_path_retry		fail" + "\n")
									mpathnew.write("		wwid			" + cleanMpath + "\n")
									mpathnew.write("		alias                   " + pureVolume['name'] + "\n")
									mpathnew.write("		}" + "\n")
									mpathnew.write("\n")

					#copy the temp multipath over the top of the old one
					os.system("sudo cp " + mpathtmp + " " + mpathconf)
					#shutil.copy2(mpathtmp, mpathconf)
					#remove temp file
					os.remove(mpathtmp)
					#restart multipath so the new config will be in place
					os.system("sudo /etc/init.d/multipathd restart")
					
					

#disconnect from API
purearray.invalidate_cookie()

