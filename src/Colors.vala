using Gtk;
using Gee;
using Clutter;

namespace ThiefMD {

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
            colors_light[6] = "#f1faee";
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
                GXml.DomDocument res = new GXml.Document ();
                // Create scheme
                // print ("Creating root\n");
                GXml.DomElement root = res.create_element ("theme");
                root.set_attribute ("version", "4");
                root.set_attribute ("displayName", name);
                root.set_attribute ("author", author);
                res.append_child (root);

                // Build light color pallet
                GXml.DomElement light_pal = res.create_element ("palette");
                light_pal.set_attribute ("version", "2");
                light_pal.set_attribute ("mode", "light");

                GXml.DomElement light_fg = res.create_element ("color");
                light_fg.set_attribute ("identifier", "foreground");
                light_fg.set_attribute ("value", pallet.foreground_light.substring (1) + "ff");
                light_pal.append_child (light_fg);

                GXml.DomElement light_bg = res.create_element ("color");
                light_bg.set_attribute ("identifier", "background");
                light_bg.set_attribute ("value", pallet.background_light.substring (1) + "ff");
                light_pal.append_child (light_bg);

                foreach (var color in pallet.colors_light) {
                    GXml.DomElement light_elem = res.create_element ("color");
                    light_elem.set_attribute ("value", color.substring (1) + "ff");
                    light_pal.append_child (light_elem);
                }

                root.append_child (light_pal);

                // Build dark color pallet
                GXml.DomElement dark_pal = res.create_element ("palette");
                dark_pal.set_attribute ("version", "2");
                dark_pal.set_attribute ("mode", "dark");

                GXml.DomElement dark_fg = res.create_element ("color");
                dark_fg.set_attribute ("identifier", "foreground");
                dark_fg.set_attribute ("value", pallet.foreground_dark.substring (1) + "ff");
                dark_pal.append_child (dark_fg);

                GXml.DomElement dark_bg = res.create_element ("color");
                dark_bg.set_attribute ("identifier", "background");
                dark_bg.set_attribute ("value", pallet.background_dark.substring (1) + "ff");
                dark_pal.append_child (dark_bg);

                foreach (var color in pallet.colors_dark) {
                    GXml.DomElement dark_elem = res.create_element ("color");
                    dark_elem.set_attribute ("value", color.substring (1) + "ff");
                    dark_pal.append_child (dark_elem);
                }

                root.append_child (dark_pal);

                // Headings
                foreach (var target in _ulysses_style_map.get ("heading").targets) {
                    GXml.DomElement item_def = res.create_element ("item");
                    item_def.set_attribute ("definition", target);
                    item_def.set_attribute ("colorsLight", get_color_string (light.headings));
                    item_def.set_attribute ("colorsDark", get_color_string (dark.headings));
                    item_def.set_attribute ("traits", get_traits (light.headings));
                    root.append_child (item_def);
                }

                // Codeblock
                foreach (var target in _ulysses_style_map.get ("codeblock").targets) {
                    GXml.DomElement item_def = res.create_element ("item");
                    item_def.set_attribute ("definition", target);
                    item_def.set_attribute ("colorsLight", get_color_string (light.codeblock));
                    item_def.set_attribute ("colorsDark", get_color_string (dark.codeblock));
                    item_def.set_attribute ("traits", get_traits (light.codeblock));
                    root.append_child (item_def);
                }

                // Codeblock
                foreach (var target in _ulysses_style_map.get ("code").targets) {
                    GXml.DomElement item_def = res.create_element ("item");
                    item_def.set_attribute ("definition", target);
                    item_def.set_attribute ("colorsLight", get_color_string (light.code));
                    item_def.set_attribute ("colorsDark", get_color_string (dark.code));
                    item_def.set_attribute ("traits", get_traits (light.code));
                    root.append_child (item_def);
                }

