/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public interface Envoyer.Widgets.Main.Sidebar.IFolderItem : GLib.Object {
    public abstract Envoyer.Models.IFolder folder { get; }
}
