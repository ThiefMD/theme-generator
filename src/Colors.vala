using Gtk;
using Gee;
using Clutter;

namespace ThiefMD {
    public class ColorPaletteLoader : Ultheme.Parser {
        private int on_dark_index = 0;
        private int on_light_index = 0;
        public ColorPaletteLoader (File file) throws Error {
            base (file);
        }

        public void copy_to (ref ColorTheme demo) {
            Ultheme.HexColorPalette light_palette;
            Ultheme.HexColorPalette dark_palette;

            get_light_theme_palette (out light_palette);
            get_dark_theme_palette (out dark_palette);

            demo.pallet.foreground_light = light_palette.global.foreground;
            demo.pallet.background_light = light_palette.global.background;

            demo.pallet.foreground_dark = dark_palette.global.foreground;
            demo.pallet.background_dark = dark_palette.global.background;
            for (int i = 0; i <= 11; i++) {
                set_item (i, ref demo, ref light_palette, ref dark_palette);
            }
        }

        private void grab_color (ref ColorMapItem set_item, ref ColorTheme demo, ref Ultheme.HexColorPalette pal, Ultheme.HexColorPair item, bool dark) {
            bool fg_set = false;
            bool bg_set = false;
            if (item.foreground == pal.global.foreground) {
                set_item.fg = -1;
                fg_set = true;

            }

            if (item.background == pal.global.background) {
                set_item.bg = -1;
                bg_set = true;
            }

            if (dark) {
                if (!fg_set) {
                    int search = -1;
                    for (int i = 0;  i < on_dark_index; i++) {
                        if (demo.pallet.colors_dark[i] == item.foreground) {
                            search = i;
                        }
                    }
                    if (!fg_set && search != -1) {
                        set_item.fg = search;
                    } else if (!fg_set) {
                        set_item.fg = on_dark_index;
                        demo.pallet.colors_dark[on_dark_index] = item.foreground;
                        on_dark_index++;
                    }
                }
                if (!bg_set) {
                    int search = -1;
                    for (int i = 0;  i < on_dark_index; i++) {
                        if (demo.pallet.colors_dark[i] == item.background) {
                            search = i;
                        }
                    }
                    if (!bg_set && search != -1) {
                        set_item.bg = search;
                    } else if (!bg_set) {
                        set_item.bg = on_dark_index;
                        demo.pallet.colors_dark[on_dark_index] = item.background;
                        on_dark_index++;
                    }
                }
            } else {
                if (!fg_set) {
                    int search = -1;
                    for (int i = 0;  i < on_light_index; i++) {
                        if (demo.pallet.colors_light[i] == item.foreground) {
                            search = i;
                        }
                    }
                    if (!fg_set && search != -1) {
                        set_item.fg = search;
                    } else if (!fg_set) {
                        set_item.fg = on_light_index;
                        demo.pallet.colors_light[on_light_index] = item.foreground;
                        on_light_index++;
                    }
                }
                if (!bg_set) {
                    int search = -1;
                    for (int i = 0;  i < on_light_index; i++) {
                        if (demo.pallet.colors_light[i] == item.background) {
                            search = i;
                        }
                    }
                    if (!bg_set && search != -1) {
                        set_item.bg = search;
                    } else if (!bg_set) {
                        set_item.bg = on_light_index;
                        demo.pallet.colors_light[on_light_index] = item.background;
                        on_light_index++;
                    }
                }
            }
        }

