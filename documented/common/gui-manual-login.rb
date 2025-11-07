# Lich5 carveout - manual login screen for GUI
# This file is intended to load as part of the loginGUI Gtk queue block method.
# It is a sequential stream presently, so do not (yet) modify to class / module.
# Lich5 carveout - manual login screen for GUI

#
# manual game entry tab
# this file is intended to load as part of the loginGUI Gtk queue block method
# it is a sequential stream presently, so do not (yet) modify to class / module

# Holds the launch data for the game session.
@launch_data = nil
# Entry field for user ID.
user_id_entry = Gtk::Entry.new

# Entry field for password.
pass_entry = Gtk::Entry.new
pass_entry.visibility = false

# Table layout for login fields.
login_table = Gtk::Table.new(2, 2, false)
login_table.attach(Gtk::Label.new('User ID:'), 0, 1, 0, 1, Gtk::AttachOptions::EXPAND | Gtk::AttachOptions::FILL, Gtk::AttachOptions::EXPAND | Gtk::AttachOptions::FILL, 5, 5)
login_table.attach(user_id_entry, 1, 2, 0, 1, Gtk::AttachOptions::EXPAND | Gtk::AttachOptions::FILL, Gtk::AttachOptions::EXPAND | Gtk::AttachOptions::FILL, 5, 5)
login_table.attach(Gtk::Label.new('Password:'), 0, 1, 1, 2, Gtk::AttachOptions::EXPAND | Gtk::AttachOptions::FILL, Gtk::AttachOptions::EXPAND | Gtk::AttachOptions::FILL, 5, 5)
login_table.attach(pass_entry, 1, 2, 1, 2, Gtk::AttachOptions::EXPAND | Gtk::AttachOptions::FILL, Gtk::AttachOptions::EXPAND | Gtk::AttachOptions::FILL, 5, 5)

# Button to disconnect from the game.
# @return [Gtk::Button] The disconnect button.
disconnect_button = Gtk::Button.new(:label => ' Disconnect ')
disconnect_button.sensitive = false

# Button to connect to the game.
# @return [Gtk::Button] The connect button.
connect_button = Gtk::Button.new(:label => ' Connect ')

# Box layout for login buttons.
login_button_box = Gtk::Box.new(:horizontal)
login_button_box.pack_end(connect_button, :expand => false, :fill => false, :padding => 5)
login_button_box.pack_end(disconnect_button, :expand => false, :fill => false, :padding => 5)

# List store for displaying game and character information.
liststore = Gtk::ListStore.new(String, String, String, String)
liststore.set_sort_column_id(1, :ascending)

renderer = Gtk::CellRendererText.new
#         renderer.background = 'white'

# Tree view for displaying the list of games and characters.
treeview = Gtk::TreeView.new(liststore)
treeview.height_request = 160

col = Gtk::TreeViewColumn.new("Game", renderer, :text => 1)
col.resizable = true
treeview.append_column(col)

col = Gtk::TreeViewColumn.new("Character", renderer, :text => 3)
col.resizable = true
treeview.append_column(col)

# Scrolled window for the tree view.
sw = Gtk::ScrolledWindow.new
sw.set_policy(:automatic, :automatic)
sw.add(treeview)

# Radio button option for Wrayth game.
stormfront_option = Gtk::RadioButton.new(:label => 'Wrayth')
wizard_option = Gtk::RadioButton.new(:label => 'Wizard', :member => stormfront_option)
avalon_option = Gtk::RadioButton.new(:label => 'Avalon', :member => stormfront_option)
suks_option = Gtk::RadioButton.new(:label => 'suks', :member => stormfront_option)

frontend_box = Gtk::Box.new(:horizontal, 10)
frontend_box.pack_start(stormfront_option, :expand => false, :fill => false, :padding => 0)
frontend_box.pack_start(wizard_option, :expand => false, :fill => false, :padding => 0)
if RUBY_PLATFORM =~ /darwin/i
  frontend_box.pack_start(avalon_option, :expand => false, :fill => false, :padding => 0)
end
# frontend_box.pack_start(suks_option, false, false, 0)

# Check button for custom launch command option.
custom_launch_option = Gtk::CheckButton.new('Custom launch command')
@custom_launch_entry = Gtk::ComboBoxText.new(:entry => true)
@custom_launch_entry.child.set_placeholder_text("(enter custom launch command)")
@custom_launch_entry.append_text("Wizard.Exe /GGS /H127.0.0.1 /P%port% /K%key%")
@custom_launch_entry.append_text("Stormfront.exe /GGS/Hlocalhost/P%port%/K%key%")
@custom_launch_dir = Gtk::ComboBoxText.new(:entry => true)
@custom_launch_dir.child.set_placeholder_text("(enter working directory for command)")
@custom_launch_dir.append_text("../wizard")
@custom_launch_dir.append_text("../StormFront")

@make_quick_option = Gtk::CheckButton.new('Save this info for quick game entry')

# Button to start playing the selected game.
# @return [Gtk::Button] The play button.
play_button = Gtk::Button.new(:label => ' Play ')
play_button.sensitive = false

play_button_box = Gtk::Box.new(:horizontal)
play_button_box.pack_end(play_button, :expand => false, :fill => false, :padding => 5)

