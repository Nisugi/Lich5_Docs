# Breaks out CLI options selected at launch.
# This script processes command line arguments for the Lich program.
# @example Running the script
#   ruby argv_options.rb --help
# break out for CLI options selected at launch
# 2024-06-13

# Removes the launcher executable from ARGV.
# This is added to ensure that the launcher executable does not interfere with argument processing.
ARGV.delete_if { |arg| arg =~ /launcher\.exe/i } # added by Simutronics Game Entry

# Stores command line options in a hash.
# @return [Hash] A hash containing the parsed command line options.
@argv_options = Hash.new
# Array to store bad arguments that are not recognized.
bad_args = Array.new

# Iterates over each argument in ARGV.
# @note This loop processes each command line argument to set options.
for arg in ARGV
  # Displays help information for the command line options.
  # @return [void]
  # @example Displaying help
  #   ruby argv_options.rb --help
  if (arg == '-h') or (arg == '--help')
    puts 'Usage:  lich [OPTION]'
    puts ''
    puts 'Options are:'
    puts '  -h, --help            Display this list.'
    puts '  -V, --version         Display the program version number and credits.'
    puts ''
    puts '  -d, --directory       Set the main Lich program directory.'
    puts '      --script-dir      Set the directoy where Lich looks for scripts.'
    puts '      --data-dir        Set the directory where Lich will store script data.'
    puts '      --temp-dir        Set the directory where Lich will store temporary files.'
    puts ''
    puts '  -w, --wizard          Run in Wizard mode (default)'
    puts '  -s, --stormfront      Run in StormFront mode.'
    puts '      --avalon          Run in Avalon mode.'
    puts '      --frostbite       Run in Frosbite mode.'
    puts ''
    puts '      --dark-mode       Enable/disable darkmode without GUI. See example below.'
    puts ''
    puts '      --gemstone        Connect to the Gemstone IV Prime server (default).'
    puts '      --dragonrealms    Connect to the DragonRealms server.'
    puts '      --platinum        Connect to the Gemstone IV/DragonRealms Platinum server.'
    puts '      --test            Connect to the test instance of the selected game server.'
    puts '  -g, --game            Set the IP address and port of the game.  See example below.'
    puts ''
    puts '      --install         Edits the Windows/WINE registry so that Lich is started when logging in using the website or SGE.'
    puts '      --uninstall       Removes Lich from the registry.'
    puts ''
    puts 'The majority of Lich\'s built-in functionality was designed and implemented with Simutronics MUDs in mind (primarily Gemstone IV): as such, many options/features provided by Lich may not be applicable when it is used with a non-Simutronics MUD.  In nearly every aspect of the program, users who are not playing a Simutronics game should be aware that if the description of a feature/option does not sound applicable and/or compatible with the current game, it should be assumed that the feature/option is not.  This particularly applies to in-script methods (commands) that depend heavily on the data received from the game conforming to specific patterns (for instance, it\'s extremely unlikely Lich will know how much "health" your character has left in a non-Simutronics game, and so the "health" script command will most likely return a value of 0).'
    puts ''
    puts 'The level of increase in efficiency when Lich is run in "bare-bones mode" (i.e. started with the --bare argument) depends on the data stream received from a given game, but on average results in a moderate improvement and it\'s recommended that Lich be run this way for any game that does not send "status information" in a format consistent with Simutronics\' GSL or XML encoding schemas.'
    puts ''
    puts ''
    puts 'Examples:'
    puts '  lich -w -d /usr/bin/lich/          (run Lich in Wizard mode using the dir \'/usr/bin/lich/\' as the program\'s home)'
    puts '  lich -g gs3.simutronics.net:4000   (run Lich using the IP address \'gs3.simutronics.net\' and the port number \'4000\')'
    puts '  lich --dragonrealms --test --genie (run Lich connected to DragonRealms Test server for the Genie frontend)'
    puts '  lich --script-dir /mydir/scripts   (run Lich with its script directory set to \'/mydir/scripts\')'
    puts '  lich --bare -g skotos.net:5555     (run in bare-bones mode with the IP address and port of the game set to \'skotos.net:5555\')'
    puts '  lich --login YourCharName --detachable-client=8000 --without-frontend --dark-mode=true'
    puts '       ... (run Lich and login without the GUI in a headless state while enabling dark mode for Lich spawned windows)'
    puts ''
    exit
  # Displays the version information of the Lich program.
  # @return [void]
  # @example Displaying version
  #   ruby argv_options.rb --version
  elsif (arg == '-v') or (arg == '--version')
    puts "The Lich, version #{LICH_VERSION}"
    puts ' (an implementation of the Ruby interpreter by Yukihiro Matsumoto designed to be a \'script engine\' for text-based MUDs)'
    puts ''
    puts '- The Lich program and all material collectively referred to as "The Lich project" is copyright (C) 2005-2006 Murray Miron.'
    puts '- The Gemstone IV and DragonRealms games are copyright (C) Simutronics Corporation.'
    puts '- The Wizard front-end and the StormFront front-end are also copyrighted by the Simutronics Corporation.'
    puts '- Ruby is (C) Yukihiro \'Matz\' Matsumoto.'
    puts ''
    puts 'Thanks to all those who\'ve reported bugs and helped me track down problems on both Windows and Linux.'
    exit
  # Links the Lich program to the Simutronics Game Entry (SGE).
  # @return [void]
  # @example Linking to SGE
  #   ruby argv_options.rb --link-to-sge
  elsif arg == '--link-to-sge'
    result = Lich.link_to_sge
    if $stdout.isatty
      if result
        $stdout.puts "Successfully linked to SGE."
      else
        $stdout.puts "Failed to link to SGE."
      end
    end
    exit
  # Unlinks the Lich program from the Simutronics Game Entry (SGE).
  # @return [void]
  # @example Unlinking from SGE
  #   ruby argv_options.rb --unlink-from-sge
  elsif arg == '--unlink-from-sge'
    result = Lich.unlink_from_sge
    if $stdout.isatty
      if result
        $stdout.puts "Successfully unlinked from SGE."
      else
        $stdout.puts "Failed to unlink from SGE."
      end
    end
    exit
  # Links the Lich program to the Simutronics Application Launcher (SAL).
  # @return [void]
  # @example Linking to SAL
  #   ruby argv_options.rb --link-to-sal
  elsif arg == '--link-to-sal'
    result = Lich.link_to_sal
    if $stdout.isatty
      if result
        $stdout.puts "Successfully linked to SAL files."
      else
        $stdout.puts "Failed to link to SAL files."
      end
    end
    exit
  # Unlinks the Lich program from the Simutronics Application Launcher (SAL).
  # @return [void]
  # @example Unlinking from SAL
  #   ruby argv_options.rb --unlink-from-sal
  elsif arg == '--unlink-from-sal'
    result = Lich.unlink_from_sal
    if $stdout.isatty
      if result
        $stdout.puts "Successfully unlinked from SAL files."
      else
        $stdout.puts "Failed to unlink from SAL files."
      end
    end
    exit
  # Installs the Lich program by linking to SGE and SAL.
  # @deprecated This option is deprecated.
  # @return [void]
  # @example Installing Lich
  #   ruby argv_options.rb --install
  elsif arg == '--install' # deprecated
    if Lich.link_to_sge and Lich.link_to_sal
      $stdout.puts 'Install was successful.'
      Lich.log 'Install was successful.'
    else
      $stdout.puts 'Install failed.'
      Lich.log 'Install failed.'
    end
    exit
  # Uninstalls the Lich program by unlinking from SGE and SAL.
  # @deprecated This option is deprecated.
  # @return [void]
  # @example Uninstalling Lich
  #   ruby argv_options.rb --uninstall
  elsif arg == '--uninstall' # deprecated
    if Lich.unlink_from_sge and Lich.unlink_from_sal
      $stdout.puts 'Uninstall was successful.'
      Lich.log 'Uninstall was successful.'
    else
      $stdout.puts 'Uninstall failed.'
      Lich.log 'Uninstall failed.'
    end
    exit
  # Sets the start scripts option.
  # @param arg [String] The argument containing the start scripts path.
  # @return [void]
  # @example Setting start scripts
  #   ruby argv_options.rb --start-scripts=/path/to/scripts
  elsif arg =~ /^--start-scripts=(.+)$/i
    @argv_options[:start_scripts] = $1
  # Enables the reconnect option.
  # @return [void]
  # @example Enabling reconnect
  #   ruby argv_options.rb --reconnect
  elsif arg =~ /^--reconnect$/i
    @argv_options[:reconnect] = true
  # Sets the reconnect delay option.
  # @param arg [String] The argument containing the reconnect delay value.
  # @return [void]
  # @example Setting reconnect delay
  #   ruby argv_options.rb --reconnect-delay=5
  elsif arg =~ /^--reconnect-delay=(.+)$/i
    @argv_options[:reconnect_delay] = $1
  # Sets the host and port for the game connection.
  # @param arg [String] The argument containing the host and port.
  # @return [void]
  # @example Setting host
  #   ruby argv_options.rb --host=example.com:4000
  elsif arg =~ /^--host=(.+):(.+)$/
    @argv_options[:host] = { :domain => $1, :port => $2.to_i }
  # Sets the hosts file option.
  # @param arg [String] The argument containing the hosts file path.
  # @return [void]
  # @example Setting hosts file
  #   ruby argv_options.rb --hosts-file=/path/to/hosts
  elsif arg =~ /^--hosts-file=(.+)$/i
    @argv_options[:hosts_file] = $1
  # Disables the GUI for the Lich program.
  # @return [void]
  # @example Disabling GUI
  #   ruby argv_options.rb --no-gui
  elsif arg =~ /^--no-gui$/i
    @argv_options[:gui] = false
  # Enables the GUI for the Lich program.
  # @return [void]
  # @example Enabling GUI
  #   ruby argv_options.rb --gui
  elsif arg =~ /^--gui$/i
    @argv_options[:gui] = true
  # Sets the game option.
  # @param arg [String] The argument containing the game name.
  # @return [void]
  # @example Setting game
  #   ruby argv_options.rb --game=Gemstone
  elsif arg =~ /^--game=(.+)$/i
    @argv_options[:game] = $1
  # Sets the account option.
  # @param arg [String] The argument containing the account name.
  # @return [void]
  # @example Setting account
  #   ruby argv_options.rb --account=my_account
  elsif arg =~ /^--account=(.+)$/i
    @argv_options[:account] = $1
  # Sets the password option.
  # @param arg [String] The argument containing the password.
  # @return [void]
  # @example Setting password
  #   ruby argv_options.rb --password=my_password
  elsif arg =~ /^--password=(.+)$/i
    @argv_options[:password] = $1
  # Sets the character option.
  # @param arg [String] The argument containing the character name.
  # @return [void]
  # @example Setting character
  #   ruby argv_options.rb --character=my_character
  elsif arg =~ /^--character=(.+)$/i
    @argv_options[:character] = $1
  # Sets the frontend option.
  # @param arg [String] The argument containing the frontend name.
  # @return [void]
  # @example Setting frontend
  #   ruby argv_options.rb --frontend=my_frontend
  elsif arg =~ /^--frontend=(.+)$/i
    @argv_options[:frontend] = $1
  # Sets the frontend command option.
  # @param arg [String] The argument containing the frontend command.
  # @return [void]
  # @example Setting frontend command
  #   ruby argv_options.rb --frontend-command=my_command
  elsif arg =~ /^--frontend-command=(.+)$/i
    @argv_options[:frontend_command] = $1
  # Enables the save option.
  # @return [void]
  # @example Enabling save
  #   ruby argv_options.rb --save
  elsif arg =~ /^--save$/i
    @argv_options[:save] = true
  # Handles Wine prefix options.
  # @note This option is already used when defining the Wine module.
  elsif arg =~ /^--wine(?:\-prefix)?=.+$/i
    nil # already used when defining the Wine module
  # Sets the SAL file option.
  # @param arg [String] The argument containing the SAL file path.
  # @return [void]
  # @example Setting SAL file
  #   ruby argv_options.rb myfile.sal
  elsif arg =~ /\.sal$|Gse\.~xt$/i
    @argv_options[:sal] = arg
    unless File.exist?(@argv_options[:sal])
      if ARGV.join(' ') =~ /([A-Z]:\\.+?\.(?:sal|~xt))/i
        @argv_options[:sal] = $1
      end
    end
    unless File.exist?(@argv_options[:sal])
      if defined?(Wine)
        @argv_options[:sal] = "#{Wine::PREFIX}/drive_c/#{@argv_options[:sal][3..-1].split('\\').join('/')}"
      end
    end
    bad_args.clear
  # Sets the dark mode option.
  # @param arg [String] The argument containing the dark mode value.
  # @return [void]
  # @example Setting dark mode
  #   ruby argv_options.rb --dark-mode=true
  elsif arg =~ /^--dark-mode=(true|false|on|off)$/i
    value = $1
    if value =~ /^(true|on)$/i
      @argv_options[:dark_mode] = true
    elsif value =~ /^(false|off)$/i
      @argv_options[:dark_mode] = false
    end
    if defined?(Gtk)
      @theme_state = Lich.track_dark_mode = @argv_options[:dark_mode]
      Gtk::Settings.default.gtk_application_prefer_dark_theme = true if @theme_state == true
    end
  else
    bad_args.push(arg)
  end
