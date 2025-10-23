# 🎬 Dopa Shorts

**Dopa Shorts** is a short video sharing app built with **Flutter**, **Supabase**, and **Firebase**.  
Users can upload, view, like, follow, and get real-time push notifications for new interactions — just like TikTok or Instagram Reels.

---

## 🚀 Features

- 📱 **User Authentication**
  - Sign up / Sign in with email and password.
  - Secure session management using Supabase Auth.

- 🎥 **Short Video Feed**
  - Upload and view short videos.
  - Auto thumbnail generation using `video_thumbnail` package.
  - Smooth playback with `video_player`.

- ❤️ **Like System**
  - Like and unlike videos instantly.
  - Each like automatically generates a notification for the video owner.

- 👥 **Follow System**
  - Follow / Unfollow users.
  - Follow actions trigger real-time notifications using Supabase Edge Functions.

- 🔔 **Push Notifications**
  - Powered by **Firebase Cloud Messaging (FCM)**.
  - Notifications are sent via Supabase Edge Functions.
  - Tokens are managed in the `user_tokens` table.

- 💬 **Comments (Planned)**
  - Users will soon be able to comment on videos.

- 🌐 **Deep Linking**
  - App links supported for sharing and opening profiles/videos.

---

## 🧩 Tech Stack

| Component | Technology |
|------------|-------------|
| **Frontend** | Flutter (Riverpod, Provider) |
| **Backend** | Supabase (Auth, Database, Edge Functions) |
| **Notifications** | Firebase Cloud Messaging (FCM) |
| **Storage** | Supabase Storage for videos and thumbnails |
| **Database** | PostgreSQL (via Supabase) |

---

## 🗂️ Database Schema

### `posts`
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| user_id | uuid | References `auth.users` |
| video_url | text | Supabase storage link |
| description | text | Caption or description |
| created_at | timestamp | Creation time |

### `likes`
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| post_id | uuid | References `posts(id)` |
| user_id | uuid | References `auth.users(id)` |
| created_at | timestamp | Time of like |

### `user_tokens`
| Column | Type | Description |
|--------|------|-------------|
| user_id | uuid | References `auth.users(id)` |
| token | text | Firebase device token |

### `notifications`
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| sender_id | uuid | Who triggered the notification |
| receiver_id | uuid | Who receives it |
| type | text | ‘like’, ‘follow’, etc. |
| message | text | Message body |
| post_id | uuid | Optional: Related post |
| is_read | boolean | Read/unread status |
| created_at | timestamp | Timestamp |

---

## ⚙️ Setup Guide

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/nk691/dopa_shorts.git
cd dopa_shorts