# Main container for the game entry tab.
@game_entry_tab = Gtk::Box.new(:vertical)
@game_entry_tab.border_width = 5
@game_entry_tab.pack_start(login_table, :expand => false, :fill => false, :padding => 0)
@game_entry_tab.pack_start(login_button_box, :expand => false, :fill => false, :padding => 0)
@game_entry_tab.pack_start(sw, :expand => true, :fill => true, :padding => 3)
@game_entry_tab.pack_start(frontend_box, :expand => false, :fill => false, :padding => 3)
@game_entry_tab.pack_start(custom_launch_option, :expand => false, :fill => false, :padding => 3)
@game_entry_tab.pack_start(@custom_launch_entry, :expand => false, :fill => false, :padding => 3)
@game_entry_tab.pack_start(@custom_launch_dir, :expand => false, :fill => false, :padding => 3)
@game_entry_tab.pack_start(@make_quick_option, :expand => false, :fill => false, :padding => 3)
@game_entry_tab.pack_start(play_button_box, :expand => false, :fill => false, :padding => 3)

# Signal connection for toggling custom launch options.
custom_launch_option.signal_connect('toggled') {
  @custom_launch_entry.visible = custom_launch_option.active?
  @custom_launch_dir.visible = custom_launch_option.active?
}

avalon_option.signal_connect('toggled') {
  if avalon_option.active?
    custom_launch_option.active = false
    custom_launch_option.sensitive = false
  else
    custom_launch_option.sensitive = true
  end
}

# Signal connection for the connect button click event.
# @note This method handles the connection logic.
connect_button.signal_connect('clicked') {
  connect_button.sensitive = false
  user_id_entry.sensitive = false
  pass_entry.sensitive = false
  iter = liststore.append
  iter[1] = 'working...'
  Gtk.queue {
    begin
      login_info = EAccess.auth(
        account: user_id_entry.text || argv.account,
        password: pass_entry.text || argv.password,
        legacy: true
      )
    end
    if login_info.to_s =~ /error/i
      @msgbox.call "\nSomething went wrong... probably invalid \nuser id and / or password.\n\nserver response: #{login_info}"
      connect_button.sensitive = true
      disconnect_button.sensitive = false
      user_id_entry.sensitive = true
      pass_entry.sensitive = true
    else

      liststore.clear
      login_info.each do |row|
        iter = liststore.append
        iter[0] = row[:game_code]
        iter[1] = row[:game_name]
        iter[2] = row[:char_code]
        iter[3] = row[:char_name]
      end
      disconnect_button.sensitive = true
    end
    true
  }
}

# Signal connection for when the tree view cursor changes.
treeview.signal_connect('cursor-changed') {
  play_button.sensitive = true
}

# Signal connection for the disconnect button click event.
disconnect_button.signal_connect('clicked') {
  disconnect_button.sensitive = false
  play_button.sensitive = false
  liststore.clear
  connect_button.sensitive = true
  user_id_entry.sensitive = true
  pass_entry.sensitive = true
}

# Signal connection for the play button click event.
# @note This method handles the game launch logic.
play_button.signal_connect('clicked') {
  play_button.sensitive = false
  game_code = treeview.selection.selected[0]
  char_name = treeview.selection.selected[3]

  launch_data_hash = EAccess.auth(
    account: user_id_entry.text,
    password: pass_entry.text,
    character: char_name,
    game_code: game_code
  )

  @launch_data = launch_data_hash.map { |k, v| "#{k.upcase}=#{v}" }
  if wizard_option.active?
    @launch_data.collect! { |line| line.sub(/GAMEFILE=.+/, "GAMEFILE=WIZARD.EXE").sub(/GAME=.+/, "GAME=WIZ") }
  elsif avalon_option.active?
    @launch_data.collect! { |line| line.sub(/GAME=.+/, "GAME=AVALON") }
  elsif suks_option.active?
    @launch_data.collect! { |line| line.sub(/GAMEFILE=.+/, "GAMEFILE=WIZARD.EXE").sub(/GAME=.+/, "GAME=SUKS") }
  end
  if custom_launch_option.active?
    @launch_data.push "CUSTOMLAUNCH=#{@custom_launch_entry.child.text}"
    unless @custom_launch_dir.child.text.empty?
      @launch_data.push "CUSTOMLAUNCHDIR=#{@custom_launch_dir.child.text}"
    end
  end
  if @make_quick_option.active?
    if wizard_option.active?
      frontend = 'wizard'
    elsif stormfront_option.active?
      frontend = 'stormfront'
    elsif avalon_option.active?
      frontend = 'avalon'
    else
      frontend = 'unkown'
    end
    if custom_launch_option.active?
      custom_launch = @custom_launch_entry.child.text
      if @custom_launch_dir.child.text.empty?
        custom_launch_dir = nil
      else
        custom_launch_dir = @custom_launch_dir.child.text
      end
    else
      custom_launch = nil
      custom_launch_dir = nil
    end
    h = { :char_name => treeview.selection.selected[3], :game_code => treeview.selection.selected[0], :game_name => treeview.selection.selected[1], :user_id => user_id_entry.text, :password => pass_entry.text, :frontend => frontend, :custom_launch => custom_launch, :custom_launch_dir => custom_launch_dir }
    @entry_data.push h
    @save_entry_data = true
  end

  if @launch_data
    user_id_entry.text = String.new
    pass_entry.text = String.new
    @window.destroy
    @done = true
  else
    disconnect_button.sensitive = false
    play_button.sensitive = false
    connect_button.sensitive = true
    user_id_entry.sensitive = true
    pass_entry.sensitive = true
  end
}

# Signal connection for user ID entry activation.
user_id_entry.signal_connect('activate') {
  pass_entry.grab_focus
}

# Signal connection for password entry activation.
pass_entry.signal_connect('activate') {
  connect_button.clicked
}