        public void set_item (int index, ref ColorTheme demo, ref Ultheme.HexColorPalette light, ref Ultheme.HexColorPalette dark) {
            switch (index) {
                case 0:
                    grab_color (ref demo.dark.headings, ref demo, ref dark, dark.headers, true);
                    grab_color (ref demo.light.headings, ref demo, ref light, light.headers, false);
                    break;
                case 1:
                    grab_color (ref demo.dark.codeblock, ref demo, ref dark, dark.code_block, true);
                    grab_color (ref demo.light.codeblock, ref demo, ref light, light.code_block, false);
                    break;
                case 2:
                    grab_color (ref demo.dark.code, ref demo, ref dark, dark.inline_code, true);
                    grab_color (ref demo.light.code, ref demo, ref light, light.inline_code, false);
                    break;
                case 3:
                    grab_color (ref demo.dark.comment, ref demo, ref dark, dark.escape_char, true);
                    grab_color (ref demo.light.comment, ref demo, ref light, light.escape_char, false);
                    break;
                case 4:
                    grab_color (ref demo.dark.blockquote, ref demo, ref dark, dark.blockquote, true);
                    grab_color (ref demo.light.blockquote, ref demo, ref light, light.blockquote, false);
                    break;
                case 5:
                    grab_color (ref demo.dark.link, ref demo, ref dark, dark.link, true);
                    grab_color (ref demo.light.link, ref demo, ref light, light.link, false);
                    break;
                case 6:
                    grab_color (ref demo.dark.divider, ref demo, ref dark, dark.divider, true);
                    grab_color (ref demo.light.divider, ref demo, ref light, light.divider, false);
                    break;
                case 7:
                    grab_color (ref demo.dark.orderedList, ref demo, ref dark, dark.list_marker, true);
                    grab_color (ref demo.light.orderedList, ref demo, ref light, light.list_marker, false);
                    break;
                case 8:
                    grab_color (ref demo.dark.image, ref demo, ref dark, dark.image_marker, true);
                    grab_color (ref demo.light.image, ref demo, ref light, light.image_marker, false);
                    break;
                case 9:
                    grab_color (ref demo.dark.emph, ref demo, ref dark, dark.emphasis, true);
                    grab_color (ref demo.light.emph, ref demo, ref light, light.emphasis, false);
                    break;
                case 10:
                    grab_color (ref demo.dark.strong, ref demo, ref dark, dark.strong, true);
                    grab_color (ref demo.light.strong, ref demo, ref light, light.strong, false);
                    break;
                case 11:
                    grab_color (ref demo.dark.strike, ref demo, ref dark, dark.deletion, true);
                    grab_color (ref demo.light.strike, ref demo, ref light, light.deletion, false);
                    break;
            }
        }
    }

    public class ColorPalette {
        public string foreground_light { get; set; }
        public string background_light { get; set; }
        public string foreground_dark { get; set; }
        public string background_dark { get; set; }
        public string[] colors_light;
        public string[] colors_dark;
        public bool dark = false;

        public ColorPalette () {
            colors_light = new string[11];
            colors_dark = new string[11];

            // Default light colors
            foreground_light = "#264653";
            background_light = "#f1faee";
            colors_light[0] = "#264653";
            colors_light[1] = "#2a9d8f";
            colors_light[2] = "#e9c46a";
            colors_light[3] = "#dc2f02";
            colors_light[4] = "#e76f51";
            colors_light[5] = "#e63946";
            colors_light[6] = "#010a0e";
            colors_light[7] = "#a8dadc";
            colors_light[8] = "#457b9d";
            colors_light[9] = "#1d3557";
            colors_light[10] = "#06d6a0";

            // Default dark colors
            foreground_dark = "#2a9d8f";
            background_dark = "#000000";
            colors_dark[0] = "#f1faee";
            colors_dark[1] = "#2a9d8f";
            colors_dark[2] = "#e9c46a";
            colors_dark[3] = "#f4a261";
            colors_dark[4] = "#e76f51";
            colors_dark[5] = "#e63946";
            colors_dark[6] = "#f1faee";
            colors_dark[7] = "#2E3D3E";
            colors_dark[8] = "#457b9d";
            colors_dark[9] = "#1d3557";
            colors_dark[10] = "#06d6a0";
        }
    }

    public class ColorMapItem {
        public int fg = -1;
        public int bg = -1;
        public bool bold = false;
        public bool italic = false;
        public bool underline = false;
        public bool strikethrough = false;

