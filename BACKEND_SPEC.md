# Track It — Full Backend Specification (.NET)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | ASP.NET Core 8 Web API |
| ORM | Entity Framework Core 8 |
| Database | SQL Server (or PostgreSQL) |
| Auth | ASP.NET Core Identity + JWT Bearer |
| File Storage | Azure Blob Storage (or AWS S3 / local disk) |
| Validation | FluentValidation |
| Mapping | AutoMapper |
| Docs | Swagger / Scalar |
| Logging | Serilog |
| DI | Built-in |

---

## Project Structure

```
TrackIt.sln
│
├── TrackIt.API/                    ← Web API layer (Controllers, Middleware, Startup)
│   ├── Controllers/
│   │   ├── AuthController.cs
│   │   ├── UsersController.cs
│   │   ├── ProjectsController.cs
│   │   ├── LogsController.cs
│   │   └── AttachmentsController.cs
│   ├── Middleware/
│   │   ├── ExceptionMiddleware.cs
│   │   └── RoleGuardAttribute.cs
│   ├── Program.cs
│   └── appsettings.json
│
├── TrackIt.Application/            ← Business logic (Services, DTOs, Interfaces)
│   ├── Services/
│   │   ├── AuthService.cs
│   │   ├── UserService.cs
│   │   ├── ProjectService.cs
│   │   ├── LogService.cs
│   │   └── AttachmentService.cs
│   ├── DTOs/
│   │   ├── Auth/
│   │   ├── Users/
│   │   ├── Projects/
│   │   ├── Logs/
│   │   └── Attachments/
│   ├── Interfaces/
│   │   └── IRepository<T>.cs
│   └── Validators/
│
├── TrackIt.Domain/                 ← Pure entities (no EF, no dependencies)
│   ├── Entities/
│   │   ├── User.cs
│   │   ├── Project.cs
│   │   ├── ProjectMember.cs
│   │   ├── DailyLog.cs
│   │   ├── DailyLogEntry.cs
│   │   └── Attachment.cs
│   └── Enums/
│       ├── UserRole.cs
│       └── AttachmentType.cs
│
└── TrackIt.Infrastructure/         ← EF Core, Repos, Storage
    ├── Data/
    │   ├── TrackItDbContext.cs
    │   └── Migrations/
    ├── Repositories/
    │   ├── UserRepository.cs
    │   ├── ProjectRepository.cs
    │   ├── LogRepository.cs
    │   └── AttachmentRepository.cs
    └── Storage/
        └── BlobStorageService.cs
```

---

## Database Schema

### Table: `Users`

| Column | Type | Notes |
|--------|------|-------|
| `Id` | `UNIQUEIDENTIFIER` PK | GUID |
| `Name` | `NVARCHAR(100)` NOT NULL | Full name |
| `Email` | `NVARCHAR(200)` NOT NULL UNIQUE | Login email |
| `PasswordHash` | `NVARCHAR(MAX)` NOT NULL | BCrypt hash |
| `Role` | `NVARCHAR(20)` NOT NULL | `'Admin'` or `'Employee'` |
| `IsActive` | `BIT` DEFAULT 1 | Soft-disable user |
| `CreatedAt` | `DATETIME2` DEFAULT NOW | |
| `UpdatedAt` | `DATETIME2` | |

---

### Table: `Projects`

| Column | Type | Notes |
|--------|------|-------|
| `Id` | `UNIQUEIDENTIFIER` PK | |
| `Name` | `NVARCHAR(100)` NOT NULL | |
| `Description` | `NVARCHAR(500)` | |
| `IsArchived` | `BIT` DEFAULT 0 | |
| `CreatedByUserId` | `UNIQUEIDENTIFIER` FK → Users | Admin who created it |
| `CreatedAt` | `DATETIME2` DEFAULT NOW | |
| `UpdatedAt` | `DATETIME2` | |

---

### Table: `ProjectMembers`

| Column | Type | Notes |
|--------|------|-------|
| `Id` | `UNIQUEIDENTIFIER` PK | |
| `ProjectId` | `UNIQUEIDENTIFIER` FK → Projects | |
| `UserId` | `UNIQUEIDENTIFIER` FK → Users | |
| `AssignedAt` | `DATETIME2` DEFAULT NOW | |

