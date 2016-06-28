/*
 * Copyright 2011-2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Envoyer.Widgets.UnifiedFolderChildItem : Envoyer.Widgets.FolderItem {
    public signal void unread_count_changed (uint new_count);

    public UnifiedFolderChildItem (Envoyer.Models.UnifiedFolderChild folder) {
        base (folder);

        connect_signals ();
        build_ui ();
    }
    
    private void connect_signals () {
        folder.unread_count_changed.connect (new_count => { unread_count_changed(new_count); });
    }
    
    private void build_ui () {
        set_left_spacing (30);
    }
}