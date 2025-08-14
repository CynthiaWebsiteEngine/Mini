import cynthia_websites_mini_client/configtype
import rsvp

/// Msg is the parent type for all the possible messages
/// that can be sent in the client
pub type Msg {
  ApiReturnedData(Result(configtype.CompleteData, rsvp.Error))
  UserNavigateTo(String)
  UserSearchTerm(String)
  UserOnGitHubLayoutToggleMenu
  UserOnDocumentationLayoutToggleSidebar
  CindyToggleMenu1
  TickUp
}
