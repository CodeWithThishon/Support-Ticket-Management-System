# Clear existing data
TicketActivity.destroy_all
TicketComment.destroy_all
Ticket.destroy_all
User.destroy_all

# Create Admin
admin = User.create!(
  name: "Admin",
  email: "admin@gmail.com",
  password: "password",
  role: "admin"
)

# Create Engineers
engineers = [
  User.create!(name: "John", email: "john@gmail.com",
               password: "111111", role: "engineer"),
  User.create!(name: "David", email: "david@gmail.com",
               password: "111111", role: "engineer"),
  User.create!(name: "Michael", email: "michael@gmail.com",
               password: "111111", role: "engineer")
]

# Create Requesters
requesters = [
  User.create!(name: "Alice", email: "alice@gmail.com",
               password: "111111", role: "requester"),
  User.create!(name: "Thishon", email: "thishon@gmail.com",
               password: "111111", role: "requester"),
  User.create!(name: "Charlie", email: "charlie@gmail.com",
               password: "111111", role: "requester")
]

# Create Tickets
statuses = %w[open in_progress resolved closed]
priorities = %w[low medium high critical]

20.times do |i|
  Ticket.create!(
    title: "Sample Issue #{i + 1}",
    description: "This is a sample support ticket.",
    requester: requesters.sample,
    assignee: engineers.sample,
    status: statuses.sample,
    priority: priorities.sample
  )
end