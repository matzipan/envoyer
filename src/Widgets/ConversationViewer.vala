

public class Envoyer.Widgets.ConversationViewer : Gtk.ListBox {

    private Envoyer.Models.ConversationThread conversation_thread;

    public ConversationViewer () { 
        expand = true;
    }

    private void build_ui () {
        clear ();

        foreach (var item in conversation_thread.messages) {
            add(new Envoyer.Widgets.MessageViewer(item));
        }

        show_all ();
    }
    
    public void load_conversation_thread (Envoyer.Models.ConversationThread conversation_thread) {
        this.conversation_thread = conversation_thread;

        build_ui ();
    }
    
    private void clear () {
        foreach(var child in get_children ()) {
            remove (child);
        }
    }
}