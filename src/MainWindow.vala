
using Gtk;
using Gst;

namespace SomaFM {

    public class MainWindow : Adw.ApplicationWindow {

private Stack stack;
private Box vbox_player_page;
private Box vbox_edit_page;
private Box search_box;
private dynamic Element player;
private ListBox list_box;
private Adw.EntryRow entry_name;
private Adw.EntryRow entry_url;
private SearchEntry entry_search;
private Button back_button;
private Button add_button;
private Button delete_button;
private Button edit_button;
private Button play_button;
private Button stop_button;
private Button record_button;
private Button stop_record_button;
private Label current_station;
private Recorder recorder;
private Adw.ToastOverlay overlay;
private string directory_path;
private string item;
private int mode;

        public MainWindow(Adw.Application application) {
            GLib.Object(application: application,
                         title: "Soma Radio",
                         resizable: true,
                         default_height: 500);
        }

        construct {
        back_button = new Gtk.Button ();
            back_button.set_icon_name ("go-previous-symbolic");
            back_button.vexpand = false;
        add_button = new Gtk.Button ();
            add_button.set_icon_name ("list-add-symbolic");
            add_button.vexpand = false;
        delete_button = new Gtk.Button ();
            delete_button.set_icon_name ("list-remove-symbolic");
            delete_button.vexpand = false;
        edit_button = new Gtk.Button ();
            edit_button.set_icon_name ("document-edit-symbolic");
            edit_button.vexpand = false;
        play_button = new Gtk.Button();
            play_button.set_icon_name ("media-playback-start-symbolic");
            play_button.vexpand = false;
        stop_button = new Gtk.Button();
            stop_button.set_icon_name ("media-playback-stop-symbolic");
            stop_button.vexpand = false;
        record_button = new Gtk.Button();
            record_button.set_icon_name ("media-record-symbolic");
            record_button.vexpand = false;
        stop_record_button = new Gtk.Button();
            stop_record_button.set_icon_name ("process-stop-symbolic");
            stop_record_button.vexpand = false;
        var menu_button = new Gtk.MenuButton();
            menu_button.set_icon_name ("open-menu-symbolic");
            menu_button.vexpand = false;
        back_button.set_tooltip_text(_("Back"));
        add_button.set_tooltip_text(_("Add station"));
        delete_button.set_tooltip_text(_("Delete station"));
        edit_button.set_tooltip_text(_("Edit station"));
        play_button.set_tooltip_text(_("Play"));
        stop_button.set_tooltip_text(_("Stop"));
        record_button.set_tooltip_text(_("Start recording"));
        stop_record_button.set_tooltip_text(_("Stop recording"));
        back_button.clicked.connect(on_back_clicked);
        add_button.clicked.connect(on_add_clicked);
        delete_button.clicked.connect(on_delete_dialog);
        edit_button.clicked.connect(on_edit_clicked);
        record_button.clicked.connect(on_record_clicked);
        stop_record_button.clicked.connect(on_stop_record_clicked);
        play_button.clicked.connect(on_play_station);
        stop_button.clicked.connect(on_stop_station);
        var headerbar = new Adw.HeaderBar();
        headerbar.pack_start(back_button);
        headerbar.pack_start(add_button);
        headerbar.pack_start(delete_button);
        headerbar.pack_start(edit_button);
        headerbar.pack_end(menu_button);
        headerbar.pack_end(record_button);
        headerbar.pack_end(stop_record_button);
        headerbar.pack_end(stop_button);
        headerbar.pack_end(play_button);
        var search_action = new GLib.SimpleAction ("search", null);
        search_action.activate.connect(()=>{
            if(search_box.is_visible()){
                search_box.hide();
                entry_search.set_text("");
                if(item != null){
                     list_box.select_row(list_box.get_row_at_index(get_index(item)));
                  }
            }else{
                search_box.show();
                entry_search.grab_focus();
              }
            });
        var open_directory_action = new GLib.SimpleAction ("open", null);
        open_directory_action.activate.connect (on_open_directory_clicked);
        var go_to_website_action = new GLib.SimpleAction ("website", null);
        go_to_website_action.activate.connect(on_start_browser_clicked);
        var about_action = new GLib.SimpleAction ("about", null);
        about_action.activate.connect (about);
        var quit_action = new GLib.SimpleAction ("quit", null);
        var app = GLib.Application.get_default();
        quit_action.activate.connect(()=>{
               app.quit();
            });
        app.add_action(search_action);
        app.add_action(open_directory_action);
        app.add_action(go_to_website_action);
        app.add_action(about_action);
        app.add_action(quit_action);
        var menu = new GLib.Menu();
        var item_search = new GLib.MenuItem (_("Search"), "app.search");
        var item_website = new GLib.MenuItem (_("Go to the website somafm.com"), "app.website");
        var item_open = new GLib.MenuItem (_("Open the Records folder"), "app.open");
        var item_about = new GLib.MenuItem (_("About Soma Radio"), "app.about");
        var item_quit = new GLib.MenuItem (_("Quit"), "app.quit");
        menu.append_item (item_search);
        menu.append_item (item_website);
        menu.append_item (item_open);
        menu.append_item (item_about);
        menu.append_item (item_quit);
        var popover = new PopoverMenu.from_model(menu);
        menu_button.set_popover(popover);
        set_widget_visible(back_button,false);
        set_widget_visible(stop_record_button, false);
        set_widget_visible(stop_button,false);
          stack = new Stack();
          stack.set_transition_duration (600);
          stack.set_transition_type (StackTransitionType.SLIDE_LEFT_RIGHT);
          stack.set_margin_end(10);
          stack.set_margin_top(10);
          stack.set_margin_start(10);
          stack.set_margin_bottom(10);
          overlay = new Adw.ToastOverlay();
          overlay.set_child(stack);
          var main_box = new Box(Orientation.VERTICAL, 0);
          main_box.append(headerbar);
          main_box.append(overlay);
          set_content(main_box);

        list_box = new Gtk.ListBox ();
        list_box.vexpand = true;
        list_box.add_css_class("boxed-list");
        list_box.row_selected.connect(on_select_item);
        var scroll = new Gtk.ScrolledWindow () {
            propagate_natural_height = true,
            propagate_natural_width = true
        };
        var clamp = new Adw.Clamp(){
            tightening_threshold = 100,
            margin_top = 5,
            margin_bottom = 5
        };
        clamp.set_child(list_box);

        scroll.set_child(clamp);

        entry_search = new SearchEntry();
        entry_search.hexpand = true;
        entry_search.changed.connect(show_stations);
        var hide_button = new Button();
        hide_button.set_icon_name("window-close-symbolic");
        hide_button.add_css_class("flat");
        search_box = new Box(Orientation.HORIZONTAL,5);
        search_box.margin_start = 30;
        search_box.margin_end = 30;
        search_box.append(entry_search);
        search_box.append(hide_button);
        search_box.hide();
        hide_button.clicked.connect(()=>{
           search_box.hide();
           entry_search.set_text("");
           if(item != null){
               list_box.select_row(list_box.get_row_at_index(get_index(item)));
            }
        });

        current_station = new Label(_("Welcome!"));
        current_station.add_css_class("title-4");
	current_station.wrap = true;
        current_station.wrap_mode = WORD;
   vbox_player_page = new Box(Orientation.VERTICAL,5);
   vbox_player_page.append (search_box);
   vbox_player_page.append (current_station);
   vbox_player_page.append (scroll);
   stack.add_child(vbox_player_page);
   var clear_name = new Button();
        clear_name.set_icon_name("edit-clear-symbolic");
        clear_name.add_css_class("destructive-action");
        clear_name.add_css_class("circular");
        clear_name.valign = Align.CENTER;
        clear_name.visible = false;
        entry_name = new Adw.EntryRow();
        entry_name.add_suffix(clear_name);
        entry_name.set_title(_("Name"));
   var clear_url = new Button();
        clear_url.set_icon_name("edit-clear-symbolic");
        clear_url.add_css_class("destructive-action");
        clear_url.add_css_class("circular");
        clear_url.valign = Align.CENTER;
        clear_url.visible = false;
        entry_url = new Adw.EntryRow();
        entry_url.add_suffix(clear_url);
        entry_url.set_title(_("URL"));
        entry_name.changed.connect((event) => {
            on_entry_change(entry_name, clear_name);
        });
        clear_name.clicked.connect((event) => {
            on_clear_entry(entry_name);
        });
        entry_url.changed.connect((event) => {
            on_entry_change(entry_url, clear_url);
        });
        clear_url.clicked.connect((event) => {
            on_clear_entry(entry_url);
        });
        var list = new ListBox();
        list.add_css_class("boxed-list");
        list.append(entry_name);
        list.append(entry_url);
        var button_ok = new Button.with_label(_("OK"));
        button_ok.add_css_class("suggested-action");
        button_ok.clicked.connect(on_ok_clicked);
        vbox_edit_page = new Box(Orientation.VERTICAL,10);
        vbox_edit_page.margin_start = 20;
        vbox_edit_page.margin_end = 20;
        vbox_edit_page.append(list);
        vbox_edit_page.append(button_ok);
        stack.add_child(vbox_edit_page);
        stack.visible_child = vbox_player_page;
        player = ElementFactory.make ("playbin", "play");
   directory_path = Environment.get_user_data_dir()+"/stations_for_soma_radio";
   GLib.File file = GLib.File.new_for_path(directory_path);
   if(!file.query_exists()){
     try{
        file.make_directory();
     }catch(Error e){
        stderr.printf ("Error: %s\n", e.message);
     }
     create_default_stations();
   }
   show_stations();
   recorder = Recorder.get_default ();
   record_button.set_sensitive(false);
 }
private void on_clear_entry(Adw.EntryRow entry){
    entry.set_text("");
    entry.grab_focus();
}
private void on_entry_change(Adw.EntryRow entry, Gtk.Button clear){
    if (!is_empty(entry.get_text())) {
        clear.set_visible(true);
    } else {
        clear.set_visible(false);
    }
}
 private void on_play_station(){
    var selection = list_box.get_selected_row();
           if (!selection.is_selected()) {
               set_toast(_("Please choose a station"));
               return;
           }
 string uri;
   try {
       FileUtils.get_contents (directory_path+"/"+item, out uri);
   } catch (Error e) {
       alert("",e.message);
       return;
   }
 player.uri = uri;
 player.set_state (State.PLAYING);
 current_station.set_text(_("Now playing: ")+item);
 set_widget_visible(play_button,false);
 set_widget_visible(stop_button,true);
 record_button.set_sensitive(true);
}

private void on_stop_station(){
 player.set_state (State.READY);
 current_station.set_text(_("Stopped"));
 set_widget_visible(play_button,true);
 set_widget_visible(stop_button,false);
 if(recorder.is_recording){
     on_stop_record_clicked();
 }
 record_button.set_sensitive(false);
}

private void on_record_clicked(){
    var selection = list_box.get_selected_row();
    if (!selection.is_selected()) {
        set_toast(_("Please choose a station"));
        return;
    }
try {
   recorder.start_recording();
 } catch (Gst.ParseError e) {
    alert("",e.message);
    return;
 }
 set_widget_visible(record_button,false);
 set_widget_visible(stop_record_button,true);
}

private void on_stop_record_clicked(){
   recorder.stop_recording();
   set_widget_visible(record_button,true);
   set_widget_visible(stop_record_button,false);
}

