# TeSS

ELIXIR's Training e-Support Service using Ruby on Rails.

# Setup
Below is an example guide to help you set up TeSS in development mode. More comprehensive guides on installing
Ruby, Rails, RVM, bundler, postgres, etc. are available elsewhere.

## Ruby, RVM, Bundler, Rails
### Ruby and RVM

It is typically recommended to install Ruby with RVM. With RVM, you can specify the version of Ruby you want
installed, plus a whole lot more (e.g. gemsets). Full installation instructions are [available online](http://rvm.io/rvm/install/).

TeSS was developed using Ruby 2.2 and we recommend using version 2.2 or higher. To install it and quickly set up a gemset 'tess', you
can do something like the following:

 * `rvm install ruby-2.2-head`
 * `rvm use --create ruby-2.2-head@tess`

### Bundler
 "Bundler provides a consistent environment for Ruby projects by tracking and installing the exact gems and versions that are needed."

`$ gem install bundler`

### Rails

Once you have Ruby, RVM and bundler installed, from the root folder of the app do:

`$ bundle install`

This will install Rails, as well as any other gem that the TeSS app needs as specified in Gemfile (located in the root folder).

## PostgreSQL

1. Install postgres and add a postgres user, say 'tess_user', for the use by the TeSS app.
Make sure tess_user is either the owner of the TeSS database (to be created in the following step), or is a superuser.
Otherwise, you may run into some issues when running and managing the TeSS app.

 From command prompt:
 * `$ createuser --superuser tess_user`

 Connect to your postgres database console as superuser 'postgres' (modify to suit your postgres installation):
 * `$ psql -U postgres`

 From the postgres console, set password for user 'tess_user':
 * `postgres=# \password tess_user`

2. Create database 'tess_development' (or any other name you want - also make sure you configure this in
config/database.yml or config/secrets.yml). From postgres console do:
 * `postgres=# create database tess_development;`

 If your tess_user it not superuser, perform various GRANT commands (make sure you connect as superuser/DB admin):
 * `postgres=# GRANT ALL ON tess_development TO tess_user;`
 * `postgres=# \connect tess_development;`
 * `tess_development=# GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO tess_user;`
 * `ALTER USER tess_user CREATEDB;` # this command is so you can run rake db:create

 Test that you can now connect to the database from command prompt with:
 * `$ psql -U tess_user -W -d tess_development`

> Handy postgres/rails tutorials:
>
> https://www.digitalocean.com/community/tutorials/how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-14-04
>
> http://robertbeene.com/rails-4-2-and-postgresql-9-4/

## App

1. Copy config/example_secrets.yml to config/secrets.yml and configure your system.

2. Edit config/database.yml or config/secrets.yml (depending on your preference) to configure the database name, user and password defined above.

3. Run:
 * `rake db:setup`
 * `rake db:migrate`

4. You should be ready to fire up TeSS in development mode:
 * `rails server`

5. Access TeSS at:
 * `http://localhost:3000`.

## Basic API

A record can be viewed as json by appending .json, for example:

    http://localhost:3000/materials.json
    http://localhost:3000/materials/1.json

The materials controller has been made token authenticable, so it is possible for a user with an auth token to post
to it. To generate the auth token the user model must first be saved.

To create a material by posting, post to this URL:

    http://localhost:3000/materials.json

Structure the JSON thus:

    {
        "user_email": "you@your.email.com",
        "user_token": "your_authentication_token",
        "material": {
            "title": "API example",
            "url": "http://example.com",
            "short_description": "This API is fun and easy",
            "doi": "Put some stuff in here"
        }
    }

A bundle install and rake db:migrate, followed by saving the user as mentioned above, should be enough to get this
working.