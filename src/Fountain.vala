using ThiefMD;

namespace ThiefMD.Enrichments {
    public class FountainEnrichment : Object {
        private GtkSource.View view;
        private Gtk.TextBuffer buffer;
        private Mutex checking;

        private Gtk.TextTag tag_character;
        private Gtk.TextTag tag_dialogue;
        private Gtk.TextTag tag_scene_heading;
        private Gtk.TextTag tag_parenthetical;

        private Regex scene_heading;
        private Regex character_dialogue;
        private Regex parenthetical_dialogue;
        private string checking_copy;

        private int copy_offset;

        public FountainEnrichment () {
            try {
                scene_heading = new Regex ("\\n(ИНТ|НАТ|инт|нат|INT|EXT|EST|I\\/E|int|ext|est|i\\/e)[\\. \\/].*\\S\\s?\\r?\\n", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF | RegexCompileFlags.CASELESS, 0);
                // character_dialogue = new Regex ("(?<=\\n)([ \\t]*[^<>a-z\\s\\/\\n][^<>a-z:!\\?\\n]*[^<>a-z\\(!\\?:,\\n\\.][ \\t]?|[ \\t]*\\(?[^\\n]\\)?[ \\t]*)\\n{1}(?!\\n)(.*?)\\r?\\n{1}", 0, 0);
                character_dialogue = new Regex ("(?<=\\n)([ \\t]*?[^<>a-z\\s\\/\\n][^<>a-z:!\\?\\n]*[^<>a-z\\(!\\?:,\\n\\.][ \\t]?|\\([^\\n]+\\))\\n{1}(?!\\n)(.+?)\\n{1}", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF, 0);
                parenthetical_dialogue = new Regex ("(?<=\\n)([ \\t]*?\\([^\\n]+\\))\\n{1}(?!\\n)(.+?)\\n{1}", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF, 0);
            } catch (Error e) {
                warning ("Could not build regexes: %s", e.message);
            }
            checking = Mutex ();
        }

        public void reset () {
            recheck_all ();
        }

        public void get_chunk_of_text_around_cursor (ref Gtk.TextIter start, ref Gtk.TextIter end, bool force_lines = false) {
            start.backward_line ();
    
            //
            // Try to make sure we don't wind up in the middle of
            // CHARACTER
            // [Iter]Dialogue
            //
            int line_checks = 0;
            if (!force_lines) {
                while (start.get_char () != '\n' && start.get_char () != '\r' && line_checks <= 5) {
                    if (!start.backward_line ()) {
                        break;
                    }
                    line_checks += 1;
                }
    
                end.forward_line ();
                line_checks = 0;
                while (end.get_char () != '\n' && end.get_char () != '\r' && line_checks <= 5) {
                    if (!end.forward_line ()) {
                        break;
                    }
                    line_checks += 1;
                }
            } else {
                while (line_checks <= 5) {
                    if (!start.backward_line ()) {
                        break;
                    }
                    line_checks += 1;
                }
    
                end.forward_line ();
                line_checks = 0;
                while (line_checks <= 5) {
                    if (!end.forward_line ()) {
                        break;
                    }
                    line_checks += 1;
                }
            }
        }

        public void recheck_all () {
            if (view == null || buffer == null) {
                return;
            }

            if (!((GtkSource.Buffer)buffer).language.get_name ().down ().contains ("fountain")) {
                return;
            }

            if (!checking.trylock ()) {
                return;
            }

            view.left_margin = 80;
            view.right_margin = 80;
            calculate_margins ();

            // Get current cursor location
            Gtk.TextIter start, end, cursor_iter;
            var cursor = buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor_iter, cursor);
            int current_cursor = cursor_iter.get_offset ();

            buffer.get_bounds (out start, out end);
            run_between_start_and_end (start, end);
            checking.unlock ();
        }

        private void run_between_start_and_end (Gtk.TextIter start, Gtk.TextIter end) {
            copy_offset = start.get_offset ();

            buffer.remove_tag (tag_scene_heading, start, end);
            buffer.remove_tag (tag_character, start, end);
            buffer.remove_tag (tag_parenthetical, start, end);
            buffer.remove_tag (tag_dialogue, start, end);
            checking_copy = buffer.get_text (start, end, true);

            regex_and_tag (scene_heading, tag_scene_heading);
            tag_characters_and_dialogue ();
            checking_copy = "";
        }

        private void tag_characters_and_dialogue () {
            if (character_dialogue == null || tag_character == null || tag_dialogue == null || parenthetical_dialogue == null) {
                return;
            }
            tag_char_diag_helper (character_dialogue);
            tag_char_diag_helper (parenthetical_dialogue);
        }