        public ColorMapItem (int foreground, int background) {
            fg = foreground;
            bg = background;
        }
    }

    public class ColorMap {
        public ColorMapItem headings;
        public ColorMapItem codeblock;
        public ColorMapItem code;
        public ColorMapItem comment;
        public ColorMapItem blockquote;
        public ColorMapItem link;
        public ColorMapItem divider;
        public ColorMapItem orderedList;
        public ColorMapItem image;
        public ColorMapItem emph;
        public ColorMapItem strong;
        public ColorMapItem strike;

        public ColorMap () {
            headings = new ColorMapItem (3, -1);
            headings.bold = true;
            codeblock = new ColorMapItem (0, 7);
            code = new ColorMapItem (0, 7);
            comment = new ColorMapItem (7, 6);
            blockquote = new ColorMapItem (5, -1);
            blockquote.italic = true;
            link = new ColorMapItem (4, -1);
            link.underline = true;
            divider = new ColorMapItem (5, -1);
            orderedList = new ColorMapItem (3, -1);
            image = new ColorMapItem (3, 5);
            emph = new ColorMapItem (1, 7);
            emph.italic = true;
            strong = new ColorMapItem (0, 7);
            strong.bold = true;
            strike = new ColorMapItem (6, -1);
            strike.strikethrough = true;
        }
    }

    public class ColorTheme {
        public ColorMap light;
        public ColorMap dark;
        public ColorPalette pallet;

        private HashMap<string, StyleTargets> _gtk_style_map;
        private HashMap<string, StyleTargets> _ulysses_style_map;

        public ColorTheme () {
            light = new ColorMap ();
            dark = new ColorMap ();

            pallet = new ColorPalette ();

            // Map from ColorMap item definitions to style names
            _gtk_style_map = new HashMap<string, StyleTargets> ();
            _gtk_style_map.set ("heading", new StyleTargets({ "markdown:header", "def:type", "def:heading" }));
            _gtk_style_map.set ("codeblock", new StyleTargets({ "markdown:code-block" }));
            _gtk_style_map.set ("code", new StyleTargets({ "markdown:code", "def:identifier", "markdown:code-span", "xml:attribute-name" }));
            _gtk_style_map.set ("comment", new StyleTargets({ "markdown:backslash-escape", "def:special-char", "def:comment", "xml:attribute-value", }));
            _gtk_style_map.set ("blockquote", new StyleTargets({ "markdown:blockquote-marker", "def:shebang", "markdown:blockquote" }));
            _gtk_style_map.set ("link", new StyleTargets({ "markdown:link-text", "markdown:url", "markdown:label", "markdown:attribute-value", "def:underlined", "def:preprocessor", "def:constant", "def:net-address", "def:link-destination", "def:type" }));
            _gtk_style_map.set ("divider", new StyleTargets({ "markdown:horizontal-rule", "def:note", "markdown:line-break" }));
            _gtk_style_map.set ("orderedList", new StyleTargets({ "markdown:list-marker", "def:statement" }));
            _gtk_style_map.set ("image", new StyleTargets({ "markdown:image-marker", }));
            _gtk_style_map.set ("emph", new StyleTargets({ "markdown:emphasis", "def:doc-comment-element" }));
            _gtk_style_map.set ("strong", new StyleTargets({ "markdown:strong-emphasis", "def:statement" }));
            _gtk_style_map.set ("strike", new StyleTargets({ "def:deletion" }));

            // Map from ColorMap item definitions to Ulysses style names
            _ulysses_style_map = new HashMap<string, StyleTargets> ();
            _ulysses_style_map.set ("heading", new StyleTargets({ "heading1", "heading2", "heading3", "heading4", "heading5", "heading6" }));
            _ulysses_style_map.set ("codeblock", new StyleTargets({ "codeblock", "nativeblock" }));
            _ulysses_style_map.set ("code", new StyleTargets({ "code", "inlineNative" }));
            _ulysses_style_map.set ("comment", new StyleTargets({ "comment", "inlineComment", "filename", }));
            _ulysses_style_map.set ("blockquote", new StyleTargets({ "blockquote", "mark" }));
            _ulysses_style_map.set ("link", new StyleTargets({ "link", "footnote", "cite", "annotation", }));
            _ulysses_style_map.set ("divider", new StyleTargets({ "divider" }));
            _ulysses_style_map.set ("orderedList", new StyleTargets({ "orderedList", "unorderedList" }));
            _ulysses_style_map.set ("image", new StyleTargets({ "image", "video" }));
            _ulysses_style_map.set ("emph", new StyleTargets({ "emph", }));
            _ulysses_style_map.set ("strong", new StyleTargets({ "strong" }));
            _ulysses_style_map.set ("strike", new StyleTargets({ "delete" }));
        }

