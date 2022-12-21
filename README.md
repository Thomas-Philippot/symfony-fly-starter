# Symfony Fly Starter

This repo is an exemple/starter repo to deploy Symfony on Fly.io.
### Docker
- PHP 7
- Nginx
- Supervisor

see the docker folder and `Dockerfile`

### Environment Variables
see : https://fly.io/docs/rails/the-basics/configuration/
If you want to add non-secret env variables, add them to the `[env]` section of the `fly.toml`

## Requirements
- [Flyctl](https://fly.io/docs/hands-on/install-flyctl/)
- [docker](https://docker.com/)
- [composer](https://getcomposer.org/)

## Install

```bash
composer install
```

## Deploy

```bash
flyctl launch
```