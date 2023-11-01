# Application states

The following plantuml diagram shows the different application states and the
different application messages that can be delivered and which state
transitions they can lead to.

As can be seen, application states are not very well defined: once the
application reaches the "Running" state, the state remains largely the same.
But the diagram clarifies well the different startup flows.

```plantuml
@startuml
state "Google Authentication" as google_authentication
state "Welcome Dialog" as welcome_dialog
state "Running" as running
state "Identity saved" as identity_saved
state "Fetching conversation content" as fetching_conversation_contect

[*] --> running : LoadIdentities(initialize: false)
[*] --> identity_saved : SaveIdentity(TestServerAccount)
[*] --> welcome_dialog : Setup
welcome_dialog --> google_authentication : OpenGoogleAuthentication
google_authentication -> identity_saved : SaveIdentity(GmailAccount)
identity_saved -> running : LoadIdentities(initialize: true)
running -> running : ShowFolder(folder)
running -> running : ShowConversation(conversation)
running -> running : NewMessages(...)
running -> running : ShowConversationContainingEmail(...)
running -> fetching_conversation_contect : ShowConversation(...)
fetching_conversation_contect -> running : ConversationContentLoadFinished(conversation)
running --> [*]
@enduml
```