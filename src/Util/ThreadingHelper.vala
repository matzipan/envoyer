/*
 * Copyright 2017 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
 public class Envoyer.Util.ThreadingContainer {
     public Envoyer.Models.Message message = null;
     public Envoyer.Util.ThreadingContainer parent = null;
     public Gee.LinkedList <Envoyer.Util.ThreadingContainer> children = new Gee.LinkedList <Envoyer.Util.ThreadingContainer> ();
     
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
         var root_set = find_root_set (group_messages_by_id (messages));
         
         foreach (var container in root_set) {
             prune_empty_containers (container);
         }
         
         root_set = refine_root_set_by_subject (root_set);
         
         var threads = new Gee.ArrayList <Envoyer.Models.ConversationThread> (); 
         
         foreach (var container in root_set) {
             threads.add (new Envoyer.Models.ConversationThread.from_container (container));
         }
         
         return threads;
     }
     
     private Gee.Collection <Envoyer.Util.ThreadingContainer> group_messages_by_id (Gee.Collection <Envoyer.Models.Message> messages) {
         // @TODO Import sent messages

         // @TODO If both headers exist, take the first thing in the In-Reply-To header 
         // that looks like a Message-ID, and append it to the References header.
         // If there are multiple things in In-Reply-To that look like Message-IDs, 
         // only use the first one of them: odds are that the later ones are 
         // actually email addresses, not IDs.
         
         var id_table = new Gee.HashMap <string, Envoyer.Util.ThreadingContainer> ();

         foreach (var current_message in messages) {
             //@TODO also take into account Gmail thread ids if present
             var message_container = find_or_create_container (id_table, current_message.id);      
             message_container.message = current_message;
             
             Envoyer.Util.ThreadingContainer previous_references_container = null;
             foreach (var reference in current_message.references) {
                 var container = find_or_create_container (id_table, reference);      
                 
                 // If they are already linked, don't change the existing links.
                 // Do not add a link if adding that link would introduce a loop.
                 if (previous_references_container != null &&
                     previous_references_container.children.index_of (container) == -1 && 
                     container.children.index_of (previous_references_container) == -1) {
                     previous_references_container.add_child (container);
                 }
                 
                 previous_references_container = container;
             }
             
             if (previous_references_container != null) {
                 previous_references_container.add_child (message_container);
             }
         }
         
         return id_table.values; 
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
             } else if (container.message == null && container.children.size != 0) {
                 // If it is a dummy message with children, delete it. 
                 
                 // Do not promote the children if doing so would make them 
                 // children of the root, unless there is only one child.
                 if (parent.parent != null || (parent.parent == null && container.children.size == 1)) {                     
                     foreach (var promoted_child in container.children) {
                         parent.add_child (promoted_child);
                     }
                     parent.children.remove (container);
                 }
             }
         }
     }
     
     private Gee.Collection <Envoyer.Util.ThreadingContainer> refine_root_set_by_subject (Gee.Collection <Envoyer.Util.ThreadingContainer> root_set) {
         var subject_table = new Gee.HashMap <string, Envoyer.Util.ThreadingContainer> ();

         foreach (var container in root_set) {
             var subject = get_subject_for_root_container (container);
             
             if (subject == "") {
                 continue;
             }
             
             if (!subject_table.has_key (subject)) {
                 subject_table[subject] = container;
             } else {
                 var old_message = subject_table[subject].message;
                 if (old_message != null) {
                     if (old_message.subject == subject && container.message == null) {
                         subject_table[subject] = container;
                     }
                     
                     if (old_message.subject.has_suffix (subject) && 
                         is_reply_or_forward_subject (old_message.subject)) {
                         subject_table[subject] = container;
                     }
                 }
             }
         }
         
         foreach (var container in root_set) {
             var subject = get_subject_for_root_container (container);
             
             if (!subject_table.has_key (subject) || subject_table[subject] == container) {
                 continue;
             }
             
             var subject_container = subject_table[subject];
             
             if (container.message == null && subject_container.message == null) {
                 // If both messages are dummies, append the current message's children to the children of the message in the subject table (the children of both messages  become siblings), and then delete the current message
                 foreach (var moved_child in container.children) {
                     subject_container.add_child (moved_child);
                 }
                 container.children.remove_all (container.children);
             } else if (subject_container.message == null && container.message != null) {
                 // If one container is a empty and the other is not, make the non-empty one be a child of the empty, and a sibling of the other ``real'' messages with the same subject (the empty's children.)
                 subject_container.add_child (container);
             } else if (subject_container.message != null &&
                         !is_reply_or_forward_subject (subject_container.message.subject) &&
                         is_reply_or_forward_subject (container.message.subject)) {
                 // If that container is a non-empty, and that message's subject does not begin with ``Re:'', but this message's subject does, then make this be a child of the other.
                 subject_container.add_child (container);
             } else {
                 // Otherwise, make a new empty container and make both msgs be a child of it. This catches the both-are-replies and neither-are-replies cases, and makes them be siblings instead of asserting a hierarchical relationship which might not be true.
                 var new_container = new Envoyer.Util.ThreadingContainer ();                
                 new_container.add_child(container);
                 new_container.add_child(subject_container);
                 subject_table[subject] = new_container;
             }    
         }
         
         return subject_table.values;
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