        public void build_ultheme (string dest, string name, string author) {
            try {
                Xml.Doc* res = new Xml.Doc ("1.0");
                Xml.Ns* ns = new Xml.Ns (null, "", null);
                // Create scheme
                // print ("Creating root\n");
                Xml.Node* root = new Xml.Node (ns, "theme");
                root->new_prop ("version", "4");
                root->new_prop ("displayName", name);
                root->new_prop ("author", author);
                res->set_root_element (root);

                // Build light color pallet
                Xml.Node* light_pal = new Xml.Node (ns, "palette");
                light_pal->new_prop ("version", "2");
                light_pal->new_prop ("mode", "light");

                Xml.Node* light_fg = new Xml.Node (ns, "color");
                light_fg->new_prop ("identifier", "foreground");
                light_fg->new_prop ("value", pallet.foreground_light.substring (1) + "ff");
                light_pal->add_child (light_fg);

                Xml.Node* light_bg = new Xml.Node (ns, "color");
                light_bg->new_prop ("identifier", "background");
                light_bg->new_prop ("value", pallet.background_light.substring (1) + "ff");
                light_pal->add_child (light_bg);

                foreach (var color in pallet.colors_light) {
                    Xml.Node* light_elem = new Xml.Node (ns, "color");
                    light_elem->new_prop ("value", color.substring (1) + "ff");
                    light_pal->add_child (light_elem);
                }

                root->add_child (light_pal);

                // Build dark color pallet
                Xml.Node* dark_pal = new Xml.Node (ns, "palette");
                dark_pal->new_prop ("version", "2");
                dark_pal->new_prop ("mode", "dark");

                Xml.Node* dark_fg = new Xml.Node (ns, "color");
                dark_fg->new_prop ("identifier", "foreground");
                dark_fg->new_prop ("value", pallet.foreground_dark.substring (1) + "ff");
                dark_pal->add_child (dark_fg);

                Xml.Node* dark_bg = new Xml.Node (ns, "color");
                dark_bg->new_prop ("identifier", "background");
                dark_bg->new_prop ("value", pallet.background_dark.substring (1) + "ff");
                dark_pal->add_child (dark_bg);

                foreach (var color in pallet.colors_dark) {
                    Xml.Node* dark_elem = new Xml.Node (ns, "color");
                    dark_elem->new_prop ("value", color.substring (1) + "ff");
                    dark_pal->add_child (dark_elem);
                }

                root->add_child (dark_pal);

                // Headings
                foreach (var target in _ulysses_style_map.get ("heading").targets) {
                    Xml.Node* item_def = new Xml.Node (ns, "item");
                    item_def->new_prop ("definition", target);
                    item_def->new_prop ("colorsLight", get_color_string (light.headings));
                    item_def->new_prop ("colorsDark", get_color_string (dark.headings));
                    item_def->new_prop ("traits", get_traits (light.headings));
                    root->add_child (item_def);
                }

                // Codeblock
                foreach (var target in _ulysses_style_map.get ("codeblock").targets) {
                    Xml.Node* item_def = new Xml.Node (ns, "item");
                    item_def->new_prop ("definition", target);
                    item_def->new_prop ("colorsLight", get_color_string (light.codeblock));
                    item_def->new_prop ("colorsDark", get_color_string (dark.codeblock));
                    item_def->new_prop ("traits", get_traits (light.codeblock));
                    root->add_child (item_def);
                }

                // Codeblock
                foreach (var target in _ulysses_style_map.get ("code").targets) {
                    Xml.Node* item_def = new Xml.Node (ns, "item");
                    item_def->new_prop ("definition", target);
                    item_def->new_prop ("colorsLight", get_color_string (light.code));
                    item_def->new_prop ("colorsDark", get_color_string (dark.code));
                    item_def->new_prop ("traits", get_traits (light.code));
                    root->add_child (item_def);
                }

                // comment
                foreach (var target in _ulysses_style_map.get ("comment").targets) {
                    Xml.Node* item_def = new Xml.Node (ns, "item");
                    item_def->new_prop ("definition", target);
                    item_def->new_prop ("colorsLight", get_color_string (light.comment));
                    item_def->new_prop ("colorsDark", get_color_string (dark.comment));
                    item_def->new_prop ("traits", get_traits (light.comment));
                    root->add_child (item_def);
                }

                // blockquote
                foreach (var target in _ulysses_style_map.get ("blockquote").targets) {
                    Xml.Node* item_def = new Xml.Node (ns, "item");
                    item_def->new_prop ("definition", target);
                    item_def->new_prop ("colorsLight", get_color_string (light.blockquote));
                    item_def->new_prop ("colorsDark", get_color_string (dark.blockquote));
                    item_def->new_prop ("traits", get_traits (light.blockquote));
                    root->add_child (item_def);
                }

                // link
                foreach (var target in _ulysses_style_map.get ("link").targets) {
                    Xml.Node* item_def = new Xml.Node (ns, "item");
                    item_def->new_prop ("definition", target);
                    item_def->new_prop ("colorsLight", get_color_string (light.link));
                    item_def->new_prop ("colorsDark", get_color_string (dark.link));
                    item_def->new_prop ("traits", get_traits (light.link));
                    root->add_child (item_def);
                }

                // link
                foreach (var target in _ulysses_style_map.get ("divider").targets) {
                    Xml.Node* item_def = new Xml.Node (ns, "item");
                    item_def->new_prop ("definition", target);
                    item_def->new_prop ("colorsLight", get_color_string (light.divider));
                    item_def->new_prop ("colorsDark", get_color_string (dark.divider));
                    item_def->new_prop ("traits", get_traits (light.divider));
                    root->add_child (item_def);
                }

                // link
                foreach (var target in _ulysses_style_map.get ("orderedList").targets) {
                    Xml.Node* item_def = new Xml.Node (ns, "item");
                    item_def->new_prop ("definition", target);
                    item_def->new_prop ("colorsLight", get_color_string (light.orderedList));
                    item_def->new_prop ("colorsDark", get_color_string (dark.orderedList));
                    item_def->new_prop ("traits", get_traits (light.orderedList));
                    root->add_child (item_def);
                }

                // image
                foreach (var target in _ulysses_style_map.get ("image").targets) {
                    Xml.Node* item_def = new Xml.Node (ns, "item");
                    item_def->new_prop ("definition", target);
                    item_def->new_prop ("colorsLight", get_color_string (light.image));
                    item_def->new_prop ("colorsDark", get_color_string (dark.image));
                    item_def->new_prop ("traits", get_traits (light.image));
                    root->add_child (item_def);
                }

                // emph
                foreach (var target in _ulysses_style_map.get ("emph").targets) {
                    Xml.Node* item_def = new Xml.Node (ns, "item");
                    item_def->new_prop ("definition", target);
                    item_def->new_prop ("colorsLight", get_color_string (light.emph));
                    item_def->new_prop ("colorsDark", get_color_string (dark.emph));
                    item_def->new_prop ("traits", get_traits (light.emph));
                    root->add_child (item_def);
                }

                // strong
                foreach (var target in _ulysses_style_map.get ("strong").targets) {
                    Xml.Node* item_def = new Xml.Node (ns, "item");
                    item_def->new_prop ("definition", target);
                    item_def->new_prop ("colorsLight", get_color_string (light.strong));
                    item_def->new_prop ("colorsDark", get_color_string (dark.strong));
                    item_def->new_prop ("traits", get_traits (light.strong));
                    root->add_child (item_def);
                }

                // strong
                foreach (var target in _ulysses_style_map.get ("strike").targets) {
                    Xml.Node* item_def = new Xml.Node (ns, "item");
                    item_def->new_prop ("definition", target);
                    item_def->new_prop ("colorsLight", get_color_string (light.strike));
                    item_def->new_prop ("colorsDark", get_color_string (dark.strike));
                    item_def->new_prop ("traits", get_traits (light.strike));
                    root->add_child (item_def);
                }

                string scheme;
                res->dump_memory_enc_format (out scheme);
                delete res;
                scheme = scheme.substring (scheme.index_of ("\n") + 1);
                File save = File.new_for_path (dest);
                if (save.query_exists()) {
                    save.delete ();
                }
                save_file (save, scheme.data);
            } catch (Error e) {
                warning ("Could not generate theme: %s", e.message);
            }
        }