> **Composite unique constraint**: `(ProjectId, UserId)` — no duplicate members.

---

### Table: `DailyLogs`

| Column | Type | Notes |
|--------|------|-------|
| `Id` | `UNIQUEIDENTIFIER` PK | |
| `UserId` | `UNIQUEIDENTIFIER` FK → Users | |
| `LogDate` | `DATE` NOT NULL | Date only, no time |
| `CreatedAt` | `DATETIME2` DEFAULT NOW | |
| `UpdatedAt` | `DATETIME2` | |

> **Composite unique constraint**: `(UserId, LogDate)` — one log per user per day.

---

### Table: `DailyLogEntries`

| Column | Type | Notes |
|--------|------|-------|
| `Id` | `UNIQUEIDENTIFIER` PK | |
| `DailyLogId` | `UNIQUEIDENTIFIER` FK → DailyLogs | |
| `ProjectId` | `UNIQUEIDENTIFIER` FK → Projects | |
| `Description` | `NVARCHAR(MAX)` NOT NULL | What they worked on |
| `CreatedAt` | `DATETIME2` DEFAULT NOW | |
| `UpdatedAt` | `DATETIME2` | |

---

### Table: `Attachments`

| Column | Type | Notes |
|--------|------|-------|
| `Id` | `UNIQUEIDENTIFIER` PK | |
| `DailyLogEntryId` | `UNIQUEIDENTIFIER` FK → DailyLogEntries | |
| `FileName` | `NVARCHAR(255)` NOT NULL | Original file name |
| `FileType` | `NVARCHAR(20)` NOT NULL | `image/pdf/zip/apk/video/other` |
| `FileSizeBytes` | `BIGINT` | |
| `StorageUrl` | `NVARCHAR(MAX)` NOT NULL | Blob/S3 URL |
| `UploadedAt` | `DATETIME2` DEFAULT NOW | |

---

## EF Core Entity Code (Domain Layer)

```csharp
// User.cs
public class User
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public string Email { get; set; } = default!;
    public string PasswordHash { get; set; } = default!;
    public UserRole Role { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public ICollection<ProjectMember> ProjectMemberships { get; set; } = [];
    public ICollection<DailyLog> DailyLogs { get; set; } = [];
}

// Project.cs
public class Project
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public string? Description { get; set; }
    public bool IsArchived { get; set; }
    public Guid CreatedByUserId { get; set; }
    public User CreatedBy { get; set; } = default!;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public ICollection<ProjectMember> Members { get; set; } = [];
    public ICollection<DailyLogEntry> LogEntries { get; set; } = [];
}

// ProjectMember.cs
public class ProjectMember
{
    public Guid Id { get; set; }
    public Guid ProjectId { get; set; }
    public Project Project { get; set; } = default!;
    public Guid UserId { get; set; }
    public User User { get; set; } = default!;
    public DateTime AssignedAt { get; set; }
}

// DailyLog.cs
public class DailyLog
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public User User { get; set; } = default!;
    public DateOnly LogDate { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public ICollection<DailyLogEntry> Entries { get; set; } = [];
}

// DailyLogEntry.cs
public class DailyLogEntry
{
    public Guid Id { get; set; }
    public Guid DailyLogId { get; set; }
    public DailyLog DailyLog { get; set; } = default!;
    public Guid ProjectId { get; set; }
    public Project Project { get; set; } = default!;
    public string Description { get; set; } = default!;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public ICollection<Attachment> Attachments { get; set; } = [];
}

// Attachment.cs
public class Attachment
{
    public Guid Id { get; set; }
    public Guid DailyLogEntryId { get; set; }
    public DailyLogEntry DailyLogEntry { get; set; } = default!;
    public string FileName { get; set; } = default!;
    public string FileType { get; set; } = default!;
    public long FileSizeBytes { get; set; }
    public string StorageUrl { get; set; } = default!;
    public DateTime UploadedAt { get; set; }
}

// Enums
public enum UserRole { Admin, Employee }
```

---

## API Endpoints

**Base URL**: `https://api.trackit.app/api/v1`

