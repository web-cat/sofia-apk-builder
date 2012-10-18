Sofia APK Builder
====

Sofia APK Builder is a Sinatra app that allows students to effortlessly
upload their source code for a Micro-Sofia project and have an APK file
generated that they can install on their Android phone or tablet.


WARNING
----
Currently the service uses Virginia Tech's directory for authentication,
so modification would be necessary to use it elsewhere.


Developer Instructions
----

1. Make sure you have Ruby 1.8.7 or higher installed.
2. Install Bundler ("gem install bundler") if you haven't already.
3. Run "bundle install".
4. Run "./run-devel.sh" to start the local development server.


Deployment Instructions
----

Refer to your web server's documentation (nginx, Apache, etc.) for help
on deploying the app.


Project Structure
----
* lib/ - Support code.

* masters/ - Master projects that are merged with student code. Eventually
we might want to have multiple projects here and intelligently figure out what the student wants to build (for example, by scraping the README).

* public/ - Public web resources.

* storage/ - Storage area for building and for generated APKs.

* views/ - Ruby view templates.

* appconfig.yml - Application configuration, such as where the Android SDK is
located. Can be configured differently in development and production.
