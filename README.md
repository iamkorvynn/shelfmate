# ShelfMate

**ShelfMate** is a clean, reliable personal lending tracker built with Flutter and Material 3.
It answers one question: *"What did I lend, to whom, and when is it coming back?"*

## What It Does

- **Items**: Add anything you lend — books, notes, chargers, lab gear, or other items. Simple photo-free entry with category, optional notes, and creation date.
- **Lend It Out**: Pick a borrower (a friend), the date lent, and an expected return date. Status immediately becomes **Out**.
- **Return It**: Mark returned with the return date and optional return notes. Status becomes **Returned** and moves to loan history.
- **Overdue Detection**: Any Out item past its expected return date automatically highlights as **Overdue**.
- **Borrowers (Friends List)**: Keep track of friends with name and optional phone number. View active loans and all-time borrowing history per borrower.
- **Return Reminders**: Local notification reminders for items due tomorrow, due today, and overdue. Configurable reminder time in Settings.
- **Dashboard**: High-level glance at items out now, due soon, overdue, total lent ever, and the next item due back.
- **History**: Full archive of returned items with lent date, return date, and total duration out.
- **Stats**: Rich insights including most-borrowed item, most frequent borrower, longest loan, on-time return rate, and loans per category.
- **Settings**: Default loan period in days, reminder time picker, 12h/24h clock toggle, CSV data export, JSON backup & restore, and complete data wipe.
