using Gdk;
using ThiefMD.Enrichments;

namespace ThiefMD {
    public class ThemeGenerator : Gtk.Application {
        private GtkSource.View view_dark;
        private GtkSource.View view_light;
        private GtkSource.Buffer buffer_dark;
        private GtkSource.Buffer buffer_light;
        public static string temp_dir;
        public static GtkSource.StyleSchemeManager preview_manager;
        public ColorTheme demo;
        private string dark_path;
        private string light_path;
        private string ultheme_path;
        private Gtk.HeaderBar bar;
        private Gtk.Stack stack;
        public signal void state_change ();
        MarkdownEnrichment light_enrich;
        MarkdownEnrichment dark_enrich;
        FountainEnrichment light_fountain;
        FountainEnrichment dark_fountain;

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

            preview_manager = new GtkSource.StyleSchemeManager ();
            preview_manager.append_search_path (temp_dir);
            preview_manager.force_rescan ();

            var window = new Gtk.ApplicationWindow (this);
            window.set_title ("");
            window.set_default_size (800, 600);

            // Attempt to set taskbar icon
            window.set_icon_name ("io.github.thiefmd.themegenerator");

            bar = new Gtk.HeaderBar ();

            window.set_titlebar(bar);
            var preview_box = new Gtk.ScrolledWindow ();

            var manager = new GtkSource.LanguageManager ();
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

            var language_picker = new Gtk.ComboBoxText ();
            language_picker.append_text ("Markdown");
            language_picker.append_text ("Fountain");
            language_picker.append_text ("C/C++");
            language_picker.append_text ("HTML");
            language_picker.append_text ("Python");
            language_picker.append_text ("C#");
            language_picker.append_text ("Vala");
            language_picker.append_text ("Rust");
            language_picker.set_active (0);

            language_picker.changed.connect (() => {
                var selected = language_picker.get_active_text ();
                switch (selected.down ()) {
                    case "markdown":
                        language = manager.guess_language (null, "text/markdown");
                        buffer_dark.set_text (IPSUM);
                        buffer_light.set_text (IPSUM);
                        break;
                    case "fountain":
                        language = manager.guess_language (null, "text/fountain");
                        buffer_dark.set_text (fountain);
                        buffer_light.set_text (fountain);
                        break;
                    case "c/c++":
                        language = manager.guess_language (null, "text/x-cpp");
                        buffer_dark.set_text (c);
                        buffer_light.set_text (c);
                        break;
                    case "html":
                        language = manager.guess_language (null, "text/html");
                        buffer_dark.set_text (html);
                        buffer_light.set_text (html);
                        break;
                    case "python":
                        language = manager.guess_language (null, "text/x-python3");
                        buffer_dark.set_text (py);
                        buffer_light.set_text (py);
                        break;
                    case "c#":
                        language = manager.guess_language (null, "text/x-csharp");
                        buffer_dark.set_text (cs);
                        buffer_light.set_text (cs);
                        break;
                    case "vala":
                        language = manager.guess_language (null, "text/x-vala");
                        buffer_dark.set_text (cs);
                        buffer_light.set_text (cs);
                        break;
                    case "rust":
                        language = manager.guess_language (null, "text/rust");
                        buffer_dark.set_text (rust);
                        buffer_light.set_text (rust);
                        break;
                }
                buffer_light.set_language (language);
                buffer_dark.set_language (language);
                light_enrich.recheck_all ();
                dark_enrich.recheck_all ();
                dark_fountain.recheck_all ();
                light_fountain.recheck_all ();
                
            });

            bar.pack_end (language_picker);

            view_dark = new GtkSource.View ();
            view_dark.show_line_numbers = true;
            buffer_dark = new GtkSource.Buffer.with_language (language);
            buffer_dark.highlight_syntax = true;
            view_dark.set_buffer (buffer_dark);
            view_dark.set_wrap_mode (Gtk.WrapMode.WORD);
            buffer_dark.text = IPSUM;
            dark_enrich = new MarkdownEnrichment ();
            dark_enrich.attach (view_dark);
            dark_enrich.recheck_all ();
            dark_fountain = new FountainEnrichment ();
            dark_fountain.attach (view_dark);
            dark_fountain.recheck_all ();
            buffer_dark.changed.connect (() => {
                dark_enrich.recheck_all ();
                dark_fountain.recheck_all ();
            });

            view_light = new GtkSource.View ();
            view_light.highlight_current_line = true;
            view_light.show_line_numbers = true;
            view_light.highlight_current_line = true;
            buffer_light = new GtkSource.Buffer.with_language (language);
            buffer_light.highlight_syntax = true;
            view_light.set_buffer (buffer_light);
            view_light.set_wrap_mode (Gtk.WrapMode.WORD);
            buffer_light.text = IPSUM;
            light_enrich = new MarkdownEnrichment ();
            light_enrich.attach (view_light);
            light_enrich.recheck_all ();
            light_fountain = new FountainEnrichment ();
            light_fountain.attach (view_light);
            light_fountain.recheck_all ();
            buffer_light.changed.connect (() => {
                light_enrich.recheck_all ();
                light_fountain.recheck_all ();
            });

