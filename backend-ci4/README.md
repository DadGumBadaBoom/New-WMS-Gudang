# Backend (CodeIgniter 4)

Backend service for the warehouse management system, built with CodeIgniter 4. Use this to run the REST APIs, background jobs, and any integrations required by the Flutter frontend.

## Prerequisites

- PHP 8.1+ with `intl`, `mbstring`, `json`, `mysqlnd`, and `curl`
- Composer
- MySQL/MariaDB (or another configured database)
- Git (optional, for clone)

## Quick start

1) Install dependencies:

```bash
composer install
```

2) Copy environment file and adjust settings:

```bash
cp env .env
```

Update `.env` for:
- `app.baseURL` (e.g. http://localhost:8080)
- Database credentials (`database.default.*`)

3) Run database migrations and seeders when available:

```bash
php spark migrate
php spark db:seed <SeederName>
```

4) Serve locally:

```bash
php spark serve
```

The app serves from `public/` by default. Configure your web server (Nginx/Apache) to point to that folder in non-dev environments.

## Testing

```bash
php vendor/bin/phpunit
```

## Common tasks

- Clear caches: `php spark cache:clear`
- Generate key (if needed): `php spark key:generate`
- Check routes: `php spark routes`

## Documentation

- CodeIgniter 4 guide: https://codeigniter.com/user_guide/
- Project docs: see [../docs](../docs) for architecture and troubleshooting notes.
