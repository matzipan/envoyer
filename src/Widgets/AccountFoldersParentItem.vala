public class Mail.AccountFoldersParentItem : Mail.SimpleExpandableItem {
    public AccountFoldersParentItem (E.Source identity_source) {
        base (identity_source.get_display_name ());
    }
}