**Auth Header**: `Authorization: Bearer <jwt_token>`

---

### AUTH

```
POST   /auth/login
POST   /auth/refresh
POST   /auth/logout
```

#### `POST /auth/login`
**Request**
```json
{
  "email": "rahul@trackit.app",
  "password": "MyPassword123"
}
```
**Response 200**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1...",
  "refreshToken": "dGhpcyBpcyBhIHJlZnJl...",
  "expiresIn": 3600,
  "user": {
    "id": "guid",
    "name": "Rahul Sharma",
    "email": "rahul@trackit.app",
    "role": "Employee"
  }
}
```
**Response 401** — Invalid credentials

---

#### `POST /auth/refresh`
**Request**
```json
{ "refreshToken": "dGhpcyBpcyBhIHJlZnJl..." }
```
**Response 200** — Returns new `accessToken` + `refreshToken`

---

#### `POST /auth/logout`
**Auth Required**
Invalidates the refresh token on the server.
**Response 204**

---

### USERS `[Admin Only for management, Employee for self]`

```
GET    /users                    ← Admin: list all users
POST   /users                    ← Admin: create user (onboarding)
GET    /users/me                 ← Any: get own profile
PUT    /users/me                 ← Any: update own name/password
GET    /users/{id}               ← Admin: get any user
PUT    /users/{id}               ← Admin: update user role/active status
DELETE /users/{id}               ← Admin: soft-delete (set IsActive = false)
GET    /users/{id}/today-status  ← Admin: has this user logged today?
GET    /users/{id}/logs          ← Admin: get all logs for a user
```

#### `GET /users` — Admin Only
```json
{
  "users": [
    {
      "id": "guid",
      "name": "Rahul Sharma",
      "email": "rahul@trackit.app",
      "role": "Employee",
      "isActive": true,
      "createdAt": "2026-01-10T00:00:00Z",
      "hasLoggedToday": true
    }
  ],
  "total": 4
}
```

---

#### `POST /users` — Admin Only
**Request**
```json
{
  "name": "Karan Mehta",
  "email": "karan@trackit.app",
  "password": "TempPass@123",
  "role": "Employee"
}
```
**Response 201**
```json
{
  "id": "guid",
  "name": "Karan Mehta",
  "email": "karan@trackit.app",
  "role": "Employee"
}
```

---

#### `GET /users/me`
```json
{
  "id": "guid",
  "name": "Rahul Sharma",
  "email": "rahul@trackit.app",
  "role": "Employee",
  "createdAt": "2026-01-10T00:00:00Z"
}
```

---

#### `PUT /users/me`
**Request**
```json
{
  "name": "Rahul S.",
  "currentPassword": "OldPass",
  "newPassword": "NewPass123"
}
```

---

#### `GET /users/{id}/today-status` — Admin Only
```json
{
  "userId": "guid",
  "userName": "Rahul Sharma",
  "hasLoggedToday": true,
  "logId": "guid-or-null"
}
```

---

### PROJECTS

```
GET    /projects                         ← Admin: all | Employee: assigned only
POST   /projects                         ← Admin only
GET    /projects/{id}                    ← Both roles
PUT    /projects/{id}                    ← Admin only
DELETE /projects/{id}                    ← Admin only (soft-delete / archive)
PATCH  /projects/{id}/archive            ← Admin: toggle archive
GET    /projects/{id}/members            ← Both roles
POST   /projects/{id}/members            ← Admin: assign employee
DELETE /projects/{id}/members/{userId}   ← Admin: remove employee
GET    /projects/{id}/timeline           ← Both roles: git-log style history
```

#### `GET /projects`
**Query params**: `?archived=false` (default), `?archived=true`, `?archived=all`

**Response 200**
```json
{
  "projects": [
    {
      "id": "guid",
      "name": "Credvisor",
      "description": "Credit management platform",
      "isArchived": false,
      "memberCount": 4,
      "createdByName": "Shashvat",
      "createdAt": "2026-01-10T00:00:00Z"
    }
  ],
  "total": 3
}
```

---

#### `POST /projects` — Admin Only
**Request**
```json
{
  "name": "Pharma ERP",
  "description": "ERP for pharma companies"
}
```
**Response 201**
```json
{
  "id": "guid",
  "name": "Pharma ERP",
  "description": "ERP for pharma companies",
  "isArchived": false,
  "createdAt": "2026-07-20T00:00:00Z"
}
```

---

#### `GET /projects/{id}`
```json
{
  "id": "guid",
  "name": "Credvisor",
  "description": "...",
  "isArchived": false,
  "members": [
    {
      "userId": "guid",
      "name": "Rahul Sharma",
      "email": "rahul@trackit.app",
      "assignedAt": "2026-01-12T00:00:00Z"
    }
  ],
  "createdAt": "2026-01-10T00:00:00Z"
}
```

---

#### `PUT /projects/{id}` — Admin Only
**Request**
```json
{
  "name": "Credvisor V2",
  "description": "Updated description"
}
```

---

#### `PATCH /projects/{id}/archive` — Admin Only
**Request**
```json
{ "isArchived": true }
```
**Response 200** — Returns updated project

---

#### `POST /projects/{id}/members` — Admin Only
**Request**
```json
{ "userId": "guid" }
```
**Response 201** — Member added. Employee will instantly see project on their home screen.
**Response 409** — Already a member

---

#### `DELETE /projects/{id}/members/{userId}` — Admin Only
**Response 204** — Employee removed. Project disappears from their home screen.

---

#### `GET /projects/{id}/timeline`
**Query params**: `?page=1&pageSize=20`

```json
{
  "entries": [
    {
      "date": "2026-07-20",
      "userId": "guid",
      "userName": "Rahul Sharma",
      "description": "Fixed Login API timeout issue",
      "attachmentCount": 0,
      "logEntryId": "guid"
    },
    {
      "date": "2026-07-20",
      "userId": "guid",
      "userName": "Aman Verma",
      "description": "Testing module — 23 test cases",
      "attachmentCount": 2,
      "logEntryId": "guid"
    }
  ],
  "page": 1,
  "pageSize": 20,
  "total": 47
}
```

---

### DAILY LOGS

```
GET    /logs                         ← Admin: all logs | Employee: own logs
GET    /logs/today                   ← Any: get own today's log (or 404 if not created)
GET    /logs/{date}                  ← Any: get own log for date (yyyy-MM-dd)
POST   /logs                         ← Any: create today's log
PUT    /logs/{id}                    ← Any: update TODAY's log only (400 if past/future)
GET    /logs/user/{userId}           ← Admin: get all logs for an employee
GET    /logs/user/{userId}/{date}    ← Admin: get specific date log for employee
```

> **Core Rule enforced server-side**:
> - `POST /logs` — `LogDate` must be today, else `400 Bad Request`
> - `PUT /logs/{id}` — Log's date must be today, else `403 Forbidden`
> - Cannot create a log for a date in the past or future

---

#### `GET /logs/today`
**Response 200 — If logged**
```json
{
  "id": "guid",
  "userId": "guid",
  "logDate": "2026-07-20",
  "createdAt": "2026-07-20T09:30:00Z",
  "updatedAt": "2026-07-20T11:00:00Z",
  "entries": [
    {
      "id": "guid",
      "projectId": "guid",
      "projectName": "Credvisor",
      "description": "Fixed the OTP timeout issue.",
      "attachments": [
        {
          "id": "guid",
          "fileName": "screenshot.png",
          "fileType": "image",
          "storageUrl": "https://storage.../...",
          "uploadedAt": "2026-07-20T09:45:00Z"
        }
      ]
    }
  ]
}
```
**Response 404** — No log for today yet

---

#### `GET /logs/{date}` (format: `yyyy-MM-dd`)
Same response shape as `/logs/today` but for any past date.
**Response 404** — No log for that date
**Response 400** — Future date requested

---

#### `POST /logs` — Create today's log
**Request**
```json
{
  "entries": [
    {
      "projectId": "guid",
      "description": "Fixed the OTP timeout issue in login flow."
    },
    {
      "projectId": "guid",
      "description": "Reviewed API contracts with backend team."
    }
  ]
}
```
**Response 201** — Full log object (same as GET)
**Response 400** — If today already has a log (use PUT to update)
**Response 400** — If any projectId is not assigned to this employee
**Response 400** — If date is not today

---

#### `PUT /logs/{id}` — Update today's log only
**Request**
```json
{
  "entries": [
    {
      "id": "guid",
      "projectId": "guid",
      "description": "Updated description here."
    },
    {
      "projectId": "guid",
      "description": "Also worked on testing module."
    }
  ],
  "deletedEntryIds": ["guid-of-entry-to-remove"]
}
```
**Response 200** — Updated log
**Response 403** — Log date is not today
**Response 404** — Log not found

---

#### `GET /logs/user/{userId}` — Admin Only
**Query params**: `?from=2026-07-01&to=2026-07-20&page=1&pageSize=20`

```json
{
  "logs": [
    {
      "id": "guid",
      "logDate": "2026-07-20",
      "entryCount": 2,
      "updatedAt": "2026-07-20T11:00:00Z"
    }
  ],
  "total": 14,
  "page": 1,
  "pageSize": 20
}
```

---

#### `GET /logs/user/{userId}/{date}` — Admin Only
Full log detail for any employee on any date (same shape as `GET /logs/today`).

---

### ATTACHMENTS

```
POST   /attachments                      ← Upload file for a log entry
DELETE /attachments/{id}                 ← Delete own attachment (today only)
GET    /attachments/{id}/download        ← Download/view file (signed URL or stream)
```

#### `POST /attachments` — Multipart Form Upload
**Form Fields**
```
logEntryId: guid
file: [binary]
```
**Response 201**
```json
{
  "id": "guid",
  "fileName": "screenshot.png",
  "fileType": "image",
  "fileSizeBytes": 204800,
  "storageUrl": "https://blob.storage.../trackit/guid/screenshot.png",
  "uploadedAt": "2026-07-20T09:45:00Z"
}
```
**Response 400** — Log entry is not from today (cannot add attachments to past logs)
**Response 413** — File too large (max 50MB)
**Response 415** — Unsupported file type

---

#### `DELETE /attachments/{id}`
**Response 204** — Deleted from DB and storage
**Response 403** — Not your attachment, or log is from a past date

---

#### `GET /attachments/{id}/download`
Returns a signed URL (Azure SAS or S3 pre-signed) valid for 15 minutes.
```json
{
  "downloadUrl": "https://blob.storage.../..?se=...&sig=...",
  "expiresAt": "2026-07-20T10:00:00Z"
}
```

---

### SEARCH

```
GET    /search?q={query}&page=1&pageSize=20
```

**Query params**

| Param | Type | Notes |
|-------|------|-------|
| `q` | string | Search keyword |
| `projectId` | guid (optional) | Filter by project |
| `userId` | guid (optional) | Admin: filter by employee |
| `from` | date (optional) | `yyyy-MM-dd` |
| `to` | date (optional) | `yyyy-MM-dd` |
| `page` | int | Default 1 |
| `pageSize` | int | Default 20, max 100 |

**Note**: Employee can only search their own logs. Admin searches all.

**Response 200**
```json
{
  "results": [
    {
      "logEntryId": "guid",
      "logDate": "2026-07-20",
      "userId": "guid",
      "userName": "Rahul Sharma",
      "projectId": "guid",
      "projectName": "Credvisor",
      "excerpt": "...Fixed the OTP timeout issue in the login...",
      "matchedAt": "description"
    }
  ],
  "total": 8,
  "page": 1,
  "pageSize": 20
}
```

---

## Error Response Standard

All errors follow this shape:

```json
{
  "statusCode": 400,
  "message": "Log date must be today.",
  "errors": {
    "logDate": ["Date must be today's date."],
    "entries[0].projectId": ["This project is not assigned to you."]
  },
  "traceId": "00-abc123..."
}
```

---

## Auth & Authorization Rules

| Endpoint Group | Admin | Employee |
|----------------|-------|----------|
| `POST /users` | YES | NO |
| `PUT /users/{id}` | YES | NO |
| `GET /users` | YES | NO |
| `GET /users/me` | YES | YES |
| `POST /projects` | YES | NO |
| `DELETE /projects/{id}` | YES | NO |
| `POST/DELETE /projects/{id}/members` | YES | NO |
| `PATCH /projects/{id}/archive` | YES | NO |
| `GET /projects` | YES - All | YES - Assigned only |
| `GET /projects/{id}/timeline` | YES | YES (if member) |
| `POST /logs` | YES - own | YES - own |
| `PUT /logs/{id}` | YES - today only | YES - today only |
| `GET /logs/user/{id}` | YES | NO |
| `GET /search` | YES - all | YES - own only |

---

## JWT Token Payload

```json
{
  "sub": "guid",
  "name": "Rahul Sharma",
  "email": "rahul@trackit.app",
  "role": "Employee",
  "iat": 1753024800,
  "exp": 1753028400
}
```

- Access Token: **60 minutes**
- Refresh Token: **30 days** (stored in DB, rotated on use)

---

## appsettings.json Structure

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=.;Database=TrackItDb;Trusted_Connection=True;"
  },
  "Jwt": {
    "Secret": "your-256-bit-secret-key-here",
    "Issuer": "trackit.app",
    "Audience": "trackit.app",
    "AccessTokenExpiryMinutes": 60,
    "RefreshTokenExpiryDays": 30
  },
  "Storage": {
    "Provider": "Azure",
    "AzureConnectionString": "DefaultEndpointsProtocol=https;...",
    "ContainerName": "trackit-attachments",
    "MaxFileSizeMB": 50
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  }
}
```

