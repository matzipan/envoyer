[CCode (cprefix = "E", lower_case_cprefix = "e_")]
namespace E {
    [CCode (cheader_filename = "libedataserverui/libedataserverui.h", type_id = "e_credentials_prompter_get_type ()")]
    public class CredentialsPrompter : GLib.Object {
        public CredentialsPrompter (E.SourceRegistry registry);
        public bool loop_prompt_sync (E.Source source,
                                E.CredentialsPrompterPromptFlags flags,
                                E.CredentialsPrompterLoopPromptFunc func,
                                void* data,
                                GLib.Cancellable? cancellable = null) throws GLib.Error;
        public E.SourceCredentialsProvider get_provider();
    }
    
    [CCode (has_target=false)]
    public delegate bool CredentialsPrompterLoopPromptFunc (E.CredentialsPrompter prompter,
                                E.Source source,
                                [CCode (type = "const ENamedParameters *")]  E.NamedParameters credentials,
                                bool* out_authenticated,
                                void* data, 
                                GLib.Cancellable? cancellable = null) throws GLib.Error;

    [CCode (cheader_filename = "libedataserverui/libedataserverui.h", cprefix = "E_CREDENTIALS_PROMPTER_PROMPT_FLAG_", has_type_id = false)]
    [Flags]
    public enum CredentialsPrompterPromptFlags {
        NONE,
        ALLOW_SOURCE_SAVE,
        ALLOW_STORED_CREDENTIALS
    }
}