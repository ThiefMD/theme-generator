namespace ThiefMD {

    public delegate void OnFileCallback (File target);

    public void get_save_location (
        string title,
        string ext,
        string name,
        OnFileCallback callback)
    {
        var dialog = new Gtk.FileDialog ();
        dialog.set_title (title);
        var suggestion = name.replace (" ", "-").replace ("/", "-").replace ("\\", "-");
        if (suggestion == "") {
            suggestion = "my-great-theme";
        }
        var filters = new GLib.ListStore (typeof (Gtk.FileFilter));
        Gtk.FileFilter? default_filter = null;

        if (ext == "xml") {
            var xml = new Gtk.FileFilter ();
            xml.set_filter_name (_("XML file"));
            xml.add_mime_type ("application/xml");
            xml.add_pattern ("*.xml");
            filters.append (xml);
            default_filter = xml;
            dialog.set_initial_name (suggestion + ".xml");
        }

        if (ext == "ultheme") {
            var ultheme = new Gtk.FileFilter ();
            ultheme.set_filter_name (_("Ulysses Theme"));
            ultheme.add_mime_type ("application/zip");
            ultheme.add_pattern ("*.ultheme");
            filters.append (ultheme);
            default_filter = ultheme;
            dialog.set_initial_name (suggestion + ".ultheme");
        }

        if (filters.get_n_items () > 0) {
            dialog.set_filters (filters);
        }
        if (default_filter != null) {
            dialog.set_default_filter (default_filter);
        }

        dialog.save.begin (null, null, (obj, res) => {
            try {
                File target = dialog.save.end (res);
                if (target != null) {
                    callback (target);
                }
            } catch (Error e) {
                warning ("Could not save file: %s", e.message);
            }
        });
    }

    public void get_open_file (
        string title,
        OnFileCallback callback)
    {
        var dialog = new Gtk.FileDialog ();
        dialog.set_title (title);

        var ultheme = new Gtk.FileFilter ();
        ultheme.set_filter_name (_("Ulysses Theme"));
        ultheme.add_pattern ("*.ultheme");
        var filters = new GLib.ListStore (typeof (Gtk.FileFilter));
        filters.append (ultheme);
        dialog.set_filters (filters);
        dialog.set_default_filter (ultheme);

        dialog.open.begin (null, null, (obj, res) => {
            try {
                File target = dialog.open.end (res);
                if (target != null) {
                    callback (target);
                }
            } catch (Error e) {
                warning ("Could not open file: %s", e.message);
            }
        });
    }

    public bool write_ultheme_archive (string target_name) {
        bool success = false;

        return success;
    }

    public Gtk.ColorDialogButton create_color_button (string new_color) {
        var dialog = new Gtk.ColorDialog ();
        Gtk.ColorDialogButton button = new Gtk.ColorDialogButton (dialog);
        try {
            Regex valid_color = new Regex ("^#[A-Fa-f0-9]{6}$");
            GLib.MatchInfo info = null;
            if (valid_color.match (new_color, RegexMatchFlags.ANCHORED, out info)) {
                Ultheme.Color color = Ultheme.Color.from_string (new_color);
                Gdk.RGBA colour = Gdk.RGBA () {
                    red = color.red / 255.0f,
                    green = color.green / 255.0f,
                    blue = color.blue / 255.0f,
                    alpha = 1.0f
                };
                button.rgba = colour;
            }
        } catch (Error e) {
            warning ("Could not set color: %s", e.message);
        }
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
            set_child (my_label);
            set_color_from_string (color);
        }

        public bool set_color_from_string (string new_color) {
            try {
                Regex valid_color = new Regex ("^#[A-Fa-f0-9]{6}$");
                GLib.MatchInfo info = null;
                if (valid_color.match (new_color, RegexMatchFlags.ANCHORED, out info)) {
                    Ultheme.Color color = Ultheme.Color.from_string (new_color);
                    double hue, lum, sat;
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
            set_child (pallet_grid);
        }

        public void update_pallet (ref ColorPalette pallet, bool dark, bool fg) {
            child = null;
            pallet_grid = null;
            build_grid (ref pallet, dark, fg);
            set_child (pallet_grid);
        }

        private void build_grid (ref ColorPalette pallet, bool dark, bool fg) {
            pallet_grid = new Gtk.Grid ();
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

            pallet_grid.show ();
        }
    }
}