            stack = new Gtk.Stack ();
            stack.add_titled (view_light, _("Light Theme"), _("Light"));
            stack.add_titled (view_dark, _("Dark Theme"), _("Dark"));
            stack.add_titled (export_grid (), _("Export Theme"), _("Export"));

            Gtk.StackSwitcher switcher = new Gtk.StackSwitcher ();
            switcher.set_stack (stack);
            switcher.halign = Gtk.Align.CENTER;

            bar.set_title_widget (switcher);

            Gtk.Button open_button = new Gtk.Button.with_label ("Open");
            open_button.clicked.connect (() => {

                get_open_file ("Load Colors From Theme", (open_file) => {
                    if (open_file.query_exists ()) {
                        load_file (open_file);
                    }
                });
            });
            bar.pack_start (open_button);

            preview_box.set_child (stack);
            preview_box.vexpand = true;
            preview_box.hexpand = true;

            Gtk.Grid window_grid = new Gtk.Grid ();
            window_grid.row_spacing = 12;
            window_grid.column_spacing = 12;
            window_grid.orientation = Gtk.Orientation.VERTICAL;
            window_grid.hexpand = true;
            window_grid.vexpand = true;

            window_grid.attach (pallet_grid (), 0, 0);
            var syntax_box = new Gtk.ScrolledWindow ();
            syntax_box.set_child (syntax_grid ());
            syntax_box.vexpand = true;
            syntax_box.hexpand = true;
            syntax_box.show ();
            window_grid.attach (syntax_box, 0, 1, 1, 3);
            window_grid.attach (preview_box, 0, 4, 1, 4);

            show_themes ();

            window.set_child (window_grid);
            window.show ();
            bar.show ();
        }

        public Gtk.Grid export_grid () {
            Gtk.Grid grid = new Gtk.Grid ();
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
                build_real_themes (theme_name, theme_author);
                get_save_location ("Save Light Theme", "xml", theme.get_text (), (light_target) => {
                    if (light_target != null){
                        try {
                            if (light_target.query_exists ()) {
                                light_target.delete ();
                            }
                            File temp_light = File.new_for_path (light_path);
                            temp_light.copy (light_target, FileCopyFlags.OVERWRITE);
                        } catch (Error e) {
                            warning ("Could not save file: %s", e.message);
                        }
                    }
                });
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
                build_real_themes (theme_name, theme_author);
                get_save_location ("Save Dark Theme", "xml", theme.get_text (), (dark_target) => {
                    if (dark_target != null){
                        try {
                            if (dark_target.query_exists ()) {
                                dark_target.delete ();
                            }
                            File temp_dark = File.new_for_path (dark_path);
                            temp_dark.copy (dark_target, FileCopyFlags.OVERWRITE);
                        } catch (Error e) {
                            warning ("Could not save file: %s", e.message);
                        }
                    }
                });
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
                get_save_location ("Save Ulysses Theme", "ultheme", theme.get_text (), (ulysses_target) => {
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
            });

            return grid;
        }

