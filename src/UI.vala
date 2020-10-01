namespace ThiefMD {

    public File get_save_location (
        string title,
        string ext)
    {
        var action = Gtk.FileChooserAction.SAVE;
        var chooser = new Gtk.FileChooserNative (title, null, action, "_Save", "_Cancel");
        chooser.set_do_overwrite_confirmation (true);

        chooser.action = action;

        if (ext == "xml") {
            var xml = new Gtk.FileFilter ();
            xml.set_filter_name (_("XML file"));
            xml.add_mime_type ("application/xml");
            xml.add_pattern ("*.xml");
            chooser.add_filter (xml);

            chooser.set_current_name ("my-awesome-theme.xml");
            chooser.set_filter (xml);
        }

        if (ext == "ultheme") {
            var ultheme = new Gtk.FileFilter ();
            ultheme.set_filter_name (_("Ulysses Theme"));
            ultheme.add_mime_type ("application/zip");
            ultheme.add_pattern ("*.ultheme");
            chooser.add_filter (ultheme);

            chooser.set_current_name ("my-awesome-theme.ultheme");
            chooser.set_filter (ultheme);
        }

        File file = null;
        if (chooser.run () == Gtk.ResponseType.ACCEPT) {
            file = chooser.get_file ();
        }

        chooser.destroy ();
        return file;
    }

    public bool write_ultheme_archive (string target_name) {
        bool success = false;

        return success;
    }

    public Gtk.ColorButton create_color_button (string new_color) {
        Gtk.ColorButton button;
        try {
            Regex valid_color = new Regex ("^#[A-Fa-f0-9]{6}$");
            GLib.MatchInfo info = null;
            if (valid_color.match (new_color, RegexMatchFlags.ANCHORED, out info)) {
                Clutter.Color color = Clutter.Color.from_string (new_color);
                Gdk.RGBA colour = Gdk.RGBA () {
                    red = color.red / 255.0,
                    green = color.green / 255.0,
                    blue = color.blue / 255.0,
                    alpha = 1.0
                };
                button = new Gtk.ColorButton.with_rgba (colour);
                return button;
            }
        } catch (Error e) {
            warning ("Could not set color: %s", e.message);
        }

        button = new Gtk.ColorButton ();

        return button;
    }

    public class ThiefColorButton : Gtk.Button {
        public string my_color;
        public string my_title;
        public Gtk.Label my_label;
        public signal void changed ();
        public ThiefColorButton (string color, string title = "  ") {
            my_title = title;
            my_label = new Gtk.Label(my_title);
            my_label.use_markup = true;
            add (my_label);
            set_color_from_string (color);
        }

        public bool set_color_from_string (string new_color) {
            try {
                Regex valid_color = new Regex ("^#[A-Fa-f0-9]{6}$");
                GLib.MatchInfo info = null;
                if (valid_color.match (new_color, RegexMatchFlags.ANCHORED, out info)) {
                    Clutter.Color color = Clutter.Color.from_string (new_color);
                    float hue, lum, sat;
                    color.to_hls (out hue, out lum, out sat);
                    string fg = "#000000";
                    if (hue < 0.4) {
                        fg = "#FFFFFF";
                    }
                    my_color = new_color;
                    my_label.label = "<span background='" + new_color + "' foreground='" + fg + "'>  " + my_title + "  </span>";
                    changed ();
                    return true;
                }
            } catch (Error e) {
                warning ("Could not set color: %s", e.message);
            }

            return false;
        }
    }

    public class PalletPopover : Gtk.Popover {
        public signal void clicked ();
        public int value;
        private Gtk.Grid pallet_grid = null;
        public PalletPopover (ref ColorPalette pallet, bool dark, bool fg) {
            build_grid (ref pallet, dark, fg);
            add (pallet_grid);
        }

        public void update_pallet (ref ColorPalette pallet, bool dark, bool fg) {
            remove (pallet_grid);
            pallet_grid = null;
            build_grid (ref pallet, dark, fg);
            add (pallet_grid);
        }

        private void build_grid (ref ColorPalette pallet, bool dark, bool fg) {
            pallet_grid = new Gtk.Grid ();
            pallet_grid.margin = 6;
            pallet_grid.row_spacing = 6;
            pallet_grid.column_spacing = 12;
            pallet_grid.orientation = Gtk.Orientation.HORIZONTAL;
            string def_color = "";
            if (dark) {
                if (fg) {
                    def_color = pallet.foreground_dark;
                } else {
                    def_color = pallet.background_dark;
                }
            } else {
                if (fg) {
                    def_color = pallet.foreground_light;
                } else {
                    def_color = pallet.background_light;
                }
            }

            ThiefColorButton default_btn = new ThiefColorButton (def_color);
            default_btn.clicked.connect (() => {
                value = -1;
                clicked ();
                this.hide ();
            });
            pallet_grid.attach (default_btn, 0, 0);

            int offset = 0;
            if (dark) {
                foreach (var color in pallet.colors_dark) {
                    ThiefColorButton pallet_color = new ThiefColorButton (color);
                    int val = offset;
                    pallet_color.clicked.connect (() => {
                        value = val;
                        clicked ();
                        this.hide ();
                    });
                    offset++;
                    pallet_grid.attach (pallet_color, offset, 0);
                }
            } else {
                foreach (var color in pallet.colors_light) {
                    ThiefColorButton pallet_color = new ThiefColorButton (color);
                    int val = offset;
                    pallet_color.clicked.connect (() => {
                        value = val;
                        clicked ();
                        this.hide ();
                    });
                    offset++;
                    pallet_grid.attach (pallet_color, offset, 0);
                }
            }

            pallet_grid.show_all ();
        }
    }
}