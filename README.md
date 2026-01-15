<h1 align="center">
  Swift Server
</h1>

<p align="center">
  Swift Web Server using Vapor
</p>

---

## Setup

### Environment Variables

Set the `DATABASE_URL` environment variable to your PostgreSQL database connection string.

Example:
```bash
export DATABASE_URL="postgresql://username:password@localhost:5432/database_name"
```

### Database Migration

The application will automatically run database migrations on startup. The migrations create the necessary tables for the waitlist functionality.

## Available Scripts

**Run Server**

```bash
swift run
```

This will start the server and run any pending database migrations.

**Build for Production**

```bash
swift build
```

---
