/* 
 * Copyright 2011-2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Util.SidebarBuilder : GLib.Object {
    public static void build_list (Envoyer.NestedListBox listbox) {
        var summaries_geelist = build_summaries_list ();

        var unified_inbox = new Envoyer.Models.UnifiedFolderParent ("Inbox");
        var unified_starred = new Envoyer.Models.UnifiedFolderParent ("Starred");
        var unified_important = new Envoyer.Models.UnifiedFolderParent ("Important"); //@TODO this is only a gmail feature, only show if this folder type really exists
        var unified_drafts = new Envoyer.Models.UnifiedFolderParent ("Drafts");
        var unified_sent = new Envoyer.Models.UnifiedFolderParent ("Sent");
        var unified_archive = new Envoyer.Models.UnifiedFolderParent ("Archive"); //@TODO check if items exist for each and every one of these, if it does not, then don't create
        var unified_all_mail = new Envoyer.Models.UnifiedFolderParent ("All Mail");
        var unified_junk = new Envoyer.Models.UnifiedFolderParent ("Spam");
        var unified_trash = new Envoyer.Models.UnifiedFolderParent ("Trash");
        
        foreach (var summary in summaries_geelist) {

            foreach(var folder in summary.folders_list) {
                if(folder.is_inbox) {
                    unified_inbox.add (new Envoyer.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_starred) {
                    unified_starred.add (new Envoyer.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_important) {
                    unified_important.add (new Envoyer.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_drafts) {
                    unified_drafts.add (new Envoyer.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_sent) {
                    unified_sent.add (new Envoyer.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_junk) {
                    unified_junk.add (new Envoyer.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_trash) {
                    unified_trash.add (new Envoyer.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_archive) {
                    unified_archive.add (new Envoyer.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_all_mail) {
                    unified_all_mail.add (new Envoyer.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
            }
        }

        listbox.add (new Envoyer.UnifiedFolderParentItem (unified_inbox));
        listbox.add (new Envoyer.UnifiedFolderParentItem (unified_starred));
        listbox.add (new Envoyer.UnifiedFolderParentItem (unified_important));
        listbox.add (new Envoyer.UnifiedFolderParentItem (unified_drafts));
        listbox.add (new Envoyer.UnifiedFolderParentItem (unified_sent));
        listbox.add (new Envoyer.UnifiedFolderParentItem (unified_archive));
        listbox.add (new Envoyer.UnifiedFolderParentItem (unified_all_mail));
        listbox.add (new Envoyer.UnifiedFolderParentItem (unified_junk));
        listbox.add (new Envoyer.UnifiedFolderParentItem (unified_trash));

        foreach (var summary in summaries_geelist) {
            var account_folders_parent = new Envoyer.AccountFoldersParentItem (summary.identity_source);

            foreach (var folder in summary.folders_list) {
                if (folder.is_normal) {
                    account_folders_parent.add (new Envoyer.FolderItem (folder));
                }
            }
            
            listbox.add (account_folders_parent);
        }
    }
    
    public static Gee.Collection<Envoyer.Models.AccountSummary> build_summaries_list () {  //@TODO async
        var summaries_list = new Gee.ArrayList<Envoyer.Models.AccountSummary> (null);

        Envoyer.session.get_services().foreach((service) => {
            summaries_list.add(new Envoyer.Models.AccountSummary (service));
        });   
        
        return summaries_list;     
    }
}