        private void tag_char_diag_helper (Regex regex) {
            Gtk.TextIter cursor_iter;
            var cursor = buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor_iter, cursor);
            try {
                MatchInfo match_info;
                if (regex.match_full (checking_copy, checking_copy.length, 0, 0, out match_info)) {
                    do {
                        int start_pos, end_pos;
                        bool highlight = false;
                        Gtk.TextIter start, end;

                        // Clear tags from all
                        highlight = match_info.fetch_pos (0, out start_pos, out end_pos);
                        if (highlight) {
                            start_pos = copy_offset + checking_copy.char_count (start_pos);
                            end_pos = copy_offset + checking_copy.char_count (end_pos);
                            buffer.get_iter_at_offset (out start, start_pos);
                            buffer.get_iter_at_offset (out end, end_pos);
                            buffer.remove_tag (tag_character, start, end);
                            buffer.remove_tag (tag_dialogue, start, end);
                            buffer.remove_tag (tag_parenthetical, start, end);
                        }

                        highlight = match_info.fetch_pos (1, out start_pos, out end_pos);
                        string character = match_info.fetch (1);
                        string dialogue = match_info.fetch (2);
                        if (character == null || dialogue == null || dialogue.chomp ().chug () == "" || dialogue.has_prefix ("\t") || dialogue.has_prefix ("    ")) {
                            continue;
                        }
                        start_pos = copy_offset + checking_copy.char_count (start_pos);
                        end_pos = copy_offset + checking_copy.char_count (end_pos);
        
                        if (highlight) {
                            buffer.get_iter_at_offset (out start, start_pos);
                            buffer.get_iter_at_offset (out end, end_pos);
                            if (character.chomp ().chug ().has_prefix ("(")) {
                                buffer.apply_tag (tag_parenthetical, start, end);
                            } else {
                                buffer.apply_tag (tag_character, start, end);
                                start.backward_word_start ();
                                end.forward_word_end ();
                            }
                        }

                        highlight = match_info.fetch_pos (2, out start_pos, out end_pos);
                        start_pos = copy_offset + checking_copy.char_count (start_pos);
                        end_pos = copy_offset + checking_copy.char_count (end_pos);
                        if (highlight) {
                            buffer.get_iter_at_offset (out start, start_pos);
                            buffer.get_iter_at_offset (out end, end_pos);
                            buffer.apply_tag (tag_dialogue, start, end);
                        }
                    } while (match_info.next ());
                }
            } catch (Error e) {
                warning ("Could not tag characters and dialogues: %s", e.message);
            }
        }

        private void regex_and_tag (Regex regex, Gtk.TextTag tag) {
            if (regex == null || tag == null) {
                return;
            }
            try {
                MatchInfo match_info;
                if (regex.match_full (checking_copy, checking_copy.length, 0, 0, out match_info)) {
                    highlight_results (match_info, tag);
                }
            } catch (Error e) {
                warning ("Could not apply tags: %s", e.message);
            }
        }

        private void highlight_results (MatchInfo match_info, Gtk.TextTag marker) throws Error {
            do {
                int start_pos, end_pos;
                bool highlight = false;
                highlight = match_info.fetch_pos (0, out start_pos, out end_pos);
                string word = match_info.fetch (0);
                start_pos = copy_offset + checking_copy.char_count (start_pos);
                end_pos = copy_offset + checking_copy.char_count (end_pos);

                if (word != null && highlight) {
                    debug ("%s: %s", marker.name, word);
                    Gtk.TextIter start, end;
                    buffer.get_iter_at_offset (out start, start_pos);
                    buffer.get_iter_at_offset (out end, end_pos);
                    buffer.apply_tag (marker, start, end);
                }
            } while (match_info.next ());
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

            view.destroy.connect (detach);

            // Bold Scene Headings
            tag_scene_heading = buffer.create_tag ("scene_heading");
            tag_scene_heading.weight = Pango.Weight.BOLD;
            tag_scene_heading.weight_set = true;

            // Character
            tag_character = buffer.create_tag ("fou_char");
            tag_character.accumulative_margin = true;
            tag_character.left_margin_set = true;
            tag_parenthetical = buffer.create_tag ("fou_paren");
            tag_parenthetical.accumulative_margin = true;
            tag_parenthetical.left_margin_set = true;
            // Dialogue
            tag_dialogue = buffer.create_tag ("fou_diag");
            tag_dialogue.accumulative_margin = true;
            tag_dialogue.left_margin_set = true;
            tag_dialogue.right_margin_set = true;

            calculate_margins ();

            return true;
        }

        private int get_string_px_width (string str) {
            int f_w = 14;
            if (view.get_realized ()) {
                var font_context = view.get_pango_context ();
                var font_desc = font_context.get_font_description ();
                var font_layout = new Pango.Layout (font_context);
                font_layout.set_font_description (font_desc);
                font_layout.set_text (str, str.length);
                Pango.Rectangle ink, logical;
                font_layout.get_pixel_extents (out ink, out logical);
                font_layout.dispose ();
                debug ("# Ink: %d, Logical: %d", ink.width, logical.width);
                return int.max (ink.width, logical.width);
            }
            return f_w;
        }

        private void calculate_margins () {
            int f_w = (int) 14;
            int hashtag_w = f_w;
            int space_w = f_w;
            int avg_w = f_w;

            if (view.get_realized ()) {
                space_w = get_string_px_width(" ");
                hashtag_w = get_string_px_width("#");
                if (space_w + hashtag_w <= 0) {
                    hashtag_w = f_w;
                    space_w = f_w;
                }
                if (space_w < (hashtag_w / 2)) {
                    avg_w = (int)((hashtag_w + hashtag_w + space_w) / 3.0);
                } else {
                    avg_w = (int)((hashtag_w + space_w) / 2.0);
                }
            }
            // Character
            tag_character.left_margin = (avg_w * 14);
            tag_parenthetical.left_margin = (avg_w * 10);
            // Dialogue
            tag_dialogue.left_margin = (avg_w * 6);
            tag_dialogue.right_margin = (avg_w * 6);
        }

        public void detach () {
            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);

            buffer.remove_tag (tag_scene_heading, start, end);
            buffer.remove_tag (tag_character, start, end);
            buffer.remove_tag (tag_parenthetical, start, end);
            buffer.remove_tag (tag_dialogue, start, end);
            buffer.tag_table.remove (tag_scene_heading);
            buffer.tag_table.remove (tag_character);
            buffer.tag_table.remove (tag_parenthetical);
            buffer.tag_table.remove (tag_dialogue);

            tag_scene_heading = null;
            tag_character = null;
            tag_parenthetical = null;
            tag_dialogue = null;

            view = null;
            buffer = null;
        }
    }
}