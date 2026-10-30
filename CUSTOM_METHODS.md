# Custom Methods in the Support Ticket System

This guide lists the methods defined by the application code and explains their purpose. It covers models, controllers, helpers, and the mailer. Rails methods such as `save`, `update`, `render`, and `redirect_to` are provided by Rails and are not listed here.

## Ticket model — `app/models/ticket.rb`

| Method | What it does / why it is used |
| --- | --- |
| `Ticket.visible_to(user)` | Returns tickets the given role may access: all tickets for admins, assigned tickets for engineers, and requested tickets for requesters. Used by ticket listing and dashboard code. |
| `Ticket.search(term)` | Filters tickets by ticket number or title. It escapes SQL wildcard characters in the search text. |
| `Ticket.filter_by(params, admin:)` | Applies valid status and priority filters. It applies requester, assignee, and unassigned filters only for admins. |
| `Ticket.ordered_by(sort)` | Applies the selected ticket order: newest, oldest, priority, or recently updated. It uses IDs as tie-breakers for consistent ordering. |
| `ticket.visible_to?(user)` | Checks whether one ticket is visible to the given user. Used to protect the ticket detail page. |
| `ticket.commentable_by?(user)` | Alias of `visible_to?`; used by the comments controller to apply the same role and ownership rule before adding a comment. |
| `ticket.change_status(new_status, user:, summary:)` | Validates the requested status transition and the user's authority, requires a resolution summary when resolving, updates status timestamps, and saves the ticket. |
| `ticket.set_ticket` | Validation callback that generates a ticket number when a new ticket has none. |

## User model — `app/models/user.rb`

| Method | What it does / why it is used |
| --- | --- |
| `user.create_reset_digest` | Generates a reset token, stores its BCrypt digest and send time, and keeps the raw token available for the reset email. |
| `user.authenticated_reset_token?(token)` | Checks a submitted token against the stored digest. Returns false for missing tokens or malformed digests. |
| `user.password_reset_expired?` | Checks whether the reset token is older than the two-hour validity period or has no send time. |
| `user.clear_reset_digest` | Clears the stored digest and send time after a successful password reset, and clears the in-memory raw token. |
| `user.normalize_email` | Validation callback that trims whitespace and lowercases the email before validation. |

## Controllers — `app/controllers/`

Controller actions are methods Rails calls in response to routes.

### `ApplicationController`

| Method | What it does / why it is used |
| --- | --- |
| `login_user` | Before-action callback that redirects visitors to the login page unless they are signed in. Controllers can skip it for public actions. |

### `CommentsController`

| Method | What it does / why it is used |
| --- | --- |
| `create` | Checks that the signed-in user can comment on the ticket, creates the comment, then redirects with a success or error message. |
| `comment_params` | Strong-parameters method that permits only the comment body from the request. |

### `PagesController`

| Method | What it does / why it is used |
| --- | --- |
| `home` | Builds the signed-in user's dashboard counts and recent ticket list. For admins, it also counts unassigned tickets. |

### `PasswordResetsController`

| Method | What it does / why it is used |
| --- | --- |
| `new` | Renders the password reset request form. |
| `create` | Looks up the submitted email, sends a reset email for a matching account, and redirects with a success or invalid-email flash message. |
| `edit` | Displays the password form only when the reset token is valid and unexpired; otherwise redirects to the request form. |
| `update` | Rechecks the token, validates and saves the new password, clears the reset digest, resets the session, and redirects. |
| `set_user` | Before-action callback that loads the account named in the reset URL or redirects if it does not exist. |
| `valid_reset_token?` | Combines the digest check and expiry check used by the edit and update actions. |
| `password_reset_params` | Strong-parameters method that permits the email submitted by the reset request form. |
| `user_password_params` | Strong-parameters method that permits only the new password and its confirmation. |

### `SessionsController`

| Method | What it does / why it is used |
| --- | --- |
| `new` | Renders the login form. |
| `create` | Finds the account by normalized email, authenticates the password, signs in the user, and redirects. On failure it redisplays the form with an error. |
| `destroy` | Signs out the current user and redirects to the login page. |

### `TicketsController`

| Method | What it does / why it is used |
| --- | --- |
| `index` | Builds the visible ticket list using the model's search, filter, and ordering methods. It also loads requester and engineer options for admins. |
| `new` | Creates an empty ticket object for the ticket form. |
| `show` | Loads a ticket and its requester/assignee, checks visibility, and renders its detail page. |
| `create` | Creates a ticket for the current requester and writes a creation activity in the same database transaction. |
| `assign` | Validates the selected engineer, changes the assignee, and records a history entry in a transaction. It avoids recording a no-op assignment. |
| `update_status` | Delegates transition rules to the ticket model and writes an activity when the status changes, in a transaction. |
| `update_priority` | Validates and updates priority, then records an activity in a transaction. |
| `ticket_params` | Strong-parameters method that permits only ticket title, description, and priority from the create form. |
| `require_requester` | Before-action callback that restricts ticket creation to requesters. |
| `require_admin` | Before-action callback that restricts assignment and priority changes to admins. |

## Helpers

### `SessionsHelper` — `app/helpers/sessions_helper.rb`

| Method | What it does / why it is used |
| --- | --- |
| `log_in(user)` | Stores the user's ID in the session to sign them in. |
| `current_user` | Finds and memoizes the user associated with the current session. |
| `logged_in?` | Returns whether a valid current user is signed in. |
| `log_out` | Resets the session and clears the memoized current user. |

### `TicketsHelper` — `app/helpers/tickets_helper.rb`

| Method | What it does / why it is used |
| --- | --- |
| `ticket_status_options(ticket, user)` | Supplies the status choices shown on the ticket page based on the user's role, ticket ownership/assignment, and current ticket status. |

## Mailer — `app/mailers/password_reset_mailer.rb`

| Method | What it does / why it is used |
| --- | --- |
| `reset_email(user)` | Prepares and sends the password reset email for the given user. The mailer template uses the user's reset token to build the link. |

## Notes

- The `new` controller actions are intentionally empty because Rails renders the matching form template by convention.
- The status options helper currently receives `ticket` and `user` arguments; its implementation should use those arguments consistently instead of relying on controller instance variables.
- Associations, validations, callbacks, and constants are application configuration, but they are not custom methods, so they are not included as method entries above.