        public Gtk.Grid syntax_grid () {
            Gtk.Grid grid = new Gtk.Grid ();
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
            headings.has_tooltip = true;
            headings.tooltip_text = "def:type, def:heading";
            grid.attach (headings, 0, 1);
            grid.attach (color_map_item (0, false), 1, 1);
            grid.attach (color_map_item (0, true), 2, 1);

            Gtk.Label strong = new Gtk.Label (_("Strong"));
            strong.has_tooltip = true;
            strong.tooltip_text = "def:statement";
            grid.attach (strong, 0, 2);
            grid.attach (color_map_item (10, false), 1, 2);
            grid.attach (color_map_item (10, true), 2, 2);

            Gtk.Label emphasis = new Gtk.Label (_("Emphasis"));
            emphasis.has_tooltip = true;
            emphasis.tooltip_text = "def:doc-comment-element";
            grid.attach (emphasis, 0, 3);
            grid.attach (color_map_item (9, false), 1, 3);
            grid.attach (color_map_item (9, true), 2, 3);

            Gtk.Label strikethrough = new Gtk.Label (_("Deleted"));
            strikethrough.has_tooltip = true;
            strikethrough.tooltip_text = "def:deletion";
            grid.attach (strikethrough, 0, 4);
            grid.attach (color_map_item (11, false), 1, 4);
            grid.attach (color_map_item (11, true), 2, 4);

            Gtk.Label image = new Gtk.Label (_("Image"));
            grid.attach (image, 0, 5);
            grid.attach (color_map_item (8, false), 1, 5);
            grid.attach (color_map_item (8, true), 2, 5);

            Gtk.Label link = new Gtk.Label (_("Link"));
            link.has_tooltip = true;
            link.tooltip_text = "def:underlined, def:preprocessor, def:constant, def:net-address, def:link-destination, def:type";
            grid.attach (link, 0, 6);
            grid.attach (color_map_item (5, false), 1, 6);
            grid.attach (color_map_item (5, true), 2, 6);

            Gtk.Label code = new Gtk.Label (_("Inline Code"));
            code.has_tooltip = true;
            code.tooltip_text = "def:identifier";
            grid.attach (code, 0, 7);
            grid.attach (color_map_item (2, false), 1, 7);
            grid.attach (color_map_item (2, true), 2, 7);

            Gtk.Label codeblock = new Gtk.Label (_("Code Block"));
            grid.attach (codeblock, 0, 8);
            grid.attach (color_map_item (1, false), 1, 8);
            grid.attach (color_map_item (1, true), 2, 8);

            Gtk.Label comment = new Gtk.Label (_("Comment"));
            comment.has_tooltip = true;
            comment.tooltip_text = "def:special-char, def:comment";
            grid.attach (comment, 0, 9);
            grid.attach (color_map_item (3, false), 1, 9);
            grid.attach (color_map_item (3, true), 2, 9);

            Gtk.Label blockquote = new Gtk.Label (_("Blockquote"));
            blockquote.has_tooltip = true;
            blockquote.tooltip_text = "def:shebang";
            grid.attach (blockquote, 0, 10);
            grid.attach (color_map_item (4, false), 1, 10);
            grid.attach (color_map_item (4, true), 2, 10);

            Gtk.Label listitem = new Gtk.Label (_("List Item"));
            listitem.has_tooltip = true;
            listitem.tooltip_text = "def:statement";
            grid.attach (listitem, 0, 11);
            grid.attach (color_map_item (7, false), 1, 11);
            grid.attach (color_map_item (7, true), 2, 11);

            Gtk.Label divider = new Gtk.Label (_("Divider"));
            divider.has_tooltip = true;
            divider.tooltip_text = "def:note";
            grid.attach (divider, 0, 12);
            grid.attach (color_map_item (6, false), 1, 12);
            grid.attach (color_map_item (6, true), 2, 12);

            grid.show ();
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
            PalletPopover fg_popover = new PalletPopover (ref demo.pallet, dark, true);
            fg_popover.set_default_widget (fg_button);
            fg_popover.set_parent (fg_button);
            fg_button.clicked.connect (() => {
                fg_popover.update_pallet (ref demo.pallet, dark, true);
                fg_popover.popup ();
                state_change ();
                rebuild ();
            });
            fg_popover.clicked.connect (() => {
                item.fg = fg_popover.value;
                state_change ();
                rebuild ();
            });

            ThiefColorButton bg_button = new ThiefColorButton (bg_color);
            PalletPopover bg_popover = new PalletPopover (ref demo.pallet, dark, false);
            bg_popover.set_default_widget (bg_button);
            bg_popover.set_parent (bg_button);
            bg_button.set_tooltip_text (_("Background Color"));
            bg_button.clicked.connect (() => {
                bg_popover.update_pallet (ref demo.pallet, dark, false);
                bg_popover.popup ();
                state_change ();
                rebuild ();
            });

            bg_popover.clicked.connect (() => {
                item.bg = bg_popover.value;
                state_change ();
                rebuild ();
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
            bold.icon_name = "format-text-bold-symbolic";
            bold.set_tooltip_text (_("Bold"));
            bold.set_active(item.bold);
            bold.clicked.connect (() => {
                item.bold = bold.active;
                rebuild ();
            });

            Gtk.ToggleButton underline = new Gtk.ToggleButton ();
            underline.icon_name = "format-text-underline-symbolic";
            underline.set_tooltip_text (_("Underline"));
            underline.set_active (item.underline);
            underline.clicked.connect (() => {
                item.underline = underline.active;
                rebuild ();
            });

            Gtk.ToggleButton italic = new Gtk.ToggleButton ();
            italic.icon_name = "format-text-italic-symbolic";
            italic.set_tooltip_text (_("Italics"));
            italic.set_active (item.italic);
            italic.clicked.connect (() => {
                item.italic = italic.active;
                rebuild ();
            });

            Gtk.ToggleButton strikethrough = new Gtk.ToggleButton ();
            strikethrough.icon_name = "format-text-strikethrough-symbolic";
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

            grid.show ();
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
            Ultheme.Color colour = Ultheme.Color.from_string ("#FFFFFF");
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