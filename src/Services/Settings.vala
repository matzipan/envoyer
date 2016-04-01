public class Mail.Services.Settings : Granite.Services.Settings {
    public int window_width { get; set; }
    public int window_height { get; set; }

    public Settings () {
        base ("org.pantheon.mail");
    }
}
