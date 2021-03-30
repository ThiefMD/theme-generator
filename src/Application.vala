using Gdk;
using ThiefMD.Enrichments;

namespace ThiefMD {
    public class ThemeGenerator : Gtk.Application {
        private Gtk.SourceView view_dark;
        private Gtk.SourceView view_light;
        private Gtk.SourceBuffer buffer_dark;
        private Gtk.SourceBuffer buffer_light;
        public static string temp_dir;
        public static Gtk.SourceStyleSchemeManager preview_manager;
        public ColorTheme demo;
        private string dark_path;
        private string light_path;
        private string ultheme_path;
        private Gtk.HeaderBar bar;
        private Gtk.Stack stack;
        public signal void state_change ();
        MarkdownEnrichment light_enrich;
        MarkdownEnrichment dark_enrich;

        public ThemeGenerator () {
            Object (
                application_id: "io.github.thiefmd.themegenerator",
                flags: ApplicationFlags.FLAGS_NONE
            );
        }

        protected override void activate () {
            shutdown.connect (on_delete_event);
            temp_dir = Path.build_path (Path.DIR_SEPARATOR_S, Environment.get_tmp_dir (), "theme-generator");
            File temp_location = File.new_for_path (temp_dir);

            if (!temp_location.query_exists ()) {
                if (temp_location.make_directory_with_parents ()) {
                    print ("Created temporary location: %s\n", temp_dir);
                }
            }

            demo = new ColorTheme ();
            build_themes ();

            preview_manager = new Gtk.SourceStyleSchemeManager ();
            preview_manager.append_search_path (temp_dir);
            preview_manager.force_rescan ();

            var window = new Gtk.ApplicationWindow (this);
            window.set_title ("");
            window.set_default_size (800, 600);

            // Attempt to set taskbar icon
            try {
                window.icon = Gtk.IconTheme.get_default ().load_icon ("io.github.thiefmd.themegenerator", Gtk.IconSize.DIALOG, 0);
            } catch (Error e) {
                warning ("Could not set application icon: %s", e.message);
            }

            bar = new Gtk.HeaderBar ();
            bar.set_show_close_button (true);
            bar.set_title ("");

            window.set_titlebar(bar);
            var preview_box = new Gtk.ScrolledWindow (null, null);

            var manager = new Gtk.SourceLanguageManager ();
            string custom_languages = Path.build_path (
                Path.DIR_SEPARATOR_S,
                Build.PKGDATADIR,
                "gtksourceview-4",
                "language-specs");
            string[] language_paths = {
                custom_languages
            };
            manager.set_search_path (language_paths);
            var language = manager.guess_language (null, "text/markdown");

            view_dark = new Gtk.SourceView ();
            view_dark.margin = 0;
            view_dark.show_line_numbers = true;
            view_light.highlight_current_line = true;
            buffer_dark = new Gtk.SourceBuffer.with_language (language);
            buffer_dark.highlight_syntax = true;
            view_dark.set_buffer (buffer_dark);
            view_dark.set_wrap_mode (Gtk.WrapMode.WORD);
            buffer_dark.text = IPSUM;
            dark_enrich = new MarkdownEnrichment ();
            dark_enrich.attach (view_dark);
            dark_enrich.recheck_all ();
            buffer_dark.changed.connect (() => {
                dark_enrich.recheck_all ();
            });

            view_light = new Gtk.SourceView ();
            view_light.margin = 0;
            view_light.show_line_numbers = true;
            view_light.highlight_current_line = true;
            buffer_light = new Gtk.SourceBuffer.with_language (language);
            buffer_light.highlight_syntax = true;
            view_light.set_buffer (buffer_light);
            view_light.set_wrap_mode (Gtk.WrapMode.WORD);
            buffer_light.text = IPSUM;
            light_enrich = new MarkdownEnrichment ();
            light_enrich.attach (view_light);
            light_enrich.recheck_all ();
            buffer_light.changed.connect (() => {
                light_enrich.recheck_all ();
            });

            stack = new Gtk.Stack ();
            stack.add_titled (view_light, _("Light Theme"), _("Light"));
            stack.add_titled (view_dark, _("Dark Theme"), _("Dark"));
            stack.add_titled (export_grid (), _("Export Theme"), _("Export"));

            Gtk.StackSwitcher switcher = new Gtk.StackSwitcher ();
            switcher.set_stack (stack);
            switcher.halign = Gtk.Align.CENTER;

            bar.set_custom_title (switcher);

            Gtk.Button open_button = new Gtk.Button.with_label ("Open");
            open_button.clicked.connect (() => {

                File open_file = get_open_file ("Load Colors From Theme");
                if (open_file.query_exists ()) {
                    load_file (open_file);
                }
            });
            bar.pack_start (open_button);

            preview_box.add (stack);
            preview_box.vexpand = true;
            preview_box.hexpand = true;

            Gtk.Grid window_grid = new Gtk.Grid ();
            window_grid.margin = 0;
            window_grid.row_spacing = 12;
            window_grid.column_spacing = 12;
            window_grid.orientation = Gtk.Orientation.VERTICAL;
            window_grid.hexpand = true;
            window_grid.vexpand = true;

            window_grid.attach (pallet_grid (), 0, 0);
            var syntax_box = new Gtk.ScrolledWindow (null, null);
            syntax_box.add (syntax_grid ());
            syntax_box.vexpand = true;
            syntax_box.hexpand = true;
            syntax_box.show_all ();
            window_grid.attach (syntax_box, 0, 1, 1, 3);
            window_grid.attach (preview_box, 0, 4, 1, 4);

            show_themes ();

            window.add (window_grid);
            window.show_all ();
            bar.show_all ();
        }

