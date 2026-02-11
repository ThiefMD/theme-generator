/*
 * Copyright (C) 2021 kmwallio
 * 
 * Modified March 21, 2021
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

using ThiefMD;

namespace ThiefMD.Enrichments {
    public class MarkdownEnrichment {
        private GtkSource.View view;
        private Gtk.TextBuffer buffer;
        private Mutex checking;
        private bool markup_inserted_around_selection;
        private bool cursor_at_interesting_location = false;
        public bool active_selection = false;

        private Gtk.TextTag[] heading_text;
        public Gtk.TextTag code_block;
        public Gtk.TextTag markdown_link;
        public Gtk.TextTag markdown_url;

        //
        // Regexes
        // 
        private Regex is_list;
        private Regex is_partial_list;
        private Regex numerical_list;
        private Regex is_url;
        private Regex is_markdown_url;
        private Regex is_heading;

        private string checking_copy;
        private string code_block_background;

        private int last_cursor;
        private int copy_offset;
        private int hashtag_w;
        private int space_w;
        private int avg_w;

        public MarkdownEnrichment () {
            code_block_background = "";
            try {
                is_heading = new Regex ("(#+\\s[^\\n\\r]+?)\\r?\\n", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF | RegexCompileFlags.CASELESS, 0);
                is_list = new Regex ("^(\\s*([\\*\\-\\+\\>]|[0-9]+(\\.|\\)))\\s)\\s*(.+)", RegexCompileFlags.CASELESS, 0);
                is_partial_list = new Regex ("^(\\s*([\\*\\-\\+\\>]|[0-9]+\\.))\\s+$", RegexCompileFlags.CASELESS, 0);
                numerical_list = new Regex ("^(\\s*)([0-9]+)((\\.|\\))\\s+)$", RegexCompileFlags.CASELESS, 0);
                is_url = new Regex ("^(http|ftp|ssh|mailto|tor|torrent|vscode|atom|rss|file)?s?(:\\/\\/)?(www\\.)?([a-zA-Z0-9\\.\\-]+)\\.([a-z]+)([^\\s]+)$", RegexCompileFlags.CASELESS, 0);
                is_codeblock = new Regex ("(```[a-zA-Z]*[\\n\\r]((.*?)[\\n\\r])*?```[\\n\\r])", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
                is_markdown_url = new Regex ("(?<text_group>\\[(?>[^\\[\\]]+|(?&text_group))+\\])(?:\\((?<url>\\S+?)(?:[ ]\"(?<title>(?:[^\"]|(?<=\\\\)\")*?)\")?\\))", RegexCompileFlags.CASELESS, 0);
            } catch (Error e) {
                warning ("Could not initialize regexes: %s", e.message);
            }
            checking = Mutex ();
            markup_inserted_around_selection = false;
            active_selection = false;
            last_cursor = -1;
        }

        private void tag_code_blocks () {
            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);
            buffer.remove_tag (code_block, start, end);
            string code_block_copy = buffer.get_text (start, end, true);
            // Tag code blocks as such (regex hits issues on large text)
            int block_occurrences = code_block_copy.down ().split ("\n```").length - 1;
            if (block_occurrences % 2 == 0) {
                int offset = code_block_copy.index_of ("\n```");
                while (offset > 0) {
                    offset = offset + 1;
                    int next_offset = code_block_copy.index_of ("\n```", offset + 1);
                    if (next_offset > 0) {
                        int start_pos, end_pos;
                        start_pos = code_block_copy.char_count (offset);
                        end_pos = code_block_copy.char_count ((next_offset + 4));
                        buffer.get_iter_at_offset (out start, start_pos);
                        buffer.get_iter_at_offset (out end, end_pos);
                        buffer.apply_tag (code_block, start, end);
                        //
                        // Remove links and headings from codeblock.
                        //
                        for (int h = 0; h < 6; h++) {
                            buffer.remove_tag (heading_text[h], start, end);
                        }
                        buffer.remove_tag (markdown_link, start, end);
                        buffer.remove_tag (markdown_url, start, end);
                        offset = code_block_copy.index_of ("\n```", next_offset + 1);
                    } else {
                        break;
                    }
                }
            }
        }

        public void set_code_background (string new_bg) {
            code_block_background = new_bg;
            if (code_block_background != "") {
                code_block.background = code_block_background;
                code_block.background_set = true;
                code_block.paragraph_background = code_block_background;
                code_block.paragraph_background_set = true;
                code_block.background_full_height = true;
                code_block.background_full_height_set = true;
            }
        }

        private void run_between_start_and_end (Gtk.TextIter start, Gtk.TextIter end) {
            copy_offset = start.get_offset ();
            checking_copy = buffer.get_text (start, end, true);

            update_heading_margins (start, end);

            checking_copy = "";
        }

        private void update_heading_margins (Gtk.TextIter start_region, Gtk.TextIter end_region) {
            try {
                Gtk.TextIter start, end;
                Gtk.TextIter cursor_location;
                var cursor = buffer.get_insert ();
                MatchInfo match_info;
                buffer.get_iter_at_mark (out cursor_location, cursor);

                for (int h = 0; h < 6; h++) {
                    buffer.remove_tag (heading_text[h], start_region, end_region);
                }

                // Tag headings and make sure they're not in code blocks
                if (is_heading.match_full (checking_copy, checking_copy.length, 0, RegexMatchFlags.BSR_ANYCRLF | RegexMatchFlags.NEWLINE_ANYCRLF, out match_info)) {
                    do {
                        int start_pos, end_pos;
                        string heading = match_info.fetch (1);
                        bool headify = match_info.fetch_pos (1, out start_pos, out end_pos) && (heading.index_of ("\n") < 0);
                        if (headify) {
                            start_pos = copy_offset + checking_copy.char_count (start_pos);
                            end_pos = copy_offset + checking_copy.char_count (end_pos);
                            buffer.get_iter_at_offset (out start, start_pos);
                            buffer.get_iter_at_offset (out end, end_pos);
                            if (start.has_tag (code_block) || end.has_tag (code_block)) {
                                continue;
                            }
                            int heading_depth = heading.index_of (" ") - 1;
                            if (heading_depth >= 0 && heading_depth < 6) {
                                buffer.apply_tag (heading_text[heading_depth], start, end);
                            }
                        }
                    } while (match_info.next ());
                }
            } catch (Error e) {
                warning ("Could not adjust headers: %s", e.message);
            }
        }

        public void reset () {
            last_cursor = -1;
            recheck_all ();
        }

        public void recheck_all () {
            if (view == null || buffer == null) {
                return;
            }

            if (!((GtkSource.Buffer)buffer).language.get_name ().down ().contains ("markdown")) {
                if (view.left_margin != 0) {
                    Gtk.TextIter start, end;
                    buffer.get_bounds (out start, out end);

                    buffer.remove_tag (code_block, start, end);
                    buffer.remove_tag (markdown_link, start, end);
                    buffer.remove_tag (markdown_url, start, end);
                    for (int h = 0; h < 6; h++) {
                        buffer.remove_tag (heading_text[h], start, end);
                    }
                    if (((GtkSource.Buffer)buffer).language.get_name ().down ().contains ("fountain")) {
                        return;
                    }
                    view.left_margin = 0;
                    view.right_margin = 0;
                }
                return;
            } else if (((GtkSource.Buffer)buffer).language.get_name ().down ().contains ("markdown")) {
                view.left_margin = 80;
                view.right_margin = 80;
            }

            recalculate_margins ();

            if (!checking.trylock ()) {
                return;
            }

            code_block.background_full_height = true;
            code_block.background_full_height_set = true;

            // Remove any previous tags
            Gtk.TextIter start, end, cursor_iter;
            var cursor = buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor_iter, cursor);
            int current_cursor = cursor_iter.get_offset ();

            tag_code_blocks ();
            buffer.get_bounds (out start, out end);
            run_between_start_and_end (start, end);
            last_cursor = current_cursor;
            checking.unlock ();
        }

        public bool attach (GtkSource.View textview) {
            if (textview == null) {
                return false;
            }

            view = textview;
            buffer = textview.get_buffer ();

            if (buffer == null) {
                view = null;
                return false;
            }
            view.left_margin = 80;
            view.right_margin = 80;

            view.destroy.connect (detach);

            heading_text = new Gtk.TextTag[6];
            for (int h = 0; h < 6; h++) {
                heading_text[h] = buffer.create_tag ("heading%d-text".printf (h + 1));
                heading_text[h].left_margin_set = true;
                heading_text[h].accumulative_margin = false;
            }

            code_block = buffer.create_tag ("code-block");
            markdown_link = buffer.create_tag ("markdown-link");
            markdown_url = buffer.create_tag ("markdown-url");
            markdown_url.invisible = true;
            markdown_url.invisible_set = true;
            markup_inserted_around_selection = false;
            cursor_at_interesting_location = false;
            active_selection = false;

            settings_updated ();

            last_cursor = -1;

            return true;
        }

        private void settings_updated () {
            markdown_url.invisible = false;
            markdown_url.invisible_set = false;

            if (code_block_background != "") {
                code_block.background = code_block_background;
                code_block.background_set = true;
                code_block.paragraph_background = code_block_background;
                code_block.paragraph_background_set = true;
                code_block.background_full_height = true;
                code_block.background_full_height_set = true;
            }

            recalculate_margins ();
        }

        private void recalculate_margins () {
            int f_w = 10;
            int m = view.left_margin;
            hashtag_w = f_w;
            space_w = f_w;
            avg_w = f_w;

            if (m - ((hashtag_w * 6) + space_w) <= 0) {
                heading_text[0].left_margin = m;
                heading_text[1].left_margin = m;
                heading_text[2].left_margin = m;
                heading_text[3].left_margin = m;
                heading_text[4].left_margin = m;
                heading_text[5].left_margin = m;
            } else {
                heading_text[0].left_margin = m - ((hashtag_w * 1) + space_w);
                heading_text[1].left_margin = m - ((hashtag_w * 2) + space_w);
                heading_text[2].left_margin = m - ((hashtag_w * 3) + space_w);
                heading_text[3].left_margin = m - ((hashtag_w * 4) + space_w);
                heading_text[4].left_margin = m - ((hashtag_w * 5) + space_w);
                heading_text[5].left_margin = m - ((hashtag_w * 6) + space_w);
            }
        }

        public void detach () {
        }
    }
}