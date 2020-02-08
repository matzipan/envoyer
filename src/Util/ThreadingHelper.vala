/*
 * Copyright (C) 2019  Andrei-Costin Zisu
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
 
 public class Envoyer.Util.ThreadingContainer {
     public Envoyer.Models.Message message = null;
     public Envoyer.Util.ThreadingContainer parent = null;
     public Gee.LinkedList <Envoyer.Util.ThreadingContainer> children = new Gee.LinkedList <Envoyer.Util.ThreadingContainer> ();

     // This returns a copied list which is not susceptible to changes when the original list has items removed from it
     public Gee.LinkedList <Envoyer.Util.ThreadingContainer> children_copied {
         owned get {
             var children_copy = new Gee.LinkedList<Envoyer.Util.ThreadingContainer> (null);

             children_copy.add_all (children);

             return children_copy;
         }
     }

     public void add_child (Envoyer.Util.ThreadingContainer child) {
         if (child.parent != null) {
             child.parent.children.remove (child);
         }
         children.add (child);
         child.parent = this;
     }
 }

 public class Envoyer.Util.ThreadingHelper : GLib.Object {
     // Base algorithm from Jamie Zawinski https://www.jwz.org/doc/threading.html
     // Standardized in RFC 5256 https://tools.ietf.org/html/rfc5256.html
     // Inspiration from https://github.com/fdietz/jwz_threading/

     public ThreadingHelper () {
         //@TODO add tests from https://github.com/fdietz/jwz_threading/blob/master/test/threading_test.rb

     }

     public Gee.Collection <Envoyer.Models.ConversationThread> process_messages (Gee.Collection <Envoyer.Models.Message> messages) {
         var unpruned_root_set = find_root_set (group_messages_by_id (messages));

         var root_set = (Gee.Collection <Envoyer.Util.ThreadingContainer>) new Gee.LinkedList <Envoyer.Util.ThreadingContainer> ();

         foreach (var container in unpruned_root_set) {
             prune_empty_containers (container);

            if(container.children.size != 0 || container.message != null)  {
                root_set.add (container);
            }
         }

         var threads = new Gee.ArrayList <Envoyer.Models.ConversationThread> ();

         foreach (var container in root_set) {
             threads.add (new Envoyer.Models.ConversationThread.from_container (container));
         }

         return threads;
     }

     private Gee.Collection <Envoyer.Util.ThreadingContainer> group_messages_by_id (Gee.Collection <Envoyer.Models.Message> messages) {
         var id_table = new Gee.HashMap <string, Envoyer.Util.ThreadingContainer> ();

         foreach (var current_message in messages) {
             //@TODO also take into account Gmail thread ids if present
             var message_container = find_or_create_container (id_table, current_message.id);
             message_container.message = current_message;
             
             var references_set = new Gee.HashSet <string> ();
             
             foreach (var reference in current_message.references) {
                 references_set.add (reference);
             }
             
             // If both References and In-Reply-To exist, take the first thing in the In-Reply-To header
             // that looks like a Message-ID, and append it to the References header.
             // If there are multiple things in In-Reply-To that look like Message-IDs,
             // only use the first one of them: odds are that the later ones are
             // actually email addresses, not IDs.
             if(current_message.in_reply_to.size >= 1) {
                 var in_reply_to_reference = current_message.in_reply_to[0];
            
                 references_set.add (in_reply_to_reference);
             }

             Envoyer.Util.ThreadingContainer previous_references_container = null;
             foreach (var reference in references_set) {
                 var container = find_or_create_container (id_table, reference);

                 if(previous_references_container != null) {
                    add_container_as_child(previous_references_container, container);
                 }

                 previous_references_container = container;
             }

             if(previous_references_container != null) {
                add_container_as_child(previous_references_container, message_container);
             }
         }

         return id_table.values;
     }

    private void add_container_as_child (Envoyer.Util.ThreadingContainer previous_references_container, Envoyer.Util.ThreadingContainer container) {
         // If they are already linked, don't change the existing links.
         // Do not add a link if adding that link would introduce a loop.
         if (previous_references_container != null &&
             previous_references_container.children.index_of (container) == -1 &&
             container.children.index_of (previous_references_container) == -1) {
             previous_references_container.add_child (container);
         }
    }

     private Envoyer.Util.ThreadingContainer find_or_create_container (Gee.HashMap <string, Envoyer.Util.ThreadingContainer> table, string key) {
         if (table.has_key (key)) {
             return table[key];
         } else {
             var message_container = new Envoyer.Util.ThreadingContainer ();
             table[key] =  message_container;

             return message_container;
         }
     }

     private Gee.Collection <Envoyer.Util.ThreadingContainer> find_root_set (Gee.Collection <Envoyer.Util.ThreadingContainer> containers) {
         var root_set = new Gee.ArrayList <Envoyer.Util.ThreadingContainer> ();

         foreach (var container in containers) {
             if (container.parent == null) {
                 root_set.add (container);
             }
         }

         return root_set;
     }

     private void prune_empty_containers (Envoyer.Util.ThreadingContainer parent) {
         foreach (var container in parent.children) {
             prune_empty_containers(container);

             if (container.message == null && container.children.size == 0) {
                 // If it is a dummy message with no children, delete it.
                 parent.children.remove (container);
             } else if (container.message == null) {
                 // If it is a dummy message with children.

                 // Do not promote the children if doing so would make them
                 // children of the root, unless there is only one child.

                 // Since we're iterating through parent's items, container will
                 // never be a root item. So unlike other JWZ algorithm
                 // implementations, no further checks are needed.
                 foreach (var promoted_child in container.children_copied) {
                     parent.add_child (promoted_child);
                 }
                 parent.children.remove (container);
             }
         }
     }

     private bool is_reply_or_forward_subject (string subject) {
         //@TODO add support for internationalized reply indicators: https://en.wikipedia.org/wiki/List_of_email_subject_abbreviations#Abbreviations_in_other_languages
         return subject.has_prefix ("Re:") || subject.has_prefix ("RE:") ||
                 subject.has_prefix ("Fwd:") || subject.has_prefix ("FWD:");
     }

     private string get_subject_for_root_container (Envoyer.Util.ThreadingContainer root_container) {
         string subject;

         if (root_container.message != null) {
             subject = root_container.message.subject;
         } else {
             // If there is no message in the Container, then the Container will have at least one child Container, and that Container will have a message. Use the subject of that message instead.
             subject = root_container.children[0].message.subject;
         }

         while (is_reply_or_forward_subject (subject)) {
             subject = subject.substring (subject.index_of (":") + 1).chug ();
         }

         return subject;
     }
}
