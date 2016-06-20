/* 
 * Copyright 2011-2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.AccountFoldersParentItem : Envoyer.SimpleExpandableItem {
    public AccountFoldersParentItem (E.Source identity_source) {
        base (identity_source.get_display_name ());
    }
}