end
# rubocop:disable Lint/UselessAssignment

# Checks for the hosts directory option.
# @return [void]
# @example Checking hosts directory
#   ruby argv_options.rb --hosts-dir=/path/to/hosts
if (arg = ARGV.find { |a| a == '--hosts-dir' })
  i = ARGV.index(arg)
  ARGV.delete_at(i)
  hosts_dir = ARGV[i]
  ARGV.delete_at(i)
  if hosts_dir and File.exist?(hosts_dir)
    hosts_dir = hosts_dir.tr('\\', '/')
    hosts_dir += '/' unless hosts_dir[-1..-1] == '/'
  else
    $stdout.puts "warning: given hosts directory does not exist: #{hosts_dir}"
    hosts_dir = nil
  end
else
  hosts_dir = nil
end

# Default host for the detachable client.
@detachable_client_host = '127.0.0.1'
@detachable_client_port = nil
# Checks for the detachable client option.
# @return [void]
# @example Checking detachable client
#   ruby argv_options.rb --detachable-client=8000
if (arg = ARGV.find { |a| a =~ /^\-\-detachable\-client=[0-9]+$/ })
  @detachable_client_port = /^\-\-detachable\-client=([0-9]+)$/.match(arg).captures.first
elsif (arg = ARGV.find { |a| a =~ /^\-\-detachable\-client=((?:\d{1,3}\.){3}\d{1,3}):([0-9]{1,5})$/ })
  @detachable_client_host, @detachable_client_port = /^\-\-detachable\-client=((?:\d{1,3}\.){3}\d{1,3}):([0-9]{1,5})$/.match(arg).captures
