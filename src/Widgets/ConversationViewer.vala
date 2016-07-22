

public class Envoyer.Widgets.ConversationViewer : Gtk.Grid {
    private Gtk.ListBox listbox; //@TODO abstract this
    private Envoyer.Models.ConversationThread conversation_thread;

    public ConversationViewer () {
        build_ui ();
    }

    private void build_ui () {
        orientation = Gtk.Orientation.VERTICAL;
        hexpand = true;
        
        listbox = new Gtk.ListBox ();
        
        var scroll_box = new Gtk.ScrolledWindow (null, null);
        scroll_box.expand = true;
        scroll_box.add (listbox);
        scroll_box.hscrollbar_policy = Gtk.PolicyType.NEVER;

        add (scroll_box);
        show_all ();
    }
    
    private void load_data () {
        clear ();

        foreach (var item in conversation_thread.messages) {
            listbox.add(new Envoyer.Widgets.MessageViewer(item));
        }

        listbox.show_all ();
    }
    
    public void load_conversation_thread (Envoyer.Models.ConversationThread conversation_thread) {
        this.conversation_thread = conversation_thread;

        load_data ();
    }
    
    private void clear () {
        foreach(var child in listbox.get_children ()) {
            listbox.remove (child);
        }
    }
}