   private void on_start_browser_clicked(){
       var start_browser_dialog = new Adw.MessageDialog(this, _("Do you want to visit the website somafm.com?"), "");
            start_browser_dialog.add_response("cancel", _("_Cancel"));
            start_browser_dialog.add_response("ok", _("_OK"));
            start_browser_dialog.set_default_response("ok");
            start_browser_dialog.set_close_response("cancel");
            start_browser_dialog.set_response_appearance("ok", SUGGESTED);
            start_browser_dialog.show();
            start_browser_dialog.response.connect((response) => {
                if (response == "ok") {
                    Gtk.show_uri(this, "https://somafm.com/", Gdk.CURRENT_TIME);
                }
                start_browser_dialog.close();
            });
       }
   
   private void on_open_directory_clicked(){
      Gtk.show_uri(this, "file://"+Environment.get_user_data_dir(), Gdk.CURRENT_TIME);
  }  

   private void on_select_item () {
           var selection = list_box.get_selected_row();
           if (!selection.is_selected()) {
               return;
           }
          GLib.Value value = "";
          selection.get_property("title", ref value);
          item = value.get_string();
          recorder.station_name = item;
       }

   private void on_add_clicked () {
              stack.visible_child = vbox_edit_page;
              set_buttons_on_edit_page();
              mode = 1;
              if(!is_empty(entry_name.get_text())){
                    entry_name.set_text("");
              }
              if(!is_empty(entry_url.get_text())){
                    entry_url.set_text("");
              }
  }