        private string get_traits (ColorMapItem item) {
            string[] traits = { };
            if (item.bold) {
                traits += "bold";
            }

            if (item.italic) {
                traits += "italic";
            }

            if (item.underline) {
                traits += "underline";
            }

            if (item.strikethrough) {
                traits += "strikethrough";
            }

            return string.joinv (",", traits);
        }

        private string get_color_string (ColorMapItem item) {
            string res = "";
            if (item.fg >= 0 && item.fg <= 10) {
                res += item.fg.to_string () + ",0";
            }
            res += ";";

            if (item.fg >= 0 && item.fg <= 10) {
                res += item.fg.to_string () + ",0";
            }
            res += ";";

            if (item.bg >= 0 && item.bg <= 10) {
                res += item.bg.to_string () + ",0";
            }

            return res;
        }

        public void build_lightscheme (string dest, string name, string author) {
            try {
                File save = File.new_for_path (dest);
                if (save.query_exists()) {
                    save.delete ();
                }
                build_style (dest, light, pallet, false, name, author);
            } catch (Error e) {
                warning ("Could not generate theme: %s", e.message);
            }
        }

        public void build_darkscheme (string dest, string name, string author) {
            try {
                File save = File.new_for_path (dest);
                if (save.query_exists()) {
                    save.delete ();
                }
                build_style (dest, dark, pallet, true, name, author);
            } catch (Error e) {
                warning ("Could not generate theme: %s", e.message);
            }
        }

