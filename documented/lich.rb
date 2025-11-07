# Provides functionality for managing Lich settings and database interactions.
# This module contains methods for handling mutexes, database operations, and user settings.
# @example Using the Lich module
#   Lich.init_db
module Lich
  @@hosts_file           = nil
  @@lich_db              = nil
  @@last_warn_deprecated = 0
  @@deprecated_log       = []

  @@db_mutex             ||= Mutex.new

  # settings
  @@display_lichid       = nil # boolean
  @@display_uid          = nil # boolean
  @@display_exits        = nil # boolean
  @@display_stringprocs  = nil # boolean
  @@hide_uid_flag        = nil # boolean
  @@track_autosort_state = nil # boolean
  @@track_dark_mode      = nil # boolean
  @@track_layout_state   = nil # boolean
  @@debug_messaging      = nil # boolean

  # Returns the database mutex for thread safety.
  # @return [Mutex] The mutex used for database operations.
  def self.db_mutex
    @@db_mutex
  end

  # Locks the database mutex to ensure thread safety during operations.
  # @raise [StandardError] If an error occurs while locking the mutex.
  # @example Locking the mutex
  #   Lich.mutex_lock
  def self.mutex_lock
    begin
      self.db_mutex.lock unless self.db_mutex.owned?
    rescue StandardError
      respond "--- Lich: error: Lich.mutex_lock: #{$!}"
      Lich.log "error: Lich.mutex_lock: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
    end
  end

  # Unlocks the database mutex after operations are complete.
  # @raise [StandardError] If an error occurs while unlocking the mutex.
  # @example Unlocking the mutex
  #   Lich.mutex_unlock
  def self.mutex_unlock
    begin
      self.db_mutex.unlock if self.db_mutex.owned?
    rescue StandardError
      respond "--- Lich: error: Lich.mutex_unlock: #{$!}"
      Lich.log "error: Lich.mutex_unlock: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
    end
  end

  # Handles calls to undefined methods, providing a warning for deprecated usage.
  # @param arg1 [Symbol] The name of the method being called.
  # @param arg2 [String] An optional second argument.
  # @return [Object] The result of the Vars.method_missing call.
  # @example Calling a missing method
  #   Lich.some_missing_method
  def Lich.method_missing(arg1, arg2 = '')
    if (Time.now.to_i - @@last_warn_deprecated) > 300
      respond "--- warning: Lich.* variables will stop working in a future version of Lich.  Use Vars.* (offending script: #{Script.current.name || 'unknown'})"
      @@last_warn_deprecated = Time.now.to_i
    end
    Vars.method_missing(arg1, arg2)
  end

  # Determines the location of the front-end based on the provided identifier.
  # @param fe [String] The front-end identifier (e.g., 'wizard', 'stormfront').
  # @return [String, nil] The location of the front-end or nil if not found.
  # @example Seeking a front-end location
  #   location = Lich.seek("wizard")
  def Lich.seek(fe)
    if fe =~ /wizard/
      return $wiz_fe_loc
    elsif fe =~ /stormfront/
      return $sf_fe_loc
    end
    pp "Landed in get_simu_launcher method"
  end

  # Initializes and returns the SQLite3 database connection.
  # @return [SQLite3::Database] The database connection.
  def Lich.db
    @@lich_db ||= SQLite3::Database.new("#{DATA_DIR}/lich.db3")
  end

  # Initializes the database and creates necessary tables if they do not exist.
  # @raise [SQLite3::BusyException] If the database is busy.
  # @example Initializing the database
  #   Lich.init_db
  def Lich.init_db
    begin
      Lich.db.execute("CREATE TABLE IF NOT EXISTS script_setting (script TEXT NOT NULL, name TEXT NOT NULL, value BLOB, PRIMARY KEY(script, name));")
      Lich.db.execute("CREATE TABLE IF NOT EXISTS script_auto_settings (script TEXT NOT NULL, scope TEXT, hash BLOB, PRIMARY KEY(script, scope));")
      Lich.db.execute("CREATE TABLE IF NOT EXISTS lich_settings (name TEXT NOT NULL, value TEXT, PRIMARY KEY(name));")
      Lich.db.execute("CREATE TABLE IF NOT EXISTS uservars (scope TEXT NOT NULL, hash BLOB, PRIMARY KEY(scope));")
      if (RUBY_VERSION =~ /^2\.[012]\./)
        Lich.db.execute("CREATE TABLE IF NOT EXISTS trusted_scripts (name TEXT NOT NULL);")
      end
      Lich.db.execute("CREATE TABLE IF NOT EXISTS simu_game_entry (character TEXT NOT NULL, game_code TEXT NOT NULL, data BLOB, PRIMARY KEY(character, game_code));")
      Lich.db.execute("CREATE TABLE IF NOT EXISTS enable_inventory_boxes (player_id INTEGER NOT NULL, PRIMARY KEY(player_id));")
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
  end

  def Lich.class_variable_get(*_a); nil; end

  def Lich.class_eval(*_a);         nil; end

  def Lich.module_eval(*_a);        nil; end

  # Logs a message to standard error with a timestamp.
  # @param msg [String] The message to log.
  # @example Logging a message
  #   Lich.log("This is a log message")
  def Lich.log(msg)
    $stderr.puts "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}: #{msg}"
  end

  # Logs a deprecation warning for the use of old objects.
  # @param old_object [String] The deprecated object name.
  # @param new_object [String] The recommended replacement object name.
  # @param script_location [String] The location of the script using the deprecated object.
  # @param debug_log [Boolean] Whether to log the message for debugging.
  # @param fe_log [Boolean] Whether to send the message to the front-end.
  # @param limit_log [Boolean] Whether to limit logging of the same message.
  # @return [nil]
  # @example Logging a deprecation
  #   Lich.deprecated("old_method", "new_method")
  def Lich.deprecated(old_object = '', new_object = '', script_location = "#{Script.current.name || 'unknown'}", debug_log: true, fe_log: false, limit_log: true)
    msg = "Deprecated call to #{old_object} used in #{script_location}. Please change to #{new_object} instead!"
    return if limit_log && @@deprecated_log.include?(msg)
    Lich.log(msg) if debug_log
    Lich::Messaging.msg("bold", msg) if fe_log
    @@deprecated_log.push(msg) unless @@deprecated_log.include?(msg)
  end

  # Displays the log of deprecated messages.
  # @return [nil]
  # @example Showing the deprecated log
  #   Lich.show_deprecated_log
  def Lich.show_deprecated_log
    @@deprecated_log.each do |msg|
      respond(msg)
    end
  end

  # Displays a message box with the specified options.
  # @param args [Hash] Options for the message box.
  # @option args [String] :message The message to display.
  # @option args [String] :title The title of the message box.
  # @option args [Symbol] :buttons The buttons to display (:ok_cancel, :yes_no).
  # @option args [Symbol] :icon The icon to display (:error, :question, :warning).
  # @return [Symbol, nil] The response from the message box (:ok, :cancel, :yes, :no) or nil.
  # @example Displaying a message box
  #   response = Lich.msgbox(:message => "Hello, World!", :title => "Greeting")
  def Lich.msgbox(args)
    if defined?(Win32)
      if args[:buttons] == :ok_cancel
        buttons = Win32::MB_OKCANCEL
      elsif args[:buttons] == :yes_no
        buttons = Win32::MB_YESNO
      else
        buttons = Win32::MB_OK
      end
      if args[:icon] == :error
        icon = Win32::MB_ICONERROR
      elsif args[:icon] == :question
        icon = Win32::MB_ICONQUESTION
      elsif args[:icon] == :warning
        icon = Win32::MB_ICONWARNING
      else
        icon = 0
      end
      args[:title] ||= "Lich v#{LICH_VERSION}"
      r = Win32.MessageBox(:lpText => args[:message], :lpCaption => args[:title], :uType => (buttons | icon))
      if r == Win32::IDIOK
        return :ok
      elsif r == Win32::IDICANCEL
        return :cancel
      elsif r == Win32::IDIYES
        return :yes
      elsif r == Win32::IDINO
        return :no
      else
        return nil
      end
    elsif defined?(Gtk)
      if args[:buttons] == :ok_cancel
        buttons = Gtk::MessageDialog::BUTTONS_OK_CANCEL
      elsif args[:buttons] == :yes_no
        buttons = Gtk::MessageDialog::BUTTONS_YES_NO
      else
        buttons = Gtk::MessageDialog::BUTTONS_OK
      end
      if args[:icon] == :error
        type = Gtk::MessageDialog::ERROR
      elsif args[:icon] == :question
        type = Gtk::MessageDialog::QUESTION
      elsif args[:icon] == :warning
        type = Gtk::MessageDialog::WARNING
      else
        type = Gtk::MessageDialog::INFO
      end
      dialog = Gtk::MessageDialog.new(nil, Gtk::Dialog::MODAL, type, buttons, args[:message])
      args[:title] ||= "Lich v#{LICH_VERSION}"
      dialog.title = args[:title]
      response = nil
      dialog.run { |d_r|
        response = d_r
        dialog.destroy
      }
      if response == Gtk::Dialog::RESPONSE_OK
        return :ok
      elsif response == Gtk::Dialog::RESPONSE_CANCEL
        return :cancel
      elsif response == Gtk::Dialog::RESPONSE_YES
        return :yes
      elsif response == Gtk::Dialog::RESPONSE_NO
        return :no
      else
        return nil
      end
    elsif $stdout.isatty
      $stdout.puts(args[:message])
      return nil
    end
  end

  # Retrieves the command for launching the Simutronics game.
  # @return [String, nil] The launcher command or nil if not found.
  def Lich.get_simu_launcher
    if defined?(Win32)
      begin
        launcher_key = Win32.RegOpenKeyEx(:hKey => Win32::HKEY_LOCAL_MACHINE, :lpSubKey => 'Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command', :samDesired => (Win32::KEY_ALL_ACCESS | Win32::KEY_WOW64_32KEY))[:phkResult]
        launcher_cmd = Win32.RegQueryValueEx(:hKey => launcher_key, :lpValueName => 'RealCommand')[:lpData]
        if launcher_cmd.nil? or launcher_cmd.empty?
          launcher_cmd = Win32.RegQueryValueEx(:hKey => launcher_key)[:lpData]
        end
        return launcher_cmd
      ensure
        Win32.RegCloseKey(:hKey => launcher_key) rescue nil
      end
    elsif defined?(Wine)
      launcher_cmd = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\RealCommand')
      unless launcher_cmd and not launcher_cmd.empty?
        launcher_cmd = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\')
      end
      return launcher_cmd
    else
      return nil
    end
  end

  # Links the Lich application to the Simutronics game environment.
  # @return [Boolean] True if linked successfully, false otherwise.
  def Lich.link_to_sge
    if defined?(Win32)
      if Win32.admin?
        begin
          launcher_key = Win32.RegOpenKeyEx(:hKey => Win32::HKEY_LOCAL_MACHINE, :lpSubKey => 'Software\\Simutronics\\Launcher', :samDesired => (Win32::KEY_ALL_ACCESS | Win32::KEY_WOW64_32KEY))[:phkResult]
          r = Win32.RegQueryValueEx(:hKey => launcher_key, :lpValueName => 'RealDirectory')
          if (r[:return] == 0) and not r[:lpData].empty?
            # already linked
            return true
          end

          r = Win32.GetModuleFileName
          unless r[:return] > 0
            # fixme
            return false
          end

          new_launcher_dir = "\"#{r[:lpFilename]}\" \"#{File.expand_path($PROGRAM_NAME)}\" "
          r = Win32.RegQueryValueEx(:hKey => launcher_key, :lpValueName => 'Directory')
          launcher_dir = r[:lpData]
          r = Win32.RegSetValueEx(:hKey => launcher_key, :lpValueName => 'RealDirectory', :dwType => Win32::REG_SZ, :lpData => launcher_dir)
          return false unless (r == 0)

          r = Win32.RegSetValueEx(:hKey => launcher_key, :lpValueName => 'Directory', :dwType => Win32::REG_SZ, :lpData => new_launcher_dir)
          return (r == 0)
        ensure
          Win32.RegCloseKey(:hKey => launcher_key) rescue nil
        end
      else
        begin
          r = Win32.GetModuleFileName
          file = ((r[:return] > 0) ? r[:lpFilename] : 'rubyw.exe')
          params = "#{$PROGRAM_NAME.split(/\/|\\/).last} --link-to-sge"
          r = Win32.ShellExecuteEx(:lpVerb => 'runas', :lpFile => file, :lpDirectory => LICH_DIR.tr("/", "\\"), :lpParameters => params, :fMask => Win32::SEE_MASK_NOCLOSEPROCESS)
          if r[:return] > 0
            process_id = r[:hProcess]
            sleep 0.2 while Win32.GetExitCodeProcess(:hProcess => process_id)[:lpExitCode] == Win32::STILL_ACTIVE
            sleep 3
          else
            Win32.ShellExecute(:lpOperation => 'runas', :lpFile => file, :lpDirectory => LICH_DIR.tr("/", "\\"), :lpParameters => params)
            sleep 6
          end
        rescue
          Lich.msgbox(:message => $!)
        end
      end
    elsif defined?(Wine)
      launch_dir = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\Directory')
      return false unless launch_dir

      lich_launch_dir = "#{File.expand_path($PROGRAM_NAME)} --wine=#{Wine::BIN} --wine-prefix=#{Wine::PREFIX}  "
      result = true
      if launch_dir
        if launch_dir =~ /lich/i
          $stdout.puts "--- warning: Lich appears to already be installed to the registry"
          Lich.log "warning: Lich appears to already be installed to the registry"
          Lich.log 'info: launch_dir: ' + launch_dir
        else
          result = result && Wine.registry_puts('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\RealDirectory', launch_dir)
          result = result && Wine.registry_puts('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\Directory', lich_launch_dir)
        end
      end
      return result
    else
      return false
    end
  end

  # Unlinks the Lich application from the Simutronics game environment.
  # @return [Boolean] True if unlinked successfully, false otherwise.
  def Lich.unlink_from_sge
    if defined?(Win32)
      if Win32.admin?
        begin
          launcher_key = Win32.RegOpenKeyEx(:hKey => Win32::HKEY_LOCAL_MACHINE, :lpSubKey => 'Software\\Simutronics\\Launcher', :samDesired => (Win32::KEY_ALL_ACCESS | Win32::KEY_WOW64_32KEY))[:phkResult]
          real_directory = Win32.RegQueryValueEx(:hKey => launcher_key, :lpValueName => 'RealDirectory')[:lpData]
          if real_directory.nil? or real_directory.empty?
            # not linked
            return true
          end

          r = Win32.RegSetValueEx(:hKey => launcher_key, :lpValueName => 'Directory', :dwType => Win32::REG_SZ, :lpData => real_directory)
          return false unless (r == 0)

          r = Win32.RegDeleteValue(:hKey => launcher_key, :lpValueName => 'RealDirectory')
          return (r == 0)
        ensure
          Win32.RegCloseKey(:hKey => launcher_key) rescue nil
        end
      else
        begin
          r = Win32.GetModuleFileName
          file = ((r[:return] > 0) ? r[:lpFilename] : 'rubyw.exe')
          params = "#{$PROGRAM_NAME.split(/\/|\\/).last} --unlink-from-sge"
          r = Win32.ShellExecuteEx(:lpVerb => 'runas', :lpFile => file, :lpDirectory => LICH_DIR.tr("/", "\\"), :lpParameters => params, :fMask => Win32::SEE_MASK_NOCLOSEPROCESS)
          if r[:return] > 0
            process_id = r[:hProcess]
            sleep 0.2 while Win32.GetExitCodeProcess(:hProcess => process_id)[:lpExitCode] == Win32::STILL_ACTIVE
            sleep 3
          else
            Win32.ShellExecute(:lpOperation => 'runas', :lpFile => file, :lpDirectory => LICH_DIR.tr("/", "\\"), :lpParameters => params)
            sleep 6
          end
        rescue
          Lich.msgbox(:message => $!)
        end
      end
    elsif defined?(Wine)
      real_launch_dir = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\RealDirectory')
      result = true
      if real_launch_dir and not real_launch_dir.empty?
        result = result && Wine.registry_puts('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\Directory', real_launch_dir)
        result = result && Wine.registry_puts('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\RealDirectory', '')
      end
      return result
    else
      return false
    end
  end

  # Links the Lich application to the Simutronics Autolaunch environment.
  # @return [Boolean] True if linked successfully, false otherwise.
  def Lich.link_to_sal
    if defined?(Win32)
      if Win32.admin?
        begin
          # fixme: 64 bit browsers?
          launcher_key = Win32.RegOpenKeyEx(:hKey => Win32::HKEY_LOCAL_MACHINE, :lpSubKey => 'Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command', :samDesired => (Win32::KEY_ALL_ACCESS | Win32::KEY_WOW64_32KEY))[:phkResult]
          r = Win32.RegQueryValueEx(:hKey => launcher_key, :lpValueName => 'RealCommand')
          if (r[:return] == 0) and not r[:lpData].empty?
            # already linked
            return true
          end

          r = Win32.GetModuleFileName
          unless r[:return] > 0
            # fixme
            return false
          end

          new_launcher_cmd = "\"#{r[:lpFilename]}\" \"#{File.expand_path($PROGRAM_NAME)}\" %1"
          r = Win32.RegQueryValueEx(:hKey => launcher_key)
          launcher_cmd = r[:lpData]
          r = Win32.RegSetValueEx(:hKey => launcher_key, :lpValueName => 'RealCommand', :dwType => Win32::REG_SZ, :lpData => launcher_cmd)
          return false unless (r == 0)

          r = Win32.RegSetValueEx(:hKey => launcher_key, :dwType => Win32::REG_SZ, :lpData => new_launcher_cmd)
          return (r == 0)
        ensure
          Win32.RegCloseKey(:hKey => launcher_key) rescue nil
        end
      else
        begin
          r = Win32.GetModuleFileName
          file = ((r[:return] > 0) ? r[:lpFilename] : 'rubyw.exe')
          params = "#{$PROGRAM_NAME.split(/\/|\\/).last} --link-to-sal"
          r = Win32.ShellExecuteEx(:lpVerb => 'runas', :lpFile => file, :lpDirectory => LICH_DIR.tr("/", "\\"), :lpParameters => params, :fMask => Win32::SEE_MASK_NOCLOSEPROCESS)
          if r[:return] > 0
            process_id = r[:hProcess]
            sleep 0.2 while Win32.GetExitCodeProcess(:hProcess => process_id)[:lpExitCode] == Win32::STILL_ACTIVE
            sleep 3
          else
            Win32.ShellExecute(:lpOperation => 'runas', :lpFile => file, :lpDirectory => LICH_DIR.tr("/", "\\"), :lpParameters => params)
            sleep 6
          end
        rescue
          Lich.msgbox(:message => $!)
        end
      end
    elsif defined?(Wine)
      launch_cmd = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\')
      return false unless launch_cmd

      new_launch_cmd = "#{File.expand_path($PROGRAM_NAME)} --wine=#{Wine::BIN} --wine-prefix=#{Wine::PREFIX} %1"
      result = true
      if launch_cmd
        if launch_cmd =~ /lich/i
          $stdout.puts "--- warning: Lich appears to already be installed to the registry"
          Lich.log "warning: Lich appears to already be installed to the registry"
          Lich.log 'info: launch_cmd: ' + launch_cmd
        else
          result = result && Wine.registry_puts('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\RealCommand', launch_cmd)
          result = result && Wine.registry_puts('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\', new_launch_cmd)
        end
      end
      return result
    else
      return false
    end
  end

  # Unlinks the Lich application from the Simutronics Autolaunch environment.
  # @return [Boolean] True if unlinked successfully, false otherwise.
  def Lich.unlink_from_sal
    if defined?(Win32)
      if Win32.admin?
        begin
          launcher_key = Win32.RegOpenKeyEx(:hKey => Win32::HKEY_LOCAL_MACHINE, :lpSubKey => 'Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command', :samDesired => (Win32::KEY_ALL_ACCESS | Win32::KEY_WOW64_32KEY))[:phkResult]
          real_directory = Win32.RegQueryValueEx(:hKey => launcher_key, :lpValueName => 'RealCommand')[:lpData]
          if real_directory.nil? or real_directory.empty?
            # not linked
            return true
          end

          r = Win32.RegSetValueEx(:hKey => launcher_key, :dwType => Win32::REG_SZ, :lpData => real_directory)
          return false unless (r == 0)

          r = Win32.RegDeleteValue(:hKey => launcher_key, :lpValueName => 'RealCommand')
          return (r == 0)
        ensure
          Win32.RegCloseKey(:hKey => launcher_key) rescue nil
        end
      else
        begin
          r = Win32.GetModuleFileName
          file = ((r[:return] > 0) ? r[:lpFilename] : 'rubyw.exe')
          params = "#{$PROGRAM_NAME.split(/\/|\\/).last} --unlink-from-sal"
          r = Win32.ShellExecuteEx(:lpVerb => 'runas', :lpFile => file, :lpDirectory => LICH_DIR.tr("/", "\\"), :lpParameters => params, :fMask => Win32::SEE_MASK_NOCLOSEPROCESS)
          if r[:return] > 0
            process_id = r[:hProcess]
            sleep 0.2 while Win32.GetExitCodeProcess(:hProcess => process_id)[:lpExitCode] == Win32::STILL_ACTIVE
            sleep 3
          else
            Win32.ShellExecute(:lpOperation => 'runas', :lpFile => file, :lpDirectory => LICH_DIR.tr("/", "\\"), :lpParameters => params)
            sleep 6
          end
        rescue
          Lich.msgbox(:message => $!)
        end
      end
    elsif defined?(Wine)
      real_launch_cmd = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\RealCommand')
      result = true
      if real_launch_cmd and not real_launch_cmd.empty?
        result = result && Wine.registry_puts('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\', real_launch_cmd)
        result = result && Wine.registry_puts('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\RealCommand', '')
      end
      return result
    else
      return false
    end
  end

  # Finds and returns the path to the hosts file used by the system.
  # @return [String, false] The path to the hosts file or false if not found.
  def Lich.hosts_file
    Lich.find_hosts_file if @@hosts_file.nil?
    return @@hosts_file
  end

  def Lich.find_hosts_file
    if defined?(Win32)
      begin
        key = Win32.RegOpenKeyEx(:hKey => Win32::HKEY_LOCAL_MACHINE, :lpSubKey => 'System\\CurrentControlSet\\Services\\Tcpip\\Parameters', :samDesired => Win32::KEY_READ)[:phkResult]
        hosts_path = Win32.RegQueryValueEx(:hKey => key, :lpValueName => 'DataBasePath')[:lpData]
      ensure
        Win32.RegCloseKey(:hKey => key) rescue nil
      end
      if hosts_path
        windir = (ENV['windir'] || ENV['SYSTEMROOT'] || 'c:\windows')
        hosts_path.gsub('%SystemRoot%', windir)
        hosts_file = "#{hosts_path}\\hosts"
        if File.exist?(hosts_file)
          return (@@hosts_file = hosts_file)
        end
      end
      if (windir = (ENV['windir'] || ENV['SYSTEMROOT'])) and File.exist?("#{windir}\\system32\\drivers\\etc\\hosts")
        return (@@hosts_file = "#{windir}\\system32\\drivers\\etc\\hosts")
      end

      for drive in ['C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']
        for windir in ['winnt', 'windows']
          if File.exist?("#{drive}:\\#{windir}\\system32\\drivers\\etc\\hosts")
            return (@@hosts_file = "#{drive}:\\#{windir}\\system32\\drivers\\etc\\hosts")
          end
        end
      end
    else # Linux/Mac
      if File.exist?('/etc/hosts')
        return (@@hosts_file = '/etc/hosts')
      elsif File.exist?('/private/etc/hosts')
        return (@@hosts_file = '/private/etc/hosts')
      end
    end
    return (@@hosts_file = false)
  end

  # Modifies the hosts file to include the specified game host.
  # @param game_host [String] The game host to add to the hosts file.
  # @return [Boolean] True if modified successfully, false otherwise.
  def Lich.modify_hosts(game_host)
    if Lich.hosts_file and File.exist?(Lich.hosts_file)
      at_exit { Lich.restore_hosts }
      Lich.restore_hosts
      if File.exist?("#{Lich.hosts_file}.bak")
        return false
      end

      begin
        # copy hosts to hosts.bak
        File.open("#{Lich.hosts_file}.bak", 'w') { |hb| File.open(Lich.hosts_file) { |h| hb.write(h.read) } }
      rescue
        File.unlink("#{Lich.hosts_file}.bak") if File.exist?("#{Lich.hosts_file}.bak")
        return false
      end
      File.open(Lich.hosts_file, 'a') { |f| f.write "\r\n127.0.0.1\t\t#{game_host}" }
      return true
    else
      return false
    end
  end

  # Restores the original hosts file from the backup.
  # @return [nil]
  # @example Restoring hosts
  #   Lich.restore_hosts
  def Lich.restore_hosts
    if Lich.hosts_file and File.exist?(Lich.hosts_file)
      begin
        # fixme: use rename instead?  test rename on windows
        if File.exist?("#{Lich.hosts_file}.bak")
          File.open("#{Lich.hosts_file}.bak") { |infile|
            File.open(Lich.hosts_file, 'w') { |outfile|
              outfile.write(infile.read)
            }
          }
          File.unlink "#{Lich.hosts_file}.bak"
        end
      rescue
        $stdout.puts "--- error: restore_hosts: #{$!}"
        Lich.log "error: restore_hosts: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
        exit(1)
      end
    end
  end

  # Checks if inventory boxes are enabled for the specified player.
  # @param player_id [Integer] The ID of the player.
  # @return [Boolean] True if inventory boxes are enabled, false otherwise.
  def Lich.inventory_boxes(player_id)
    begin
      v = Lich.db.get_first_value('SELECT player_id FROM enable_inventory_boxes WHERE player_id=?;', [player_id.to_i])
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    if v
      true
    else
      false
    end
  end

  # Sets the inventory boxes state for the specified player.
  # @param player_id [Integer] The ID of the player.
  # @param enabled [Boolean] Whether to enable or disable inventory boxes.
  # @return [nil]
  def Lich.set_inventory_boxes(player_id, enabled)
    if enabled
      begin
        Lich.db.execute('INSERT OR REPLACE INTO enable_inventory_boxes values(?);', [player_id.to_i])
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
    else
      begin
        Lich.db.execute('DELETE FROM enable_inventory_boxes where player_id=?;', [player_id.to_i])
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
    end
    nil
  end

  # Retrieves the current Windows launch method setting.
  # @return [String] The launch method setting.
  def Lich.win32_launch_method
    begin
      val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='win32_launch_method';")
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    val
  end

  # Sets the Windows launch method setting.
  # @param val [String] The new launch method setting.
  # @return [nil]
  def Lich.win32_launch_method=(val)
    begin
      Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('win32_launch_method',?);", [val.to_s.encode('UTF-8')])
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
  end

  # Fixes the game host and port based on known mappings.
  # @param gamehost [String] The original game host.
  # @param gameport [Integer] The original game port.
  # @return [Array] The fixed game host and port.
  def Lich.fix_game_host_port(gamehost, gameport)
    if (gamehost == 'gs-plat.simutronics.net') and (gameport.to_i == 10121)
      gamehost = 'storm.gs4.game.play.net'
      gameport = 10124
    elsif (gamehost == 'gs3.simutronics.net') and (gameport.to_i == 4900)
      gamehost = 'storm.gs4.game.play.net'
      gameport = 10024
    elsif (gamehost == 'gs4.simutronics.net') and (gameport.to_i == 10321)
      gamehost = 'storm.gs4.game.play.net'
      gameport = 10324
    elsif (gamehost == 'prime.dr.game.play.net') and (gameport.to_i == 4901)
      gamehost = 'dr.simutronics.net'
      gameport = 11024
    end
    [gamehost, gameport]
  end

  # Reverts the game host and port to their original values based on known mappings.
  # @param gamehost [String] The current game host.
  # @param gameport [Integer] The current game port.
  # @return [Array] The reverted game host and port.
  def Lich.break_game_host_port(gamehost, gameport)
    if (gamehost == 'storm.gs4.game.play.net') and (gameport.to_i == 10324)
      gamehost = 'gs4.simutronics.net'
      gameport = 10321
    elsif (gamehost == 'storm.gs4.game.play.net') and (gameport.to_i == 10124)
      gamehost = 'gs-plat.simutronics.net'
      gameport = 10121
    elsif (gamehost == 'storm.gs4.game.play.net') and (gameport.to_i == 10024)
      gamehost = 'gs3.simutronics.net'
      gameport = 4900
    elsif (gamehost == 'dr.simutronics.net') and (gameport.to_i == 11024)
      gamehost = 'prime.dr.game.play.net'
      gameport = 4901
    end
    [gamehost, gameport]
  end

  # new feature GUI / internal settings states

  # Retrieves the current debug messaging setting.
  # @return [Boolean] True if debug messaging is enabled, false otherwise.
  def Lich.debug_messaging
    if @@debug_messaging.nil?
      begin
        val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='debug_messaging';")
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
      @@debug_messaging = (val.to_s =~ /on|true|yes/ ? true : false)
      Lich.debug_messaging = @@debug_messaging
    end
    return @@debug_messaging
  end

  # Sets the debug messaging setting.
  # @param val [Boolean] The new debug messaging setting.
  # @return [nil]
  def Lich.debug_messaging=(val)
    @@debug_messaging = (val.to_s =~ /on|true|yes/ ? true : false)
    begin
      Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('debug_messaging',?);", [@@debug_messaging.to_s.encode('UTF-8')])
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    return nil
  end

  # Retrieves the current display Lich ID setting.
  # @return [Boolean] True if display Lich ID is enabled, false otherwise.
  def Lich.display_lichid
    if @@display_lichid.nil?
      begin
        val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='display_lichid';")
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
      val = (XMLData.game =~ /^GS/ ? true : false) if val.nil? and XMLData.game != ""; # default false if DR, otherwise default true
      @@display_lichid = (val.to_s =~ /on|true|yes/ ? true : false) if !val.nil?;
    end
    return @@display_lichid
  end

  # Sets the display Lich ID setting.
  # @param val [Boolean] The new display Lich ID setting.
  # @return [nil]
  def Lich.display_lichid=(val)
    @@display_lichid = (val.to_s =~ /on|true|yes/ ? true : false)
    begin
      Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('display_lichid',?);", [@@display_lichid.to_s.encode('UTF-8')])
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    return nil
  end

  # Retrieves the current hide UID flag setting.
  # @return [Boolean] True if hide UID flag is enabled, false otherwise.
  def Lich.hide_uid_flag
    if @@hide_uid_flag.nil?
      begin
        val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='hide_uid_flag';")
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
      val = false if val.nil? and XMLData.game != ""; # default false
      @@hide_uid_flag = (val.to_s =~ /on|true|yes/ ? true : false) if !val.nil?;
    end
    return @@hide_uid_flag
  end

  # Sets the hide UID flag setting.
  # @param val [Boolean] The new hide UID flag setting.
  # @return [nil]
  def Lich.hide_uid_flag=(val)
    @@hide_uid_flag = (val.to_s =~ /on|true|yes/ ? true : false)
    begin
      Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('hide_uid_flag',?);", [@@hide_uid_flag.to_s.encode('UTF-8')])
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    return nil
  end

  # Retrieves the version with which the core was last updated.
  # @return [String] The version string.
  def Lich.core_updated_with_lich_version
    begin
      val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='core_updated_with_lich_version';")
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    return val.to_s
  end

  # Sets the version with which the core was last updated.
  # @param val [String] The new version string.
  # @return [nil]
  def Lich.core_updated_with_lich_version=(val)
    begin
      Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('core_updated_with_lich_version',?);", [val.to_s.encode('UTF-8')])
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    return nil
  end

  # Retrieves the current display UID setting.
  # @return [Boolean] True if display UID is enabled, false otherwise.
  def Lich.display_uid
    if @@display_uid.nil?
      begin
        val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='display_uid';")
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
      val = (XMLData.game =~ /^GS/ ? true : false) if val.nil? and XMLData.game != ""; # default false if DR, otherwise default true
      @@display_uid = (val.to_s =~ /on|true|yes/ ? true : false) if !val.nil?;
    end
    return @@display_uid
  end

  # Sets the display UID setting.
  # @param val [Boolean] The new display UID setting.
  # @return [nil]
  def Lich.display_uid=(val)
    @@display_uid = (val.to_s =~ /on|true|yes/ ? true : false)
    begin
      Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('display_uid',?);", [@@display_uid.to_s.encode('UTF-8')])
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    return nil
  end

  # Retrieves the current display exits setting.
  # @return [Boolean] True if display exits is enabled, false otherwise.
  def Lich.display_exits
    if @@display_exits.nil?
      begin
        val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='display_exits';")
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
      val = false if val.nil? and XMLData.game != ""; # default false
      @@display_exits = (val.to_s =~ /on|true|yes/ ? true : false) if !val.nil?;
    end
    return @@display_exits
  end

  # Sets the display exits setting.
  # @param val [Boolean] The new display exits setting.
  # @return [nil]
  def Lich.display_exits=(val)
    @@display_exits = (val.to_s =~ /on|true|yes/ ? true : false)
    begin
      Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('display_exits',?);", [@@display_exits.to_s.encode('UTF-8')])
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    return nil
  end

  # Retrieves the current display string procs setting.
  # @return [Boolean] True if display string procs is enabled, false otherwise.
  def Lich.display_stringprocs
    if @@display_stringprocs.nil?
      begin
        val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='display_stringprocs';")
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
      val = false if val.nil? and XMLData.game != ""; # default false
      @@display_stringprocs = (val.to_s =~ /on|true|yes/ ? true : false) if !val.nil?;
    end
    return @@display_stringprocs
  end

  # Sets the display string procs setting.
  # @param val [Boolean] The new display string procs setting.
  # @return [nil]
  def Lich.display_stringprocs=(val)
    @@display_stringprocs = (val.to_s =~ /on|true|yes/ ? true : false)
    begin
      Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('display_stringprocs',?);", [@@display_stringprocs.to_s.encode('UTF-8')])
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    return nil
  end

  # Retrieves the current track autosort state setting.
  # @return [Boolean] True if track autosort state is enabled, false otherwise.
  def Lich.track_autosort_state
    if @@track_autosort_state.nil?
      begin
        val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='track_autosort_state';")
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
      @@track_autosort_state = (val.to_s =~ /on|true|yes/ ? true : false)
    end
    return @@track_autosort_state
  end

  # Sets the track autosort state setting.
  # @param val [Boolean] The new track autosort state setting.
  # @return [nil]
  def Lich.track_autosort_state=(val)
    @@track_autosort_state = (val.to_s =~ /on|true|yes/ ? true : false)
    begin
      Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('track_autosort_state',?);", [@@track_autosort_state.to_s.encode('UTF-8')])
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    return nil
  end

  # Retrieves the current track dark mode setting.
  # @return [Boolean] True if track dark mode is enabled, false otherwise.
  def Lich.track_dark_mode
    if @@track_dark_mode.nil?
      begin
        val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='track_dark_mode';")
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
      @@track_dark_mode = (val.to_s =~ /on|true|yes/ ? true : false)
    end
    return @@track_dark_mode
  end

  # Sets the track dark mode setting.
  # @param val [Boolean] The new track dark mode setting.
  # @return [nil]
  def Lich.track_dark_mode=(val)
    @@track_dark_mode = (val.to_s =~ /on|true|yes/ ? true : false)
    begin
      Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('track_dark_mode',?);", [@@track_dark_mode.to_s.encode('UTF-8')])
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    return nil
  end

  # Retrieves the current track layout state setting.
  # @return [Boolean] True if track layout state is enabled, false otherwise.
  def Lich.track_layout_state
    if @@track_layout_state.nil?
      begin
        val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='track_layout_state';")
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
      @@track_layout_state = (val.to_s =~ /on|true|yes/ ? true : false)
    end
    return @@track_layout_state
  end

  # Sets the track layout state setting.
  # @param val [Boolean] The new track layout state setting.
  # @return [nil]
  def Lich.track_layout_state=(val)
    @@track_layout_state = (val.to_s =~ /on|true|yes/ ? true : false)
    begin
      Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('track_layout_state',?);", [@@track_layout_state.to_s.encode('UTF-8')])
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    return nil
  end
end
