/*
 * Copyright 2011-2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Envoyer.FolderItem : Envoyer.IFolderItem, Gtk.ListBoxRow {
    private Gtk.Grid grid;
    private Envoyer.FolderLabel folder_label;
    
    private Envoyer.Models.IFolder _folder;
    public Envoyer.Models.IFolder folder { get { return _folder; } }

    public FolderItem (Envoyer.Models.IFolder folder) {
        _folder = folder;

        build_ui ();
    }

    private void build_ui () {
        grid = new Gtk.Grid ();
        grid.margin_top = 4;
        grid.margin_bottom = 4;
        grid.margin_right = 8;

        set_left_spacing (20);

        grid.add (new Envoyer.FolderLabel(folder));

        add (grid);

        show_all ();
    }

    protected void set_left_spacing (int margin) {
        grid.margin_left = margin;
    }
}

