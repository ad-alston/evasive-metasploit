#####################################################
# README.txt
#
# Evasion Applicator Module
# Aubrey Alston (ada2145), Spring 2015 Project
# Intrusion Detection Systems (IDS) Lab
#####################################################

I. Module Overview

The goal of the evasion applicator module is to take Metasploit binaries and modify
them so they evade static analysis, dynamic sandboxing, and reputation-based
methods of malware detection.  The user invokes the module, specifying
a Metasploit payload and a semi-colon-separated list of template-defined
dynamic evasion execution contexts, and the evasion applicator then
generates a modified binary including (a) the encrypted original binary
and (b) a decryption and execution routine that is carried out within
the context(s) given.

The templates used by the module define a programmatic context in which
malicious code is executed.  In this way, programmatic methods of detecting
sandboxing can be used with any Metasploit payload.

Setup:

The evasion applicator module is a Metasploit module, and as such, must be
added to the framework.

   Steps to add the module to the framework:
       [-.  Install Metasploit.)
       1.  Navigate to your Metasploit installation directory.
       2.  Navigate to the Metasploit modules directory.
       3.  In the "auxiliary" directory, add to or create directories "pro/ids".
       4.  Copy evasion_applicator.rb as well as the "evasion_techniques" folder
           and all of its contents to this directory.

Running instructions:

   1.  Start the Metasploit console.
   2.  Issue command "use auxiliary/pro/ids/evasion_applicator"
   3.  Set options as desired. (Metasploit syntax: set [OPTION] [VALUE])
   4.  Issue command "run".

Options:
	EXECUTABLE_NAME (required) - Specifies the name of the modified binary to
	  be output.

	MSFVENOM_PATH (not required) - Specify the directory in which msfvenom
	  relies (may be necessary for some custom Metasploit installations).

	PAYLOAD (required) - Specify the Metasploit payload to be modified.

	PAYLOAD OPTIONS (not required) - Specify a string of Metasploit options to give to the payload
		(e.g. "LHOST=127.0.0.1 LPORT=4500")

	EVASION_STACK (not required) - Specify a semi-colon separated list of evasion templates
	   to be applied.
	   		Example: technique1();technique2(a);technique3(a,b,c)

	   		Parameters can be passed to the template by specifying them within parentheses
	   		as above.


	LIST_TECHNIQUES (not required) - If this option is set to true, causes the module to
	   output available evasion techniques and their required parameters.

II. Understanding and Adding new Evasion Techniques

The evasion applicator module defines and applies evasion techniques using 
user-defined templates which can be found in the "evasion_techniques" folder.

The module implements and expects a template language adhering to the following
syntax:

[Text block containing comments, usage, etc. The contents of this block
are output by the module whent he LIST_TECHNIQUES option is set.]
%% INCLUDE
[Required header files, one per line]
%% DEFINITIONS
[Definition of functions and constants used in the context section;
standard C syntax expected.]
%%
[C code defining pre-decryption and execution context.]
>> EXECUTE [This is the point where the malicious code is executed.]
[C code defining post decryption and execution context.]
%%

Example scenario:

I know that my target's antivirus software attempts to sandbox all 
files, but a flaw in that sandbox is that 1 + 1 will always evaluate
to 1.  (Unrealistic case.)

---------------------------
example-evasion-technique

Verifies that 1 + 1 == 2 before allowing execution of malicious code.

Usage: example-evasion-technique()
%% INCLUDE
%% DEFINITIONS
#define ONE 1
%%
if(ONE + ONE == 2){
>> EXECUTE
}
----------------------------

A template can access parameters it is passed using @@[param number].

---------------------------
example-evasion-technique

Verifies that a + b == c before allowing execution of malicious code.

Usage: example-evasion-technique(a,b,c)
%% INCLUDE
%% DEFINITIONS
%%
if(@@1 + @@2 == @@3){
>> EXECUTE
}
---------------------------

To add a new module, simply create a file adhering to the proper syntax and
semantics and add it to "[metasploit modules folder]/auxiliary/pro/ids/evasion_techniques".
