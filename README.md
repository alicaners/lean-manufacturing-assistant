# Yalın Üretim Asistanı (Lean Manufacturing Assistant)

[![Backend CI](https://github.com/alicaners/lean-manufacturing-assistant/actions/workflows/backend-ci.yml/badge.svg?branch=main)](https://github.com/alicaners/lean-manufacturing-assistant/actions/workflows/backend-ci.yml)
[![Mobile CI](https://github.com/alicaners/lean-manufacturing-assistant/actions/workflows/mobile-ci.yml/badge.svg?branch=main)](https://github.com/alicaners/lean-manufacturing-assistant/actions/workflows/mobile-ci.yml)
[![Main CI](https://github.com/alicaners/lean-manufacturing-assistant/actions/workflows/main-ci.yml/badge.svg?branch=main)](https://github.com/alicaners/lean-manufacturing-assistant/actions/workflows/main-ci.yml)

Kaizen, 5S ve Andon süreçlerini kâğıttan çıkarıp tek bir mobil uygulamada
birleştiren, offline çalışabilen bir fabrika uygulaması.

A mobile app that digitizes Kaizen, 5S and Andon lean manufacturing processes,
built with Flutter and ASP.NET Core.

> 🚧 Geliştirme aşamasında / Work in progress

## Teknolojiler / Tech stack

- **Mobil:** Flutter, Bloc, drift (offline), Firebase Cloud Messaging
- **Backend:** ASP.NET Core (.NET 10), Clean Architecture, modüler monolit
- **Veri:** PostgreSQL, Redis, MinIO
- **DevOps:** Docker, GitHub Actions

## Repo yapısı / Repository structure

| Klasör | İçerik |
| --- | --- |
| `mobile/` | Flutter uygulaması |
| `backend/` | ASP.NET Core API |
| `infra/` | Docker Compose ve altyapı ayarları |
| `load-tests/` | k6 yük testleri |
| `docs/` | Mimari, iş kuralları ve mimari karar kayıtları (ADR) |