public class Mail.Util.SidebarBuilder : GLib.Object {
    public static void build_list (Mail.NestedListBox listbox) {
        var summaries_geelist = build_summaries_list ();

        var unified_inbox = new Mail.Models.UnifiedFolderParent ("Inbox");
        var unified_starred = new Mail.Models.UnifiedFolderParent ("Starred");
        var unified_important = new Mail.Models.UnifiedFolderParent ("Important"); //@TODO this is only a gmail feature, only show if this folder type really exists
        var unified_drafts = new Mail.Models.UnifiedFolderParent ("Drafts");
        var unified_sent = new Mail.Models.UnifiedFolderParent ("Sent");
        var unified_archive = new Mail.Models.UnifiedFolderParent ("Archive"); //@TODO check if items exist for each and every one of these, if it does not, then don't create
        var unified_all_mail = new Mail.Models.UnifiedFolderParent ("All Mail");
        var unified_junk = new Mail.Models.UnifiedFolderParent ("Spam");
        var unified_trash = new Mail.Models.UnifiedFolderParent ("Trash");
        
        foreach (var summary in summaries_geelist) {

            foreach(var folder in summary.folders_list) {
                if(folder.is_inbox) {
                    unified_inbox.add (new Mail.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_starred) {
                    unified_starred.add (new Mail.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_important) {
                    unified_important.add (new Mail.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_drafts) {
                    unified_drafts.add (new Mail.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_sent) {
                    unified_sent.add (new Mail.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_junk) {
                    unified_junk.add (new Mail.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_trash) {
                    unified_trash.add (new Mail.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_archive) {
                    unified_archive.add (new Mail.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_all_mail) {
                    unified_all_mail.add (new Mail.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
            }
        }

        listbox.add (new Mail.UnifiedFolderParentItem (unified_inbox));
        listbox.add (new Mail.UnifiedFolderParentItem (unified_starred));
        listbox.add (new Mail.UnifiedFolderParentItem (unified_important));
        listbox.add (new Mail.UnifiedFolderParentItem (unified_drafts));
        listbox.add (new Mail.UnifiedFolderParentItem (unified_sent));
        listbox.add (new Mail.UnifiedFolderParentItem (unified_archive));
        listbox.add (new Mail.UnifiedFolderParentItem (unified_all_mail));
        listbox.add (new Mail.UnifiedFolderParentItem (unified_junk));
        listbox.add (new Mail.UnifiedFolderParentItem (unified_trash));

        foreach (var summary in summaries_geelist) {
            var account_folders_parent = new Mail.AccountFoldersParentItem (summary.identity_source);

            foreach (var folder in summary.folders_list) {
                if (folder.is_normal) {
                    account_folders_parent.add (new Mail.FolderItem (folder));
                }
            }
            
            listbox.add (account_folders_parent);
        }
    }
    
    public static Gee.Collection<Mail.Models.AccountSummary> build_summaries_list () {  //@TODO async
        var summaries_list = new Gee.ArrayList<Mail.Models.AccountSummary> (null);

        Mail.session.get_services().foreach((service) => {
            summaries_list.add(new Mail.Models.AccountSummary (service));
        });   
        
        return summaries_list;     
    }
}