        public Gtk.Grid export_grid () {
            Gtk.Grid grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.row_spacing = 6;
            grid.column_spacing = 6;
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.hexpand = true;

            Gtk.Label theme_label = new Gtk.Label (_("ThemeID"));
            Gtk.Entry theme = new Gtk.Entry ();

            Gtk.Label author_label = new Gtk.Label (_("Author"));
            Gtk.Entry author = new Gtk.Entry ();

            Gtk.Button save_light = new Gtk.Button.with_label (_("Save Light"));
            Gtk.Button save_dark = new Gtk.Button.with_label (_("Save Dark"));
            Gtk.Button save_ultheme = new Gtk.Button.with_label (_("Save Ulysses Theme"));

            grid.attach (theme_label, 0, 0);
            grid.attach (theme, 1, 0, 2);
            grid.attach (author_label, 0, 1);
            grid.attach (author, 1, 1, 2);

            grid.attach (save_ultheme, 0, 3, 1);
            grid.attach (save_light, 1, 3, 1);
            grid.attach (save_dark, 2, 3, 1);

            save_light.clicked.connect (() => {
                string theme_name = theme.get_text ().chomp ().chug ();
                string theme_author = author.get_text ().chomp ().chug ();
                if (theme_name == "") {
                    theme_name = "SuperAwesomeTheme";
                }
                if (theme_author == "") {
                    theme_author = "Super Awesome Creator";
                }
                File light_target = get_save_location ("Save Light Theme", "xml");
                if (light_target != null){
                    try {
                        if (light_target.query_exists ()) {
                            light_target.delete ();
                        }
                        demo.build_lightscheme (light_target.get_path (), theme_name, theme_author);
                    } catch (Error e) {
                        warning ("Could not save file: %s", e.message);
                    }
                }
            });

            save_dark.clicked.connect (() => {
                string theme_name = theme.get_text ().chomp ().chug ();
                string theme_author = author.get_text ().chomp ().chug ();
                if (theme_name == "") {
                    theme_name = "SuperAwesomeTheme";
                }
                if (theme_author == "") {
                    theme_author = "Super Awesome Creator";
                }
                File dark_target = get_save_location ("Save Dark Theme", "xml");
                if (dark_target != null){
                    try {
                        if (dark_target.query_exists ()) {
                            dark_target.delete ();
                        }
                        demo.build_darkscheme (dark_target.get_path (), theme_name, theme_author);
                    } catch (Error e) {
                        warning ("Could not save file: %s", e.message);
                    }
                }
            });

            save_ultheme.clicked.connect (() => {
                string theme_name = theme.get_text ().chomp ().chug ();
                string theme_author = author.get_text ().chomp ().chug ();
                if (theme_name == "") {
                    theme_name = "SuperAwesomeTheme";
                }
                if (theme_author == "") {
                    theme_author = "Super Awesome Creator";
                }
                build_real_themes (theme_name, theme_author);
                File ulysses_target = get_save_location ("Save Ulysses Theme", "ultheme");
                if (ulysses_target != null){
                    try {
                        if (ulysses_target.query_exists ()) {
                            ulysses_target.delete ();
                        }
                        File working_dir = File.new_for_path(temp_dir);

                        Archive.Write archive = new Archive.Write ();
                        archive.add_filter_none ();
                        archive.set_format_zip ();
                        archive.open_filename (ulysses_target.get_path ());
                        File ulysses_theme = File.new_for_path(ultheme_path);
                        FileInfo ulysses_theme_info = ulysses_theme.query_info (GLib.FileAttribute.STANDARD_SIZE, GLib.FileQueryInfoFlags.NONE);
                        FileInputStream input_stream = ulysses_theme.read ();
                        DataInputStream data_input_stream = new DataInputStream (input_stream);

                        Archive.Entry entry = new Archive.Entry ();
                        entry.set_pathname (working_dir.get_relative_path (ulysses_theme));
                        entry.set_size ((Archive.int64_t) ulysses_theme_info.get_size ());
                        entry.set_filetype (Archive.FileType.IFREG);
                        entry.set_perm (0644);

                        if (archive.write_header (entry) != Archive.Result.OK) {
                            warning ("Could not save file: %s (%d)", archive.error_string (), archive.errno ());
                            return;
                        }

                        size_t bytes_read;
                        uint8[] buffer = new uint8[64];
                        while (data_input_stream.read_all (buffer, out bytes_read)) {
                            if (bytes_read <= 0) {
                                break;
                            }
                            archive.write_data (buffer);
                        }

                        if (archive.close() != Archive.Result.OK) {
                            warning ("Could not close file: %s (%d)", archive.error_string (), archive.errno ());
                        }
                    } catch (Error e) {
                        warning ("Could not save file: %s", e.message);
                    }
                }
            });

            return grid;
        }