        private void build_style (string dest, ColorMap colors, ColorPalette pallet, bool dark, string name, string author) throws Error {
            Xml.Doc* res = new Xml.Doc ("1.0");

            // Create scheme
            Xml.Ns* ns = new Xml.Ns (null, "", null);
            // print ("Creating root\n");
            Xml.Node* root = new Xml.Node (ns, "style-scheme");
            root->new_prop ("id", name.down () + "-" + ((dark) ? "dark" : "light"));
            root->new_prop ("name", name.down () + "-" + ((dark) ? "dark" : "light"));
            root->new_prop ("version", "1.0");
            res->set_root_element (root);

            // Add frontmatter
            // print ("Adding frontmatter\n");
            root->new_text_child (ns, "author", author);
            root->new_text_child (ns, "description", "Style Scheme generated with poor decisions");

            // Set default colors
            Xml.Node* text = new Xml.Node (ns, "style");
            text->new_prop ("name", "text");
            if (dark) {
                text->new_prop ("foreground", pallet.foreground_dark);
                text->new_prop ("background", pallet.background_dark);
            } else {
                text->new_prop ("foreground", pallet.foreground_light);
                text->new_prop ("background", pallet.background_light);
            }
            root->add_child (text);

            Xml.Node* line_numbers = new Xml.Node (ns, "style");
            line_numbers->new_prop ("name", "line-numbers");
            if (dark) {
                line_numbers->new_prop ("foreground", lighten (pallet.foreground_dark, 2));
                line_numbers->new_prop ("background", lighten (pallet.background_dark, 1));
            } else {
                line_numbers->new_prop ("foreground", lighten (pallet.foreground_light, 1));
                line_numbers->new_prop ("background", darken (pallet.background_light, 2));
            }
            root->add_child (line_numbers);

            // Come up with additional stylings not in file
            Xml.Node* selection = new Xml.Node (ns, "style");
            selection->new_prop ("name", "selection");
            if (dark) {
                selection->new_prop ("foreground", darken (pallet.foreground_dark, 1));
                selection->new_prop ("background", lighten (pallet.background_dark, 2));
            } else {
                selection->new_prop ("foreground", darken (pallet.foreground_light, 2));
                selection->new_prop ("background", lighten (pallet.background_light, 1));
            }
            root->add_child (selection);

            Xml.Node* current_line = new Xml.Node (ns, "style");
            current_line->new_prop ("name", "current-line");
            if (dark) {
                current_line->new_prop ("background", lighten (pallet.background_dark, 1));
            } else {
                current_line->new_prop ("foreground", darken (pallet.foreground_light, 1));
            }
            root->add_child (current_line);

            Xml.Node* cursor = new Xml.Node (ns, "style");
            cursor->new_prop ("name", "cursor");
            if (dark) {
                if (colors.headings.fg >= 0 && colors.headings.fg <= 10) {
                    cursor->new_prop ("foreground", pallet.colors_dark[colors.headings.fg]);
                }
            } else {
                if (colors.headings.fg >= 0 && colors.headings.fg <= 10) {
                    cursor->new_prop ("foreground", pallet.colors_light[colors.headings.fg]);
                }
            }
            root->add_child (cursor);

            // heading
            foreach (var apply in _gtk_style_map.get ("heading").targets) {
                Xml.Node* style = new Xml.Node (ns, "style");
                style->new_prop ("name", apply);
                add_attributes (colors.headings, pallet, dark, ref style);
                style->new_prop ("scale", "large");
                root->add_child (style);
            }

            // Code block
            foreach (var apply in _gtk_style_map.get ("codeblock").targets) {
                Xml.Node* style = new Xml.Node (ns, "style");
                style->new_prop ("name", apply);
                add_attributes (colors.codeblock, pallet, dark, ref style);
                root->add_child (style);
            }

            // Code
            foreach (var apply in _gtk_style_map.get ("code").targets) {
                Xml.Node* style = new Xml.Node (ns, "style");
                style->new_prop ("name", apply);
                add_attributes (colors.code, pallet, dark, ref style);
                root->add_child (style);
            }

            // Comment
            foreach (var apply in _gtk_style_map.get ("comment").targets) {
                Xml.Node* style = new Xml.Node (ns, "style");
                style->new_prop ("name", apply);
                add_attributes (colors.comment, pallet, dark, ref style);
                root->add_child (style);
            }

            // Blockquote
            foreach (var apply in _gtk_style_map.get ("blockquote").targets) {
                Xml.Node* style = new Xml.Node (ns, "style");
                style->new_prop ("name", apply);
                add_attributes (colors.blockquote, pallet, dark, ref style);
                root->add_child (style);
            }

            // Link
            foreach (var apply in _gtk_style_map.get ("link").targets) {
                Xml.Node* style = new Xml.Node (ns, "style");
                style->new_prop ("name", apply);
                add_attributes (colors.link, pallet, dark, ref style);
                root->add_child (style);
            }

            // Divider
            foreach (var apply in _gtk_style_map.get ("divider").targets) {
                Xml.Node* style = new Xml.Node (ns, "style");
                style->new_prop ("name", apply);
                add_attributes (colors.divider, pallet, dark, ref style);
                root->add_child (style);
            }

            // List
            foreach (var apply in _gtk_style_map.get ("orderedList").targets) {
                Xml.Node* style = new Xml.Node (ns, "style");
                style->new_prop ("name", apply);
                add_attributes (colors.orderedList, pallet, dark, ref style);
                root->add_child (style);
            }

            // Image
            foreach (var apply in _gtk_style_map.get ("image").targets) {
                Xml.Node* style = new Xml.Node (ns, "style");
                style->new_prop ("name", apply);
                add_attributes (colors.image, pallet, dark, ref style);
                root->add_child (style);
            }

            // Emphasis
            foreach (var apply in _gtk_style_map.get ("emph").targets) {
                Xml.Node* style = new Xml.Node (ns, "style");
                style->new_prop ("name", apply);
                add_attributes (colors.emph, pallet, dark, ref style);
                root->add_child (style);
            }

            // Strong
            foreach (var apply in _gtk_style_map.get ("strong").targets) {
                Xml.Node* style = new Xml.Node (ns, "style");
                style->new_prop ("name", apply);
                add_attributes (colors.strong, pallet, dark, ref style);
                root->add_child (style);
            }

            // Strong
            foreach (var apply in _gtk_style_map.get ("strike").targets) {
                Xml.Node* style = new Xml.Node (ns, "style");
                style->new_prop ("name", apply);
                add_attributes (colors.strike, pallet, dark, ref style);
                root->add_child (style);
            }

            res->save_format_file_enc (dest);

            delete res;
        }