---

## Business Logic Rules (Server-Side Enforcement)

```
1. POST /logs  → LogDate MUST be today (UTC). Return 400 if not.
2. PUT /logs/{id} → Log.LogDate MUST be today. Return 403 if past.
3. Employee can only log entries for projects they are assigned to.
4. One DailyLog per (UserId, LogDate) — enforced by unique DB constraint + service check.
5. POST /attachments → Only allowed if DailyLog.LogDate == today.
6. DELETE /attachments → Only allowed if owner + log is today.
7. Archived project entries still visible in history but won't appear in POST /logs project list.
8. Employee cannot see other employees' logs via GET /logs/* — only Admin can.
9. Search: Employee sees own logs only. Admin sees all.
10. User deactivation (IsActive=false) → 401 on next login / token refresh.
```

---

## Suggested NuGet Packages

```xml
<!-- TrackIt.API -->
<PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="8.*" />
<PackageReference Include="Swashbuckle.AspNetCore" Version="6.*" />
<PackageReference Include="Serilog.AspNetCore" Version="8.*" />

<!-- TrackIt.Application -->
<PackageReference Include="AutoMapper" Version="13.*" />
<PackageReference Include="FluentValidation.AspNetCore" Version="11.*" />
<PackageReference Include="BCrypt.Net-Next" Version="4.*" />

<!-- TrackIt.Infrastructure -->
<PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="8.*" />
<PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="8.*" />
<PackageReference Include="Azure.Storage.Blobs" Version="12.*" />
```

---

## EF Core Migration Commands

```bash
# Add a migration
dotnet ef migrations add InitialCreate --project TrackIt.Infrastructure --startup-project TrackIt.API

# Update database
dotnet ef database update --project TrackIt.Infrastructure --startup-project TrackIt.API
```

---

## Flutter <-> .NET Mapping

| Flutter Provider | .NET Endpoint |
|-----------------|---------------|
| `currentUserProvider` | `GET /users/me` |
| `myProjectsProvider` | `GET /projects` |
| `todayLogProvider` | `GET /logs/today` |
| `yesterdayLogProvider` | `GET /logs/2026-07-19` |
| `allLogsProvider` (admin) | `GET /logs/user/{id}` |
| `datesWithLogsProvider` | `GET /logs/user/{id}?from=...&to=...` |
| `searchResultsProvider` | `GET /search?q=...` |
| `employeeTodayStatusProvider` | `GET /users/{id}/today-status` |
| `saveLog(ref, log)` | `POST /logs` or `PUT /logs/{id}` |
| Project member assign | `POST /projects/{id}/members` |
| Project member remove | `DELETE /projects/{id}/members/{userId}` |
| Archive project | `PATCH /projects/{id}/archive` |