        public Gtk.Grid syntax_grid () {
            Gtk.Grid grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.row_spacing = 6;
            grid.column_spacing = 6;
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.hexpand = true;

            Gtk.Label dark = new Gtk.Label (_("<b>Dark</b>"));
            dark.xalign = 0;
            dark.use_markup = true;
            Gtk.Label light = new Gtk.Label (_("<b>Light</b>"));
            light.xalign = 0;
            light.use_markup = true;

            grid.attach (light, 1, 0);
            grid.attach (dark, 2, 0);

            Gtk.Label headings = new Gtk.Label (_("Headings"));
            grid.attach (headings, 0, 1);
            grid.attach (color_map_item (0, false), 1, 1);
            grid.attach (color_map_item (0, true), 2, 1);

            Gtk.Label strong = new Gtk.Label (_("Strong"));
            grid.attach (strong, 0, 2);
            grid.attach (color_map_item (10, false), 1, 2);
            grid.attach (color_map_item (10, true), 2, 2);

            Gtk.Label emphasis = new Gtk.Label (_("Emphasis"));
            grid.attach (emphasis, 0, 3);
            grid.attach (color_map_item (9, false), 1, 3);
            grid.attach (color_map_item (9, true), 2, 3);

            Gtk.Label strikethrough = new Gtk.Label (_("Deleted"));
            grid.attach (strikethrough, 0, 4);
            grid.attach (color_map_item (11, false), 1, 4);
            grid.attach (color_map_item (11, true), 2, 4);

            Gtk.Label image = new Gtk.Label (_("Image"));
            grid.attach (image, 0, 5);
            grid.attach (color_map_item (8, false), 1, 5);
            grid.attach (color_map_item (8, true), 2, 5);

            Gtk.Label link = new Gtk.Label (_("Link"));
            grid.attach (link, 0, 6);
            grid.attach (color_map_item (5, false), 1, 6);
            grid.attach (color_map_item (5, true), 2, 6);

            Gtk.Label code = new Gtk.Label (_("Inline Code"));
            grid.attach (code, 0, 7);
            grid.attach (color_map_item (2, false), 1, 7);
            grid.attach (color_map_item (2, true), 2, 7);

            Gtk.Label codeblock = new Gtk.Label (_("Code Block"));
            grid.attach (codeblock, 0, 8);
            grid.attach (color_map_item (1, false), 1, 8);
            grid.attach (color_map_item (1, true), 2, 8);

            Gtk.Label comment = new Gtk.Label (_("Comment"));
            grid.attach (comment, 0, 9);
            grid.attach (color_map_item (3, false), 1, 9);
            grid.attach (color_map_item (3, true), 2, 9);

            Gtk.Label blockquote = new Gtk.Label (_("Blockquote"));
            grid.attach (blockquote, 0, 10);
            grid.attach (color_map_item (4, false), 1, 10);
            grid.attach (color_map_item (4, true), 2, 10);

            Gtk.Label listitem = new Gtk.Label (_("List Item"));
            grid.attach (listitem, 0, 11);
            grid.attach (color_map_item (7, false), 1, 11);
            grid.attach (color_map_item (7, true), 2, 11);

            Gtk.Label divider = new Gtk.Label (_("Divider"));
            grid.attach (divider, 0, 12);
            grid.attach (color_map_item (6, false), 1, 12);
            grid.attach (color_map_item (6, true), 2, 12);

            grid.show_all ();
            return grid;
        }