                // comment
                foreach (var target in _ulysses_style_map.get ("comment").targets) {
                    GXml.DomElement item_def = res.create_element ("item");
                    item_def.set_attribute ("definition", target);
                    item_def.set_attribute ("colorsLight", get_color_string (light.comment));
                    item_def.set_attribute ("colorsDark", get_color_string (dark.comment));
                    item_def.set_attribute ("traits", get_traits (light.comment));
                    root.append_child (item_def);
                }

                // blockquote
                foreach (var target in _ulysses_style_map.get ("blockquote").targets) {
                    GXml.DomElement item_def = res.create_element ("item");
                    item_def.set_attribute ("definition", target);
                    item_def.set_attribute ("colorsLight", get_color_string (light.blockquote));
                    item_def.set_attribute ("colorsDark", get_color_string (dark.blockquote));
                    item_def.set_attribute ("traits", get_traits (light.blockquote));
                    root.append_child (item_def);
                }

                // link
                foreach (var target in _ulysses_style_map.get ("link").targets) {
                    GXml.DomElement item_def = res.create_element ("item");
                    item_def.set_attribute ("definition", target);
                    item_def.set_attribute ("colorsLight", get_color_string (light.link));
                    item_def.set_attribute ("colorsDark", get_color_string (dark.link));
                    item_def.set_attribute ("traits", get_traits (light.link));
                    root.append_child (item_def);
                }

                // link
                foreach (var target in _ulysses_style_map.get ("divider").targets) {
                    GXml.DomElement item_def = res.create_element ("item");
                    item_def.set_attribute ("definition", target);
                    item_def.set_attribute ("colorsLight", get_color_string (light.divider));
                    item_def.set_attribute ("colorsDark", get_color_string (dark.divider));
                    item_def.set_attribute ("traits", get_traits (light.divider));
                    root.append_child (item_def);
                }

                // link
                foreach (var target in _ulysses_style_map.get ("orderedList").targets) {
                    GXml.DomElement item_def = res.create_element ("item");
                    item_def.set_attribute ("definition", target);
                    item_def.set_attribute ("colorsLight", get_color_string (light.orderedList));
                    item_def.set_attribute ("colorsDark", get_color_string (dark.orderedList));
                    item_def.set_attribute ("traits", get_traits (light.orderedList));
                    root.append_child (item_def);
                }

                // image
                foreach (var target in _ulysses_style_map.get ("image").targets) {
                    GXml.DomElement item_def = res.create_element ("item");
                    item_def.set_attribute ("definition", target);
                    item_def.set_attribute ("colorsLight", get_color_string (light.image));
                    item_def.set_attribute ("colorsDark", get_color_string (dark.image));
                    item_def.set_attribute ("traits", get_traits (light.image));
                    root.append_child (item_def);
                }

                // emph
                foreach (var target in _ulysses_style_map.get ("emph").targets) {
                    GXml.DomElement item_def = res.create_element ("item");
                    item_def.set_attribute ("definition", target);
                    item_def.set_attribute ("colorsLight", get_color_string (light.emph));
                    item_def.set_attribute ("colorsDark", get_color_string (dark.emph));
                    item_def.set_attribute ("traits", get_traits (light.emph));
                    root.append_child (item_def);
                }

                // strong
                foreach (var target in _ulysses_style_map.get ("strong").targets) {
                    GXml.DomElement item_def = res.create_element ("item");
                    item_def.set_attribute ("definition", target);
                    item_def.set_attribute ("colorsLight", get_color_string (light.strong));
                    item_def.set_attribute ("colorsDark", get_color_string (dark.strong));
                    item_def.set_attribute ("traits", get_traits (light.strong));
                    root.append_child (item_def);
                }

                // strong
                foreach (var target in _ulysses_style_map.get ("strike").targets) {
                    GXml.DomElement item_def = res.create_element ("item");
                    item_def.set_attribute ("definition", target);
                    item_def.set_attribute ("colorsLight", get_color_string (light.strike));
                    item_def.set_attribute ("colorsDark", get_color_string (dark.strike));
                    item_def.set_attribute ("traits", get_traits (light.strike));
                    root.append_child (item_def);
                }

