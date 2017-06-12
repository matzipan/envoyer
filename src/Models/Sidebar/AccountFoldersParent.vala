/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

using Envoyer.Models;

public class Envoyer.Models.Sidebar.AccountFoldersParent : Basalt.Widgets.SidebarHeaderModel  {
    public AccountFoldersParent (Identity identity) {
        base (identity.account_name, false);
    }
}