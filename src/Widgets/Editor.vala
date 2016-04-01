public class Mail.Editor : Gtk.Box {
    private Gtk.SourceView code_view;
    private Gtk.SourceBuffer code_buffer;

    private bool edited = false;


    public Editor () {
        build_ui ();
        reset (true);
    }

    
    public void save_file () {
        if (edited) {
        	edited = false;
        }
    }

    public void set_text (string text, bool new_file = false) {
        if (new_file) {
            code_buffer.changed.disconnect (trigger_changed);
        }

        code_buffer.text = text;

        if (new_file) {
            code_buffer.changed.connect (trigger_changed);
        }
    }

    public void restore () {
    	
    }

    public void reset (bool disable_save = false) {
        if (disable_save) {
            edited = false;
        }
        
        code_buffer.text = "";
    }

    public string get_text () {
        return code_view.buffer.text;
    }

    public void give_focus () {
        code_view.grab_focus ();
    }

    public void set_font (string name) {
        var font = Pango.FontDescription.from_string (name);
        code_view.override_font (font);
    }

    public void set_scheme (string id) {
        var style_manager = Gtk.SourceStyleSchemeManager.get_default ();
        var style = style_manager.get_scheme (id);
        code_buffer.set_style_scheme (style);
    }

    private void trigger_changed () {
        edited = true;
    }

    private void build_ui () {
        var manager = Gtk.SourceLanguageManager.get_default ();
        var language = manager.guess_language (null, "text/x-markdown");
        code_buffer = new Gtk.SourceBuffer (null);
        code_buffer.set_max_undo_levels (100);

        code_view = new Gtk.SourceView.with_buffer (code_buffer);

        set_size_request (250,50);
        expand = true;

        code_buffer.changed.connect (trigger_changed);

        code_view.left_margin = code_view.right_margin = code_view.top_margin = 24;
        code_view.pixels_above_lines = 6;
        code_view.wrap_mode = Gtk.WrapMode.WORD;
        code_view.show_line_numbers = false;

	    var scroll_box = new Gtk.ScrolledWindow (null, null);
	    scroll_box.add (code_view);

	    this.set_orientation (Gtk.Orientation.VERTICAL);
        this.add (scroll_box);
        this.set_sensitive (false);
	    scroll_box.expand = true;
        this.show_all ();
    }
}
