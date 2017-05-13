#####################################################
# README.txt
#
# Drive-by Dropper Module
# Aubrey Alston (ada2145), Spring 2015 Project
# Intrusion Detection Systems (IDS) Lab
#####################################################

I. Module Overview

The goal of the drive-by dropper module is to coordinate Metasploit functionality
to configure and create a malicious web-server which will drop an arbitrary
executable in a specified location on the machine of vulnerable visitors.

Setup:

The drive-by dropper module is a Metasploit module, and as such, must be
added to the framework.

   Steps to add the module to the framework:
       [-.  Install Metasploit.)
       1.  Navigate to your Metasploit installation directory.
       2.  Navigate to the Metasploit modules directory.
       3.  In the "auxiliary" directory, add to or create directories "pro/ids".
       4.  Copy driveby_dropper.rb into this directory.

       ** The default option configuration of the drive-by dropper module expects
          an exploit (auxiliary/pro/ids/blind_firefox_crmfrequest) to exist in 
          the framework.  blind_firefox_crmfrequest.rb into this directory as well
          if intending to use the default configuration.

Running instructions:

   1.  Start the Metasploit console.
   2.  Issue command "use auxiliary/pro/ids/driveby_dropper"
   3.  Set options as desired. (Metasploit syntax: set [OPTION] [VALUE])
   4.  Issue command "run".

Options:
	DROPDIRS (not required) - Specifies specific folder(s) in which to drop the
	  arbitrary file.  To configure the module to drop the file in multiple directories,
	  separate directories using a semi-colon.

	DROPFILE (required) - Specify the location of the file to be dropped on the machines
	  of vulnerable visitors.

	DROPNAME (required) - Specify what to name the file on the machine of vulnerable visitors.

	EXPLOIT (required) - Specify the Metasploit browser exploit to use to gain a covert
	  connection.

	HOST (required) - Specify the host/domain the server should use.

	SRVPORT (required) - Specify the port to be used by the server.

    URIPATH (required) - Specify the malicious URI path which will cause the arbitrary file to be
      dropped.

	LPORT (required) - Specify the port to be used in covert connections.

	NETWORK_EVADE - Set to true to configure the dropper to evade network detection.  
	   This causes all meterpreter sessions to be encoded and introduces packet delay
	   and random space injection. **Note: do not use this option with browser exploits
	   which perform probing OS detection.  This can be easily detected.

	SHELL (required) - Specify the meterpreter shell to be used to drop the file. 

	TARGET - Metasploit target code representing the machine of expected vulnerable visitors 
	   (default is 1 - Windows).