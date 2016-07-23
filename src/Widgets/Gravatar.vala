
public class Envoyer.Widgets.Gravatar : Granite.Widgets.Avatar {
    public const int MIN_SIZE = 1;
    public const int MAX_SIZE = 512;
        
    public enum FallbackImage {
        NOT_FOUND,
        MYSTERY_MAN,
        IDENTICON,
        MONSTER_ID,
        WAVATAR,
        RETRO;
        
        public string to_param () {
            switch (this) {
                case NOT_FOUND:
                    return "404";
                
                case MYSTERY_MAN:
                    return "mm";
                
                case IDENTICON:
                    return "identicon";
                
                case MONSTER_ID:
                    return "monsterid";
                
                case WAVATAR:
                    return "wavatar";
                
                case RETRO:
                    return "retro";
                
                default:
                    assert_not_reached();
            }
        }
    }
    
    private string email_address;
    private int size;
    
    public Gravatar () {
        size = 80;
        base.with_default_icon (size);
    }

    public Gravatar.with_default_icon (int size) {
        base.with_default_icon (size);
        this.size = size;
    }
    
    public void set_address(Envoyer.Models.Address address) {
        email_address = address.email;
    }

    public async void fetch_async (FallbackImage fallback = FallbackImage.NOT_FOUND) throws IOError {
        var uri = get_image_uri (fallback);
        var icon = new FileIcon (File.new_for_uri (uri));
        var icon_info = Gtk.IconTheme.get_default ().lookup_by_gicon_for_scale (icon, size, scale_factor, 0);
        
        pixbuf = yield icon_info.load_icon_async ();
    }
    
    private string get_image_uri(FallbackImage fallback = FallbackImage.NOT_FOUND) {
        string md5 = Checksum.compute_for_string(ChecksumType.MD5, email_address.strip ().down ());
        
        return "https://secure.gravatar.com/avatar/%s?d=%s&s=%d".printf(md5, fallback.to_param (), size);
    }
    


}
