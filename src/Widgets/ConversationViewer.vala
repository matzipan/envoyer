

public class Envoyer.Widgets.ConversationViewer : Gtk.Grid {
    private Gtk.ListBox listbox; //@TODO abstract this
    private Gtk.ScrolledWindow scrollbox; //@TODO abstract this
    private Envoyer.Models.ConversationThread conversation_thread;

    public ConversationViewer () {
        build_ui ();
    }

    private void build_ui () {
        orientation = Gtk.Orientation.VERTICAL;
        hexpand = true;
        
        listbox = new Gtk.ListBox ();
        
        scrollbox = new Gtk.ScrolledWindow (null, null);
        scrollbox.expand = true;
        scrollbox.add (listbox);
        scrollbox.hscrollbar_policy = Gtk.PolicyType.NEVER;
        
        add (scrollbox);
        show_all ();
    }
    
    private void load_data () {
        clear ();

        foreach (var item in conversation_thread.messages) {
            var viewer = new Envoyer.Widgets.MessageViewer(item);
            viewer.scroll_event.connect(handle_scroll_event);
            listbox.add(viewer);
        }

        listbox.show_all ();
    }
    
    private bool handle_scroll_event (Gdk.EventScroll event) {
        /*
         * I admit that this solution feels hacky, but I could not find any other working solution
         * for propagating the scroll event upwards. 
         */
        scrollbox.scroll_event (event);
        
        return Gdk.EVENT_PROPAGATE;
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