end

# Checks for the game option.
# @return [void]
# @example Checking game
#   ruby argv_options.rb --game=example_game
if @argv_options[:sal]
  unless File.exist?(@argv_options[:sal])
    Lich.log "error: launch file does not exist: #{@argv_options[:sal]}"
    Lich.msgbox "error: launch file does not exist: #{@argv_options[:sal]}"
    exit
  end
  Lich.log "info: launch file: #{@argv_options[:sal]}"
  if @argv_options[:sal] =~ /SGE\.sal/i
    unless (launcher_cmd = Lich.get_simu_launcher)
      $stdout.puts 'error: failed to find the Simutronics launcher'
      Lich.log 'error: failed to find the Simutronics launcher'
      exit
    end
    launcher_cmd.sub!('%1', @argv_options[:sal])
    Lich.log "info: launcher_cmd: #{launcher_cmd}"
    if defined?(Win32) and launcher_cmd =~ /^"(.*?)"\s*(.*)$/
      dir_file = $1
      param = $2
      dir = dir_file.slice(/^.*[\\\/]/)
      file = dir_file.sub(/^.*[\\\/]/, '')
      operation = (Win32.isXP? ? 'open' : 'runas')
      Win32.ShellExecute(:lpOperation => operation, :lpFile => file, :lpDirectory => dir, :lpParameters => param)
      if r < 33
        Lich.log "error: Win32.ShellExecute returned #{r}; Win32.GetLastError: #{Win32.GetLastError}"
      end
    elsif defined?(Wine)
      system("#{Wine::BIN} #{launcher_cmd}")
    else
      system(launcher_cmd)
    end
    exit
  end
