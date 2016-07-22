public class Envoyer.Models.Address : GLib.Object {
    public string name { get; private set; }
    public string email { get; private set; }
    
    public Address (string name, string email) {
        this.name = name;
        this.email = email;
    }
    
    public string to_string () {
        if (name == "") {
            return email;
        } else {
            return "%s <%s>".printf(name, email);
        }
    }
    
    public string to_escaped_string () {
        return GLib.Markup.escape_text(to_string ());
    }
}