        public ColorMapItem get_item (int index, bool dark) {
            if (dark) {
                switch (index) {
                    case 0:
                        return demo.dark.headings;
                    case 1:
                        return demo.dark.codeblock;
                    case 2:
                        return demo.dark.code;
                    case 3:
                        return demo.dark.comment;
                    case 4:
                        return demo.dark.blockquote;
                    case 5:
                        return demo.dark.link;
                    case 6:
                        return demo.dark.divider;
                    case 7:
                        return demo.dark.orderedList;
                    case 8:
                        return demo.dark.image;
                    case 9:
                        return demo.dark.emph;
                    case 10:
                        return demo.dark.strong;
                    case 11:
                        return demo.dark.strike;
                }
            } else {
                switch (index) {
                    case 0:
                        return demo.light.headings;
                    case 1:
                        return demo.light.codeblock;
                    case 2:
                        return demo.light.code;
                    case 3:
                        return demo.light.comment;
                    case 4:
                        return demo.light.blockquote;
                    case 5:
                        return demo.light.link;
                    case 6:
                        return demo.light.divider;
                    case 7:
                        return demo.light.orderedList;
                    case 8:
                        return demo.light.image;
                    case 9:
                        return demo.light.emph;
                    case 10:
                        return demo.light.strong;
                    case 11:
                        return demo.light.strike;
                }
            }

            return new ColorMapItem (0, 0);
        }

