# Freshcom API

## This is a work in process

I don't recommend using this in production just yet. I am aiming for a stable release by early August 2018.

## Introduction

Freshcom API is a eCommerce backend solution that provides a RESTful eCommerce API.

Some key highlights of Freshcom API:

- Multi tenant
- Multi language support
- Advanced product pricing strategy
- Email and SMS templating without redeployment
- Test mode without effecting live store
- Two factor authentication for customer

Freshcom API can be used with [Freshcom Dashboard](https://github.com/freshcom/freshcom-dashboard) which is the front-end for back office.

The front-end for the customer facing store is not provided. This is intentional because every store demands different experiences for their customer, it is up to you to develop your own customer facing store using the Freshcom API. We recommend using [VueJS](https://vuejs.org), but any SPA front-end (ex. React, Angular) framework works well with our [JS SDK](https://github.com/freshcom/freshcom-js-sdk)

## Required Third Party Dependencies

Right now Freshcom API depends on the following third party services.

- AWS S3 for file storage
- AWS Cloudfront for CDN
- AWS SES for account specific email
- Postmark for global email
- Stripe for payment processing
- Sentry for error tracking

## Getting Started

1. Clone this repo
2. Rename `.env.example` to `.env`
3. Generate RSA key pairs and put them into `keys/dev` folder
4. Add your credentials for third party services
5. Install dependencies with `mix deps.get`
6. Create and migrate your database with `mix ecto.create && mix ecto.migrate`
7. Start Phoenix endpoint with `mix phx.server
8. You can now make API request to [`localhost:4000`](http://localhost:4000)

## Generate RSA key pairs

To generate use the following command

```
> openssl genrsa -out private.pem 2048
> openssl rsa -in private.pem -outform PEM -pubout -out public.pem
```

