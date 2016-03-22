# You-Get.bot

A naïve bot that listens to GitHub webhooks, (asynchronously) tests URL downloads with `you-get` on a remote server, thus helps me to maintain the [you-get](https://github.com/soimort/you-get) project.

## System requirements

The bot server runs on **Node.js 5.9.0** and **CoffeeScript 1.10.0**. Older versions may or may not work.

These dependencies are required during run-time:

* you-get >= 0.4 (and python3)
* git >= 1.8.5
* bind-tools (specifically, the dig program)
* geoip
* [translate-shell](https://www.soimort.org/translate-shell/) >= 0.9

Tested on CentOS 7 and Arch Linux.

## Step-by-step

1. Register a [machine user on GitHub](https://developer.github.com/guides/managing-deploy-keys/#machine-users). (and optionally: attach an SSH key to it)
2. Create an [access token](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) for _the machine user_.
3. Login as _the administrator_ of [soimort/you-get](https://github.com/soimort/you-get), and:
   1. Add the machine user as a collaborator;
   2. Create a [webhook](https://developer.github.com/webhooks/creating/) and point it to your server. On more details about how to set up a payload server, you can follow the [GitHub webhooks tutorial](https://developer.github.com/webhooks/) if you want, though their example code is in Ruby.
4. Create a `bot.sh` on the production server:
```sh
export GITHUB_OAUTH_TOKEN=    # Add the bot's access token here
export WEBHOOK_SECRET_TOKEN=  # Add the repository's webhook secret token here
export GITHUB_OWNER=soimort   # Change these if you would like to use it on
export GITHUB_REPO=you-get    #   another GitHub repository
coffee server.coffee 4567     # Change this number to your port of choice
```

And deploy it! (using [pm2](http://pm2.keymetrics.io/))

    $ pm2 start bot.sh
