# TaskNest API

A beginner-friendly Ruby on Rails 8 REST API for a SaaS task management app.

This backend is written to be **simple and readable** — straightforward CRUD,
clear variable names, and comments on important logic.

---

## Overview

TaskNest lets users:

- Register and log in with JWT
- Manage a profile (including avatar upload)
- Create workspaces and invite members with roles
- Organize work into projects and tasks
- Comment on tasks and upload attachments
- View dashboard stats and notifications

---

## Tech Stack

| Technology | Purpose |
|---|---|
| Ruby on Rails 8 (API mode) | Application framework |
| PostgreSQL | Database |
| JWT (`jwt` gem) | Authentication tokens |
| bcrypt | Password hashing (`has_secure_password`) |
| Active Storage | File uploads (avatars + attachments) |
| ActiveModel Serializers | JSON response shaping |
| Rack::Cors | CORS for React at `http://localhost:5173` |
| RSpec + FactoryBot + Faker | Testing |

---

## Prerequisites

- Ruby **3.3.11**
- PostgreSQL
- Bundler

---

## How to Run

```bash
# 1. Install gems
bundle install

# 2. Create + migrate + seed the database
bin/rails db:prepare
bin/rails db:seed

# 3. Start the server
bin/rails server
```

API base URL: `http://localhost:3000/api/v1`

### Seed users

| Email | Password | Role in demo workspace |
|---|---|---|
| `alice@tasknest.com` | `password` | owner |
| `carol@tasknest.com` | `password` | admin |
| `bob@tasknest.com` | `password` | member |

### Run tests

```bash
bundle exec rspec
```

---

## Folder Structure

```
app/
├── controllers/api/v1/     # All API endpoints
├── models/                 # Database models
├── serializers/            # JSON serializers
├── services/               # Small helpers (JWT, notifications)
├── policies/               # Reserved for future authorization objects
├── queries/                # Reserved for future query objects
db/
├── migrate/                # Schema migrations
├── seeds.rb                # Sample data
spec/
├── factories/              # FactoryBot factories
├── requests/               # Request (API) specs
├── support/                # Spec helpers
```

---

## Models Explained

### `User`
A person who can sign up and use the API.
- Has a secure password (`password_digest`)
- Can upload an `avatar` (Active Storage)
- Can own workspaces and belong to many workspaces
- Supports forgot/reset password tokens

### `Workspace`
A shared team space.
- Belongs to an `owner` (User)
- Has many `memberships`, `members`, and `projects`
- Automatically adds the owner as a member with role `owner`

### `Membership`
Links a User to a Workspace.
- Roles: `owner`, `admin`, `member`
- Unique per user + workspace

### `Project`
A collection of tasks inside a workspace.
- Can be archived (`archived_at`) and restored

### `Task`
A unit of work inside a project.
- Status: `todo`, `in_progress`, `review`, `done`
- Priority: `low`, `medium`, `high`
- Optional assignee, required creator
- Supports search / filter / sort scopes

### `Comment`
A text note on a task, written by a user.

### `Attachment`
Metadata for a file uploaded to a task.
- Actual file stored with Active Storage (`has_one_attached :file`)

### `Notification`
Simple inbox message for a user (`read` true/false).

### `TokenBlacklist`
Stores JWT `jti` values after logout so those tokens stop working.

---

## Controllers Explained

### `BaseController`
Parent for all v1 controllers.
- JWT auth (`authenticate_user!`)
- `render_success` / `render_error`
- Pagination helper
- Workspace membership checks
- Global rescue for `RecordNotFound` and `RecordInvalid`

### `HealthController`
Public health check — no auth required.

### `AuthController`
Register, login, logout, forgot password, reset password.

### `UsersController`
Show/update current profile and upload avatar.

### `WorkspacesController`
CRUD for workspaces + invite member by email.

### `MembershipsController`
List members, change roles, remove members.

### `ProjectsController`
CRUD + archive / restore.

### `TasksController`
CRUD + search, filter, sort, pagination.
Notifies assignee on assign.

### `CommentsController`
CRUD for task comments (users edit/delete only their own).

### `AttachmentsController`
Upload, list, download, delete task files.

### `DashboardController`
Returns total / completed / pending / overdue task counts.

### `NotificationsController`
List notifications, mark one read, mark all read.

---

## Authentication

Send the JWT in the `Authorization` header:

```
Authorization: Bearer <token>
```

Example login:

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@tasknest.com","password":"password"}'
```

---

## API Endpoints

### Health

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/health` | No | API status |

### Auth

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/api/v1/auth/register` | No | Create account |
| POST | `/api/v1/auth/login` | No | Login, get JWT |
| DELETE | `/api/v1/auth/logout` | Yes | Blacklist current token |
| POST | `/api/v1/auth/forgot_password` | No | Generate reset token (logged in development) |
| POST | `/api/v1/auth/reset_password` | No | Reset password with token |

**Register body:** `{ "name", "email", "password", "password_confirmation" }`  
**Login body:** `{ "email", "password" }`  
**Forgot body:** `{ "email" }`  
**Reset body:** `{ "token", "password", "password_confirmation" }`

### Profile

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/profile` | Yes | Current user profile |
| PATCH | `/api/v1/profile` | Yes | Update name/email/password |
| POST | `/api/v1/profile/avatar` | Yes | Upload avatar (`multipart` field `avatar`) |

