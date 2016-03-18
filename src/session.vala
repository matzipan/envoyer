public class Session : Camel.Session {
    public Session(string user_data_dir, string user_cache_dir) {
        Object(user_data_dir: user_data_dir, user_cache_dir: user_cache_dir);
    }

}