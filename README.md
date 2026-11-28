Pronoia is a smart pill organizer that helps people take their medication on time. An ESP32-C3 inside the box keeps track of the schedule and sounds a buzzer 
when a dose is due. A reed switch notices when the lid is opened. The box sends each event 
to Firebase, so a companion iOS app built in SwiftUI can show reminders and dose history. A dose only counts as taken after two confirmations: the lid has to 
open around the scheduled time, and the user also confirms in the app.
