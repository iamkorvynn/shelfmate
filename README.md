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

## Architecture & Technology Stack

- **Framework**: Flutter 3.x (Dart SDK)
- **Design System**: Material Design 3 with dynamic color schemes and accessibility support
- **State Management**: `ChangeNotifier` and `Provider` pattern for predictable, reactive UI updates
- **Local Persistence**: SQLite via `sqflite` (desktop / mobile FFI compatible)
- **Local Notifications**: `flutter_local_notifications` with desugaring enabled
- **Privacy First**: Zero accounts, zero analytics, zero cloud sync. 100% on-device SQLite storage. Starts empty with no demo data.

### Database Schema

ShelfMate stores all data locally in a SQLite database with four tables:
1. `items`: Stores lent items (`id`, `name`, `category`, `notes`, `created_at`).
2. `borrowers`: Stores friends (`id`, `name`, `phone`, `created_at`).
3. `loans`: Tracks loan instances (`id`, `item_id`, `borrower_id`, `lent_date`, `expected_return_date`, `return_date`, `status`, `notes`, `created_at`).
4. `app_settings`: Stores user preferences (`id`, `default_loan_period_days`, `reminder_time_hour`, `reminder_time_minute`, `use_24_hour_format`).

## Screens & Navigation

The app features a bottom navigation bar with 5 primary destinations:
1. **Dashboard**:
   - Metric cards: Out now, Due soon, Overdue, Total lent ever.
   - **Next Due Card**: Urgent highlight of the next item expected back, with borrower details and days remaining / overdue status.
   - Quick lend Floating Action Button.
2. **Items**:
   - Dual tabs: **Out** (currently active loans) and **Returned** (completed history).
   - Category filter chips (All, Books, Notes, Chargers, Lab gear, Other).
   - Quick "Mark Returned" action sheet directly from loan cards.
3. **Borrowers**:
   - Friends list with active loan count badges.
   - Borrower detail screen with contact info, currently borrowed items, and borrowing history.
   - Floating Action Button to add new friends.
4. **Stats**:
   - Key statistics: Most-borrowed item, most frequent borrower, longest loan, on-time return rate.
   - Interactive visual breakdown of loans per category.
5. **Settings**:
   - Default loan period in days.
   - Daily reminder time picker.
   - 12h / 24h clock format selector.
   - Export all loans to standard RFC-4180 CSV.
   - Full JSON backup and restore with schema validation.
   - Clear all data with confirmation protection.
