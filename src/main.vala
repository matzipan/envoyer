

int main(string[] args) {
    try {
        var source = new E.Source.with_uid("bla", null);
        var client = E.BookClient.connect(source, 5, null);
    } catch(GLib.Error e) {
        
    }
    
    
    return 0;
}