        public Gtk.Grid color_map_item (int elem, bool dark) {
            Gtk.Grid grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.row_spacing = 6;
            grid.column_spacing = 6;
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.hexpand = true;

            ColorMapItem item = get_item (elem, dark);
            if (item == demo.dark.codeblock) {
                dark_enrich.set_code_background ((item.bg >= 0 && item.bg <= 10) ? demo.pallet.colors_dark[item.bg] : demo.pallet.background_dark);
            }
            if (item == demo.light.codeblock) {
                light_enrich.set_code_background ((item.bg >= 0 && item.bg <= 10) ? demo.pallet.colors_light[item.bg] : demo.pallet.background_light);
            }

            string fg_color = "", bg_color = "";
            if (dark){
                bg_color = (item.bg >= 0 && item.bg <= 10) ? demo.pallet.colors_dark[item.bg] : demo.pallet.background_dark;
                fg_color = (item.fg >= 0 && item.fg <= 10) ? demo.pallet.colors_dark[item.fg] : demo.pallet.foreground_dark;
            } else {
                bg_color = (item.bg >= 0 && item.bg <= 10) ? demo.pallet.colors_light[item.bg] : demo.pallet.background_light;
                fg_color = (item.fg >= 0 && item.fg <= 10) ? demo.pallet.colors_light[item.fg] : demo.pallet.foreground_light;
            }
            ThiefColorButton fg_button = new ThiefColorButton (fg_color);
            fg_button.set_tooltip_text (_("Foreground Color"));
            fg_button.clicked.connect (() => {
                PalletPopover popover = new PalletPopover (ref demo.pallet, dark, true);
                popover.set_relative_to (fg_button);
                popover.update_pallet (ref demo.pallet, dark, true);
                popover.popup ();
                popover.clicked.connect (() => {
                    item.fg = popover.value;
                    state_change ();
                    rebuild ();
                });
            });

            ThiefColorButton bg_button = new ThiefColorButton (bg_color);
            bg_button.set_tooltip_text (_("Background Color"));
            bg_button.clicked.connect (() => {
                PalletPopover popover = new PalletPopover (ref demo.pallet, dark, false);
                popover.set_relative_to (bg_button);
                popover.update_pallet (ref demo.pallet, dark, false);
                popover.popup ();
                popover.clicked.connect (() => {
                    item.bg = popover.value;
                    state_change ();
                    rebuild ();
                });
            });

            state_change.connect (() => {
                if (dark){
                    bg_color = (item.bg >= 0 && item.bg <= 10) ? demo.pallet.colors_dark[item.bg] : demo.pallet.background_dark;
                    fg_color = (item.fg >= 0 && item.fg <= 10) ? demo.pallet.colors_dark[item.fg] : demo.pallet.foreground_dark;
                    if (item == demo.dark.codeblock) {
                        dark_enrich.set_code_background (bg_color);
                    }
                } else {
                    bg_color = (item.bg >= 0 && item.bg <= 10) ? demo.pallet.colors_light[item.bg] : demo.pallet.background_light;
                    fg_color = (item.fg >= 0 && item.fg <= 10) ? demo.pallet.colors_light[item.fg] : demo.pallet.foreground_light;
                    if (item == demo.light.codeblock) {
                        light_enrich.set_code_background (bg_color);
                    }
                }
                fg_button.set_color_from_string (fg_color);
                bg_button.set_color_from_string (bg_color);
            });

            Gtk.ToggleButton bold = new Gtk.ToggleButton ();
            bold.set_image (new Gtk.Image.from_icon_name ("format-text-bold-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            bold.set_tooltip_text (_("Bold"));
            bold.set_active(item.bold);
            bold.clicked.connect (() => {
                item.bold = bold.active;
                rebuild ();
            });

            Gtk.ToggleButton underline = new Gtk.ToggleButton ();
            underline.set_image (new Gtk.Image.from_icon_name ("format-text-underline-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            underline.set_tooltip_text (_("Underline"));
            underline.set_active (item.underline);
            underline.clicked.connect (() => {
                item.underline = underline.active;
                rebuild ();
            });

            Gtk.ToggleButton italic = new Gtk.ToggleButton ();
            italic.set_image (new Gtk.Image.from_icon_name ("format-text-italic-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            italic.set_tooltip_text (_("Italics"));
            italic.set_active (item.italic);
            italic.clicked.connect (() => {
                item.italic = italic.active;
                rebuild ();
            });

            Gtk.ToggleButton strikethrough = new Gtk.ToggleButton ();
            strikethrough.set_image (new Gtk.Image.from_icon_name ("format-text-strikethrough-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            strikethrough.set_tooltip_text (_("Strikethrough"));
            strikethrough.set_active (item.strikethrough);
            strikethrough.clicked.connect (() => {
                item.strikethrough = strikethrough.active;
                rebuild ();
            });

            grid.attach (fg_button, 0, 0);
            grid.attach (bg_button, 1, 0);
            grid.attach (bold, 2, 0);
            grid.attach (underline, 3, 0);
            grid.attach (italic, 4, 0);
            grid.attach (strikethrough, 5, 0);

            return grid;
        }

        Gtk.ColorButton light_fg;
        Gtk.ColorButton light_bg;
        Gtk.ColorButton[] light_pallet;
        Gtk.ColorButton dark_fg;
        Gtk.ColorButton dark_bg;
        Gtk.ColorButton[] dark_pallet;
        public Gtk.Grid pallet_grid () {
            Gtk.Grid grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.row_spacing = 6;
            grid.column_spacing = 6;
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.hexpand = true;

            Gtk.Label light_colors = new Gtk.Label (_("Light"));
            grid.attach (light_colors, 0, 0);

            light_fg = create_color_button (demo.pallet.foreground_light);
            light_fg.set_title (_("Foreground Color"));
            light_fg.set_tooltip_text (_("Foreground Color"));
            light_fg.color_set.connect (update_colors); 
            grid.attach (light_fg, 1, 0);

            light_bg = create_color_button (demo.pallet.background_light);
            light_bg.set_title (_("Background Color"));
            light_bg.set_tooltip_text (_("Background Color"));
            light_bg.color_set.connect (update_colors); 
            grid.attach (light_bg, 2, 0);

            light_pallet = new Gtk.ColorButton[11];
            for (int i = 0; i < 11; i++) {
                light_pallet[i] = create_color_button (demo.pallet.colors_light[i]);
                light_pallet[i].set_title (_("Pallet Color"));
                light_pallet[i].set_tooltip_text (_("Pallet Color"));
                light_pallet[i].color_set.connect (update_colors); 
                grid.attach (light_pallet[i], 3 + i, 0);
            }

            Gtk.Label dark_colors = new Gtk.Label (_("Dark"));
            grid.attach (dark_colors, 0, 1);

            dark_fg = create_color_button (demo.pallet.foreground_dark);
            dark_fg.set_title (_("Foreground Color"));
            dark_fg.set_tooltip_text (_("Foreground Color"));
            dark_fg.color_set.connect (update_colors); 
            grid.attach (dark_fg, 1, 1);

            dark_bg = create_color_button (demo.pallet.background_dark);
            dark_bg.set_title (_("Background Color"));
            dark_bg.set_tooltip_text (_("Background Color"));
            dark_bg.color_set.connect (update_colors); 
            grid.attach (dark_bg, 2, 1);

            dark_pallet = new Gtk.ColorButton[11];
            for (int i = 0; i < 11; i++) {
                dark_pallet[i] = create_color_button (demo.pallet.colors_dark[i]);
                dark_pallet[i].set_title (_("Pallet Color"));
                dark_pallet[i].set_tooltip_text (_("Pallet Color"));
                dark_pallet[i].color_set.connect (update_colors); 
                grid.attach (dark_pallet[i], 3 + i, 1);
            }

            grid.show_all ();
            return grid;
        }

        private void load_file (File file) {
            try {
                ColorPaletteLoader parser = new ColorPaletteLoader (file);
                parser.copy_to (ref demo);
                reverse_update_colors ();
            } catch (Error e) {
                warning ("Could not load file: %s", e.message);
            }
        }

        private void rebuild () {
            build_themes ();
            show_themes ();
        }

        private Gdk.RGBA color_to_rgba (string color) {
            Gdk.RGBA ret_color = Gdk.RGBA ();
            ret_color.parse (color);
            return ret_color;
        }

        private void reverse_update_colors () {
            light_fg.rgba = color_to_rgba (demo.pallet.foreground_light);
            light_bg.rgba = color_to_rgba (demo.pallet.background_light);

            for (int i = 0; i < 11; i++) {
                light_pallet[i].rgba = color_to_rgba (demo.pallet.colors_light[i]);
            }

            dark_fg.rgba = color_to_rgba (demo.pallet.foreground_dark);
            dark_bg.rgba = color_to_rgba (demo.pallet.background_dark);

            for (int i = 0; i < 11; i++) {
                dark_pallet[i].rgba = color_to_rgba (demo.pallet.colors_dark[i]);
            }

            state_change ();
            build_themes ();
            show_themes ();
        }

        private void update_colors () {
            demo.pallet.foreground_light = get_hex_color (light_fg.get_rgba ());
            demo.pallet.background_light = get_hex_color (light_bg.get_rgba ());

            for (int i = 0; i < 11; i++) {
                demo.pallet.colors_light[i] = get_hex_color (light_pallet[i].get_rgba ());
            }

            demo.pallet.foreground_dark = get_hex_color (dark_fg.get_rgba ());
            demo.pallet.background_dark = get_hex_color (dark_bg.get_rgba ());

            for (int i = 0; i < 11; i++) {
                demo.pallet.colors_dark[i] = get_hex_color (dark_pallet[i].get_rgba ());
            }

            state_change ();
            build_themes ();
            show_themes ();
        }

        private string get_hex_color (Gdk.RGBA rgba) {
            Clutter.Color colour = Clutter.Color.from_string ("#FFFFFF");
            colour.red = (uint8)(255 * rgba.red);
            colour.green = (uint8)(255 * rgba.green);
            colour.blue = (uint8)(255 * rgba.blue);
            return colour.to_string ().substring (0, 7);
        }

        public void on_delete_event () {
            File temp_location = File.new_for_path (temp_dir);
    
            try {
                if (temp_location.query_exists ()) {
                    Dir dir = Dir.open (temp_dir, 0);
                    string? file_name = null;
                    while ((file_name = dir.read_name()) != null) {
                        print ("Checking %s...\n", file_name);
                        if (!file_name.has_prefix(".")) {
                            string path = Path.build_filename (temp_dir, file_name);
                            if (FileUtils.test (path, FileTest.IS_REGULAR) && !FileUtils.test (path, FileTest.IS_SYMLINK)) {
                                File rm_file = File.new_for_path (path);
                                print ("Cleaning %s...\n", path);
                                rm_file.delete ();
                            }
                        }
                    }
                    temp_location.delete ();
                    print ("Cleaning %s...\n", temp_dir);
                }
            } catch (Error e) {
                print ("Could not clean up: %s\n", e.message);
                return;
            }
    
            print ("Deleted temporary files\n");
        }

        private void build_real_themes (string name, string author) {
            dark_path = Path.build_filename (temp_dir, name + "-dark.xml");
            demo.build_darkscheme (dark_path, name, author);
            light_path = Path.build_filename (temp_dir, name +"-light.xml");
            demo.build_lightscheme (light_path, name, author);
            ultheme_path = Path.build_filename (temp_dir, "Theme.xml");
            demo.build_ultheme (ultheme_path, name, author);
        }

        private void build_themes () {
            dark_path = Path.build_filename (temp_dir, "demo-dark.xml");
            demo.build_darkscheme (dark_path, "demo", "demo");
            light_path = Path.build_filename (temp_dir, "demo-light.xml");
            demo.build_lightscheme (light_path, "demo", "demo");
            ultheme_path = Path.build_filename (temp_dir, "DemoTheme.xml");
            demo.build_ultheme (ultheme_path, "demo", "demo");
        }

        private void show_themes () {
            preview_manager.force_rescan ();

            var dark_style = preview_manager.get_scheme ("demo-dark");
            buffer_dark.highlight_syntax = true;
            buffer_dark.set_style_scheme (dark_style);

            var light_style = preview_manager.get_scheme ("demo-light");
            buffer_light.highlight_syntax = true;
            buffer_light.set_style_scheme (light_style);
        }

        public static int main (string[] args) {
            return new ThemeGenerator ().run (args);
        }
    }
}