   private void on_edit_clicked(){
    var selection = list_box.get_selected_row();
           if (!selection.is_selected()) {
               set_toast(_("Choose a station"));
               return;
           }
        stack.visible_child = vbox_edit_page;
        set_buttons_on_edit_page();
        mode = 0;
        entry_name.set_text(item);
        string url;
        try {
            FileUtils.get_contents (directory_path+"/"+item, out url);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
        entry_url.set_text(url);
   }

   private void on_ok_clicked(){
         if(is_empty(entry_name.get_text())){
		    set_toast(_("Enter the name"));
                    entry_name.grab_focus();
                    return;
		}
		if(is_empty(entry_url.get_text())){
		   set_toast(_("Enter the url"));
                   entry_url.grab_focus();
                   return;
		}
        switch(mode){
            case 0:
		GLib.File select_file = GLib.File.new_for_path(directory_path+"/"+item);
		GLib.File edit_file = GLib.File.new_for_path(directory_path+"/"+entry_name.get_text().strip());
		if (select_file.get_basename() != edit_file.get_basename() && !edit_file.query_exists()){
                FileUtils.rename(select_file.get_path(), edit_file.get_path());
                if(!edit_file.query_exists()){
                    set_toast(_("Rename failed"));
                    return;
                }
                try {
                 FileUtils.set_contents (edit_file.get_path(), entry_url.get_text().strip());
              } catch (Error e) {
                     stderr.printf ("Error: %s\n", e.message);
            }
            }else{
                if (select_file.get_basename() != edit_file.get_basename()) {
                    alert(_("A station with the same name already exists"),"");
                    entry_name.grab_focus();
                    return;
                }
                try {
                 FileUtils.set_contents (edit_file.get_path(), entry_url.get_text().strip());
              } catch (Error e) {
                     stderr.printf ("Error: %s\n", e.message);
             }
            }
            show_stations();
            list_box.select_row(list_box.get_row_at_index(get_index(edit_file.get_basename())));
            break;
            case 1:
	GLib.File file = GLib.File.new_for_path(directory_path+"/"+entry_name.get_text().strip());
        if(file.query_exists()){
            alert(_("A station with the same name already exists"),"");
            entry_name.grab_focus();
            return;
        }
        try {
            FileUtils.set_contents (file.get_path(), entry_url.get_text().strip());
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
        if(!file.query_exists()){
           set_toast(_("Add failed"));
           return;
        }else{
           show_stations();
           list_box.select_row(list_box.get_row_at_index(get_index(file.get_basename())));
        }
        break;
      }
      on_back_clicked();
   }

   private int get_index(string item){
            int index_of_item = 0;
            try {
            Dir dir = Dir.open (directory_path, 0);
            string? name = null;
            int index = 0;
            while ((name = dir.read_name ()) != null) {
                index++;
                if(name == item){
                  index_of_item = index - 1;
                  break;
                }
            }
        } catch (FileError err) {
            stderr.printf (err.message);
          }
          return index_of_item;
        }

   private void on_back_clicked(){
       stack.visible_child = vbox_player_page;
       set_buttons_on_player_page();
   }

   private void on_delete_dialog(){
    var selection = list_box.get_selected_row();
    if (!selection.is_selected()) {
        set_toast(_("Choose a station"));
        return;
    }
           GLib.File file = GLib.File.new_for_path(directory_path+"/"+item);
        var delete_station_dialog = new Adw.MessageDialog(this, _("Delete station ")+file.get_basename()+"?", "");
            delete_station_dialog.add_response("cancel", _("_Cancel"));
            delete_station_dialog.add_response("ok", _("_OK"));
            delete_station_dialog.set_default_response("ok");
            delete_station_dialog.set_close_response("cancel");
            delete_station_dialog.set_response_appearance("ok", SUGGESTED);
            delete_station_dialog.show();
            delete_station_dialog.response.connect((response) => {
                if (response == "ok") {
                    FileUtils.remove (directory_path+"/"+item);
                    if(file.query_exists()){
                       set_toast(_("Delete failed"));
                    }else{
                       show_stations();
                    }
                }
                delete_station_dialog.close();
            });
         }

   private void show_stations () {
           var list = new GLib.List<string> ();
            try {
            Dir dir = Dir.open (directory_path, 0);
            string? name = null;
            while ((name = dir.read_name ()) != null) {
                if(search_box.is_visible()){
                    if(name.down().contains(entry_search.get_text().down())){
                       list.append(name);
                    }
                    }else{
                       list.append(name);
                }
            }
        } catch (FileError err) {
            stderr.printf (err.message);
        }
        for (
            var child = (Gtk.ListBoxRow) list_box.get_last_child ();
                child != null;
                child = (Gtk.ListBoxRow) list_box.get_last_child ()
        ) {
            list_box.remove(child);
        }
           foreach (string item in list) {
                var row = new Adw.ActionRow () {
                title = item
            };
            list_box.append(row);
           }
       }

   private void set_widget_visible (Gtk.Widget widget, bool visible) {
         widget.visible = !visible;
         widget.visible = visible;
  }

   private void set_buttons_on_player_page(){
       set_widget_visible(back_button,false);
       set_widget_visible(add_button,true);
       set_widget_visible(delete_button,true);
       set_widget_visible(edit_button,true);
   }

   private void set_buttons_on_edit_page(){
       set_widget_visible(back_button,true);
       set_widget_visible(add_button,false);
       set_widget_visible(delete_button,false);
       set_widget_visible(edit_button,false);
   }

   private bool is_empty(string str){
        return str.strip().length == 0;
      }

   private void create_default_stations(){
          string[] name_station = {"Groove Salad","Drone Zone","Deep Space One","Indie Pop Rocks!","Space Station Soma","Lush","Secret Agent","Underground 80s","Groove Salad Classic","Left Coast 70s","Folk Forward","Beat Blender","DEF CON Radio","Boot Liquor","Suburbs of Goa","BAGeL Radio","Synphaera Radio","The Trip","Sonic Universe","PopTron","Seven Inch Soul","Fluid","Dub Step Beyond","Illinois Street Lounge","ThistleRadio","Mission Control","Digitalis","Heavyweight Reggae","cliqhop idm","Metal Detector","Vaporwaves","SF 10-33","Covers","Black Rock FM","Doomed (Special)","n5MD Radio","SomaFM Live","SF Police Scanner"};
          string[] url_station = {"http://ice4.somafm.com/groovesalad-256-mp3","http://ice2.somafm.com/dronezone-256-mp3","http://ice4.somafm.com/deepspaceone-128-mp3","http://ice2.somafm.com/indiepop-128-mp3","http://ice6.somafm.com/spacestation-128-mp3","http://ice6.somafm.com/lush-128-mp3","http://ice6.somafm.com/secretagent-128-mp3","http://ice6.somafm.com/u80s-256-mp3","http://ice2.somafm.com/gsclassic-128-mp3","http://ice2.somafm.com/seventies-320-mp3","http://ice4.somafm.com/folkfwd-128-mp3","http://ice2.somafm.com/beatblender-128-mp3","http://ice4.somafm.com/defcon-256-mp3","http://ice4.somafm.com/bootliquor-320-mp3","http://ice6.somafm.com/suburbsofgoa-128-mp3","http://ice6.somafm.com/bagel-128-mp3","http://ice6.somafm.com/synphaera-256-mp3","http://ice4.somafm.com/thetrip-128-mp3","http://ice6.somafm.com/sonicuniverse-256-mp3","http://ice2.somafm.com/poptron-128-mp3","http://ice6.somafm.com/7soul-128-mp3","http://ice2.somafm.com/fluid-128-mp3","http://ice4.somafm.com/dubstep-256-mp3","http://ice6.somafm.com/illstreet-128-mp3","http://ice6.somafm.com/thistle-128-mp3","http://ice6.somafm.com/missioncontrol-128-mp3","http://ice4.somafm.com/digitalis-128-mp3","http://ice4.somafm.com/reggae-256-mp3","http://ice4.somafm.com/cliqhop-256-mp3","http://ice6.somafm.com/metal-128-mp3","http://ice4.somafm.com/vaporwaves-128-mp3","http://ice6.somafm.com/sf1033-128-mp3","http://ice2.somafm.com/covers-128-mp3","http://ice2.somafm.com/brfm-128-mp3","http://ice6.somafm.com/specials-128-mp3","http://ice2.somafm.com/n5md-128-mp3","http://ice2.somafm.com/live-128-mp3","http://ice6.somafm.com/scanner-128-mp3"};
          for(int i=0;i<38;i++){
            try {
                 FileUtils.set_contents (directory_path+"/"+name_station[i], url_station[i]);
              } catch (Error e) {
                     stderr.printf ("Error: %s\n", e.message);
             }
          }
   }
    private void about () {
	        var win = new Adw.AboutWindow () {
                application_name = "Soma Radio",
                application_icon = "com.github.alexkdeveloper.somafm",
                version = "1.2.3",
                copyright = "Copyright © 2021-2023 Alex Kryuchkov",
                license_type = License.GPL_3_0,
                developer_name = "Alex Kryuchkov",
                developers = {"Alex Kryuchkov https://github.com/alexkdeveloper"},
                translator_credits = _("translator-credits"),
                website = "https://github.com/alexkdeveloper/somafm",
                issue_url = "https://github.com/alexkdeveloper/somafm/issues"
            };
            win.set_transient_for (this);
            win.show ();
        }
   private void set_toast (string str){
       var toast = new Adw.Toast(str);
       toast.set_timeout(3);
       overlay.add_toast(toast);
   }
   private void alert (string heading, string body){
            var dialog_alert = new Adw.MessageDialog(this, heading, body);
            if (body != "") {
                dialog_alert.set_body(body);
            }
            dialog_alert.add_response("ok", _("_OK"));
            dialog_alert.set_response_appearance("ok", SUGGESTED);
            dialog_alert.response.connect((_) => { dialog_alert.close(); });
            dialog_alert.show();
        }
   }
}
