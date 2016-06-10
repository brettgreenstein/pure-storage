## Synopsis

This is a collection of python scripts that interact with pure storage array's using pure's python toolkit. This was developed on RHEL 6.5 using Python 2.6.6. Requires the pure python tool kit, sg3_utils and device-mapper-multipath are installed. You must create a user on the pure array as well as on the local system where this script runs that is in suoders with ALL=(ALL)       NOPASSWD:ALL.  Please verify the variables match up with what you're trying to do. There is just about zero error checking currently in this set of scripts. Run at your own risk!

## Motivation

I wanted to have a consistent and easy way of snapshotting a set of volumes and creating new volumes from those snapshots.

## Installation

Install the pure python automated tool kit
http://pythonhosted.org//purestorage/installation.html

## API Reference

http://pythonhosted.org//purestorage/api.html

## License

I'm not sure. Use at your own risk!