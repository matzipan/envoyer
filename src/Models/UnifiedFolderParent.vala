public class Mail.Models.UnifiedFolderParent {
    private string name;

    public string display_name { get { return name; } }

    //@TODO keep track of children
    //@TODO add up all the children's unread counts and then propagate to UnifiedFolderParentItem
    //@TODO keep track of children being added

    public UnifiedFolderParent (string name) {
        this.name = name;
    }
    
    public void add(Mail.Models.UnifiedFolderChild child) {
        //@TODO
    }
}