        public void add_attributes (ColorMapItem item, ColorPalette pallet, bool is_dark, ref Xml.Node* elem) {
            string fg;
            string bg;

            if (is_dark) {
                fg = (item.fg >= 0 && item.fg <= 10) ? pallet.colors_dark[item.fg] : pallet.foreground_dark;
                bg = (item.bg >= 0 && item.bg <= 10) ? pallet.colors_dark[item.bg] : pallet.background_dark;
            } else {
                fg = (item.fg >= 0 && item.fg <= 10) ? pallet.colors_light[item.fg] : pallet.foreground_light;
                bg = (item.bg >= 0 && item.bg <= 10) ? pallet.colors_light[item.bg] : pallet.background_light;
            }

            if (item.bold) {
                elem->new_prop ("bold", "true");
            }

            if (item.italic) {
                elem->new_prop ("italic", "true");
            }

            if (item.underline) {
                elem->new_prop ("underline", "true");
                elem->new_prop ("underline-color", fg);
            }

            if (item.strikethrough) {
                elem->new_prop ("strikethrough", "true");
            }

            if (item.bg >= 0 && item.bg <= 10) {
                elem->new_prop ("background", bg);
            }

            if (item.fg >= 0 && item.fg <= 10) {
                elem->new_prop ("foreground", fg);
            }
        }

        public string darken (string color, int how_much = 1) {
            Color selection = Color.from_string (color);

            while (how_much != 0) {
                selection = selection.darken ();
                how_much--;
            }

            string sc = selection.to_string ();
            sc = sc.substring (0, 7);
            return sc;
        }

        public string lighten (string color, int how_much = 1) {
            Color selection = Color.from_string (color);

            while (how_much != 0) {
                selection = selection.darken ();
                how_much--;
            }

            string sc = selection.to_string ();
            sc = sc.substring (0, 7);
            return sc;
        }
    }

    private class StyleTargets {
        public string[] targets;
        public StyleTargets (string[] classes) {
            targets = classes;
        }
    }
}