end

# Processes the game option to set host and port.
# @return [void]
# @example Processing game
#   ruby argv_options.rb --game=example_game
if (arg = ARGV.find { |a| (a == '-g') or (a == '--game') })
  @game_host, @game_port = ARGV[ARGV.index(arg) + 1].split(':')
  @game_port = @game_port.to_i
  if ARGV.any? { |arg| (arg == '-s') or (arg == '--stormfront') }
    $frontend = 'stormfront'
  elsif ARGV.any? { |arg| (arg == '-w') or (arg == '--wizard') }
    $frontend = 'wizard'
  elsif ARGV.any? { |arg| arg == '--avalon' }
    $frontend = 'avalon'
  elsif ARGV.any? { |arg| arg == '--frostbite' }
    $frontend = 'frostbite'
  else
    $frontend = 'unknown'
  end
elsif ARGV.include?('--gemstone')
  if ARGV.include?('--platinum')
    $platinum = true
    if ARGV.any? { |arg| (arg == '-s') or (arg == '--stormfront') }
      @game_host = 'storm.gs4.game.play.net'
      @game_port = 10124
      $frontend = 'stormfront'
    else
      @game_host = 'gs-plat.simutronics.net'
      @game_port = 10121
      if ARGV.any? { |arg| arg == '--avalon' }
        $frontend = 'avalon'
      else
        $frontend = 'wizard'
      end
    end
  else
    $platinum = false
    if ARGV.any? { |arg| (arg == '-s') or (arg == '--stormfront') }
      @game_host = 'storm.gs4.game.play.net'
      @game_port = 10024
      $frontend = 'stormfront'
    else
      @game_host = 'gs3.simutronics.net'
      @game_port = 4900
      if ARGV.any? { |arg| arg == '--avalon' }
        $frontend = 'avalon'
      else
        $frontend = 'wizard'
      end
    end
  end