                string scheme = ((GXml.Document) res).write_string ();
                scheme = scheme.replace ("<?xml version=\"1.0\"?>\n", "");
                scheme = scheme.replace ("><", ">\n  <");
                scheme = scheme.replace ("displayname", "displayName");
                scheme = scheme.replace ("colorslight", "colorsLight");
                scheme = scheme.replace ("colorsdark", "colorsDark");
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
                string scheme = build_style (light, pallet, false, name, author);
                File save = File.new_for_path (dest);
                if (save.query_exists()) {
                    save.delete ();
                }
                save_file (save, scheme.data);
            } catch (Error e) {
                warning ("Could not generate theme: %s", e.message);
            }
        }

        public void build_darkscheme (string dest, string name, string author) {
            try {
                string scheme = build_style (dark, pallet, true, name, author);
                File save = File.new_for_path (dest);
                if (save.query_exists()) {
                    save.delete ();
                }
                save_file (save, scheme.data);
            } catch (Error e) {
                warning ("Could not generate theme: %s", e.message);
            }
        }

        private string build_style (ColorMap colors, ColorPalette pallet, bool dark, string name, string author) throws Error {
            GXml.DomDocument res = new GXml.Document ();

            // Create scheme
            // print ("Creating root\n");
            GXml.DomElement root = res.create_element ("style-scheme");
            root.set_attribute ("id", name.down () + "-" + ((dark) ? "dark" : "light"));
            root.set_attribute ("name", name.down () + "-" + ((dark) ? "dark" : "light"));
            root.set_attribute ("version", "1.0");
            res.append_child (root);

            // Add frontmatter
            // print ("Adding frontmatter\n");
            GXml.DomElement author_elem = res.create_element ("author");
            GXml.DomText author_text = res.create_text_node (author);
            author_elem.append_child (author_text);
            root.append_child (author_elem);

            GXml.DomElement description = res.create_element ("description");
            GXml.DomText description_text = res.create_text_node (
                "Style Scheme generated with poor decisions"
            );
            description.append_child (description_text);
            root.append_child (description);

            // Set default colors
            GXml.DomElement text = res.create_element ("style");
            text.set_attribute ("name", "text");
            if (dark) {
                text.set_attribute ("foreground", pallet.foreground_dark);
                text.set_attribute ("background", pallet.background_dark);
            } else {
                text.set_attribute ("foreground", pallet.foreground_light);
                text.set_attribute ("background", pallet.background_light);
            }
            root.append_child (text);

            // Come up with additional stylings not in file
            GXml.DomElement selection = res.create_element ("style");
            selection.set_attribute ("name", "selection");
            if (dark) {
                selection.set_attribute ("foreground", darken (pallet.foreground_dark, 1));
                selection.set_attribute ("background", lighten (pallet.background_dark, 2));
            } else {
                selection.set_attribute ("foreground", darken (pallet.foreground_light, 2));
                selection.set_attribute ("background", lighten (pallet.background_light, 1));
            }
            root.append_child (selection);

            GXml.DomElement current_line = res.create_element ("style");
            current_line.set_attribute ("name", "current-line");
            if (dark) {
                current_line.set_attribute ("background", lighten (pallet.background_dark, 1));
            } else {
                selection.set_attribute ("foreground", darken (pallet.foreground_light, 1));
            }
            root.append_child (current_line);

            GXml.DomElement cursor = res.create_element ("style");
            cursor.set_attribute ("name", "cursor");
            if (dark) {
                cursor.set_attribute ("foreground", (colors.headings.fg >= 0 && colors.headings.fg <= 10) ? pallet.colors_dark[ colors.headings.fg] : pallet.foreground_dark);
            } else {
                cursor.set_attribute ("foreground", (colors.headings.fg >= 0 && colors.headings.fg <= 10) ? pallet.colors_light[ colors.headings.fg] : pallet.foreground_light);
            }
            root.append_child (cursor);

            // heading
            foreach (var apply in _gtk_style_map.get ("heading").targets) {
                GXml.DomElement style = res.create_element ("style");
                style.set_attribute ("name", apply);
                add_attributes (colors.headings, pallet, dark, ref style);
                style.set_attribute ("scale", "large");
                root.append_child (style);
            }

            // Code block
            foreach (var apply in _gtk_style_map.get ("codeblock").targets) {
                GXml.DomElement style = res.create_element ("style");
                style.set_attribute ("name", apply);
                add_attributes (colors.codeblock, pallet, dark, ref style);
                root.append_child (style);
            }

            // Code
            foreach (var apply in _gtk_style_map.get ("code").targets) {
                GXml.DomElement style = res.create_element ("style");
                style.set_attribute ("name", apply);
                add_attributes (colors.code, pallet, dark, ref style);
                root.append_child (style);
            }

            // Comment
            foreach (var apply in _gtk_style_map.get ("comment").targets) {
                GXml.DomElement style = res.create_element ("style");
                style.set_attribute ("name", apply);
                add_attributes (colors.comment, pallet, dark, ref style);
                root.append_child (style);
            }

            // Blockquote
            foreach (var apply in _gtk_style_map.get ("blockquote").targets) {
                GXml.DomElement style = res.create_element ("style");
                style.set_attribute ("name", apply);
                add_attributes (colors.blockquote, pallet, dark, ref style);
                root.append_child (style);
            }

            // Link
            foreach (var apply in _gtk_style_map.get ("link").targets) {
                GXml.DomElement style = res.create_element ("style");
                style.set_attribute ("name", apply);
                add_attributes (colors.link, pallet, dark, ref style);
                root.append_child (style);
            }

            // Divider
            foreach (var apply in _gtk_style_map.get ("divider").targets) {
                GXml.DomElement style = res.create_element ("style");
                style.set_attribute ("name", apply);
                add_attributes (colors.divider, pallet, dark, ref style);
                root.append_child (style);
            }

            // List
            foreach (var apply in _gtk_style_map.get ("orderedList").targets) {
                GXml.DomElement style = res.create_element ("style");
                style.set_attribute ("name", apply);
                add_attributes (colors.orderedList, pallet, dark, ref style);
                root.append_child (style);
            }

            // Image
            foreach (var apply in _gtk_style_map.get ("image").targets) {
                GXml.DomElement style = res.create_element ("style");
                style.set_attribute ("name", apply);
                add_attributes (colors.image, pallet, dark, ref style);
                root.append_child (style);
            }

            // Emphasis
            foreach (var apply in _gtk_style_map.get ("emph").targets) {
                GXml.DomElement style = res.create_element ("style");
                style.set_attribute ("name", apply);
                add_attributes (colors.emph, pallet, dark, ref style);
                root.append_child (style);
            }

            // Strong
            foreach (var apply in _gtk_style_map.get ("strong").targets) {
                GXml.DomElement style = res.create_element ("style");
                style.set_attribute ("name", apply);
                add_attributes (colors.strong, pallet, dark, ref style);
                root.append_child (style);
            }

            // Strong
            foreach (var apply in _gtk_style_map.get ("strike").targets) {
                GXml.DomElement style = res.create_element ("style");
                style.set_attribute ("name", apply);
                add_attributes (colors.strike, pallet, dark, ref style);
                root.append_child (style);
            }

            return ((GXml.Document) res).write_string ();
        }

        public void add_attributes (ColorMapItem item, ColorPalette pallet, bool is_dark, ref GXml.DomElement elem) {
            try {
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
                    elem.set_attribute ("bold", "true");
                }

                if (item.italic) {
                    elem.set_attribute ("italic", "true");
                }

                if (item.underline) {
                    elem.set_attribute ("underline", "true");
                    elem.set_attribute ("underline-color", fg);
                }

                if (item.strikethrough) {
                    elem.set_attribute ("strikethrough", "true");
                }

                elem.set_attribute ("background", bg);
                elem.set_attribute ("foreground", fg);
            } catch (Error e) {
                warning ("Could not add attributes: %s", e.message);
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