### Workspaces

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/workspaces` | Yes | List my workspaces |
| POST | `/api/v1/workspaces` | Yes | Create workspace |
| GET | `/api/v1/workspaces/:id` | Yes | Show workspace |
| PATCH | `/api/v1/workspaces/:id` | Yes | Update (admin/owner) |
| DELETE | `/api/v1/workspaces/:id` | Yes | Delete (owner only) |
| POST | `/api/v1/workspaces/:id/invite` | Yes | Invite by email (admin/owner) |

**Invite body:** `{ "email", "role" }` — role is `admin` or `member`

### Memberships

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/workspaces/:workspace_id/memberships` | Yes | List members |
| PATCH | `/api/v1/workspaces/:workspace_id/memberships/:id` | Yes | Change role |
| DELETE | `/api/v1/workspaces/:workspace_id/memberships/:id` | Yes | Remove member |

### Projects

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/workspaces/:workspace_id/projects` | Yes | List projects (`?archived=true`) |
| POST | `/api/v1/workspaces/:workspace_id/projects` | Yes | Create project |
| GET | `/api/v1/projects/:id` | Yes | Show project |
| PATCH | `/api/v1/projects/:id` | Yes | Update project |
| DELETE | `/api/v1/projects/:id` | Yes | Delete project |
| POST | `/api/v1/projects/:id/archive` | Yes | Archive project |
| POST | `/api/v1/projects/:id/restore` | Yes | Restore project |

### Tasks

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/projects/:project_id/tasks` | Yes | List tasks (search/filter/sort/paginate) |
| POST | `/api/v1/projects/:project_id/tasks` | Yes | Create task |
| GET | `/api/v1/tasks/:id` | Yes | Show task |
| PATCH | `/api/v1/tasks/:id` | Yes | Update task |
| DELETE | `/api/v1/tasks/:id` | Yes | Delete task |

**Task query params**

| Param | Example | Description |
|---|---|---|
| `q` | `wireframe` | Search title/description |
| `status` | `todo` | Filter by status |
| `priority` | `high` | Filter by priority |
| `assignee_id` | `2` | Filter by assignee |
| `sort` | `due_date` | Sort column |
| `direction` | `asc` | `asc` or `desc` |
| `page` | `1` | Page number |
| `per_page` | `10` | Items per page (max 50) |

**Task status values:** `todo`, `in_progress`, `review`, `done`  
**Task priority values:** `low`, `medium`, `high`

### Comments

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/tasks/:task_id/comments` | Yes | List comments |
| POST | `/api/v1/tasks/:task_id/comments` | Yes | Create comment |
| GET | `/api/v1/comments/:id` | Yes | Show comment |
| PATCH | `/api/v1/comments/:id` | Yes | Update own comment |
| DELETE | `/api/v1/comments/:id` | Yes | Delete own comment |

### Attachments

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/tasks/:task_id/attachments` | Yes | List files |
| POST | `/api/v1/tasks/:task_id/attachments` | Yes | Upload file (`multipart` field `file`) |
| GET | `/api/v1/attachments/:id/download` | Yes | Download file |
| DELETE | `/api/v1/attachments/:id` | Yes | Delete file |

### Dashboard

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/dashboard` | Yes | Task stats (`?workspace_id=` optional) |

Returns:

```json
{
  "success": true,
  "message": "Dashboard stats retrieved",
  "data": {
    "total_tasks": 10,
    "completed": 4,
    "pending": 6,
    "overdue": 2
  }
}
```

### Notifications

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/notifications` | Yes | List notifications (`?unread=true`) |
| PATCH | `/api/v1/notifications/:id` | Yes | Mark one as read |
| POST | `/api/v1/notifications/mark_all_read` | Yes | Mark all as read |

---

## JSON Response Format

Success:

```json
{
  "success": true,
  "message": "Tasks retrieved",
  "data": [],
  "meta": {
    "page": 1,
    "per_page": 10,
    "total_count": 25,
    "total_pages": 3
  }
}
```

Error:

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": ["Title can't be blank"]
}
```

---

## Services

### `JwtService`
Encodes/decodes JWTs. Each token includes `user_id`, `exp`, and `jti`.

### `NotificationService`
Tiny helper to create a notification row for a user.

---

## CORS

Configured in `config/initializers/cors.rb` for:

```
http://localhost:5173
```

---

## Learning Notes

- Prefer **simple controllers** over heavy abstractions.
- Authorization is checked in controllers with membership helpers (not Pundit).
- Password reset emails are **not sent** — the token is written to the Rails log in development.
- `app/policies` and `app/queries` are empty placeholders for later learning.
