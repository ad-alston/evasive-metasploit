#####################################################
# README.txt
#
# Multi-dropper Module
# Aubrey Alston (ada2145), Spring 2015 Project
# Intrusion Detection Systems (IDS) Lab
#####################################################

I. Module Overview

The goal of the multi-dropper module is to coordinate the generation and
distribution of evasive malicious executables on a large, organized scale.
Given a set of evasion techniques, the aim is to create one evasive executable
per combination of evasion techniques and to set up a drive-by dropper 
instance to distribute each as a drive-by download.

When all servers are set up, the module will output two files:
attack_urls, a simple text file containing a list of activated drive-by
dropper instances, and attack_mapping, a line-by-line mapping of each
URL in attack_urls to its corresponding evasion stack.

Setup:

The evasion applicator module is a Metasploit module, and as such, must be
added to the framework.

   Steps to add the module to the framework:
       [-.  Install Metasploit.)
       1.  Navigate to your Metasploit installation directory.
       2.  Navigate to the Metasploit modules directory.
       3.  In the "auxiliary" directory, add to or create directories "pro/ids".
       4.  Copy multi_dropper.rb to this directory.

Running instructions:

   1.  Start the Metasploit console.
   2.  Issue command "use auxiliary/pro/ids/multi_dropper"
   3.  Set options as desired. (Metasploit syntax: set [OPTION] [VALUE])
   4.  Issue command "run".

   * NOTE, evasive executables must be generated before the servers are
     started.  See the 'GENERATOR' option below.

Options:
	DROPDIRS (not required) - Specifies specific folder(s) in which to drop the
	  arbitrary file.  To configure the module to drop the file in multiple directories,
	  separate directories using a semi-colon.

	DROPNAME (required) - Specify what to name the file on the machine of vulnerable visitors
		to drive-by dropper servers.

	EXPLOIT (required) - Specify the Metasploit browser exploit to use to gain a covert
	  connection.

	HOST (required) - Specify the host/domain the servers should use.

	URIPATH (required) - Specify the malicious URI path for the drive-by dropper servers.

	NETWORK_EVADE - Set to true to configure the droppers to evade network detection.  
	   This causes all meterpreter sessions to be encoded and introduces packet delay
	   and random space injection. **Note: do not use this option with browser exploits
	   which perform probing OS detection.  This can be easily detected.

	SHELL (required) - Specify the meterpreter shell to be used to drop the files. 

	TARGET - Metasploit target code representing the machine of expected vulnerable visitors 
	   (default is 1 - Windows).

	EVASION_TECHNIQUES - Set of evasion techniques, the combinations of which to be used
	   to generate evasive executables to be distributed by the drive-by dropper 
	   instances.  (The expected syntax is the same as EVASION_STACK for the evasion
	   applicator module.)

	PAYLOAD_EXECUTABLE - The Metasploit payload to be made evasive and then distributed.

	SERVSTART - (For larger combinations of evasion techniques) - the index of the first
	    combination considered in the range of all combinations.

	SERVEND - (For larger combinations of evasion techniques) - the index of the last
	    combination considered in the range of all combinations.

	STARTPORT - The first port in the range of ports to be used by the drive-by
	    dropper instances.

	GENERATOR - If true, generates the evasive executables and indexes them to be
	    used by the drive-by dropper instances.  If false, sets up the drive-by
	    dropper instances.