elsif ARGV.include?('--shattered')
  $platinum = false
  if ARGV.any? { |arg| (arg == '-s') or (arg == '--stormfront') }
    @game_host = 'storm.gs4.game.play.net'
    @game_port = 10324
    $frontend = 'stormfront'
  else
    @game_host = 'gs4.simutronics.net'
    @game_port = 10321
    if ARGV.any? { |arg| arg == '--avalon' }
      $frontend = 'avalon'
    else
      $frontend = 'wizard'
    end
  end
elsif ARGV.include?('--fallen')
  $platinum = false
  # Not sure what the port info is for anything else but Genie :(
  if ARGV.any? { |arg| (arg == '-s') or (arg == '--stormfront') }
    $frontend = 'stormfront'
    $stdout.puts "fixme"
    Lich.log "fixme"
    exit
  elsif ARGV.grep(/--genie/).any?
    @game_host = 'dr.simutronics.net'
    @game_port = 11324
    $frontend = 'genie'
  else
    $stdout.puts "fixme"
    Lich.log "fixme"
    exit
  end
elsif ARGV.include?('--dragonrealms')
  if ARGV.include?('--platinum')
    $platinum = true
    if ARGV.any? { |arg| (arg == '-s') or (arg == '--stormfront') }
      $frontend = 'stormfront'
      $stdout.puts "fixme"
      Lich.log "fixme"
      exit
    elsif ARGV.grep(/--genie/).any?
      @game_host = 'dr.simutronics.net'
      @game_port = 11124
      $frontend = 'genie'
    elsif ARGV.grep(/--frostbite/).any?
      @game_host = 'dr.simutronics.net'
      @game_port = 11124
      $frontend = 'frostbite'
    else
      $frontend = 'wizard'
      $stdout.puts "fixme"
      Lich.log "fixme"
      exit
    end
  else
    $platinum = false
    if ARGV.any? { |arg| (arg == '-s') or (arg == '--stormfront') }
      $frontend = 'stormfront'
      $stdout.puts "fixme"
      Lich.log "fixme"
      exit
    elsif ARGV.grep(/--genie/).any?
      @game_host = 'dr.simutronics.net'
      @game_port = ARGV.include?('--test') ? 11624 : 11024
      $frontend = 'genie'
    else
      @game_host = 'dr.simutronics.net'
      @game_port = ARGV.include?('--test') ? 11624 : 11024
      if ARGV.any? { |arg| arg == '--avalon' }
        $frontend = 'avalon'
      elsif ARGV.any? { |arg| arg == '--frostbite' }
        $frontend = 'frostbite'
      else
        $frontend = 'wizard'
      end
    end
  end
else
  @game_host, @game_port = nil, nil
  Lich.log "info: no force-mode info given"
end
# rubocop:enable Lint/UselessAssignment
